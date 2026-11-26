# Tasks

## 1. Reagents entry (#67)

- [x] 1.1 `reagentList` in `ClosestVendor/Core.lua` returns a second value, true when a watched reagent's count is unread; the controller (`ClosestVendor/Controller.lua`) keeps no reagent text or counts then. Add a test in `tests/test_controller.lua` (an unread count gives no `reagents` value, never `none`; readable reagents still warn) and a Core test through the entry. Break the fix, see the tests fail for that reason, restore, see them pass.
- [x] 1.2 Update the `reagents` row in `docs/contracts.md` and the comment above the entry in `ClosestVendor/CheckThat.lua`; `make test` passes.

## 2. Test settings follow the run (#72)

- [x] 2.1 In `ClosestVendor/CheckThat.lua`, `CT.Start` reads `ActiveRun` (calling `ctx.runGone` when no run is open) and then registers `OnRun`, guarded and in pcall; it logs `checkthat: run hook registered` or `checkthat: run hook not available`. Tests in `tests/test_checkthat.lua` with a fake CheckThat: registered once, start and end reach the handlers with the run id and reason, a missing `OnRun` changes nothing, a raising `OnRun` fails the integration, a raising handler is logged and contained, after a failure an end still restores.
- [x] 2.2 In `ClosestVendor/Core.lua`, add `runStarted`, `runEnded` and `runGone` around `swapTestSettings`, with `ClosestVendorCharDB.testRun` and the log lines from design.md. Tests in `tests/test_core.lua`: start turns on and records the run, a repeated start after the last step turned them off keeps them off, start while on does not reset, end restores, end while off changes nothing and logs the end, a different run resets the test set, a start without an id is ignored, the catch-up start inside `OnRun` at login (number id), login with `testRun` and no open run restores, login after a manual `on` keeps them on, no callback keeps today's behaviour. Break each, see it fail, restore.
- [x] 2.3 Document it: `README.md` test settings section (follows a CheckThat run when CheckThat supports it), `docs/contracts.md` (the new log lines as "Diagnostic, no plan step", `ClosestVendorCharDB.testRun`). Verify with `make test` (README checks included).

## 3. Integration

- [x] 3.1 Run `make test`, `make check` and `make plan`; all pass.
- [x] 3.2 File the follow-up issue: once a CheckThat release has `OnRun`, add a core plan step for the run callback and drop the setup step's Run command.

## Workflow follow-up

- Set version 1.14.0 in both TOC files and write the `## 1.14.0` CHANGELOG section at archive.
- Archive, commit, open the PR with the tests listed, and close #67 and #72.
