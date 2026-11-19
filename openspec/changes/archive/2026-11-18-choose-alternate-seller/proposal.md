# Proposal

## Why

Clicking a status row always routes to one seller, picked by distance and the map preference. When that seller is the wrong one (an outpost the player does not want to go to, a city across water, a vendor they dislike), there is no way to pick another without leaving the addon. The notice already names a second choice ("The other choice was ..."), so players know other sellers exist but cannot pick them. GitHub issue #35.

## What Changes

- Each routable status row with more than one known eligible seller gets a small chevron at its right edge. Its tooltip names the action, e.g. "Other repair vendors".
- Clicking the chevron opens the game's own menu anchored to it. The menu lists the seller a row click would pick (marked), then up to three other eligible sellers by straight-line distance, each with name, zone and distance.
- Choosing an entry pins that seller the same way a row click does: waypoint, chat line, notification, and the warning counts as handled. Escape or clicking elsewhere closes the menu and changes nothing.
- All routable rows take part: repair (durability), ammo, food, water, pet food, class reagents, profession trainers and sell (bag space). Display-only rows get no chevron.
- With the auction house setting on and outside an instance, the nearest auctioneer may fill one entry for ammo and tradeable reagents, as the row click already allows.
- One NPC listed in more than one place counts once (its nearest record).
- The row click itself is unchanged.
- Fallback noted for in-game review: if the chevron looks wrong at the narrow window width, right-click on the row opens the same menu instead and the chevron is removed.

## Capabilities

### New Capabilities
- `seller-choice`: the list of other eligible sellers for a need and how the player picks one from the status window. Supply search (#34) is expected to reuse it.

### Modified Capabilities
None. The row-click requirement in `status-window` and the auction rules in `auction-routing` keep their current behavior; the new capability refers to them.

## Impact

- `Search.lua`: a several-nearest search for vendors and trainers, with duplicate NPCs removed, kept linear so the status window can ask it on each refresh.
- `Controller.lua`: the part of `direct()` that resolves what to look for and where to start becomes shared, so the row click and the chooser agree; a new entry point lists choices and another pins a chosen one.
- `Tracker.lua`: a chevron button per row, its tooltip, width accounting, and click guards (move mode, Shift on an unlocked window).
- `Adapter.lua`: one menu call that uses `MenuUtil.CreateContextMenu` when present and `UIDropDownMenu` otherwise, guarded in pcall.
- `Core.lua`: wires the tracker to the controller's choice list.
- Locale strings, tests (search, controller, tracker, adapter, core), README, `docs/listing.md`, `docs/test-plan.md` new section.
- Minor version bump at archive (1.9.0). No saved-settings change.
