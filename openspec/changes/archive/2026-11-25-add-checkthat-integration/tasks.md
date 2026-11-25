## 1. Plan

- [x] 1.1 Copy CheckThat's `plans/full/closestvendor.yaml` to `plans/closestvendor.yaml`; delete the scratch `ct from-md` copy
- [x] 1.2 Insert the version step `cv.s0.1`; renumber s0 setup to `cv.s0.2`-`cv.s0.4`; add a debug-on setup step; fix references to them
- [x] 1.3 Repair cut-off step titles
- [x] 1.4 Add `logs.facts`, `logs.errors` and the `offline` block; rewrite the `cv.s2.1` assertion as `pattern`
- [x] 1.5 Remove the #60 boundary and unreadable-row steps after their unit tests exist

## 2. Integration

- [x] 2.1 `A.checkThat()` and `A.addonVersion()` in `Adapter.lua`
- [x] 2.2 `ClosestVendor/CheckThat.lua` in both TOCs before `Core.lua`: status, guarded Entry/Report, entries `version`, `setting`, `integration`
- [x] 2.3 `Core.lua`: `CT.Start` last in `start()` in pcall; `CheckThat: ...` report header line

## 3. Tests

- [x] 3.1 `tests/test_checkthat.lua`: missing, old, Entry raises (first and second), Report raises then Entry, entry error, version encoding, setting, no saved-variable change; break and restore each
- [x] 3.2 `tests/test_plan.lua`: unique ordered ids from s0, gaps allowed, references resolve, no CheckThat checkout path; break and restore
- [x] 3.3 `test_smoke` loads `CheckThat.lua`; `test_core` checks the report line
- [x] 3.4 #60: boundary tests in `test_commands.lua`, unreadable-row test in `test_status.lua`; break and restore

## 4. Docs and tooling

- [x] 4.1 Makefile `plan`; `.pkgmeta` and `.gitignore`
- [x] 4.2 `docs/test-plan.md` pointer; AGENTS.md `## CheckThat` and reworded Documentation/Testing bullets; README, CONTRIBUTING, DESIGN.md, docs/localization.md, docs/listing.md; new docs/contracts.md

## 5. Gate and release

- [x] 5.1 `make test`, `make check`, `make plan` clean; list every `lines` miss; record `ct coverage` result
- [x] 5.2 Independent Opus review of the plan against the CheckThat card; fix findings
- [x] 5.3 File CheckThat issues (remove CV plans, coverage reads Commands.lua, lines contains gap); comment on #59
- [x] 5.4 Opus and Codex code reviews; fix findings
- [x] 5.5 Sync specs, bump both TOCs to 1.11.0, CHANGELOG 1.11.0, archive, commit, PR
