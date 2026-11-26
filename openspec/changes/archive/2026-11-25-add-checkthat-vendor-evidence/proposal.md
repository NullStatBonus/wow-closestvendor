# Proposal

## Why

Phase 3 of #61. The plan sections for vendors, navigation and trainers (s3, s4, s6, s11, s16, s17, s19, s21, s24 to s27, s30, s33) are player steps. Many of their results are decisions the addon makes silently (a waypoint cleared, a trainer pin skipped, a vendor learned) or values only the `/cvn log` header shows (learned counts, standing, the waypoint method), which a plan cannot read.

## What Changes

- **Automatic steps** where a log line or entry proves the result; waypoint drawing, sound, menus and page looks stay player steps with required log assertions and a reason in `notes`.
- **New debug log lines** at the silent decision points, once per change.
- **New CheckThat entries** for learned places, standing and the waypoint method.

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `diagnostics`: the debug log records vendor, trainer and waypoint decisions.
- `checkthat-integration`: new entries.

## Impact

- **Code:** `Controller.lua`, `Core.lua`, `CheckThat.lua`, possibly `Discovery.lua`, `Professions.lua`.
- **Tests:** matching `tests/test_*.lua`.
- **Plan:** `plans/closestvendor.yaml` sections listed above; the offline block.
- **Saved data:** no change.
- **Release:** patch, 1.11.2.
