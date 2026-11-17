## Why

Journeyman and Expert trainers usually stand side by side, so the closest trainer works for those tiers. Artisan is taught by only a few trainers per profession, and the addon cannot yet tell which (issue #27). Routing a player at 225 to the closest trainer usually sends them to one who cannot teach Artisan.

## What Changes

- No trainer question, red row or route when Artisan is the next tier (cap 225). A click on that profession row says why in chat.
- The status window demo uses Journeyman and Expert caps only.

## Capabilities

### New Capabilities

### Modified Capabilities

- `profession-trainer`: Artisan is not routed.

## Impact

`Professions.lua`, `Controller.lua`, `Status.lua` (demo), tests, README, listing, test plan. No settings or saved data change.
