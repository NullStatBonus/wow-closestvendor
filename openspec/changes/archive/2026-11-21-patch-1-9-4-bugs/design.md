## Context

Small fixes in separate modules; each has a test. See proposal.md.

## Decisions

1. Gear events: only durability and own-unit inventory events are folded (0.2 s timer, `evaluateSoon`). Bag events stay immediate: the game already folds them and many flows rely on them.
2. The debug log drops the raw line for those two events and writes "gear events: N folded into one check" when the check runs.
3. Distance: the controller keeps a `dist` function; `yards` rounds it for display only.
4. `Nav.ReadGame` returns `nil, true` when the slot cannot be read, so the demo can tell it from an empty slot.
5. Settings pages: `notifications` and `status-window` are pages with their own tab path in `Options.PATHS`.

## Risks

- A gear event now acts up to 0.2 s later. Repair and ammo questions are not time critical.
