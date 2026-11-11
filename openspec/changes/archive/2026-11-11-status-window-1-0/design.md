# Design

## Context

- All "is it low" decisions live inline in `Triggers.Update` (the `now` table) and `Controller.Evaluate` (the reagent test, which repeats `Reagents.Low`). The window needs the same answers, so they must be shared or the two will drift.
- `Controller.offer` has an `auto` branch that pins without asking and prints the "why" notice. A row click needs exactly that, regardless of mode.
- `clearVendorNav()` runs when any trigger reports `{"clear"}`, so a manual pin could be wiped by an unrelated trigger.
- `A.mapPosition()` returns nil where the game gives no position. In a battleground a position probably exists but the continent has no vendors, so `findVendor` returns "novendor", the request is dropped and `Triggers` has already latched it (battleground bug; position behavior unverified in-game).
- `Options.lua` is one long page. The Settings API's subcategory function is unverified on Classic Era and Forever.
- Game calls are only in `Adapter.lua`; `Report.lua` and `Options.lua` already create frames, which is the precedent for a UI file.
- `GetBindLocation()` returns a place name only, no coordinates (unverified on 1.60).

## Goals / Non-Goals

**Goals:**
- One source of truth for "low". A window row and a warning can never disagree.
- Click to navigate with no question, one entry point, same wording and notices as an auto pin.
- A window that costs nothing when mode is all `never`.
- Instances handled explicitly instead of by accident.
- Settings split without renaming or migrating any saved key.

**Non-Goals:**
- Potions, pet food, bandages, healthstones, mana gems, gold, hearthstone cooldown (future specs, listed in the proposal).
- Opening a specific settings subcategory from the cog.
- Redesigning the settings layout beyond this split.

## Decisions

### Shared conditions
`Triggers.Conditions(cfg, free, dur, ammo)` returns `{ sell, repair, ammo }` booleans; `Update` and the window both call it. The controller uses `Reagents.Low`. Professions use `Professions.Within`. Mutation tests then cover warning and row together.

### Pure `Status.lua`, frame in `Tracker.lua`
`Status.Rows(snapshot, cfg, class)` returns `{ key, kind, id, text, low, routable }` in a fixed order. `Status.Visible(rows, cfg)` applies each row's mode and returns the shown rows (empty means hide the window). All text is `L["..."]` with whole sentences, e.g. `L["Bag space: %d free"]`. `Tracker.lua` only draws, moves and forwards clicks; all state reads (shift key, combat, bind location, instance type) go through new Adapter functions. Core builds it in `pcall`, like Options.

Alternative considered: put row logic in the frame file. Rejected: untestable under `luajit tests/run.lua`.

### Refresh
Existing events (`BAG_UPDATE_DELAYED`, `UPDATE_INVENTORY_DURABILITY`, `UNIT_INVENTORY_CHANGED`, `SKILL_LINES_CHANGED`, `SPELLS_CHANGED`) set a dirty flag; one `A.after(0.25)` timer redraws. Skills are cached and refreshed on `SKILL_LINES_CHANGED`. With every row `never`, nothing is computed.

### One mode per row group, one table (decision, revised)
`cfg.hudRow = { [group] = "low"|"always"|"never" }` with exactly five group keys: `ammo`, `reagents`, `bags`, `durability`, `professions` (`Status.GROUPS`, in window order). Absent means `low` for every group. Rows keep their own stable keys for drawing and logging (`ammo`, `bags`, `durability`, `prof:<name>`, `reagent:<itemId>`), and `Status.Group(rowKey)` maps each to its group; `Status.Mode(cfg, rowKey)` looks the mode up through the group, so every profession row follows Professions and every reagent and display-only row follows Reagents. Absent-by-default means a row added later (a new profession, a new reagent) needs no setting of its own.

The first build had a mode per row (`prof:<name>`, `reagent:<itemId>` keys, display-only items defaulting to `never`): twelve profession dropdowns and one per reagent made the settings page long, and a mode for a profession the character does not have meant nothing. It was never released, so there is no migration; `Core.init` drops any `cfg.hudRow` entry that is not a group key with a real mode (a `prof:` or `reagent:` key from a test build), and `Status.Mode` ignores such keys anyway.

Display-only items have no low state, so in the Reagents group they show only while Reagents is `always`; `low` and `never` hide them. That keeps the old default (hidden) without a second default, and one Reagents choice still means one thing for every reagent line. `Status.Snapshot` reads their counts only while Reagents is `always`, since nothing else could show them.

