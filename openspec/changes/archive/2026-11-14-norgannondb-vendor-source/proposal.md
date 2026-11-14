# Proposal

## Why

WoW Forever added zones (Mount Hyjal, Riverglades, Shen'dralas, Zephras Isle, Darkspear Islands) that our shipped vendor list does not cover, because it is built from Vanilla data. Until a player opens a vendor there, the addon knows none (Zephras Isle and the Darkspear Islands have their own continent, so they report "No known vendor on this continent"). NorgannonDB, an independent addon with a documented API, holds about 76 vendors with positions, stock and repair flags in those zones. We cannot copy it (GPL-3.0), but we can read it at runtime when the player has installed it.

## What Changes

- Read vendors from NorgannonDB when it is installed and its data schema is supported (1.4 or later, major 1). It is optional: nothing changes without it, and no data from it is copied into the package.
- Only vendors on the five Forever-only maps are read, using its vendor list and per-zone index, so the 15,000-NPC table is not decoded.
- All sources feed one pool and the nearest eligible vendor still wins. Precedence only settles the same NPC id in more than one source: NorgannonDB over the shipped list for static data; for a learned vendor, its flags (repair, ammo, reagents, supplies) win, and its position wins only when it differs from the static position by more than 3% of the map (the NPC moved).
- The debug report says whether NorgannonDB was found and how many vendors it added.
- README, store listing and the test plan say it is optional.

## Capabilities

### New Capabilities
- `external-vendor-source`: reading vendors from an optional addon, what is read, how records are converted, how sources are combined, and what the report shows.

### Modified Capabilities
- `vendor-discovery`: "Learned data wins" now states how it combines with an optional external source.

## Impact

`Adapter.lua` (one guarded read), `Discovery.lua` (combining sources), `Core.lua` (rebuild buckets, late load, report line), both TOC files (`OptionalDeps`), tests, README, `docs/listing.md`, `docs/test-plan.md`, `CHANGELOG.md`. No saved-data change and no new setting. Out of scope: copying or shipping any NorgannonDB, MerchantMap or other third-party data; reading vendors outside the five new maps; trainers and auctioneers from NorgannonDB.
