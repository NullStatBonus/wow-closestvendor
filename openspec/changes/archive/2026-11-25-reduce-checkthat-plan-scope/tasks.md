# Tasks

## 1. Plans

- [x] 1.1 Write `plans/closestvendor.yaml` (core, s0 to s6), `plans/closestvendor.ui.yaml` (s10 to s13) and `plans/closestvendor.addons.yaml` (s20 to s21), each under 25 steps, reusing the reviewed steps and assertions; verify `make plan` passes validate, compile, replay-flow, lines and offline on all three
- [x] 1.2 Remove the old steps (Git history keeps them); keep the entry calls in the core offline block and give the ui and addons plans the calls they use
- [x] 1.3 Remap the requirement coverage to the new ids; verify at least 206 of 228 are covered

## 2. Tests

- [x] 2.1 Rewrite `tests/test_plan.lua` for the plan set (all three present, own section range, under 25 steps, version step first, no-Lua-error step last, ids unique across the set, references resolve against the set); verify a duplicated id fails it
- [x] 2.2 Add unit tests: water controls only for mana classes and pet food controls only for hunters (`tests/test_options.lua`), the presentation lines of the report header (`tests/test_core.lua`); verify each fails with the behavior broken and passes with it restored

## 3. Tooling and docs

- [x] 3.1 `make plan` loops over the three plans, stops at the first failure and writes one `build/<plan>.ct` each
- [x] 3.2 Update AGENTS.md (CheckThat plan set, step limit, the version-bump exception), `docs/test-plan.md`, README, CONTRIBUTING, DESIGN.md, `docs/localization.md` and `docs/contracts.md` (lines and entries no plan step checks)

## 4. Integration

- [x] 4.1 Run `make test`, `make check` and `make plan`; verify all pass
- [x] 4.2 Sync the spec and run `openspec validate --specs --strict`; archive without a version bump or CHANGELOG section
