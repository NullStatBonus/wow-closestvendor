## 1. Hearthstone point

- [x] 1.1 `Core.lua` `learnHearth`: with the same name and a pending position whose area matches, save that position and log "hearthstone point learned" (bind event, login or zone change: Era may not fire the bind event)
- [x] 1.2 `tests/test_core.lua`: name-only point + same-inn `CONFIRM_BINDER` + `HEARTHSTONE_BOUND`, or + zone change, gets the position; a question for another place keeps the point; mutation-check

## 2. Picked seller fits

- [x] 2.1 `Search.lua`: export `S.Fits(v, need)` (the local `eligible`)
- [x] 2.2 `Controller.lua` `Pick`: for a non-auction entry, check `S.Fits` with `needFor(q.find, q.item, q.supplyBits)`, or `Professions.Teaches(v[7][q.trade], q.need)` for a trainer; on a miss log, say `L["The seller list changed. Open it again to choose."]`, return false
- [x] 2.3 Add the sentence to the locale files (`tests/test_locale.lua` passes)
- [x] 2.4 Tests: `test_search` for `Fits`; `test_controller` arrow list, gun equipped, pick arrow-only seller pins nothing and says the line; a fitting pick still pins; mutation-check

## 3. Unlearned profession

- [x] 3.1 `Professions.lua` `Changed`: a name in the previous ranks and missing now is a change
- [x] 3.2 Tests: `test_professions` removed skill reads as changed; `test_controller` trainer pin ends after the profession leaves the skills; mutation-check

## 4. Demo keeps the game waypoint

- [x] 4.1 `Nav.lua`: `N.ReadGameWaypoint(api)` and `N.SetGameWaypoint(api, p)`, guarded, keeping the super-track state when it can be read
- [x] 4.2 `Core.lua`: wire both into the controller env from the Nav api
- [x] 4.3 `Controller.lua`: `Demo` stores the snapshot in `demoBefore`; `endDemo` sets it again only when the slot is empty or holds a demo pin
- [x] 4.4 Tests: `test_nav` read/set with a fake `C_Map`; `test_controller` restore at end and on stop, and no restore when the player set a new one during the tour; mutation-check

## 5. Failed timer

- [x] 5.1 `Adapter.lua` `A.after`: true only when `C_Timer.After` did not throw
- [x] 5.2 Tests: `test_adapter` throwing `C_Timer.After` returns false and logs once; `test_core` a redraw request after a failed timer schedules again; mutation-check

## 6. Review fixes (Codex)

- [x] 6.1 Demo: note the player's newest game waypoint before each step and at the end; do not put the addon's earlier pin over the player's point; tests for a point set after step 1 and at the last step, with and without an addon pin; mutation-check
- [x] 6.2 Trainer pin: `dropTrainerPin` on every readable skill update, also the first read and with warnings off; tests; mutation-check
- [x] 6.3 Pick: say the "list changed" line when the row no longer applies; test with the bow put away; mutation-check
- [x] 6.4 Hearth: same name needs a question that named the place; forget a question for another place; tests; mutation-check
- [x] 6.5 File GitHub issues for the deferred review findings (#46, #47, #48: waypoint read error, demo timer failure, lost question on logout without the bind event)

## 7. Docs and checks

- [x] 7.1 `docs/test-plan.md`: new §33 "Places and waypoints" (same-inn rebind, chooser after a weapon swap, unlearn with a trainer pin, demo with a game waypoint)
- [x] 7.2 `make test`, `make check`, `openspec validate --specs --strict` pass
