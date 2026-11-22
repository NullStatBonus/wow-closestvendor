# Proposal

## Why

Before a trip a player wants to know where to buy one supply, such as Moonberry Juice, without waiting for a low-supply warning. Today the addon only routes from a warning or a status-row click. Issue #34 asks for a one-time search by item.

## What Changes

- **New:** `/cvn find <item link or name>` finds known sellers of a supply or class reagent.
- **New:** a **Find supplies** input at the bottom of Home runs the same lookup.
- Match by item id. An item link gives its id; a typed name matches the game's own item names, case-insensitive and partial.
- Four outcomes, each with its own chat line: no item matches; too many items match (type more of the name, above 8); the item is recognized but no eligible seller is known; or a seller list.
- One matching item goes straight to the seller list. Several matching items open a menu of icon and name first.
- The seller list is the existing choice list: nearest seller marked, up to three alternatives, with zone and distance. It uses the same eligibility, instance anchor and auctioneer rules as a status-row click.
- Picking a seller sets the waypoint as a row click does. Browsing changes nothing.
- Vendor data is per category for food, drink and pet food (not per item). A supply query therefore finds sellers of that category, and the answer says so. Class reagents are exact. Exact per-item stock is deferred to #56.

## Capabilities

### New Capabilities
- `supply-search`: one-time lookup of known sellers by item name, link or id, and how its outcomes and results are shown.

### Modified Capabilities
- `slash-interface`: adds the `find` command.
- `settings-interaction`: adds the Find supplies input to Home.

## Impact

- `ClosestVendor/Search.lua` or a small new pure module: item-text lookup (candidate ids from `ns.SupplyItems` and the class reagents).
- `ClosestVendor/Controller.lua`: a find entry that builds the query and reuses the choice list and `pinTarget`.
- `ClosestVendor/Commands.lua`: the `find` verb and help line.
- `ClosestVendor/Options.lua`: the Home input.
- `ClosestVendor/Adapter.lua`: item name and icon by id, and a menu at the cursor, guarded as other game calls are.
- `ClosestVendor/Locales`, both TOCs only if a new file is added.
- Docs: `README.md`, `docs/listing.md`, `docs/test-plan.md`. No new saved setting, so no debug-report line.
- Out of scope: exact per-item stock (#56), tracking thresholds, automatic buying, ammo and repair lookup.
