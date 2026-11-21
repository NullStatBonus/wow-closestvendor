## Why

Patch 1.9.4 gathers the open bug and small-refactor issues: #41 (small command and data bugs), #44 (saved data and diagnostics), #45 (CI Node.js warning), #46 and #47 (demo edge cases), #51 (Move tests) and #52 (adapter rule wording).

## What Changes

- `/cvn settings status-window` opens the Status window tab; `/cvn settings notifications` opens the Notifications tab.
- The standing of a trainer only NorgannonDB knows is recorded.
- An auctioneer and a vendor are compared by exact distance, not rounded yards.
- Ending navigation clears the game waypoint only when it is exactly the addon's (tolerance 0.00001).
- Worn-gear events fold into one check; the debug log gets one line with the count instead of a raw line per event.
- Load drops old account-level keys and the retired `toastLocked`.
- The demo restores the player's game waypoint only when the slot was readable, and clears its made-up rows when a step timer fails.
- CI uses `actions/checkout@v5`. `tests/test_move.lua` covers Move. `AGENTS.md` states the Nav exception to the Adapter rule.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `slash-interface`, `diagnostics`, `saved-settings`, `vendor-trigger`, `auction-routing`, `vendor-discovery`, `vendor-navigation`, `visual-preview`.

## Impact

- Code: `Core.lua`, `Controller.lua`, `Nav.lua`, `Commands.lua`, `Presentation.lua`, `Options.lua`, workflows.
- No new player sentence. No saved-data break (old keys are removed).
- Out of scope: #48 (needs an in-game check), #50 (test plan rewrite), `/cvn reagent` names on other locales (new issue), the enhancements.