### Display-only items
Reagent-table entries gain `vendor = false`. They have no `bit` (they are never in a vendor record) and are skipped by `Watched`. Conjured Food and Water carry a list of item ids; the count is the sum. Item ids must be verified against the wago tables before use, as was done for reagents; if an id cannot be verified it is left out rather than guessed.

### Direct pin: `Controller.Go(kind, id)`
Refactor the auto branch of `offer` into `autoPin(...)` and call it from `Go`. `Go` ignores `vendorMode`, still uses `vendorPrefer`, ignores the combat gate (an explicit action), closes an open question (`cancelPrompt`), and when the condition is low now calls a new `triggers.Take(kind, id)` that marks it handled and active, so the normal "ends on resolution" rules apply and it is not asked again. No position or no vendor reuses the `Test` messages.

### Pin kinds
Record `pinKind` (and item id) when a pin is set. A trigger's `{"clear"}` removes only a pin of its own kind; a merchant window still clears every vendor pin. A profession row click is allowed only while the profession is within its threshold, so `checkTrade` never clears it at once.

### Instances
`A.instanceType()` wraps `IsInInstance()` and returns `none`, `party`, `raid` or `pvp`, nil when unknown (treated as `none`). `Triggers.Update` takes an `inInstance` input beside `inCombat` and returns before picking, so no latch is consumed. `DB.lastOutside = { continent, map, x, y }` is saved on evaluate while `none` and a position exists. The hearthstone point: on login and zone change read `GetBindLocation()`; when the name differs from `DB.hearth.name` and a position exists, save the position. `findVendor` takes an optional anchor in place of the player position. A pin made from an anchor says so in chat (new `L[...]` sentence).

Alternative considered: match innkeeper data to the bind name. Rejected: names are localized and pfQuest keys innkeepers by zone, so matching is brittle.

