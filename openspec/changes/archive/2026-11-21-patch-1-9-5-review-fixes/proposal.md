## Why

A Codex review of 1.9.4 found three regressions and three smaller gaps.

## What Changes

- A worn-gear check that waits for its timer runs first when a merchant opens, so the merchant answers its repair question.
- At the end of `/cvn demo`, an unreadable game waypoint stops the old addon pin from replacing the player's point.
- The demo and `Nav.clear` share one tolerance (`Nav.SPOT`, 0.00001).
- The invalid-page message lists `notifications` and `status-window`.
- Tests: a logout registration check and a bind to a new inn.
- Not fixed: localized reagent names match case-insensitively for ASCII only (Lua has no Unicode lowercase); the README says so.

## Capabilities

### Modified Capabilities

- `vendor-trigger`, `visual-preview`.

## Impact

- Code: `Core.lua`, `Controller.lua`, `Nav.lua`, `Commands.lua`. Patch 1.9.5, no saved-data change.
