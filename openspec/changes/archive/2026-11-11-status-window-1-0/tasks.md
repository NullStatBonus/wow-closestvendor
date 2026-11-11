# Tasks

## 1. Shared logic and instance awareness

- [x] 1.1 `Triggers`: extract `Conditions(cfg, free, dur, ammo)`; `Update` uses it; add an `inInstance` input that returns before picking without consuming any latch; `tests/test_triggers.lua` (including the battleground latch case)
- [x] 1.2 `Controller.Evaluate`: use `Reagents.Low` instead of the repeated test; `tests/test_controller.lua`
- [x] 1.3 `Adapter`: `instanceType()` (guarded `IsInInstance`, nil when unknown), `bindLocation()`, `shiftDown()`; `tests/test_adapter.lua`
- [x] 1.4 `Core`: save `DB.lastOutside` while in the open world with a position; learn `DB.hearth` when the bind name changes; log instance changes; `tests/test_core.lua`
- [x] 1.5 `Search`/`Controller.findVendor`: optional anchor in place of the player position; `tests/test_search.lua`

## 2. Direct pin

- [x] 2.1 `Controller`: factor the auto branch of `offer` into `autoPin`; record `pinKind`; a trigger clear removes only its own kind, a merchant window still clears all; `tests/test_controller.lua`
- [x] 2.2 `Triggers.Take(kind, id)`: mark a low condition handled and active; `tests/test_triggers.lua`
- [x] 2.3 `Controller.Go(kind, id)`: no question, ignores `vendorMode`, works in combat, closes an open question, uses the anchor in instances, says so in chat, "no vendor" and "no anchor" messages, profession rows only while within threshold; `tests/test_controller.lua`

## 3. Items and rows

- [x] 3.1 `Reagents`: `vendor = false` display-only entries (Soul Shards, Blinding Powder, Conjured Food, Conjured Water with summed item ids); verify item ids and spells against the wago tables first and leave out any that cannot be verified; `Watched` skips them; `tools/build_vendors.py` and `tests/test_data.lua` ignore them; `tests/test_reagents.lua`
- [x] 3.2 `Status.lua` (pure): `Rows`, `Visible`, per-row modes and defaults, nil hides, low marking; add to both TOCs; `tests/test_status.lua`
- [x] 3.3 `Core`: saved keys `hudRow`, `hudLocked`, `hudScale`, `hudAlpha`, `instanceAnchor`, `ahEnabled` with defaults, `DB.hud`; report header lists them and the log records instance changes and clicks; `tests/test_core.lua`

## 4. Window

- [x] 4.1 `Tracker.lua`: frame with title, rows, cog, plain background, title drag and Shift-drag, lock, clamped, saved position, scale and opacity, row click calling `Controller.Go`, display-only rows inert; add to both TOCs after `Report.lua`; `tests/test_tracker.lua` in the fake-frame style
- [x] 4.2 `Core`: build the tracker in `pcall`, dirty-flag refresh with one `A.after(0.25)` timer, cached skills, no work when every row is `never`; `tests/test_core.lua`
- [x] 4.3 `Commands`: `/cvn hud lock|unlock|reset|scale <50-200>|row <name> low/always/never`, `/cvn anchor hearth|last`, `/cvn ah on|off`; status lines; help; `tests/test_commands.lua`, `tests/test_readme.lua`

## 5. Auction house

- [x] 5.1 `tools/build_vendors.py`: write `ns.ShippedAuctioneers` from the pinned pfQuest `auctioneer` list; `tools/test_build_vendors.py`; regenerate `Data/`; `tests/test_data.lua`
- [x] 5.2 `Discovery`: record auctioneers on the auction house open event, learned wins; `Adapter` event/NPC read; `tests/test_discovery.lua`, `tests/test_adapter.lua`
- [x] 5.3 `Search` need `"auction"` and `Controller.Go` comparison (setting on, tradeable, not in an instance); `tests/test_search.lua`, `tests/test_controller.lua`

## 6. Settings

- [x] 6.1 `Options`: `page(name)` helper using subcategories or falling back to one page with headers; main page Warnings and Navigation sections (anchor dropdown, auction checkbox); `tests/fake_settings.lua` records subcategories; `tests/test_options.lua` both paths
- [x] 6.2 `Options`: Reagents, Ammo and Status window subcategories (Lock first, scale, opacity, one mode dropdown per row that applies to the class); cog opens the main page; `tests/test_options.lua`, `tests/test_locale.lua`

