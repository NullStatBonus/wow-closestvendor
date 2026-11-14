# Design

## Context

- Vendors reach the search through `Core.rebuildBuckets`, which merges the shipped list and the learned table with `Discovery.Merge` and converts each record to world coordinates by continent. `Search.Nearest` then picks the nearest eligible record; nothing in it knows about sources.
- `Adapter.lua` is the only file that reads game or third-party globals, guarded and in `pcall`, returning nil when something is missing. Optional addons (TomTom, WaypointUI) are already handled that way.
- NorgannonDB (separate addon, GPL-3.0, so nothing of it is copied) exposes `NorgannonDB:RequireSchema(major, minor)`, `:Peek(kind, id)` for bulk reads that do not keep records decoded, `categories.vendor.npcs` and `categories.repair.npcs` (id lists), `index.zones[areaId].npcs` (NPCs by zone), `maps` (area to UiMap), and NPC fields `name`, `flags`, `reaction`, `spawns` and `sells`. Positions are 0 to 100 percent of a zone map; zones carry `uiMapId` and sub-zones carry `parent`, `center` and `extent`.
- Measured earlier (read-only): it lists 76 vendors in the new zones, all with stock lists. Its positions for the vendors it shares with the shipped list agree closely (median gap 0.0004 of the map) with about 13% off by more than 3%.

## Goals / Non-Goals

**Goals:**
- A player in a new zone gets vendors from login when NorgannonDB is installed.
- No change at all when it is not installed, and no copy of its data.
- A vendor the player has opened stays the best evidence for flags and for a moved NPC.

**Non-Goals:**
- Replacing the shipped list, or reading vendors on older maps.
- Trainers, auctioneers, or anything else NorgannonDB holds.
- Any setting to switch the source on or off (it is on when installed).

## Decisions

1. **One pool, precedence only by NPC id.** All sources are searched together and the nearest eligible vendor wins. A ranked pick (prefer a source even when farther) would break "closest vendor". Rejected: choosing the first source that has any vendor.
2. **Field-level precedence.** Static data: NorgannonDB over shipped. Learned: flags and faction win when present; the position wins only when it is more than 3% of the map from the static position. Reason: a learned flag is what the player's client saw, while a learned position is where the player stood (within interaction range), so it is a little less exact than a spawn coordinate unless the NPC really moved. 3% is large against interaction range (a few yards) and small against zone size. Rejected: learned last (an observed repair vendor would stay "no repair"), and learned always first (it would keep the less exact position).
3. **NorgannonDB over shipped is specified but rarely applies.** Shipped has no vendors on the five new maps, so the two never share an id there. It is kept as the rule if the scope widens later.
4. **Scope to the five Forever-only maps.** They are identified by UiMap id (2482, 2548, 2652, 2521, 2665, 2524). Reading only their zones through `index.zones` and `categories.vendor` keeps the cost to dozens of records. On the 99% of vendors both sources share there is little to gain and some risk (13% position disagreements).
5. **Conversion reuses what we have.** Repair from the `REPAIR` flag. Ammo from the stock's item class and sub-class (arrows and bullets, as `Adapter.merchantAmmo` does). Reagents from `Reagents.Mask` and food, water and pet food from `Supplies.VendorMask` on the stock's item ids. Faction from the reaction code (`A` Alliance, `H` Horde, `AH` or none both).
6. **One guarded read in `Adapter.lua`**, `A.externalVendors(mapIds)`, behind `RequireSchema(1, 4)` and `pcall`, returning a list of our record shape or nil. It runs once after login and again when the `NorgannonDB` addon loads (`ADDON_LOADED`), then `Core` rebuilds the buckets. Both TOC files get `OptionalDeps: NorgannonDB`, which also makes it load first.
7. **Combining in pure Lua.** `Discovery` gets a function that takes the shipped list, the external list and the learned table and returns the pool, so it is testable without the game. `Core.rebuildBuckets` calls it.
8. **No new saved data.** External records are rebuilt each session and never written to `ClosestVendorDB`.

## Risks / Trade-offs

- **Sub-zone coordinates (settled by measurement).** In the NorgannonDB 1.5 data every vendor spawn on the five maps is listed under a zone that has its own map (Mount Hyjal 616, Riverglades 16591, Zephras Isle 16593); none sits under a sub-zone, and the sub-zones in the data carry no `center` or `extent`. So no sub-zone conversion exists: spawns whose area has no `uiMapId` in the five maps are skipped and counted. Shen'dralas and the Darkspear Islands have no vendors.
- **Position accuracy.** Of the 17 vendors shared with Wago, three are on the new maps (Grizzek and Martha Wellsworth in Riverglades, Lenedil Moonwing in Hyjal). Converting Wago's world position with the map's assignment (checked first on Ashenvale and The Barrens, which agree within 0.1 percent) puts them within about 0.4 to 2.3 percent of NorgannonDB, and Lenedil about 3.7 percent. Positions are good enough to navigate to the right area, which is why a learned position that differs by more than 3 percent wins.
- **Format drift.** The schema may change under us. `RequireSchema` and `pcall` turn that into "not supported", never an error. The adapter reads only the fields listed above.
- **Early-stage data.** It is crowd-sourced and new. A wrong position is limited to the new zones, and a learned vendor corrects it.
- **Licensing.** Reading another addon's data at runtime copies nothing into our package, which keeps the repo MIT; whether that is acceptable for the GPL data is the owner's decision, recorded here. No notice is added to `THIRD_PARTY.md` because nothing is distributed.
- **Zones with no data.** The Darkspear Islands have no vendors in it, so nothing improves there.
- **Load order.** If NorgannonDB loads late, the second read covers it. If it loads and then reloads its data, the next login sees it.

## Open Questions

- None.
