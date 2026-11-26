# Proposal

## Why

The addon saves a learned vendor, trainer or auctioneer at the place where the player stands when its window opens, and compares that place exactly. Standing a step to the side counts as a change. So almost every visit logs `updated`, rewrites the saved record and rebuilds the search lists. The first in-game run of the core plan showed it: six visits to the same vendor, six `updated` lines, and only the position differed.

## What Changes

- On a repeat visit on the same map, a position within 0.005 of the saved one on both axes (a fraction of the map: a few yards in a city) keeps the saved position.
- The record changes only when the npc moved further, went to another map, or another field changed (name, faction, repair, ammo, reagents, supplies, or the professions a trainer teaches).
- A visit with nothing else changed logs `unchanged`.
- The same rule applies to vendors, trainers and auctioneers.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `vendor-discovery`: a small change in position on a repeat visit does not change the record.

## Impact

- `ClosestVendor/Discovery.lua` (`Record`, `RecordTrainer`, `RecordAuctioneer`), `tests/test_discovery.lua`, `README.md`, `CHANGELOG.md`.
- Saved data keeps its shape. No migration.
- Version: patch bump to 1.13.1.
