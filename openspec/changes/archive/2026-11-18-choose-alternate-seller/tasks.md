# Tasks

## 1. Search

- [x] 1.1 Add `Search.Several(bucket, px, py, need, faction, n)` and `Search.SeveralTrainers(...)`: eligible records sorted by distance, nearest record per npcId only, cut to n; verify in `tests/test_search.lua` (order, cap, faction filter, duplicate npcId keeps the nearer, trainer tier rule) and that breaking the dedupe or sort makes a test fail
- [x] 1.2 Keep `Several` linear in the bucket (a kept list of n, no full sort) so the chevron check can reuse it on every refresh; verify with a test that an NPC whose near record comes after its far record still keeps the near one

## 2. Controller

- [x] 2.1 Split `direct()` into `resolve(kind, id, quiet)` returning a query or nil (quiet: no chat or log), plus shared auction and vendor pin tails; verify all existing `tests/test_controller.lua` row-click tests pass unchanged and that a quiet resolve says nothing
- [x] 2.2 Add `self.Choices(kind, id)`: default pick first and marked (honoring `vendorPrefer`), up to three others by distance, one auctioneer only when `ahEnabled`, outside, and the item is not soulbound, labels from `target()`; verify with controller tests for default-on-map, cap of three, auctioneer present/absent/soulbound/instance, instance anchor distances, trainer tier, display-only reagent returns nil
- [x] 2.3 Add `self.ChoiceTitle(kind, id)` (the title when there is more than one entry, else nil) and `self.Pick(kind, id, entry)`: Pick sets the waypoint, prints the vendor or auction-house notice, notifies, and runs `triggers.Take`; verify with controller tests (the picked vendor is pinned and named, the warning counts as handled, auctioneer text) and a mutation check on `Take`
- [x] 2.4 Add the per-kind title strings as whole `L["..."]` sentences in `Locales/Example.lua`; verify `tests/test_locale.lua` passes

## 3. Adapter menu

- [x] 3.1 Add `A.menu(anchor, title, items)` and `A.hasMenu()`: `MenuUtil.CreateContextMenu` when present, else `UIDropDownMenu`, pcall-guarded, false when neither exists; verify in `tests/test_adapter.lua` with fakes for each path (title, checked default, func called on pick) and the neither case

## 4. Status window chevron

- [x] 4.1 In `Tracker.lua` add a non-draggable chevron Button per row (arrow texture, ">" fallback), shown when `env.choiceTitle(row)` returns a title, with width accounting and that title as the tooltip; verify in `tests/test_tracker.lua`: shown/hidden, the window widens by the chevron width, no fill texture, inherits the row alpha
- [x] 4.2 Chevron `OnClick` calls `env.choose(row, chevron)` and does nothing while moving, during a move transaction, or on Shift with an unlocked window; verify with tracker tests that a chevron click does not call `env.go`, and the guard cases
- [x] 4.3 Wire it in `Core.lua`: `choiceTitle` (nil when `A.hasMenu()` is false), and `choose` builds the menu from `controller.Choices` and calls `controller.Pick` on selection; verify an end-to-end test in `tests/test_core.lua` (click chevron, pick the second entry, waypoint and chat line) and a no-menu-control test where no chevron is shown and the row click still routes

## 5. Docs

- [x] 5.1 README: the status window section explains the chevron and the "Good to know" limit (straight-line order, known sellers only); `docs/listing.md` gets one line; verify `tests/test_readme.lua` passes
- [x] 5.2 `docs/test-plan.md` §30 Other sellers: chevron at the 130px minimum width with a low row, tooltip, menu on both clients (MenuUtil and UIDropDownMenu), pick an alternative, Escape, locked and unlocked drag, Shift on unlocked, faction filtering, auction house on, trainer row, and a row with no alternative; decide whether the right-click fallback is needed; verify section numbers stay unique and in order

## 6. Integration

- [x] 6.1 Run `make test` and `make check`; verify both pass

## Workflow follow-up

- In-game review of §30. If the chevron looks wrong, change the change to right-click on the row before archiving.
- Archive with a 1.9.0 bump and CHANGELOG entry, together with `trim-about-page`.
