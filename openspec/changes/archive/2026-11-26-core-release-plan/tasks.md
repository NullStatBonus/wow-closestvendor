# Tasks

## 1. Source and distance on the question line

- [x] 1.1 Reuse the controller's existing `yards` for the distance (no new `Search.lua` helper; see `design.md`). Verify with cases in `tests/test_controller.lua`: 0 yd, 10 yd, and rounding of 9.6 and 9.4.
- [x] 1.2 In `ClosestVendor/Core.lua`, pass `env.sourceOf(kind, npcId)` to the controller (`learned`, `NorgannonDB` or `shipped`). Verify with a case in `tests/test_core.lua` (or the nearest Core test file) for each source.
- [x] 1.3 In `ask` (`ClosestVendor/Controller.lua`), add `, <source>, <n> yd` after `(npc <id>)` on all three `question shown:` forms. The count or points follow. Verify that `tests/test_controller.lua` asserts each form. Break the format, see the test fail, and restore it.
- [x] 1.4 Find every plan assertion and `docs/contracts.md` row that matches `question shown:`, and fix any that anchors after `(npc …)`. Verify that `make plan` (`ct lines`) and `make test` pass.

## 2. `/cvn test trainer`

- [x] 2.1 Parse `test trainer` in `ClosestVendor/Commands.lua` and add it to the help text with `L[...]` sentences. Verify with `tests/test_commands.lua` and `tests/test_locale.lua`.
- [x] 2.2 Add the `trainer` branch to the controller's `test(kind)`. Prefer a known profession the nearest trainer teaches, else the nearest trainer and its first profession. Pass no points. Verify with `tests/test_controller.lua` cases: a known profession, no profession, no trainer, and no position (logs `test command: nothing asked: …`). Break each, see it fail, and restore it.
- [x] 2.3 Check that a test trainer question is not withdrawn on a zone change. Verify with a `tests/test_controller.lua` case.

## 3. Core plan

- [x] 3.1 Rewrite `plans/closestvendor.yaml` to the step table in `design.md`:
  - the preamble names the one character and its place;
  - each action is one player sentence after its opener, with the commands only in `commands:`;
  - each Expect says only what is on screen;
  - cv.s1.1 is Forever-only and cv.s1.2 Era-only;
  - the version step requires 1.13.0.

  Verify that `make plan` passes for the core plan.
- [x] 3.2 Assert each step's evidence in the log:
  - cv.s1.1 and cv.s1.2: `trigger go sell` with `bags=%d` and `durability=`, then `question shown: sell, `, then `accepted: … via native` or `via chat`;
  - cv.s1.4: `status window: shown, rows: .*bags low`;
  - cv.s1.5: `trigger clear sell`;
  - cv.s2.4: the food question with its count;
  - cv.s2.7 and cv.s6.2: `, learned, %d yd`.

  Verify that `make plan` (`ct lines`, `ct replay-flow`) passes.
- [x] 3.3 Check the core plan's `logs:` block and `offline:` block for the new line format. Neither names it, so neither changes. Verify that `ct offline --client both` passes (done in `make plan`).
- [x] 3.4 Relabel `plans/closestvendor.ui.yaml` and `plans/closestvendor.addons.yaml` as feature plans in their preambles: run when that feature changes, not every release. Verify that `make plan` passes.

## 4. Plan rules

- [x] 4.1 In `tests/test_plan.lua`, add the nine retired ids. For the core plan, add rules:
  - no `/cvn` or `|cff` in action text;
  - no class, profession, dungeon, fight or third-party addon in `setup`;
  - the core step id list.

  Update the version rule (core 1.13.0, feature plans 1.12.0). Break each rule in a scratch copy of the plan, see the test fail, and restore. Verify that `make test` passes.

## 5. Docs

- [x] 5.1 `AGENTS.md`, CheckThat section: the core plan is the release gate, and the feature plans run when their feature changes. Update the plan list, the section ranges and the "all three run before each release" line. Verify by reading it and with `make test` (readme and doc reference checks).
- [x] 5.2 `docs/test-plan.md`: the release gate, the one-character setup, and the feature plans. `docs/contracts.md`: the new `question shown:` format, and `test command: trainer`. Verify with `make test`.
- [x] 5.3 `README.md`: `/cvn test trainer` in the command list and the Test and debug section, and the new `question shown:` format in the debug log notes. `docs/listing.md` has no command list and its headline does not change, so it stays. Verify with `tests/test_readme.lua`.

## 6. Full check

- [x] 6.1 Run `make test`, `make check` and `make plan`. All three pass.

## Workflow follow-up

- Run the core plan in game on WoW Forever and on Classic Era with one ordinary character, then `ct collect --plan plans/closestvendor.yaml --dest evidence` and `/ct-verify`.
- At archive: sync the specs, bump both TOCs to 1.13.0, and write the 1.13.0 CHANGELOG section (New: `/cvn test trainer`; Changed: the debug line names the vendor's source and distance).
