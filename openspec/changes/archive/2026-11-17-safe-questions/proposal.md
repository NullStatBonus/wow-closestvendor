## Why

A review found three ways questions go wrong. A purchase question left open after the merchant closes can buy whatever sits at that slot at the next merchant. Answering No, or having no vendor for a need, keeps that request active, so every lower need (ammo, reagents, food, selling) waits until the declined condition clears. A warning that fires while dead or a ghost is used up, because the game hides the question then; dying is exactly when repair is needed.

## What Changes

- Ammo and reagent purchase questions close with the merchant window. Ammo gets its own dialog, so it never shares one with route questions. Yes buys only if the open merchant still offers the same item at each slot.
- No or Escape to a route question, or finding no vendor for a need, ends that request. It is not asked again until its condition clears, and the next need is asked shortly after. Selling, which a repair or ammo trip would have covered, can be asked again, and a request that a higher one replaced is asked again after it. Questions from `/cvn test` and the demo never end a real request.
- Warnings, auto routes and trainer questions wait while the player is dead or a ghost, as in combat. Coming back to life checks again.

## Capabilities

### New Capabilities

### Modified Capabilities

- `vendor-trigger`: a declined or unserved request yields to the next need; requests wait while dead.
- `ammo-purchase`: a purchase question ends with its merchant and checks the slot at Yes.
- `class-reagents`: the same for reagent purchases.

## Impact

`Triggers.lua` (Release), `Controller.lua` (decline, no-vendor release, dead hold), `Core.lua` (dialogs, events), `Adapter.lua` (`isDead`, `merchantItemId`), `Ammo.lua`, `Reagents.lua`, tests, test plan. No settings or saved data change.
