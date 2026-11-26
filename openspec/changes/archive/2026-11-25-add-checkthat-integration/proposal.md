# Proposal

## Why

ClosestVendor's in-game test plan lives in two places: `docs/test-plan.md` here and a converted copy in the CheckThat repository (`plans/full/closestvendor.yaml`). Neither is tied to the code, the converted copy has cut-off titles and no automatic steps, and the plan does not check which version is under test (#61, Phase 1). CheckThat can run the plan in game and read the debug log, but ClosestVendor gives it nothing to call.

## What Changes

- **The plan moves here.** `plans/closestvendor.yaml` is the plan of record (from CheckThat's full plan, titles repaired). `docs/test-plan.md` becomes a pointer. "Test plan check N.M" means step `cv.sN.M`. Step ids freeze with this change.
- **Version first.** New step `cv.s0.1` asks CheckThat for the ClosestVendor version and passes at 1.11.0 or newer. The old setup steps keep their order after it.
- **CheckThat integration.** A new file talks to CheckThat when it is installed: it registers the entries `version`, `setting` and `integration` at login. ClosestVendor works the same with CheckThat missing, old or broken.
- **Report line.** `/cvn log` shows `CheckThat: working`, `CheckThat: not detected` or `CheckThat: failed: <why>`.
- **Fewer manual checks (#60).** Command boundary checks and the "unreadable row is hidden, never 0" check become unit tests and leave the plan.
- **Tooling.** `make plan` runs the installed `ct` (validate, compile, replay-flow, lines, offline). `tests/test_plan.lua` keeps step ids unique and ordered and checks every "test plan" reference.
- **Not in this change:** #59 (regroup sections) is dropped because ids freeze now and step text cites section numbers. Converting player steps to automatic steps is Phases 2-4 of #61.

## Capabilities

### New Capabilities
- `checkthat-integration`: how ClosestVendor exposes entries to the CheckThat test runner and stays safe when CheckThat is missing, old or failing; the plan of record.

### Modified Capabilities
- `diagnostics`: the copyable report adds the CheckThat status line.

## Impact

- **Code:** new `ClosestVendor/CheckThat.lua` (both TOCs, before `Core.lua`); `Adapter.lua` (CheckThat global, addon version); `Core.lua` (start at login, report line).
- **Tests:** new `tests/test_checkthat.lua`, `tests/test_plan.lua`; `test_smoke`, `test_commands`, `test_status` additions.
- **Docs:** AGENTS.md (`## CheckThat`), README, CONTRIBUTING, DESIGN.md, docs/localization.md, docs/listing.md, docs/test-plan.md, new docs/contracts.md, CHANGELOG.
- **Packaging:** `.pkgmeta` ignores `plans`, `build`; `.gitignore` ignores `build/`, `evidence/`; Makefile `plan` target.
- **Saved data:** no change.
- **Release:** minor, 1.11.0.
