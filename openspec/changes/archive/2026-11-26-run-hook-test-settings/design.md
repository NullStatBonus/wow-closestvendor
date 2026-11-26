# Design

## Context

Test settings live in `ClosestVendorCharDB.realSettings` and switch through `swapTestSettings` in `Core.lua`. CheckThat (unreleased, API_VERSION 3) adds `CheckThat.OnRun(addon, fn)` and `CheckThat.ActiveRun(addon)`. `fn("start" | "end", info)` gets `info.plan`, `digest`, `runId` and, for `end`, `reason` (`ended`, `replaced`, `deleted`). A run stays open until it is ended, also after its last step. `start` repeats after `/reload`, and comes once at registration when a run is already open. A reload never sends `end`.

## Goals / Non-Goals

**Goals:** a tester's own settings come back however a run stops; a run never turns test settings back on after its last step turned them off; nothing changes without the callback.

**Non-Goals:** removing the plan Run commands (kept as the fallback until a CheckThat release has the callback); a plan step for the callback (follow-up issue); other run-scoped state.

## Decisions

- **One run turns test settings on once.** `ClosestVendorCharDB.testRun` keeps the run id whose `start` was handled (text, cut to 40 characters). A `start` with the same id logs `test settings: run already seen` and changes nothing. Alternative: turn on at every `start`. Rejected: the plan's last step turns them off, the run stays open, and the next reload would turn them on again.
- **`start` while already on** with no run recorded (typed by hand) records the run and logs `test settings: already on (run started)`, with no reset. With a different run recorded (it ended while the addon was not loaded) it logs `test settings: another run started` and resets the test set, so each run starts from the defaults. A `start` with no run id logs `test settings: run start without an id` and is ignored.
- **`end`** clears `testRun` and logs `test settings: run ended: <reason>`. When test settings are on it then restores through the usual switch, which logs `test settings: off (own settings restored)`. A tester who turned them on by hand during a run gets them back at its end too: the run owns the mode while it is open.
- **Login without a run.** Before registering, the addon calls `ActiveRun`. Only when `testRun` is set and no run is open does it clear `testRun` and restore, logging `test settings: no run open at login` before the usual off line. Test settings turned on by command have no `testRun`, so they stay on. Checking first means a catch-up `start` never races the restore.
- **Where the code sits.** `CheckThat.lua` makes every CheckThat call (`ActiveRun`, `OnRun`) guarded and in pcall, and logs `checkthat: run hook registered` or `checkthat: run hook not available`. It registers the hook before the entries. Core supplies `runStarted(id)`, `runEnded(reason)` and `runGone()` in the Start context. A raised error from `OnRun` or `ActiveRun` fails the integration like any other call. An error inside a handler is caught and logged `checkthat: FAILED: <handler>: <why>`, and leaves the integration on. After a failure, `runEnded` and `runGone` still run (they only restore); `runStarted` does not.
- **Chat.** The switch reuses the existing on and off chat lines, so the tester sees what happened; no new strings.
- **Reagents entry (#67).** `reagentList` returns the readable reagents and a second value that is true when a watched count could not be read. The controller keeps no reagent text or counts then, so the entry answers nothing. The warning and buying keep using the readable reagents, as the class-reagents spec requires ("a reagent whose count cannot be read SHALL be skipped"). Alternative from the issue: return nil. Rejected: it would stop all buying and warnings when one count is unread, and change the buy log line.
- **Version** 1.14.0: a new capability in the test integration.

## Risks / Trade-offs

- **Unreleased API.** The callback cannot be checked in game until CheckThat ships it. Unit tests drive a fake CheckThat with the documented contract; a follow-up issue adds a plan step and drops the Run commands once it ships.
- **Ending a run restores settings changed by hand during the run.** Accepted: those changes were made to the test set.
