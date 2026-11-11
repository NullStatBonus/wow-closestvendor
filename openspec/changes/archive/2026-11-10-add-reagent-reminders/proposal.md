# Proposal

## Why

Casters run out of class reagents (powders, runes, candles, symbols, Ankhs, seeds) at the worst moments, and the addon only watches bags, gear, ammo and professions. It already knows how to find the nearest vendor for ammo; reagents are the same problem with a different item list and a different scale of quantity (a handful, not hundreds).

## What Changes

- A new **reagent trigger**: when a reagent of the player's class is at or below the reagent threshold, the addon asks to navigate to the nearest vendor that sells it, with the usual question, map/distance choice, auto mode and notice.
- A reagent is watched only when the player knows the spell that uses it, so a level 12 mage is never asked about portal runes. Rank-based reagents (druid seeds, priest candles) follow the highest rank known.
- The settings page row "Ammo" becomes **Ammo and reagents**: one master checkbox for both. Ammo keeps its own slider (default 200). A new slider, **reagent threshold** (default 5, range 1 to 40), applies to all reagents.
- **Per-reagent checkboxes** on the settings page, listing only the player's class reagents, all on by default. Stored as an off-list so reagents added later are on automatically.
- Commands: `/cvn reagent <count>` sets the threshold (`on`/`off` for the master switch stays `/cvn ammo on|off`), `/cvn reagents` lists the class's reagents with their state, `/cvn reagent on|off <name>` toggles one, `/cvn test reagent` asks the question now.
- Priority order becomes repair, ammo, reagent, sell, profession trainer. One question at a time, one per low reagent.
- **Vendor data gains reagent seller flags**: shipped vendors from the pfQuest sold-by lists, learned vendors by scanning the merchant window for known reagents. Learned records carry them, so a shipped reagent vendor you open is not stripped of its reagents.
- Remind and navigate only. No auto-buy of reagents (possible follow-up).
- Classes: Mage, Rogue, Priest, Paladin, Shaman, Druid. Warlocks (shards are not sold), hunters and warriors have none.

## Capabilities

### New Capabilities

- `class-reagents`: which reagents each class watches, when a reagent counts as low, the settings, commands and test command for them.

### Modified Capabilities

- `vendor-trigger`: priority order gains reagent; the settings panel's ammo row becomes the "Ammo and reagents" master switch.
- `vendor-data`: records say which reagents a vendor sells.
- `vendor-discovery`: opening a merchant records which reagents it sells.

## Impact

- New `ClosestVendor/Reagents.lua` (pure: class table, which reagents are low) and data in `ClosestVendor/Data/` if the table is large; both TOC files.
- `Triggers.lua` (reagent kind with per-item handling), `Controller.lua` (question text, reagent search), `Search.lua` (eligible for a reagent), `Discovery.lua` (record field), `Core.lua` (defaults, merchant scan, bucket field, report), `Adapter.lua` (spell known, item counts, merchant reagent scan), `Options.lua`, `Commands.lua`.
- `tools/build_vendors.py` and regenerated `Data/Vendors.lua` (new record field); `tests/test_data.lua`, `tools/test_build_vendors.py`.
- New and updated tests across `tests/`; docs: README, `docs/listing.md`, `docs/test-plan.md`; report header in `Core.lua`.
- Saved settings: `reagentThreshold`, `reagentOff` added; `ammoEnabled` now also switches reagents. Existing settings keep working with no migration.
- CHANGELOG `## 0.5.0` and a minor bump to 0.5.0 at archive (new feature).
