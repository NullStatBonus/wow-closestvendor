## Why

The review found two English-only labels: pet diets in the pet food question ("pet food (Meat, Fish)") and the reagent checkboxes in settings. Item and diet matching was already by id (reagents, supplies, ammo class, pet family); only these labels bypassed translation.

Routing to a trainer that can teach the player's next tier needs to know which tier each trainer teaches. The trainer API's behavior on Classic Era (level and skill requirements per service, what the filters hide) has not been seen in game, so this change only logs it; the tier logic follows once a log confirms it.

## What Changes

- Diet names in questions come from the translation table; internal diet keys stay English and are matched by pet family id.
- Reagent checkboxes name the item with the game's own (localized) name once loaded, English until then.
- With debugging on, opening a profession trainer logs every listed service with its skill line, type, level and skill requirement, and the trainer filter states. Filters are only read.

## Capabilities

### New Capabilities

### Modified Capabilities

- `localization`: diet and reagent labels are translated.
- `diagnostics`: trainer service probe.

## Impact

`Supplies.lua`, `Controller.lua`, `Options.lua`, `Core.lua`, `Adapter.lua`, tests, test plan. No settings or saved data change.
