# Tasks

## 1. Verify the data

- [x] 1.1 Compare NorgannonDB positions for the 17 vendors it shares with Wago's `CollectableSourceVendorSparse` (converted from world to map position), for both zone and sub-zone spawns, and record in `design.md` whether sub-zone positions are relative to their own map or the parent's.
- [x] 1.2 Decide from 1.1 how sub-zone spawns are converted, or that they are skipped, and note it in the design.

## 2. Combining sources

- [x] 2.1 Add a pure function in `Discovery.lua` that returns the search pool from the shipped list, the external list and the learned table, with the precedence in the spec (static, learned flags and faction, learned position past 3% of the map).
- [x] 2.2 Test it: one pool and one entry per NPC id, learned agrees, vendor moved, observed repair flag wins, external over shipped, nothing external (same result as `Merge`), and a learned record from before supplies existed.
- [x] 2.3 Break each rule in the code and confirm a test fails.

## 3. Reading NorgannonDB

- [x] 3.1 Add `A.externalVendors(mapIds)` in `Adapter.lua`: guarded, behind `RequireSchema(1, 4)`, reading `categories.vendor.npcs` and `index.zones` for the five maps with `Peek`, converting to our record shape (map, 0 to 1 position, faction, repair, ammo, reagents, supplies) and returning the count skipped.
- [x] 3.2 Test it with a fake `NorgannonDB`: missing, wrong schema, `RequireSchema` that throws, a malformed record, a vendor outside the five maps, a sub-zone vendor, repair and ammo and reagent and supply stock, and reaction codes `A`, `H`, `AH`.
- [x] 3.3 Break the guard, the map filter and the conversion and confirm a test fails.

## 4. Wiring

- [x] 4.1 `Core.rebuildBuckets` uses the new pool; read once after login and again on `ADDON_LOADED` for `NorgannonDB`, then rebuild, and never on bag, merchant or movement events.
- [x] 4.2 Add `NorgannonDB` to `## OptionalDeps` in both TOC files.
- [x] 4.3 Add the report line (found, schema, vendors added, skipped).
- [x] 4.4 Core tests: absent addon changes nothing, present addon adds vendors for a new-zone map, a late load adds them without a reload, and the report line.

## 5. Documentation and release

- [x] 5.1 README: the optional source, what it adds, that nothing is copied, and a "Good to know" limit (new zones only).
- [x] 5.2 `docs/listing.md`: add NorgannonDB to the optional relations and a "Good to know" line.
- [x] 5.3 `docs/test-plan.md`: in-game checks (with and without NorgannonDB, in Riverglades and Zephras Isle, and a vendor you open versus its data).
- [x] 5.4 `CHANGELOG.md` entry, minor version bump to 1.5.0 in both TOC files, and archive the change.
