# Design

## Context

See proposal.md for why. Today a row click runs `Tracker` row `OnClick` -> `env.go(row)` (Core) -> `controller.Go(kind, id)` -> `direct()` in `Controller.lua`. `direct()` does four things in one function:

1. Resolve what to look for: ammo type from the equipped weapon, the reagent item, supply bits from the diet, or the trainer tier from `Professions.Within`. It returns false (sometimes with a chat line) when there is nothing to route.
2. Pick the search start: the player, or in an instance the hearthstone or last outside position (`anchorFor`).
3. Search: `Search.NearestFrom` / `NearestTrainer` return one winner plus the nearest on the player's map; an auctioneer competes for ammo and tradeable reagents when `ahEnabled` and outside.
4. Pin via `autoPin`, which chooses between the overall nearest and the on-map one by `vendorPrefer`, says why, notifies, and `triggers.Take`.

The chooser needs steps 1-3 without chat output and with several results, and step 4 with a forced pick.

Menu controls differ by client. A Forever reference addon (`shared-addon-resources/ref-addons/DFLPJ/DFLProfessionJournal/UI.lua:59-93`, interface 16001) tries `MenuUtil.CreateContextMenu` and falls back to `UIDropDownMenu_Initialize` + `ToggleDropDownMenu`. Baganator uses `MenuUtil`.

## Goals / Non-Goals

**Goals:**
- The row click and the chooser can never disagree about eligibility, search start or the default pick: they share one resolve step.
- The chevron's visibility check is cheap enough to run on every window refresh.
- Search, controller and tracker logic stay testable under `luajit tests/run.lua`.

**Non-Goals:**
- Travel distance or flight paths (#23); order stays straight-line.
- Right-click on the row. It is the noted fallback if the chevron fails in-game review, not built here.
- Supply search (#34); it will reuse `Controller.Choices` later.

## Decisions

### Split `direct()` into resolve + pin
A local `resolve(kind, id, quiet)` returns a query `{ find, need, item, name, trade, supplyBits, at, which, inside, ahOk }` or nil. Without `quiet` it logs and says exactly what `direct()` says today; with `quiet` (the chooser and the chevron check) it is silent. The auction and vendor pin tails become shared locals used by `direct()` and `Pick`.
*Alternative:* reason codes mapped to chat lines. Rejected: more code for the same result.
*Alternative:* copy the resolve logic into a new function. Rejected: the two would drift, and the spec requires that they agree.

### `Search.Several` and `Search.SeveralTrainers`
`Several(bucket, px, py, need, faction, n)` returns up to n eligible records sorted by squared distance, keeping only the nearest record per npcId (index 1). Implementation: one pass that keeps the best record per npcId in a table, then sort and cut to n. The trainer version applies the same `NearestTrainer` test (trade and tier). The existing `Nearest` / `NearestTrainer` stay as they are for the hot automatic path.
*Alternative:* call `Nearest` repeatedly while excluding winners. Rejected: n passes, and exclusion still needs a set.

### Chevron check reuses `Choices`
The chevron needs only "is there a second entry". `ChoiceTitle` runs `Choices` and returns its title when there are two or more entries. `Several` keeps a list of n (O(N*n), no full sort), which is cheap enough for every window refresh (throttled by `WINDOW_DELAY` in Core). A separate early-exit scan was considered and dropped as extra code for little gain.

### Controller API
- `self.Choices(kind, id)` returns `{ title, entries = { { v, label, default, auction } } }` or nil. Order: the default pick (what `autoPin` would choose: on-map vs nearest by `vendorPrefer`), then the others by distance, capped at default + 3. The single auctioneer is merged by distance. Labels use the existing `target()` text "Name (Zone, N yards)".
- `self.ChoiceTitle(kind, id)` returns the title when there are two or more entries, else nil.
- `self.Pick(kind, id, entry)` pins `entry.v`. It reuses `autoPin`'s notice text with the pick forced. For an auctioneer it reuses the "at the auction house" text. Then `triggers.Take` as `direct()` does. It uses the shared pin tails, so `direct()` and `Pick` do not repeat them.

The record goes into the menu closure. If the player moves between opening and picking, the pinned record is still correct, and the notice measures distance from the current position.

### Tracker chevron
- One child `Button` per row, 14px wide, anchored `RIGHT` inside the row and full row height. Texture: Blizzard's arrow (`Interface\\ChatFrame\\ChatFrameExpandArrow`), with a ">" FontString fallback when the texture is missing. This is the same pattern as the cog.
- It is not draggable (no `RegisterForDrag`), so a press on it cannot start a move.
- `OnClick`: do nothing if moving, if a move transaction is active, or on Shift with an unlocked window. Otherwise call `env.choose(row, chevron)`. The chevron is its own button and so takes the click; the row's `OnClick` never fires.
- `OnEnter` / `OnLeave` show a GameTooltip with the row's title string.
- `draw()` asks `env.choiceTitle(row)` for each routable row (not during a demo) and shows or hides the chevron; the title is also the tooltip. When shown, width accounting adds the chevron width so the text never runs under it.
- Alpha: the chevron is a child of the row, so the row's `SetAlpha(textAlpha)` already applies. No background texture.

### Adapter menu
`A.menu(anchor, title, items)`, where items are `{ text, checked, func }`. It uses `MenuUtil.CreateContextMenu(anchor, ...)` with a title plus `CreateRadio`/`CreateButton` when `MenuUtil` exists. Otherwise one named `UIDropDownMenuTemplate` frame with `UIDropDownMenu_Initialize` and `ToggleDropDownMenu(1, nil, frame, anchor, 0, 0)`. It returns false when neither exists. `A.hasMenu()` tells Core whether to offer chevrons at all. Both controls already close on Escape and on a click elsewhere.

### Titles
One locale string per kind, the whole sentence: "Other repair vendors", "Other ammo vendors", "Other food vendors", "Other water vendors", "Other pet food vendors", "Other sellers of %s" (reagent), "Other %s trainers", "Other vendors to sell to".

## Risks / Trade-offs

- [The chevron crowds the 130px window or looks wrong] -> in-game test-plan check at minimum width with a low row. The fallback is right-click on the row: the chevron goes and the same `env.choose` is called from the row's right button.
- [`MenuUtil` behaves differently on the Forever client] -> the Adapter tries `MenuUtil` and falls back to `UIDropDownMenu`, both in pcall. The test plan checks both clients.
- [`ChatFrameExpandArrow` is missing on a client] -> the ">" text fallback, checked like the cog texture.
- [Visibility reads the bags (ammo type, pet diet) on each refresh] -> the same readers the rows already use in that refresh, so no extra game calls of a new kind. `Several` stays linear.
- [Refactoring `direct()` changes what a row click says] -> the existing controller tests for every `direct()` chat line stay and must pass unchanged. A mutation check runs on the reason-code mapping.

## Migration Plan

No saved data change. Ships as 1.9.0, together with the staged About-page trim if it is still pending.
