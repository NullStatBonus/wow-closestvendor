## Why

The in-game plans assume the default settings. A tester with their own settings (for example "Navigate without asking") sees question steps fail, and each plan's Run commands overwrite the tester's real settings. CheckThat has no setup or teardown for a run, so ClosestVendor provides the isolation.

## What Changes

- New command `/cvn testsettings on|off`. `on` puts the character's settings and the status window and toast positions aside and uses fresh defaults; `off` brings them back exactly. The mode lasts across `/reload` and logout, and a chat line at login says it is on.
- Switching ends open questions, previews, Move and a pending color pick, so nothing made under one set acts on the other.
- The debug log records each switch, and a line at login while the mode is on. The report header shows the mode.
- All three plans turn test settings on in their setup step and off in their last step. Version steps require 1.12.0.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `saved-settings`: test settings mode.
- `diagnostics`: log lines and the report line for test settings.
- `checkthat-integration`: the plans run under test settings.

## Impact

`Core.lua`, `Commands.lua`, locales, the three plans, `tests/test_commands.lua`, `tests/test_plan.lua`, README, `docs/listing.md`, `docs/contracts.md`, AGENTS.md, CHANGELOG, both TOCs (1.12.0).
