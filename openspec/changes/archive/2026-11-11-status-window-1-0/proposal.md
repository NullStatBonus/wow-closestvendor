# Proposal

## Why

The addon only speaks up when a condition trips, so a player cannot see how close ammo, reagents, bags or durability are, and cannot act on a number they can see. It also has two blind spots: inside a battleground a full-bags trigger is silently lost, and inside dungeons and raids it has no idea where the nearest useful vendor is. This is the 1.0.0 release: the addon becomes a small always-available tracker you can click, not only a nag.

## What Changes

- **Status window** (new): a small movable window, one line per tracked item (ammo, each class reagent, bag space, durability, each profession, plus display-only items). Visibility is set per row group (ammo, reagents, bag space, durability, professions): `low` (default), `always` or `never`; display-only items follow reagents and show only at `always`. The window shows only when at least one row qualifies; it never shows empty.
- **Click a row**: pins the closest vendor for that item at once, with no question, whatever the choice mode (`ask` or `auto`), and it works in combat. The usual "Navigating to X ... to buy Y." line and on-screen notice say why.
- **Moving**: drag the title, or hold Shift and drag anywhere. A **Lock** checkbox (first control on the Status window settings page) blocks all dragging, Shift-drag included. Position is saved.
- **Appearance, OLED-safe**: background opacity 0-100 (default 80; at 0 nothing is drawn behind the text), text and icon opacity 20-100 (default 100), and a background color (pure black by default) chosen with a swatch that opens the game's color picker where it exists, or `/cvn hud color #rrggbb`. No border or bright fixed fill.
- **Cog button** on the window opens the Closest Vendor settings page (the main page, not a subcategory).
- **Display-only items**: Soul Shards (Warlock), Blinding Powder (Rogue), Conjured Food and Conjured Water (Mage). They are tracked and shown but cannot be routed to, so a click does nothing. All default to `never`.
- **Instance awareness**: detect dungeons, raids and battlegrounds. Triggers wait without consuming their latch, which fixes the battleground bug (a full-bags question is lost for good). Remember the last outdoor position. Learn the hearthstone point from the bind location. A row click inside an instance searches near an anchor: battlegrounds use the last outdoor position; dungeons and raids use a new `instanceAnchor` setting, `hearth` (default, falls back to last position when unknown) or `last`.
- **Auction house routing** (off by default, `ahEnabled`): auctioneers are shipped (pfQuest, 28 with coordinates) and learned. When on, a row click for an item that is not soulbound goes to the auction house if it is closer than the nearest vendor. Ignored inside instances.
- **Settings reorganized** into the main page (warnings and navigation), and three subcategories: Reagents, Ammo, Status window. Existing setting names and values are unchanged; no migration. Falls back to one page when subcategories are unavailable.
- **Hidden demo command** `/cvn demo`: each press rolls a random window setup (random rows, counts and modes, at least one row low) plus one random warning, using the real notice, question and pin paths, for 10 seconds, then restores real state. Not in help, README or listing.
- **Reagent buying** (new, off by default): when a merchant window opens and sells the player's class reagents, buy each reagent the warning watches until the player carries a set amount of it (`reagentBuyTarget`, 0-100, default 20, one number for all; 0 buys none), counting what is already in the bags. Asks first by default (`reagentBuyPrompt`), in its own dialog; limited to the money held, the room in the general bags and the merchant's stock, with one chat line, mirroring ammo buying. Settings at the end of the Reagents page (greyed for a class without vendor reagents) and `/cvn reagentbuy on|off|ask|auto|<0-100>`.
- Shared "is it low" logic: the tests now inline in `Triggers.Update` and `Controller.Evaluate` move into shared functions that the window also calls.
- **Version 1.0.0**, a single release (CLAUDE.md would otherwise give 0.6.0; the user asked for a major revision).

### Out of scope, future feature specs

Recorded here so they are not lost. Each should become its own change:
- Hearthstone cooldown row (a cooldown, not a count).
- Healthstones and mana gems (created by spell; needs per-item spell logic).
- Gold and repair cost.
- Pet food, potions (health and mana), bandages and vendor-bought food and water: routable rows, with AH routing already in place.
- Redesign of the settings layout, if the first one proves cramped.

## Capabilities

### New Capabilities

- `status-window`: the window, rows and their modes, display-only items, moving and lock, cog, row click, demo.
- `instance-awareness`: detecting instances, waiting without consuming the latch, last outdoor position, hearthstone point, anchors and the `instanceAnchor` setting.
- `auction-routing`: auctioneer data, learning, the setting, and when the auction house is chosen.

### Modified Capabilities

- `vendor-trigger`: the Settings panel requirement (layout and new controls).
- `vendor-navigation`: a direct-pin entry that skips the question, and honors combat differently from automatic triggers.
- `class-reagents`: display-only tracked items; per-reagent "show in window" mode separate from the warning checkbox; buying reagents at a merchant (amount, ask first, limits and report, settings and commands).
- `vendor-data`: shipped auctioneer records.
- `vendor-discovery`: learned auctioneers and the hearthstone point.
- `diagnostics`: the report header lists the window, anchor, auction and reagent buying settings.

## Impact

- New pure `ClosestVendor/Status.lua` (rows, modes, visibility) and `ClosestVendor/Tracker.lua` (frame). New Adapter functions: instance type, bind location, shift state, frame helpers, auctioneer NPC. Both TOCs.
- Reagent buying: `Reagents.lua` (`BuyPlan`, `OnMerchant`, pure), new Adapter functions `merchantReagents`, `bagSlots`, `stackSize` and a quantity for `buyMerchantItem` (a bag slot whose read fails is now unknown, not empty, for ammo too), `Ammo.OnMerchant` also returns what it spent, `Core.lua` (defaults, its own dialog, merchant event), `Options.lua`, `Commands.lua`.
- `Triggers.lua` (shared conditions, instance wait), `Controller.lua` (`Go`, pin kinds, anchors), `Search.lua` (anchor, auction need), `Reagents.lua` (display-only items), `Core.lua`, `Options.lua` (subcategories), `Commands.lua`, `Discovery.lua`.
- `tools/build_vendors.py` and `Data/`: auctioneer list.
- Saved settings: new keys `hudRow`, `hudLocked`, `hudScale`, `hudAlpha`, `hudTextAlpha`, `hudColor`, `instanceAnchor`, `ahEnabled`, `reagentBuyEnabled` (default false), `reagentBuyPrompt` (default true), `reagentBuyTarget` (default 20, held to 0-100 at load); `DB.hud` (position), `DB.lastOutside`, `DB.hearth`. Existing settings keep working.
- Tests, README, `docs/listing.md`, `docs/test-plan.md` (the demo command is deliberately undocumented).
- CHANGELOG `## 1.0.0` and a major bump to 1.0.0 at archive.
