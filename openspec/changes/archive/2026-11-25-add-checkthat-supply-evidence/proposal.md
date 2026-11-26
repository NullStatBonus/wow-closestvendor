# Proposal

## Why

Phase 4, the last phase of #61. The plan sections for buying, supplies, the status window, settings and the report (s1, s7, s10, s12 to s15, s18, s20, s22, s28, s29, s31, s34, s35) were all player steps, and some of them asserted report-header text or saved-variable names that never reach the debug log. The status window, setting changes and purchase questions wrote no line at all.

## What Changes

- **Automatic steps** where a log line or entry proves the result; layout, colour, opacity, sound, menus and page looks stay player steps with required log assertions and a reason in `notes`. Fake assertions are replaced by real checks.
- **New debug log lines:** the status window shown or hidden and its rows (only when they change), each setting change, purchase questions asked or declined, the ammo kind and a partial purchase, why a test command asked nothing, an auctioneer learned.
- **New CheckThat entries:** `window`, `config(name)`, `reagents([id])`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `diagnostics`: the debug log records the status window, setting changes and purchase questions.
- `checkthat-integration`: new entries.

## Impact

- **Code:** `Core.lua`, `Ammo.lua`, `Controller.lua`, `Tracker.lua`, `CheckThat.lua`.
- **Tests:** matching `tests/test_*.lua`.
- **Plan:** sections listed above; the offline block.
- **Saved data:** no change.
- **Release:** patch, 1.11.3.
