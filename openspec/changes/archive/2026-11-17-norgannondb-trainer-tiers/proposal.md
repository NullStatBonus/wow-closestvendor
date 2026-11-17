## Why

The closest profession trainer often cannot teach the tier the player needs, and Artisan is taught by only a few trainers. NorgannonDB, already an optional source for Forever vendors, has every trainer's title, position and the recipes they teach. Before patch 2.3 a trainer teaches only the tiers below its title; NorgannonDB's recipe data confirms it (Journeyman X trainers teach recipes up to 75, Expert X up to about 150, Artisan X up to about 225, Master X above).

## What Changes

- With NorgannonDB installed, its trainers whose title gives a tier ("<Journeyman|Expert|Artisan|Master> <Alchemist|Blacksmith|Enchanter|Engineer|Leatherworker|Tailor>") join the trainer pool on every map, with the professions of the recipes they teach (skill line ids, named in the player's language).
- Each tier is routed only to a trainer known to teach it; a trainer whose tier is not known (learned, or another title) is trusted for Journeyman and Expert, never for Artisan.
- Artisan is routed (question, red row, row click) only when NorgannonDB gave trainer tiers; otherwise the previous behaviour stays.
- A learned trainer that NorgannonDB also has keeps its learned position and gains the tier. The debug report counts trainers with a tier. Nothing is copied or saved.

## Capabilities

### New Capabilities

### Modified Capabilities

- `profession-trainer`: tier-aware trainer routing, Artisan with NorgannonDB.
- `external-vendor-source`: NorgannonDB trainers.

## Impact

`Professions.lua`, `Search.lua`, `Adapter.lua`, `Core.lua`, `Controller.lua`, `Status.lua`, tests, README, listing, CHANGELOG 1.7.0, test plan section 27. No settings or saved data change.
