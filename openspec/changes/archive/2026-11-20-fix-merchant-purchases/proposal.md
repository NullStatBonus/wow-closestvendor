## Why

A bug review found four faults in what happens when a merchant window opens. They are fixed together because one short in-game check (visit a few merchants) covers all of them. The other bugs from the review ship as later patch releases, grouped the same way so each test pass stays short:

1. **Merchant purchases (this change)**
2. Warning flow: a row click or a No that loses or blocks a warning, a trainer question kept across a zone change, the bag-space warning lost after a replaced request, a pet or weapon change keeping the old request.
3. Places and waypoints: hearthstone rebind at the same inn, the seller chooser after a weapon change, an unlearned profession's waypoint, the demo and the player's own waypoint, a timer failure that stops window redraws.
4. Small items: settings tabs by command, translated reagent names in commands, NorgannonDB trainer standing, auctioneer distance rounding, waypoint ownership tolerance.

## What Changes

- **Fixed: a purchase answered later never buys more than is still needed.** Today the ammo and reagent questions fix the amount when they open. If the player buys some by hand before clicking Yes, Yes still buys the full amount, which goes over the reagent amount and spends more gold.
- **Fixed: items paid with gold are read correctly on every client.** The merchant line read takes the "costs more than gold" value by position. On a client that returns the newer, longer list of values, that position holds a different value, and every usable item may be left out of ammo and reagent buying.
- **Fixed: a merchant whose item kinds have not loaded does not overwrite what is known.** Today only a missing item link marks the list as partly read. An item whose kind (arrow, bullet) cannot be read yet still counts as fully read, so a known arrow seller can be saved, for every character, as selling no arrows.
- **Fixed: "best usable" ammo waits for item data.** When an arrow's required level has not loaded, the purchase skips it and never tries again when the data arrives.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ammo-purchase`: a later Yes re-reads the room and money; "best usable" retries when an item's required level was not loaded.
- `class-reagents`: a later Yes re-reads what is carried, the bags and money.
- `vendor-discovery`: an item whose kind cannot be read makes the merchant list partly read.

## Impact

- `ClosestVendor/Ammo.lua`, `ClosestVendor/Reagents.lua`: re-plan on Yes.
- `ClosestVendor/Adapter.lua`: merchant line read, merchant scan, ammo offers.
- Tests: `test_ammo`, `test_reagents`, `test_adapter`, `test_core`.
- `docs/test-plan.md`: one new section. No settings, commands or saved data change. Patch release (1.9.1) at archive.
