## Why

Group 2 of the bug review (#39). Five faults let a warning get lost, stall, or point at the wrong place. They all live in how warnings are asked, replaced and ended, so one in-game pass over the warnings and questions covers them.

## What Changes

- **Fixed: a row click or a seller choice no longer loses or blocks the warning it closes.** Today, if the clicked need is low, the warning whose question was open stays marked as handled and is not asked until its condition clears. If the clicked need is not low, that warning stays active with no question and no waypoint, and blocks every lower warning. Now the closed warning comes back: after the clicked trip resolves when the click took a request, otherwise at the next check. A higher warning does not replace a trip the player clicked.
- **Fixed: a warning found after a No is retried when the map position comes back.** Today, if that warning finds no map position, it waits for a retry that never comes.
- **Fixed: a trainer question closes when the player changes zone or enters an instance**, like a warning's question. Today Yes can still route from the old place.
- **Fixed: the bag-space warning is not lost when a repair request replaces an ammo request that covered selling.** Today, after No to both, selling is never asked.
- **Fixed: a pet or weapon change asks again for the new need.** Today a meat-eating pet swapped for a bread eater keeps the meat vendor question or route, and a bow swapped for a gun keeps the arrow route.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `status-window`: a click keeps the warning it closes, and a clicked trip is not replaced by a higher warning.
- `vendor-trigger`: a warning after a No retries without a position; selling stays covered across a replaced trip; an ammo request follows the weapon.
- `profession-trainer`: a trainer question ends with the place.
- `pet-food`: a pet food request follows the pet's diet.

## Impact

- `ClosestVendor/Triggers.lua`: Take re-arms the request it replaces and keeps a clicked trip; selling coverage survives a replaced trip.
- `ClosestVendor/Controller.lua`: click path releases a closed question it did not take; retry after No goes through Core's evaluate; trainer questions are tracked as open questions; a changed ammo kind or pet diet restarts its request.
- `ClosestVendor/Core.lua`: passes its evaluate to the controller.
- Tests: `test_triggers`, `test_controller`, `test_core`. `docs/test-plan.md`: one new section. No settings, commands or saved data change. Patch release (1.9.2) at archive.
