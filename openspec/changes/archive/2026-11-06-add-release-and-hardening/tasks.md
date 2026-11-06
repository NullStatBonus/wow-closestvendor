# Tasks

## 1. Test runner and CI

- [x] 1.1 Add `tests/harness.lua` (shared `eq`, counter, done) and `tests/run.lua [pattern]` (each `tests/test_*.lua` in its own process, failures only, summary, non-zero exit); move the existing test files onto the harness; verify `luajit tests/run.lua` passes, a pattern runs only matching files, and a deliberately failing test makes the runner exit non-zero
- [x] 1.2 Make `make test` run the runner then the Python tests, and add `make check`; verify both targets pass
- [x] 1.3 Add `.github/workflows/ci.yml` (push and pull request: install luajit, tests, checks); verify the YAML parses and the commands it runs pass locally

## 2. Adapter (api-resilience)

- [x] 2.1 `Triggers.FreeSlots` returns nil when no bag reported and `Triggers.Update` treats a nil bag count as unknown; verify with tests for all-fail, some-fail and unknown-bags-never-trigger
- [x] 2.2 Add `Adapter.lua`: guarded, `pcall`ed reads of every game value `Core.lua` uses, nil on failure, errors reported once per kind through `Adapter.onError`; move `Core.lua` onto it; verify with adapter tests (missing function, throwing function, partial slot data) and the existing core tests still passing
- [x] 2.3 Core integration: with each game function missing or throwing in turn, login and events raise no error and the other triggers still work; verify with a table-driven stub test over every adapted call

## 3. Diagnostics

- [x] 3.1 Add `Log.lua` (pure bounded ring buffer, no-op when off) and the report text builder; verify with tests for off-by-default, the 300 limit, ordering and report contents
- [x] 3.2 Wire the log: `/cvn debug on|off`, `/cvn log` (copyable window with chat fallback), events, adapter failures and `Controller` decisions recorded while on; update README and the commands test; verify with command, controller and core stub tests

## 4. Localization

- [x] 4.1 Add `Locales/enUS.lua` (`ns.L` with English fallback), `Locales/Example.lua`, `docs/localization.md`, and wrap every player-facing sentence in `L[...]` (commands, prompts, navigation text, options labels, core messages); verify all existing tests still pass
- [x] 4.2 Add a locale test that scans the source for `L["..."]` keys and fails when the example or a locale file defines a key the code does not use, and a test that a translated sentence is shown and a missing one falls back; verify by adding a bad key and seeing it fail

## 5. Release pipeline

- [x] 5.1 Add `.pkgmeta`, a fuller `.gitignore`, `tools/check-toc.sh`, `tools/check-tocs-match.sh`, `tools/check-version.sh`; verify they pass on the repo and each fails on a deliberately broken copy (missing file, differing TOCs, wrong version or tag)
- [x] 5.2 Add `.github/workflows/release.yml` (tag `v*`: tests, checks, packager, GitHub release); verify the YAML parses and the checks it runs pass locally
- [x] 5.3 Add `CHANGELOG.md` (0.1.0) and `docs/publishing.md`; verify the changelog version equals the TOC version via `tools/check-version.sh`

## 6. Docs and store listing

- [x] 6.1 Add `CLAUDE.md` (release and version rules, conventions) and `CONTRIBUTING.md`; add README "Problems?" and developer sections; verify the README test still passes and every command in the docs exists
- [x] 6.2 Add `docs/test-plan.md` (the in-game checklist from the main change, including the report window and settings page); verify it covers every item in the main change's play-test task
- [x] 6.3 Add `docs/listing.md` with copy-ready CurseForge and Wago text, summary, categories, supported versions, license, links and screenshot suggestions; verify it matches the README's claims (triggers, limits, commands)

## 7. Wrap-up

- [x] 7.1 Run everything (`make test`, `make check`, `openspec validate --strict`) and list what still needs the owner: store project IDs, secrets, the in-game checks