## 7. Demo

- [x] 7.1 `Controller.Demo` and `Tracker` fake snapshot: random rows, counts, modes (at least one low) and one random warning through the real notice, question and pin paths; 10-second restore with a token guard; clears its own pin; no saved changes; `/cvn demo` hidden from help, README and listing; `tests/test_controller.lua`, `tests/test_tracker.lua`, `tests/test_commands.lua`

## 8. Docs and release

- [x] 8.1 README (window, settings layout, commands, limits), `docs/listing.md`, `docs/test-plan.md` (new section: window, instances, anchors, auction house, plus the in-game checks listed in design.md); do not document `/cvn demo`
- [x] 8.2 `make test` and `make check` pass; break each shared predicate (the `Conditions` low test, the instance latch, the pin-kind clear, the lock, the mode filter, the AH comparison) in turn and confirm a test fails each time
- [x] 8.3 At archive: bump both TOCs to 1.0.0 and add a `## 1.0.0` CHANGELOG section noting the major bump was by request; name 1.0.0 in the commit

## 9. Opacity and colour

- [x] 9.1 `Status`: `Color`, `Hex`, `ParseColor` for `"rrggbb"` colors (black and reset are `000000`); `tests/test_status.lua`
- [x] 9.2 `Tracker`: background opacity 0-100 with nothing drawn at 0 whatever the color, `hudColor` background (black when missing or invalid), `hudTextAlpha` 20-100 on the title, the cog and every row (also rows added later), not on the frame; no border or other fill; `tests/test_tracker.lua`
- [x] 9.3 `Core`: defaults `hudAlpha` 80, `hudTextAlpha` 100, `hudColor` `000000`; saved values held to `Commands.LIMITS`, an invalid color reset to black; report header lists opacity, color and text opacity; picker passed to `Options` only when `Adapter.hasColorPicker()`; `tests/test_core.lua`
- [x] 9.4 `Adapter`: `hasColorPicker` and `pickColor` (new and old picker setup, guarded, nil and one report when missing or throwing, no opacity, Cancel restores); `tests/test_adapter.lua`
- [x] 9.5 `Options`: background opacity slider 0-100, text opacity slider 20-100, color swatch button (shows the saved color, opens the picker, any color; no dropdown) only where the picker and the button initializer exist; `tests/test_options.lua`, `tests/fake_settings.lua`
- [x] 9.6 `Commands`: `/cvn hud opacity <0-100>`, `/cvn hud textopacity <20-100>`, `/cvn hud color <#rrggbb|black|reset>` with `LIMITS`, validation messages, help and status lines; `tests/test_commands.lua`
- [x] 9.7 README, `docs/listing.md`, `docs/test-plan.md` (13.3: background 0 shows only text, text opacity, color swatch, picker on Forever, OLED check)
- [x] 9.8 Break each in turn and confirm a test fails: nothing drawn at 0, text opacity on text and icons, black default, clamping in Core, Tracker and Commands, picker button gating and Cancel
- [x] 9.9 Color picker always reachable: `Options` reports which of picker, `GetLayout`, `AddInitializer` or `CreateSettingsButtonInitializer` (or the Settings API) is missing; `Core` logs it and the report header has a picker/settings-button/swatch line (`Adapter.hasSettingsButton`); `/cvn hud color` with no color opens the picker (`Commands` action `{"hud","pick"}`) or says there is none; tests in `test_options`, `test_commands`, `test_adapter`, `test_core` fail when each is broken; docs and test plan 13.3 updated. No other Settings initializer is used: none is verified.
- [x] 9.10 Real-client fix (Forever 1.60.1 log: `category:GetLayout()` missing, so no swatch and no headers): `Options` takes the layout from the second return value of `Settings.RegisterVerticalLayoutCategory` and `...Subcategory` (kept per page, so main, subcategories and the one-page fallback all have it), falls back to `category:GetLayout()`, else nil; the swatch and section headers use it; `fake_settings.lua` has return, method-only and no-layout modes; `test_options` builds swatch and headers through each and fails when the lookup is broken. Unverified in-game: test plan 13.1 and 13.3.
- [x] 9.11 Color option looks like a color option: `Options` builds the game's own swatch row (`Settings.CreateColorSwatch`, label left, bordered square right) over a `CLOSESTVENDOR_HUD_COLOR` string setting proxied between `"aarrggbb"` and `hudColor`, in `pcall`, only where `Settings.CreateColorSwatch` exists and `Adapter.hasSwatchPicker()` is true; otherwise (or on an error) the tinted button as before, with the note naming what the swatch lacked; `Core` passes `hasSwatchPicker`; `fake_settings.lua` has an opt-in swatch (and a throwing one); tests in `test_options`, `test_adapter`, `test_core` fail when each part is broken; design.md decision and risk, test plan 13.3. Unverified in-game: test plan 13.3.
- [x] 9.12 Settings rows for familiarity: the Status window page always shows the Ammo row and, for a class without reagents, a Reagents row; one that does not apply is greyed out through `AddModifyPredicate` (guarded), says why in its tooltip, and never writes `cfg.hudRow`; `fake_settings.lua` dropdowns record predicates; `test_options` covers the disabled and enabled paths and fails when the predicate or the write guard is removed; design.md decision, test plan 13.1. Unverified in-game: test plan 13.1.
- [x] 9.13 One mode per row group: `cfg.hudRow` keys are the five groups `ammo`, `reagents`, `bags`, `durability`, `professions` (`Status.GROUPS`, window order); rows keep `prof:<name>` and `reagent:<id>` keys for drawing and `Status.Group` maps them to a group, so `Status.Mode` reads one Professions mode for every profession row and one Reagents mode for every reagent and display-only row (display-only items are never low, so only Reagents `always` shows them, and `Snapshot` reads them only then); every group defaults to `low`; `Core.init` drops any `hudRow` entry that is not a group with a real mode; `/cvn hud row <ammo|reagents|professions|bags|durability>` (`Commands.Run` no longer takes the known professions), help, `/cvn` and the report header list groups in window order; `Options` has five dropdowns (Ammo, Reagents, Bag space, Durability, Professions), Ammo greyed for non-ammo classes, Reagents greyed for a class with neither reagents nor display-only items; the demo rolls group modes and keeps one low row shown; tests in `test_status`, `test_commands`, `test_core`, `test_options` fail when the group lookup, the stale-key drop, the display-only read or the greyed-out rows are broken; spec, design.md decision, proposal, README, listing and test plan 13.1 and 13.2 updated. Unverified in-game: test plan 13.1 and 13.2.

