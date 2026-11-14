# Proposal

## Why

Buying ammo and reagents needs an item's stack size. The game may not have that item's data loaded when a merchant opens, so the read returns nothing, the addon treats the size as unknown and offers nothing, and it never tries again for that visit.

## What Changes

- When ammo or reagent buying stops because item data is not loaded yet, and it asked and bought nothing, it runs again when the game reports the data (`GET_ITEM_INFO_RECEIVED`), up to three times per visit.
- Closing the merchant window drops the pending retry.
- The event is handled before logging, because it fires for every item the game loads.

## Capabilities

### Modified Capabilities
- `ammo-purchase`: adds the retry requirement (it covers reagent buying at the same merchant).

## Impact

`Adapter.lua` (notes an unloaded item), `Core.lua` (retry on the event, `MERCHANT_CLOSED`), tests, CHANGELOG. No setting or text changes.
