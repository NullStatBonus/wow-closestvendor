# Design

## Context

Greenfield addon, MIT licensed. See proposal.md for motivation. The game API exposes no "list vendors" call, so vendor locations must ship with the addon or be learned in play. Client DB2 data (wago.tools) has map definitions but, as far as verified, not NPC spawns or vendor flags (those are server-side).

Verified:
- Blizzard's UI source (`Gethe/wow-ui-source`): Classic Era 1.15.9 has no `C_Map.SetUserWaypoint` and no `C_SuperTrack`; WoW Forever 1.60.1 has both. Both have `C_Map.GetWorldPosFromMapPos`.
- The sibling addon `wow-dontdothat` ships `DontDoThat_Vanilla.toc` (`## Interface: 11509`) and `DontDoThat_Camelot.toc` (`## Interface: 16001`), so those are the Era and Forever interface numbers and TOC suffixes.
- pfQuest (MIT) carries `meta.vendor` and `meta.repair` unit lists (unit id -> faction), unit coordinates (zone percent, zone id) and names. Questie (GPL-3), vmangos (GPL-2) and cmangos (GPL) do not fit an MIT repo.
- TomTom and WaypointUI APIs are verified only through third-party integrations, not their own source.

## Goals / Non-Goals

**Goals:**
- Tiny runtime cost: event-driven, one linear scan per trigger.
- Works with TomTom (Forever and Era) and WaypointUI / the Blizzard waypoint (Forever); degrades to a chat message on Era without TomTom.
- Logic testable outside the game client.
- Data under licenses compatible with MIT.

**Non-Goals:**
- Pathing distance, cross-continent routing, config GUI (all v2 candidates).

## Decisions

1. **Static generated table, filtered at build time.** Keep only units listed in pfQuest `meta.vendor` or `meta.repair`. Alternative: depend on Questie at runtime; rejected (fragile coupling, GPL). Alternative: store all NPCs; rejected (extra data costs load time and memory).
2. **Sources joined offline.** Vendor/repair lists, coordinates and names from the pfQuest database (MIT; notice kept in `THIRD_PARTY.md`); pfQuest zone ids mapped to `uiMapID` using the wago `UiMapAssignment` CSV (`AreaID` column). Output: one generated Lua data file. **The data source is swappable:** the runtime reads only `ns.ShippedVendors` (record shape in decision 3, enforced by `tests/test_data.lua`), and the build separates `pfquest_records()` (source -> normalized records) from `render()` (records -> data file), so another source needs only a new records function. pfQuest is Vanilla data, so one dataset serves both clients; Forever-only vendors come from discovery (decision 10).
3. **Record shape on disk:** `{npcId, name, uiMapID, mx, my, faction, repair}` with `mx,my` in 0-1 map coordinates (pfQuest percent / 100); first coordinate used for roaming NPCs. At load each record gains world coordinates `wx,wy` and is bucketed by continent (decision 4), so the build never has to match the client's world-coordinate convention.
4. **Search:** player world position via native `C_Map.GetWorldPosFromMapPos(uiMapID, C_Map.GetPlayerMapPosition(uiMapID, "player"))` (HereBeDragons dropped: native API, no embedded libs). Record world coordinates come from the same call once at load. Compare squared distance over the current continent's bucket, filter repair and faction in the same loop. No spatial index: n is a few thousand and the scan runs only on triggers.
5. **Triggers:** `BAG_UPDATE_DELAYED` (free slots via `C_Container.GetContainerNumFreeSlots`, general bags only), `UPDATE_INVENTORY_DURABILITY` (lowest `cur/max` over equipment slots). Latch per condition; clear on `MERCHANT_SHOW`/condition clear; defer in combat. A slow ticker runs only while a request is pending (deferred by combat, or no map position yet) and re-evaluates, so deferred triggers do not depend on a lucky event.
6. **Adapter order:** TomTom -> WaypointUI -> Blizzard native waypoint -> chat print, first available wins, chosen by feature test.
   - TomTom: `uid = TomTom:AddWaypoint(mapID, x, y, {title=...})` with x/y in 0-1; remove with `TomTom:RemoveWaypoint(uid)` using the returned uid. Detect with `C_AddOns.IsAddOnLoaded("TomTom")`, not the global, because other addons define a fake `TomTom`.
   - WaypointUI: `WaypointUIAPI.Navigation.NewUserNavigation({name, mapID, x, y, ...})` with x/y in 0-100; clear with `ClearUserNavigation`. Requires `C_SuperTrack`, so Forever only.
   - Blizzard native: `C_Map.SetUserWaypoint` + `C_SuperTrack.SetSuperTrackedUserWaypoint(true)`, Forever only.
   - Each adapter converts from the stored 0-1 coordinates to its own scale.
7. **Config:** SavedVariables table, slash commands `/cvn bags <n>`, `/cvn dur <pct>`, per-trigger enable.
8. **Per-flavor TOCs.** `ClosestVendor_Vanilla.toc` (11509) and `ClosestVendor_Camelot.toc` (16001), same pattern as `wow-dontdothat`, with the same `## Version:` in both. Behavior differences still come from feature tests, not flavor checks. Alternative: one TOC with a comma-delimited interface list; rejected (the per-flavor pattern is proven in a shipping addon).
9. **Testability.** Threshold math, latch, nearest-vendor search and discovery merging live in modules that reference no WoW globals; WoW calls enter through thin wrappers in `Core.lua`. Tests: `luajit` (Lua 5.1, same dialect as WoW) scripts with stubs in `tests/`, stdlib `unittest` for `tools/`, one `make test` runs both.
10. **Vendor discovery.** On `MERCHANT_SHOW`, record the merchant (npc id from `UnitGUID("npc")`, name, `CanMerchantRepair()`, faction group, player map position, which is within interaction range) into `ClosestVendorDB.learned`, keyed by npc id. Learned records overwrite shipped ones with the same id (they are first-hand) and merge into the same bucket structure at load. Alternative: ship nothing and learn only; rejected (unusable until first visits).

