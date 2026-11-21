## Why

Fix group 3 (#40) from the bug review. Five bugs make a saved place or a waypoint wrong: the hearthstone point never gets a position when the player binds again at the same inn (seen in real saved variables), a seller picked from the list can stop fitting the row, an unlearned profession keeps its trainer waypoint, `/cvn demo` erases the player's own game waypoint, and a failing game timer can stop the status window from redrawing.

## What Changes

- Binding the hearthstone again at the inn it is already bound to records that inn's position. A point saved by name only (bound before the addon saw it) gets its position this way.
- Picking an entry from a row's seller list checks again that the seller still fits the row now (the right ammo type, reagent, supply or profession). If it does not fit, nothing is pinned and chat says to open the list again.
- Unlearning a profession counts as a skill change: its trainer waypoint ends.
- `/cvn demo` notes the player's own game waypoint before the tour and sets it again at the end.
- When the game timer call fails, the addon treats the timer as not scheduled, so a status window redraw or a re-check is not left waiting for a timer that never runs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `instance-awareness`: Hearthstone point learns a position on a rebind at the same inn.
- `seller-choice`: Picking an entry rechecks the seller.
- `profession-trainer`: A removed profession is a skill change.
- `visual-preview`: Demo restores the player's own game waypoint.
- `api-resilience`: A failed timer call reports "not scheduled".

## Impact

- Code: `Core.lua` (hearth), `Controller.lua` (Pick, demo), `Search.lua` (seller fit check), `Professions.lua` (change detector), `Nav.lua` (read and restore the game waypoint), `Adapter.lua` (`A.after`).
- One new chat sentence (`L[...]`) for the refused pick.
- Tests: `test_core`, `test_controller`, `test_search`, `test_professions`, `test_nav`, `test_adapter`.
- Docs: `docs/test-plan.md` new section 33. No README or listing change (fixes only).
- Release: patch 1.9.3. No saved-data change.
- Out of scope: #45 (CI checkout version), the other fix groups (#41, #44).
