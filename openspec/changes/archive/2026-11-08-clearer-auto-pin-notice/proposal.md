# Proposal

## Why

In `auto` mode the addon sets the waypoint without a question and prints only "Navigating to <name>." The line has no zone or distance, so the player cannot tell which target was chosen, and it is easy to miss in a busy chat window. The map pin sounds, but nothing shows on screen what it is for.

## What Changes

- The auto-pin chat line names the target as `name (zone, N yards)`, the same form the two-target question uses.
- When two candidates existed, the line also names the one not chosen, with its zone and distance.
- The same text is shown as a short on-screen message with no sound (the map pin already plays one).
- New setting `autoNotice` (on by default): `/cvn notice on|off` and a settings page checkbox switch the on-screen message off. The chat line always prints.
- Applies to vendors and trainers. Nothing changes in `ask` mode.
- If the client has no way to show an on-screen message, the chat line still appears and no error is raised.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `vendor-navigation`: the "Automatic pin" requirement gains the content of the notice and the silent on-screen message.
- `vendor-trigger`: adds the on/off setting for the on-screen message (command, page, report).

## Impact

- `Adapter.lua`: a guarded on-screen message call, nil when missing.
- `Controller.lua`: builds the notice from the chosen and other candidates; sends it to chat and to the on-screen message.
- `Core.lua`: wires the new env functions (`notify`, zone name); default and report header.
- `Commands.lua`, `Options.lua`: the new setting.
- `Locales`: two new full-sentence keys.
- Tests: `test_controller`, `test_adapter`, `test_core`.
- Docs: README, `docs/listing.md`, `docs/test-plan.md` section 11; CHANGELOG `## 0.4.0` and a minor bump to 0.4.0 at archive (a new setting is a user-visible feature).
