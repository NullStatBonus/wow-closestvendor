# Proposal

## Why

Turning the "Ammo and reagents" switch off also turned off food, water, pet food and the healthstone reminder. A player who does not want ammo or reagent questions still wants food and water warnings. Food needs a switch of its own, like ammo has.

## What Changes

- Food, water, pet food and the healthstone reminder no longer depend on the "Ammo and reagents" switch. Each keeps its own on/off setting (`/cvn food on|off`, the Supplies page). The ammo switch still turns ammo and reagents off together.
- The Supplies settings controls no longer grey out with the ammo switch.
- The status window supply rows follow their own switches only.

## Capabilities

### Modified Capabilities
- `food-and-water`: adds the independence requirement.
- Wording of the master-switch dependence is removed from `food-and-water`, `pet-food`, `status-window` and `vendor-trigger`.

## Impact

`Triggers.lua`, `Status.lua`, `Controller.lua`, `Options.lua`, tests, README, test plan, CHANGELOG. No saved-data change.
