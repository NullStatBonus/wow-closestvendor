## Context

See proposal.md - Why. Five small fixes in different modules; each has its own test. Current code:

- `Core.lua` `learnHearth` returns early when the bind name equals the saved name, so the pending innkeeper position is never used for a same-inn rebind. It runs on `HEARTHSTONE_BOUND`, `PLAYER_ENTERING_WORLD` and `ZONE_CHANGED_NEW_AREA`.
- `Controller.Pick` resolves the row again but pins `entry.v` from a list built when the menu opened, without checking it against the new request.
- `Professions.New().Changed` compares only the names present now, so a removed skill is not a change and `checkTrade` (which already clears the trainer pin when the profession is no longer within the threshold) never runs.
- `Controller.Demo` saves only the addon's own pin (`pinVendor` ...). The native Nav adapter writes the game's single map waypoint slot, which overwrites one the player set.
- `A.after` returns true after `call(...)` even when `C_Timer.After` threw. `Core.lua:487` then keeps `windowDirty = true` forever, and `timerArmed` at `Core.lua:261` stays true.

## Goals / Non-Goals

**Goals:** fix the five bugs with the least code; keep Adapter the only game-call file; no saved-data change.

**Non-Goals:** keeping the player's game waypoint for normal (non-demo) pins (the slot is shared, and a pin the player asked for replaces it by design); TomTom and WaypointUI waypoints (they hold many waypoints, the demo does not remove the player's ones); the other fix groups.

## Decisions

1. **Hearth: same-name rebind from any learn call.** With the same name and a pending innkeeper position whose area matches the name, `learnHearth` saves that position and logs "hearthstone point learned". The first plan accepted it only from `HEARTHSTONE_BOUND`, but `Core.lua` registers that event only where the client has it, so on Classic Era the fix could never run (decided with the user during apply). A question closed without binding at that inn still gives the right place: the player is already bound to an inn of that name. With no matching question, the same name changes nothing, as before. After review: with the same name, the question must name the place (a question with no place does not count), and a question that named another place is dropped as soon as the bind name is read.
2. **Pick: reuse the search eligibility check.** Export `Search.Fits(v, need)` (the existing local `eligible`) and check `Professions.Teaches(v[7][q.trade], q.need)` for trainers. Pick returns false, logs "chosen pin: the seller no longer fits", and says `L["The seller list changed. Open it again to choose."]`. Alternative considered: pin the row's current default instead. Rejected: the player chose a specific NPC, and silently routing somewhere else is surprising. Faction is not rechecked (it cannot change while a menu is open). After review: when the row no longer applies at all (no ranged weapon, pet or near-cap profession), `resolve` returns a second value `true` on those silent paths, and Pick says the same line.
3. **Professions: detect removed names.** In `Changed`, also loop the previous `ranks` for names missing from `now`. One loop, no new state. After review: the trainer-pin check moves into `dropTrainerPin`, which runs on every readable skill update (also the first read and with profession warnings off), so a pin set before the first read or from the status window ends too.
4. **Demo: Nav owns reading and writing the game slot.** Add `N.ReadGame(api)` returning `{ map, x, y, tracked }` or nil (guarded, `C_Map.GetUserWaypoint`) and `N.SetGame(api, p)` (`SetUserWaypoint` with `UiMapPoint.CreateFromCoordinates`; super-track only when `C_SuperTrack.IsSuperTrackingUserWaypoint` said it was tracked, when that function exists). The controller reaches them through `env` functions wired in Core from the Nav api, as other Nav calls are. The controller keeps `demoSpots`, the game waypoints this addon set (its own pin from before the demo and each step's pin). Before each step and at the end, `noteGame` reads the slot; a point not in `demoSpots` (same map and within 0.001, the native adapter's ownership test) is the player's and becomes `demoBefore.game`, so the newest one wins. At the end, the player's point in the slot is left; an empty or addon-held slot gets `demoBefore.game` back. The addon's own earlier pin is put back only when the slot does not hold the player's point.
5. **Timer: return pcall's result.** `A.after` wraps the call so it returns true only when `C_Timer.After` did not throw: `return call("C_Timer.After", function() C_Timer.After(seconds, fn) return true end) == true`. The failure is reported once by `fail` as now. Callers already handle false.

## Risks / Trade-offs

- [Pick refuses a seller the player wanted] → only when it truly no longer sells what the row needs; the chat line says what to do.
- [Restoring the game waypoint fights a waypoint the player set during the demo] → ownership test leaves any other point alone.
- [Era client without `GetUserWaypoint`] → snapshot is nil, nothing is restored (same as today).
- [A waypoint read that throws reads as an empty slot] → the noted point may be set over an unknown one; very rare, filed as a GitHub issue.
- [A demo step whose pin replaces the player's new point] → that point is noted before the next step and set again at the end; it is off the map only while the tour runs.
- [A timer that throws every time] → each redraw request tries again and fails cheaply; the error is logged once.
