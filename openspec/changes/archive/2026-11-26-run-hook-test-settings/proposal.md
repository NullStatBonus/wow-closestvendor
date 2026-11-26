# Proposal

## Why

Test settings (1.12.0) are turned off only by a plan's last step. A tester who ends, abandons or replaces a run keeps test settings until they type `/cvn testsettings off` (#72). CheckThat now has a run start and end callback (`CheckThat.OnRun`, `CheckThat.ActiveRun`, wow-checkthat#171), so ClosestVendor can follow the run itself.

The `reagents` CheckThat entry also reports `none` when no watched reagent's count can be read (#67). That certifies a negative from a failed game read; unknown data must be nil.

## What Changes

- When a run of a ClosestVendor plan starts, test settings turn on. When it ends (ended, replaced or deleted), they turn off and the tester's own settings come back. Each run turns them on once: a repeated start for the same run (after `/reload`) changes nothing, so a tester who turned them off keeps them off.
- At login, when test settings were turned on by a run and CheckThat says no ClosestVendor run is open, the tester's settings come back. Test settings turned on by hand are never turned off by this.
- With CheckThat missing or too old to have the callback, nothing changes: the plan commands still work.
- The `reagents` entry answers nothing when the count of any watched reagent cannot be read. Warnings and reagent buying are unchanged.
- Plans keep their Run commands (`/cvn testsettings on` and `off`) as the fallback for an older CheckThat. No plan step checks the run callback until a CheckThat release has it; its log lines are diagnostic for now.

## Capabilities

### New Capabilities

### Modified Capabilities
- `checkthat-integration`: test settings follow the CheckThat run; the `reagents` entry answers nothing when a watched count is unknown.

## Impact

- `ClosestVendor/CheckThat.lua`: register the run callback and read `ActiveRun` at login, guarded.
- `ClosestVendor/Core.lua`: run start, run end and no-run handlers around the existing test settings switch; `reagentList` reports an unread count.
- `ClosestVendor/Controller.lua`: the kept reagent text is unknown when a count was unread.
- Saved variable `ClosestVendorCharDB.testRun` (the run id whose start turned test settings on).
- Tests: `tests/test_checkthat.lua`, `tests/test_core.lua`, `tests/test_controller.lua`.
- Docs: `README.md` (test settings), `docs/contracts.md` (log lines, saved variable, entry), `CHANGELOG.md`. Version 1.14.0.