## 10. Reagent buying

- [x] 10.1 `Reagents`: `BuyPlan(want, offers, slots, stack, money, target)` (to N each counting carried, never above, whole batches, stock, money in table order, shared empty slots and partial stacks, unknown is no plan or a skipped reagent, why it fell short) and `OnMerchant(cfg, env)` (off, 0, nothing watched, nothing sold, ask first, chunked single-item buys, one chat line, log lines); `tests/test_reagents.lua`
- [x] 10.2 `Adapter`: `merchantReagents()` (Reagents-table items only, gold only, `maxBuy` from a guarded `GetMerchantItemMaxStack`), `bagSlots()` (general bags only), `stackSize(id)`, `buyMerchantItem(index, quantity)`; a failing slot read is unknown, not empty; both API shapes; `tests/test_adapter.lua`
- [x] 10.3 `Ammo.OnMerchant` returns the cost of an immediate purchase; `Core`: defaults `reagentBuyEnabled` false, `reagentBuyPrompt` true, `reagentBuyTarget` 20 (held to `Commands.LIMITS`), its own dialog, reagent buying after ammo at `MERCHANT_SHOW` with the money ammo left, report header line; `tests/test_ammo.lua`, `tests/test_core.lua`
- [x] 10.4 `Commands`: `/cvn reagentbuy on|off|ask|auto|<0-100>`, refused for a class without vendor reagents, status and help lines; `tests/test_commands.lua`, `tests/test_readme.lua`
- [x] 10.5 `Options`: Buy reagents, Ask before buying reagents and the amount slider at the end of the Reagents page, ask and amount under the buy checkbox, all greyed (modify predicate, reason tooltip) for a class without vendor reagents; `tests/fake_settings.lua` checkboxes and sliders record predicates; `tests/test_options.lua`
- [x] 10.6 Break each in turn and confirm a test fails: carried count, stack size, partial stacks, shared empty slots, money and money shared across reagents, stock, whole batches, prompt, 0, chunk size, the 0-100 hold in Core and Commands, the money ammo left, the own dialog, the class check in Commands and Options, display-only excluded, general bags only
- [x] 10.7 Specs (class-reagents, diagnostics, vendor-trigger), design.md decision, proposal, README, `docs/listing.md`, `docs/test-plan.md` 13.7. Unverified in-game: test plan 13.7.
