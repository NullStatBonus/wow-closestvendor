# Proposal

## Why

The addon warns about low ammo and class reagents and points to the closest vendor, but not about the supplies every character needs: food, water, and (for hunters) pet food. Running out of them is as disruptive as running out of reagents. The reagent framework (spell-gated watching, a vendor bitmask, a trigger priority order, a merchant scan) can carry them with small additions.

## What Changes

- **Food:** watch the number of food items in the bags for every class. When it is at or below the food threshold, ask about the closest vendor that sells food.
- **Water:** the same for drink items, for classes that use mana. Warriors and rogues are never asked.
- **Pet food:** for a hunter with an active pet, watch the items that match the pet's diet (Meat, Fish, Bread, Cheese, Fruit, Fungus). The diet is read from the game at runtime. When no pet is out, nothing is watched.
- **What counts:** every food, drink or diet item in the bags, including cooked, looted and conjured items. A generated data table lists them (item id, kind, diet). It is built by a tool from a database export, with the same checks as the reagent tables.
- **No level tiers:** a vendor either sells food, water or a diet item or it does not.
- **Reminders instead of trips:** a mage who knows a conjure spell is reminded to conjure food or water, and never sent to a vendor for it. A warlock who knows Create Healthstone and holds none is reminded to create one. A reminder is a notice with no question and no pin.
- **No seller for the pet's diet:** when no known vendor sells an item the pet eats, one chat line says so (as for a reagent with no known seller).
- **Settings:** each of food, water, pet food and the healthstone reminder has its own on/off switch. Food, water and pet food have their own thresholds. The existing "Ammo and reagents" master switch also gates them. New slash commands mirror the reagent commands.
- **Vendor data:** eight new bits in each vendor record (food, water, six diets), written by `build_vendors.py` and by the merchant scan for learned vendors.

- **Status window:** a new "Supplies" row group (food, water and, for a hunter, pet food) with its own mode (low, always, never), marked low by the same test as the warnings. A click pins the nearest seller.
- **Reminder sound:** a reminder plays a sound, chosen on the Supplies settings page and by `/cvn sound`. The default is the whisper ping. `/cvn test remind` plays it too.

Not in this change: buying food or water at the merchant, potions, bandages, and warlock soulstones.

## Capabilities

### New Capabilities
- `food-and-water`: watching food and drink counts, the mana-class gate, thresholds and per-item switches, the vendor trip, and the shipped item table.
- `pet-food`: watching items matching the active pet's diet, the no-pet and no-seller cases, and the diet read from the game.
- `craft-reminders`: the notice-only trigger outcome, used to remind mages to conjure and warlocks to create healthstones, and the sound a reminder plays.

### Modified Capabilities
- `status-window`: a sixth row group, Supplies, with food, water and pet food rows.
- `vendor-trigger`: a new "supply" request kind with a place in the priority order, and a "remind" outcome that shows a notice and never asks or pins.
- `vendor-data`: the vendor record carries a supply mask, and the generated data is built with it.
- `vendor-discovery`: a merchant window records which supply bits the merchant sells.
- `diagnostics`: the settings report lists the new settings.

## Impact

- New files: `ClosestVendor/Supplies.lua` (pure logic and data lookups) and `ClosestVendor/Data/Supplies.lua` (generated table), listed in both TOC files in the same order. A tool, `tools/build_supplies.py`, generates the table.
- Changed: `Triggers.lua`, `Controller.lua`, `Discovery.lua`, `Adapter.lua` (pet diet, bag counts, merchant scan), `Options.lua`, `Commands.lua`, `Core.lua` (`reportText`), `tools/build_vendors.py`, locale files, and `Data/Vendors.lua`, which is regenerated.
- Tests: new `tests/test_supplies.lua`; additions to the trigger, controller, discovery, options, commands, adapter and data tests.
- Docs: `README.md`, `docs/listing.md`, `docs/test-plan.md`. `CHANGELOG.md` and the version bump come at archive (a new capability, so a minor bump).
- No saved setting breaks. New settings default to on and unknown settings keep their old values.
