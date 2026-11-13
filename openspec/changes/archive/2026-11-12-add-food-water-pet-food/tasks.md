# Tasks

## 1. Verify data and APIs

- [x] 1.1 Pick the item data source for food, drink and pet diet (check pfQuest `items.lua` first, otherwise a second pinned source with its license); confirm it covers Classic Era and WoW Forever item ids, and record the source and pin in `tools/fetch_data.py`
- [x] 1.2 Confirm how the game names a pet without text: `UnitCreatureFamily("pet")` returns a family id on both clients; `GetPetFoodTypes` and `C_PetInfo.CanPetEatItem` returned nothing; take the family-to-diet table from `CreatureFamily.PetFoodMask`
- [x] 1.3 Confirm which classes use mana (water gate), the Create Healthstone spell ids and the healthstone item ids of every rank, and the conjure spell ids already in `Reagents.lua` for the mage reminder
- [x] 1.4 Record the findings in design.md under Risks, replacing the open items

## 2. Item table and pure logic

- [x] 2.1 `tools/build_supplies.py`: generate `ClosestVendor/Data/Supplies.lua` from the pinned source (kind, diet), sorted and deterministic, failing on an unknown kind or diet; `tools/test_build_supplies.py` including the reproducible-build and bad-entry cases
- [x] 2.2 `ClosestVendor/Supplies.lua`: `Counts`, the watched list for a class and pet diet, the low list, key-to-mask mapping, the mana-class gate; add both files to both TOC files in the same order (`make check`)
- [x] 2.3 `tests/test_supplies.lua`: mixed food counted, conjured counted, drink not counted as food, rogue has no water, no pet or nil diet watches nothing, several diets, nil counts never low; mutation check on the class gate and the nil rule

## 3. Vendor data and discovery

- [x] 3.1 `tools/build_vendors.py`: write the supply mask as the tenth field from the table and sold-by lists, report diets with no seller; update the header comment and `tools/test_build_vendors.py`; regenerate `Data/Vendors.lua`
- [x] 3.2 `Discovery.Record`: store and compare the new field, default 0 for old records; `tests/test_discovery.lua`: new vendor, shipped vendor keeps its supplies, changed offer updates, old 9-field record
- [x] 3.3 `Adapter`: merchant scan returns the supply mask; a bag pass returns counts by item id (nil when unreadable); `petDiet()` (family id to diets, no text); all guarded and nil when missing; `tests/test_adapter.lua`
- [x] 3.4 `Search` and `Core.rebuildBuckets`: eligible for a supply key from the runtime mask, with the pet's diets as an any-of test; `tests/test_search.lua`, `tests/test_data.lua` (mask bits match the table)

## 4. Trigger, question and reminders

- [x] 4.1 `Triggers`: supply kind with per-key handled set, priority repair, ammo, reagent, food, water, pet food, sell; supply trips do not cover selling; the remind outcome with its own handled set, deferred in combat and instances; `tests/test_triggers.lua`
- [x] 4.2 `Controller`: compute the low supplies and reminders (master switch, enabled, class, pet, known conjure or healthstone spell, count), find the vendor, offer with the name and count, auto mode and notice, one chat line when no seller; `Test` for food, water, petfood and remind; sentences as whole `L[...]`; `tests/test_controller.lua`
- [x] 4.3 `Core.lua`: defaults, env wiring (class, spells, counts, pet diet), `reportText` supplies line and log lines; `tests/test_core.lua`

## 5. Settings and commands

- [x] 5.1 `Commands`: `food`, `water`, `petfood` thresholds (1 to 40) and on/off, `test food|water|petfood|remind`, help and status lines; `tests/test_commands.lua`, `tests/test_readme.lua`
- [x] 5.2 `Options`: a "Supplies" page with the standard checkbox and slider controls, water and pet food rows only for classes that use them, the healthstone reminder row for warlocks; `tests/test_options.lua`, `tests/test_locale.lua`

## 6. Docs

- [x] 6.1 `README.md` (features, settings page, commands, Good to know: meat and fish vendors are rare, reminders are notices), `docs/listing.md` (description and commands)
- [x] 6.2 `docs/test-plan.md`: a new section after the current last one, with unique numbering, covering food, water, pet food (diet change, no pet, no seller), mage and warlock reminders, the master switch, and vendors learned

## 7. Status rows and reminder sound

- [x] 7.1 `Supplies.SOUNDS` (keys, ids, labels), `Adapter.playSound`, setting `remindSound` (default `whisper`), `Controller` plays once per reminder batch, `/cvn sound [key]`, a dropdown on the Supplies page that previews, the report line; tests
- [x] 7.2 `Status`: group `supplies` with rows `supply:food|water|pet`, low from `Supplies.Evaluate`, no read when `never`; `/cvn hud row supplies`; the settings dropdown; click pins the seller; `UNIT_PET` redraws; demo maker; tests
- [x] 7.3 Docs (README silent-notice line, test plan 14.3 and 14.5 and the new sound checks, listing), delta specs, `openspec validate --strict`, mutation checks

## 8. Verify

- [x] 8.1 `make test` and `make check` pass; break the mana-class gate, the nil-count rule, the per-key handled set and the learned-keeps-supplies rule in turn and confirm a test fails each time
- [x] 8.2 Run the manual checks from the test plan in the game for one mage, one hunter and one warlock

## Workflow follow-up

- At archive: bump both TOCs to 1.1.0 and add a `## 1.1.0` CHANGELOG section; name 1.1.0 in the commit. Run `/opsx:archive` before any commit, push or PR.
