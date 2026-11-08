# Proposal

## Why

The on-screen message for an auto pin is drawn by the game's error frame, which fades it after about 3 seconds. That is too short to read a line that names a target, its zone, its distance and the other choice. The frame's timing is shared with real game errors, so it cannot be lengthened without side effects.

## What Changes

- The on-screen message stays visible for about 5 seconds, then disappears.
- It is drawn in a small frame owned by the addon, not in the error frame, so game errors are untouched.
- A newer message replaces the one showing, and restarts the five seconds.
- Still silent, still controlled by the `autoNotice` setting, and still skipped without error when the client lacks the frame API.
- No new setting or command.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `vendor-navigation`: the "Automatic pin" requirement says the on-screen message is shown for about five seconds and that a newer one replaces it.

## Impact

- `Adapter.lua`: `screenMessage` draws in an addon-owned frame and hides it after five seconds.
- Tests: `test_adapter`, `test_core`.
- Docs: `docs/test-plan.md` section 11 (about five seconds); README and listing wording if they promise a duration.
- CHANGELOG `## 0.4.1` and a patch bump to 0.4.1 at archive (it changes existing behavior only).
