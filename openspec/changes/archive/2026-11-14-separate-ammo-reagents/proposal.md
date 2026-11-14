# Proposal

## Why

Ammo and reagents shared one "Ammo and reagents" checkbox in the Warnings section, next to the ammo slider, while the reagent slider and the reagent controls were on the Reagents page. The switch and its settings were on different pages, and ammo and reagents could not be turned off separately.

## What Changes

- Ammo has its own checkbox and threshold slider on the Ammo page. Reagents have their own checkbox and the threshold slider on the Reagents page. `/cvn ammo on|off` affects ammo only; `/cvn reagents on|off` is new.
- A character saved before this keeps its choice: reagents start with whatever the ammo switch was.
- The main page Warnings section lists Bag space, Durability, Professions and Supplies. The settings pages are in alphabetical order (Ammo, Reagents, Supplies) with Status window last.

## Capabilities

### Modified Capabilities
- `class-reagents`: adds the reagents switch and its migration.
- The settings page layout text in `vendor-trigger` and the master-switch wording in `class-reagents` are updated.

## Impact

`Core.lua`, `Triggers.lua`, `Status.lua`, `Commands.lua`, `Options.lua`, tests, README, test plan, CHANGELOG. New saved key `reagentsEnabled`.
