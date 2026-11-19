# Proposal

## Why

The About page repeats the command list, which `/cvn help` and the README already give. The player said this part is unnecessary.

## What Changes

- About shows only the addon name, the installed version and the one-sentence purpose.
- Removed from About: the Commands heading, the seven command rows, the tip under them, the line listing settings/help/get/set/preview/log clear, and the note about legacy `/cvn test` commands.
- `/cvn help` and the README still list every command. No command changes.
- Ships with the next update. No separate release.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `settings-interaction`: "Settings landmarks" and "Consistent and spacious settings layout" no longer require commands on About.
- `slash-interface`: "Common command discovery" documents the demo in help and README, not About.
- `status-window`: "Demo" is documented in help and README, not About.
- `vendor-trigger`: "Settings panel" has About show version and purpose.

## Impact

- `ClosestVendor/Options.lua` (About page), `tests/test_options.lua`, `README.md` ("Advanced and About"), `docs/test-plan.md`.