### Auction routing
`build_vendors.py` writes the pfQuest `["auctioneer"]` list as `ns.ShippedAuctioneers` (28 with coordinates, 6 neutral marked as both factions, per the earlier parse). The addon learns auctioneers on the auction house open event (name to be confirmed in-game on Forever) using the same record and replace rules. `Search` gains the need `"auction"` and returns the nearest auctioneer. `Controller.Go` compares the nearest vendor and nearest auctioneer when `ahEnabled` and the item is tradeable and not in an instance. Soulbound is a per-item constant on the table (all of today's items are tradeable); the binding of future items is read once from item info (unverified on 1.60).

### Settings
A `page(name)` helper returns a subcategory (`Settings.RegisterVerticalLayoutSubcategory`) or the parent page when that is missing; section headers are used either way. The cog calls the same open function as `/cvn config` with the parent category id. `fake_settings.lua` records subcategories. All existing variable names stay; moving a control loses nothing. New flat keys in `DB.cfg`: `hudRow`, `hudLocked`, `hudScale`, `hudAlpha` (background opacity, percent 0-100, default 80), `hudTextAlpha` (text and icons, percent 20-100, default 100), `hudColor` (background, `"rrggbb"`, default `"000000"`), `instanceAnchor` (default `hearth`), `ahEnabled` (default false). `Core.init` holds the three numbers to `Commands.LIMITS` and resets a saved color that is not six hex digits to black; the sliders take their ranges from the same limits. Position lives in `DB.hud`; `DB.lastOutside` and `DB.hearth` are separate tables.

### Opacity and color (OLED-safe)
The background is one texture with `SetColorTexture(r, g, b, alpha)`; at alpha 0 it is hidden rather than drawn transparent, so nothing at all is behind the text whatever the color. No border, no other fill; a low row is red text only. Text opacity is `SetAlpha` on the title, the cog and each row button (a row made later starts with it), never on the window frame, so it does not multiply into the background. The minimum is 20 percent so the window can always be read. Colors are kept as `"rrggbb"` (`Status.Color`, `Status.Hex`, `Status.ParseColor`, pure Lua). The picker is `Adapter.pickColor`, guarded and in `pcall`: the newer `ColorPickerFrame:SetupColorPickerAndShow(info)` or, on older clients, the field-by-field setup; no opacity in the picker (opacity has its own slider); Cancel restores the starting color. Its presence on Classic Era and Forever is unverified, so `Options` shows the color control only when `Adapter.hasColorPicker()` is true and `CreateSettingsButtonInitializer` exists. The control is one settings button labelled Background color whose text is a texture tinted with the saved color (a swatch); clicking it opens the picker at that color, any color allowed, and the pick is saved and the swatch text updated (a color set by command shows when the page is next shown). There is no dropdown, and the button has no registered setting (the swatch row below has one); where the picker or button is missing no control is shown, and `/cvn hud color <#rrggbb|black|reset>` is the way to set and reset it. `/cvn hud color` with no argument opens the same picker (Commands returns the action `{"hud","pick"}`, Core calls `Adapter.pickColor`, so Commands stays pure) and says in chat when there is none. When the swatch cannot be built, Options names each missing piece to Core, which logs it and prints it in the report header together with `Adapter.hasColorPicker` and `Adapter.hasSettingsButton`. The button is now the fallback for the game's swatch row (see Color swatch row).

### Color swatch row (decision)
The first build drew the color as a `CreateSettingsButtonInitializer` button whose text is a tinted `|T...|t` tile; on Forever 1.60.1 that is a wide red push button with a black tile in it, not what a color option looks like. Both Classic Era and Forever ship the game's own swatch row in `Blizzard_Settings_Shared` (checked on the `forever` branch, build 1.60.1 (70888), and `classic_era` of Gethe/wow-ui-source): `Settings.CreateColorSwatch(category, setting, tooltip)` adds a `SettingsColorSwatchControlTemplate` row (label on the left, a 16 px bordered `ColorSwatchTemplate` square on the right; clicking it or the label opens `ColorPickerFrame:SetupColorPickerAndShow`, Cancel restores `GetPreviousValues()`), the same row retail uses through `Settings.SetupCVarColorSwatch`. Its setting is a string in `"aarrggbb"` form (it reads `CreateColorFromHexString`, writes `GenerateHexColor()`).

`Options` builds that row first: a `Settings.RegisterAddOnSetting` named `CLOSESTVENDOR_HUD_COLOR` over a proxy that reads `"ff" .. hudColor` (black when the saved value is not a color) and writes back the last six hex digits in lower case (anything else is ignored), with `onChange` as its callback, all in `pcall`. The row's swatch is set from the setting on every page show and after every pick, so a `/cvn hud color` or reset shows on the next visit and the tooltip is the setting's. It is only tried when `Settings.CreateColorSwatch` exists, the picker exists and `Adapter.hasSwatchPicker()` (both `SetupColorPickerAndShow` and `GetPreviousValues` on `ColorPickerFrame`) is true, since the game's row calls them directly, not through `Adapter.pickColor`. Otherwise, or when it raises an error, the tinted button above is built as before; the note says which control was built and names what the swatch lacked (`Settings.CreateColorSwatch`, the picker calls, or the error), and the report header shows it. A hand-made swatch (our own `ColorSwatchTemplate` frame in a `SettingsListElementTemplate` row) was not chosen: it needs frame code in Options and hooks into `InitFrame`, while the game's row is already there on both clients.

### Rows that do not apply are greyed out (decision)
The Status window page always lists the five group rows, in window order (Ammo, Reagents, Bag space, Durability, Professions), so nobody looks for an option that is missing. Ammo applies to Hunters, Rogues and Warriors; Reagents to any class with class reagents or display-only items (so a Warlock can show Soul Shards). A row that does not apply is greyed out with `initializer:AddModifyPredicate(function() return false end)`, the game's own way (`SettingsElementHierarchyMixin:AddModifyPredicate` in `Blizzard_Settings_Shared/Blizzard_SettingControls.lua`, used for example in `Blizzard_SettingsDefinitions_Frame/Accessibility.lua`; same on the `forever` and `classic_era` branches), guarded by `if init.AddModifyPredicate`. Its tooltip is the reason (`L["Your class does not use ammo."]`, `L["Your class does not use reagents."]`), and its setting never writes `cfg.hudRow`. `Status.Rows` and `Status.Visible` are unchanged: such a class still shows no window line. Without the predicate API the row stays usable but writes nothing.

### Demo
`Controller.Demo()` and `Tracker` accept a fake snapshot and fake modes that replace the real ones for 10 seconds. It rolls from a seeded list (seed from `GetTime`, passed through the Adapter) so tests can fix it. The warning is one of: auto notice, question dialog, or direct pin, all through real code paths. When the timer fires (token guard so a newer demo is not cut short): clear the pin the demo set, cancel the demo question, drop the fake snapshot, redraw. It writes nothing to `DB.cfg`. A demo pin replaces any existing waypoint and the old one cannot be restored (TomTom does not expose it).

### Reagent buying (decision)
Mirrors ammo buying: pure logic in `Reagents.lua` (`R.BuyPlan`, `R.OnMerchant`, game reads through an `env` built in Core), game calls in new Adapter functions. Differences from ammo, each on purpose:
- **What is bought:** the reagents the warning watches (`reagentList` in Core: spell known, not switched off, count readable) that the merchant sells (`A.merchantReagents`: items of the Reagents table only, so never display-only items, gold price only). The same counts as the warning are used. Buying a reagent for a spell the player does not know, or one the player switched off, would spend money for nothing; the per-reagent checkbox is the per-reagent control (its tooltip says so).
- **How much:** "stock up to N each": `reagentBuyTarget - carried` per reagent, never above. An item sold in batches is bought in whole batches that stay within N (`floor`), never rounded up. 0 buys none.
- **Where it goes:** general-purpose bags only (`A.bagSlots`: backpack and bags of family 0; quivers, ammo pouches, soul and profession bags cannot hold class reagents). Room is partial stacks of the same item plus empty slots at the item's stack size (`A.stackSize`); empty slots are shared, so what one reagent fills is gone for the next. A bag whose kind cannot be read is left out (less room, never more); an unreadable slot makes the whole purchase unknown. `bagSlot` now calls the slot API directly so a failing call is unknown instead of an empty slot (ammo gains this too).
- **Money:** spent in reagent table order; the money read is less what an ammo purchase made at once at the same merchant cost (`Ammo.OnMerchant` returns it), since the game updates the money only when the server answers. A pending ammo question is not counted; the server refuses a purchase that cannot be paid.
- **Calls:** single items are bought `quantity` at a time up to `GetMerchantItemMaxStack` (guarded; one per call when unknown), so 100 items are a handful of calls, not 100. Batches are one call per batch, as for ammo.
- **Dialog:** its own `CLOSESTVENDOR_CONFIRM_REAGENTS`, same buttons as the ammo one, so a rogue with both questions sees both. Defaults: off (buying spends money on a new feature), ask first, 20 of each (four times the default warning threshold of 5, a few casts of every reagent).
- **Chat:** one line, `L["Bought %s for %s."]` (and "(all you could afford)" or "(all that fits in your bags)") with the list built from `L["%d %s"]` items joined by commas, as `/cvn` already joins lists; nothing to buy because of money or bags says so; nothing needed is silent.

### Version
1.0.0 as one release, by explicit request. `CLAUDE.md` would otherwise give a minor bump for a feature; this exception is recorded in the CHANGELOG.

## Risks / Trade-offs

- **Subcategories on Era and Forever unverified.** Mitigated by the one-page fallback and tests of both paths.
- **`ColorPickerFrame` and the settings button initializer on Classic Era and Forever unverified.** Guarded in the Adapter (nil when missing); no color control is shown without them and `/cvn hud color` works.
- **Game swatch row unverified in-game.** `SettingsColorSwatchControlTemplate` exists in the 1.60.1 and Era UI source but no Classic page uses it, so it may look or behave differently there (Blizzard's own comment: no disabled look yet). Mitigated: only built when its function and picker calls exist, built in `pcall`, falls back to the button, and the note in `/cvn log` says which one was built.
- **Settings layout lookup.** Verified on Forever 1.60.1: `category:GetLayout()` does not exist there, so the swatch and the section headers were never built. The layout is the second return value of `Settings.RegisterVerticalLayoutCategory` and `...Subcategory` (as in the Blizzard Settings API, unverified in-game); `Options` keeps it per page, falls back to `category:GetLayout()` when that exists, and otherwise builds nothing and says so in the note.
- **`BackdropTemplate` and the cog texture on 1.60 unverified.** Use a plain colored texture background (as `Report.lua`) and a text fallback if the cog texture is blank.
- **Whether a battleground reports a position is unverified.** The instance wait does not depend on it.
- **`IsInInstance()` and `GetBindLocation()` text on Forever unverified.** Unknown is treated as open world; a failed bind read just keeps the old point.
- **Pin from inside an instance:** TomTom may refuse a waypoint set while inside; then chat says so.
- **A moved window after a UI-scale change** could land off screen; the frame is clamped and `/cvn hud reset` recovers it.
- **Ammo use may not fire frequent bag events.** The window could lag by one event; verify in-game.
- **Buying with a quantity unverified in-game.** `BuyMerchantItem(index, quantity)` and `GetMerchantItemMaxStack` are used by the game's own merchant frame on Era; if a client buys one item per call the count falls short (never over). Test plan 13.7.
- **A Yes after the merchant closed** buys nothing but the chat line still reports the purchase, as for ammo.
- **Big release.** One change keeps one version bump but is large; tasks are phased so each phase is testable alone.

## Open Questions

- None blocking. In-game checks go in the test plan (position in each battleground, `IsInInstance()` on Forever, `GetBindLocation()` text, TomTom from inside an instance, auction house open event name).
