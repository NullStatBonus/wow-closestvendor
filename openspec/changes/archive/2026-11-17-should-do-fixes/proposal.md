## Why

The Codex review's "should do" findings, as the player decided them: a question asked in one zone should not survive a zone change or an instance; the hearthstone point was saved wherever the player stood when the addon noticed a rebind, not at the inn; a merchant opened before the game loaded its items could be saved as selling nothing; trainers and auction houses ignored the reputation check vendors already had; and some docs and specs had drifted from the code.

## What Changes

- Changing zone or entering an instance withdraws a warning's open question. It is asked again from the new place, or after leaving the instance. Combat withdraws nothing.
- The hearthstone point is learned where the innkeeper asked (CONFIRM_BINDER, matched by area name), at once where the client has HEARTHSTONE_BOUND. A bind the addon did not see is kept by name only, with no guessed position.
- A merchant list with unloaded items never replaces a known vendor's record; it is read again when item data arrives. An unknown vendor is still learned from what could be read.
- Trainers and auctioneers seen as Unfriendly or Hostile by this character are skipped, like vendors; opening their window marks them as trading.
- README (professions are per character, hearth, reputation, withdrawn questions), listing, and stale wording in the status-window, settings-interaction, vendor-trigger and craft-reminders specs.

## Capabilities

### New Capabilities

### Modified Capabilities

- `vendor-trigger`: questions are withdrawn on a zone change or instance entry.
- `instance-awareness`: the hearthstone point comes from the innkeeper's question.
- `vendor-discovery`: partial merchant lists; reputation covers trainers and auctioneers.

## Impact

`Core.lua`, `Controller.lua`, `Triggers.lua`, `Adapter.lua`, tests, README, listing, test plan. No settings or saved data change.
