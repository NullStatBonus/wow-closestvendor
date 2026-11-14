# Proposal

## Why

Food, water and pet food had a switch each but no single switch in the Warnings section, where bags, durability, ammo and professions have theirs. A player looking there found nothing for supplies.

## What Changes

- A "Supplies" checkbox in the Warnings section of the main settings page and `/cvn supplies on|off`. It is the master for food, water, pet food and the healthstone reminder, default on.
- Each of them keeps its own switch and threshold on the Supplies page, which now greys out with the master when both are on one page.
- The "Ammo and reagents" switch no longer affects supplies (see `supplies-own-switches`).

## Capabilities

### Modified Capabilities
- `food-and-water`: adds the Supplies switch requirement.

## Impact

`Core.lua` (default, report line), `Triggers.lua`, `Status.lua`, `Controller.lua`, `Commands.lua`, `Options.lua`, tests, README, test plan, CHANGELOG.
