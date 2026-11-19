# Proposal

## Why

Seven requirements in four main specs have descriptions over 500 characters, so `openspec validate --specs --strict` fails for `ammo-purchase`, `profession-trainer`, `status-window` and `vendor-trigger`. Each of them packs several behaviors into one requirement, which also makes them hard to read and to test one by one.

## What Changes

- Each long requirement keeps its name and every scenario. Its description is cut down to one behavior, with no change in meaning.
- Each behavior taken out becomes its own requirement with its own scenarios.
- No addon behavior, setting, command or saved data changes. No code changes.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `ammo-purchase`: "Ammo grade selection" keeps the three modes; the fallback becomes "Ammo grade fallback".
- `profession-trainer`: "Profession trainer trigger" keeps when to ask; the Artisan rule and the tier rule become "Artisan needs known trainer tiers" and "Trainer teaches the needed tier".
- `status-window`: "Row groups" keeps the groups; "Moving and locking" keeps drag and lock; "Demo" keeps the tour. Split out: "Setting a group's mode", "Move mode", "Demo row click".
- `vendor-trigger`: "Repair takes priority" keeps the order; "Settings panel" keeps the page tree and shared behavior. Split out: "Trips that cover selling", "When a request resolves", "Settings page contents", "Appearance, Advanced and About contents", "Opening a settings page".

## Impact

Only `openspec/specs/` for the four capabilities. No version bump or tag: this is a spec-only change and ships with the next addon release.
