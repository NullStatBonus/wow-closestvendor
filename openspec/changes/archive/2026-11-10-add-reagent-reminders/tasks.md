## 1. Reagent data and pure logic

- [x] 1.1 Verify the reagent item ids and the spell ids that use them (shipped data has sellers for the items; spell ids need a character or client data); decide on Blinding Powder; record the confirmed table in `ClosestVendor/Reagents.lua` with a fixed bit number per item
- [x] 1.2 `Reagents.lua`: `ForClass`, `Watched(class, knowsSpell, off)` with highest-rank gating, `Low(...)`, `Find(class, name)`; add to both TOC files in the same order
- [x] 1.3 `tests/test_reagents.lua`: classes with and without reagents, spell not known, rank gating, switched-off item, nil counts, name matching; mutation check

## 2. Vendor data and discovery

- [x] 2.1 `tools/build_vendors.py`: write the reagent mask as the 9th field, report reagents with no seller; update header comment, `tools/test_build_vendors.py`, regenerate `Data/Vendors.lua`; `tests/test_data.lua` accepts and checks the new field and that the bit table matches the generator
- [x] 2.2 `Discovery.Record`: store and compare field 9; `tests/test_discovery.lua`: new vendor, shipped vendor keeps its reagents, changed offer updates
- [x] 2.3 `Adapter`: `merchant()` returns the reagent mask from the offered items; `knowsSpell(id)`, `classToken()`; guarded, nil when missing; `tests/test_adapter.lua`
- [x] 2.4 `Search`: eligible for a reagent from the runtime mask at index 11, with the `onMap` result; `Core.rebuildBuckets` copies field 9 to index 11; `tests/test_search.lua`

## 3. Trigger and question

- [x] 3.1 `Triggers`: reagent kind, priority repair, ammo, reagent, sell; per-item handled set; `{ "go", "reagent", id }`; a reagent trip does not cover selling; `tests/test_triggers.lua`
- [x] 3.2 `Controller`: compute the low list (master switch, enabled, spell known, count), find the vendor, `offer` with the reagent name and count, auto mode and notice, one chat line when no seller; `Test("reagent")`; `PromptText` sentences as whole `L[...]`; `tests/test_controller.lua`
- [x] 3.3 `Core.lua`: defaults `reagentThreshold = 5`, `reagentOff = {}`; wire env (class, spells, counts); report header line; `tests/test_core.lua`

## 4. Settings and commands

- [x] 4.1 `Commands`: `reagent` limits 1 to 40, `/cvn reagent <n>`, `/cvn reagent on|off <name>`, `/cvn reagents`, `/cvn test reagent`, help and status lines; `tests/test_commands.lua`, `tests/test_readme.lua`
- [x] 4.2 `Options`: rename the ammo checkbox "Ammo and reagents", add the reagent slider and one checkbox per class reagent bound to the off-list; all follow the master switch; `tests/test_options.lua`, `tests/test_locale.lua`

## 5. Docs and release

- [x] 5.1 README (features, settings, commands, Good to know), `docs/listing.md` (description and commands), `docs/test-plan.md` new section 12 "Reagents" (per class, spell gating, per-reagent off, master switch, vendors learned)
- [x] 5.2 `make test` and `make check` pass; break the spell gating, the per-item handled set and the learned-keeps-reagents rule in turn and confirm a test fails each time
- [x] 5.3 At archive: bump both TOCs to 0.5.0 and add a `## 0.5.0` CHANGELOG section; name 0.5.0 in the commit
