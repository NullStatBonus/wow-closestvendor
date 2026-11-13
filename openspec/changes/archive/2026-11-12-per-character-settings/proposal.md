# Proposal

## Why

Settings were saved once per account, so a change on one character changed every other. Players with several characters want different thresholds, switches, sounds and window positions (a hunter and a warrior do not need the same food row).

## What Changes

- Everything the player sets (thresholds, switches, reminder sound, status window options and position) is saved per character in a new `ClosestVendorCharDB`.
- What is true of one character only moves with it: known professions, the hearthstone point, the last outdoor position, and the debug log with its switch.
- Vendors, trainers and auctioneers learned from play stay in the account table `ClosestVendorDB`, shared by all characters.
- A character met for the first time starts from the settings the account had before this change (a copy), or from the defaults when there were none. The old values stay in the account table so later characters start the same way. Known professions, the hearth point and the log are not carried over; they are learned again.

## Capabilities

### New Capabilities
- `saved-settings`: what is saved per character, what is shared by the account, and how a new character starts.

### Modified Capabilities
- Requirements that said "saved per account" now say "saved per character" (`vendor-trigger`, `food-and-water`, `pet-food`, `class-reagents`).

## Impact

`Core.lua` (init and the saved tables), both TOC files (`SavedVariablesPerCharacter`), `tests/test_core.lua`, `README.md`, `docs/test-plan.md`, `CHANGELOG.md`. No setting, command or data format changes.
