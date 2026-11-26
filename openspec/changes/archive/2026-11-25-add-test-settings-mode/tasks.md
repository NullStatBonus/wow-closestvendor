# Tasks

## 1. Code

- [x] 1.1 Move init()'s normalization into `normalize(cfg, existingUser)` in Core.lua; init() calls it
- [x] 1.2 `Commands.SwapSettings` (pure) and `/cvn testsettings on|off` parsing in Commands.lua
- [x] 1.3 Core action handler: end shows, Move, color picks and questions; swap; refresh; rebaseline `cfgSeen`; log lines
- [x] 1.4 Login chat line and `test settings: on at login` log line in start(); report header line
- [x] 1.5 Locale strings

## 2. Tests

- [x] 2.1 test_commands.lua: parsing and SwapSettings (stash, identity, defaults, reset, off restores nested values exactly, not on, default filled at restore)
- [x] 2.2 Core-level checks for the report line and the rebaseline (existing Core test harness), break-then-restore per AGENTS.md
- [x] 2.3 test_plan.lua: version 11200, setup and last steps carry testsettings on/off

## 3. Plans and docs

- [x] 3.1 Three plans: setup and last steps, version 11200, logs blocks
- [x] 3.2 README, docs/listing.md, docs/contracts.md, AGENTS.md
- [x] 3.3 `make test`, `make check`, `make plan`