11. **Confirmation dialog.** After a vendor is found, `Controller` calls `env.confirm(kind, vendor, accept)` instead of navigating; `Core.lua` implements it with a `StaticPopup` ("Your bags are almost full. Navigate to the closest vendor, X (Zone)?" / repair equivalent) whose Yes button runs `accept`, which clears any previous target and sets the new one. Declining or ignoring leaves the trigger latched, so it does not ask again until the condition clears and recurs. The dialog closes (`env.cancelConfirm()`) when the condition clears or a merchant opens. The dialog text is built by a pure function so it is tested without the game. No setting to turn the dialog off in this change.

12. **Test commands.** `Commands.Run` returns the lines to print plus an optional action (`{"test", kind}`); `Core.lua` hands the action to `Controller.Test(kind)`, which uses the same vendor search and the same `env.confirm` path as a real trigger but skips the triggers and their latch, so it works whatever the bags and gear are. It returns a message instead of showing a dialog when there is no map position or no eligible vendor. Any merchant window clears the destination, which also clears a test pin.

13. **Ammo trigger.** With a ranged weapon in slot 18 (`GetItemInfoInstant` class 2: bow 2 / crossbow 18 -> arrows, gun 3 -> bullets; thrown and wands ignored), the count is `GetItemCount` of the item in the ammo slot (0), which includes bags, and 0 if that ammo is the wrong kind (class 6, subclass 2 arrows / 3 bullets) or missing. Triggers gain an ammo condition with priority repair > ammo > sell; a lower priority never replaces an open or active higher one, and an ammo or repair trip covers selling. Events: `BAG_UPDATE_DELAYED`, `UNIT_INVENTORY_CHANGED` (player only) and `PLAYER_EQUIPMENT_CHANGED`.
14. **Ammo seller data.** The on-disk record gains an eighth field, an ammo code (0 none, 1 arrows, 2 bullets, 3 both); world coordinates move to positions 9 and 10 at runtime. The build reads pfQuest `items.lua` sold-by (`V`) lists for the standard vendor ammo (arrows 2512, 2515, 3030, 11285, 18042; bullets 2516, 2519, 3033, 11284, 15997; reputation-only Ice Threaded ammo is excluded). Discovery records the code from the merchant's items (item class 6, subclass 2 or 3), so Forever vendors and changed stock are learned. `Search.Nearest` takes a need: nil, "repair", "arrow" or "bullet".
15. **Reagents later.** Other consumables (class reagents) would be another condition of the same shape: an item set to count, a threshold, and a vendor flag. Not built here.

16. **Settings panel.** `Options.lua` uses the native vertical-layout Settings API, present on both Era and Forever (`Settings.RegisterVerticalLayoutCategory`, `RegisterAddOnSetting`, `CreateCheckbox`, `CreateSlider`, `RegisterAddOnCategory`, `OpenToCategory`), not the deprecated option templates. Each setting is registered against the saved `cfg` table (`variableTbl`), so the panel and `/cvn` read and write the same values with no sync code. Slider ranges come from `Commands.LIMITS`, the single source for the slash-command limits. Registration runs inside `pcall` so an API difference can never stop the addon loading. `/cvn config` opens the page. No test buttons in the panel (the `/cvn test` commands stay).

## Risks / Trade-offs

- [pfQuest data is Vanilla 1.12; Era 1.15 and Forever may differ] -> Discovery corrects what players visit; spot-check task compares a sample.
- [Forever-only vendors absent from shipped data] -> Discovery adds them as players meet them.
- [pfQuest coordinates are zone percent and can be rough for roaming NPCs] -> Use first coordinate; accept small error; discovery overwrites with first-hand position.
- [Straight-line distance misleads around terrain] -> Acceptable for v1; document it.
- [Era has no native waypoint API] -> Era users need TomTom for an arrow; otherwise the addon prints the vendor and coordinates to chat.
- [WaypointUI API known only via third-party addons] -> Feature-detect each method before use; fall back to the Blizzard waypoint on mismatch.
- [Fake global `TomTom` from other addons] -> Detect via `C_AddOns.IsAddOnLoaded`.
- [Listing in `meta.vendor` does not imply every vendor buys all items] -> Unverified; spot-check specialty vendors.
- [Player stands a few yards from the NPC when learning] -> Within interaction range; acceptable.

## Open Questions

- Which inventory events fire when ammo is used up while shooting (`UNIT_INVENTORY_CHANGED` and/or `BAG_UPDATE_DELAYED`)? Confirm in game; the addon listens to both.
- Whether `GetItemCount` of the ammo-slot item is the number the player expects when several stacks or grades are carried.
- WaypointUI: return value of `NewUserNavigation` and the meaning of `ClearUserNavigation`'s second argument; confirm against the installed addon.
- Resolved: pfQuest zone ids map to `uiMapID` through wago `UiMapAssignment.AreaID`; on the Era build (1.15.9.70576) every vendor zone resolves and no area is ambiguous. The build kept 895 of 970 listed vendors (75 have no coordinates in pfQuest; 303 of 306 repair vendors kept).
