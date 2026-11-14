# Proposal

## Why

A character at the end of a skill tier is asked to visit a trainer even when too low a level to learn the next tier, for example 150/150 at level 15 (Expert needs level 20). The trainer refuses, and the question comes back on every skill change.

Two smaller fixes ride along: the README still said the status window has no food rows, and the warlock healthstone reminder borrowed its spell list from the Soul Shard display entry.

## What Changes

- A profession near its cap is left out of the trainer question and the status window's low state when the player is below the level the next tier needs (cap 75: level 10, 150: level 20, 225: level 35). An unreadable level gates nothing.
- The healthstone reminder keeps its own Create Healthstone spell list.
- README corrected.

## Capabilities

### Modified Capabilities
- `profession-trainer`: adds the level requirement.

## Impact

`Professions.lua`, `Controller.lua`, `Status.lua`, `Core.lua` (pass the player level), `Supplies.lua`, tests, README, CHANGELOG. No setting or command changes.
