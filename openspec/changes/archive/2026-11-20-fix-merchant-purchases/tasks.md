# Tasks

## 1. A later Yes buys only what is still needed

- [x] 1.1 `Ammo.OnMerchant`: in `buy()`, after the slot check, read `env.space` and `env.money` again, run `M.Plan`, buy `min(new, asked)` purchases; nothing left logs "nothing left to buy" and prints no "Bought" line. The chat line reports the bought amount and cost.
- [x] 1.2 `Reagents.OnMerchant`: in `buy()`, read `env.watched`, `env.slots`, `env.money` again, run `R.BuyPlan`, match lines to the asked plan by item id and take the minimum purchases; skip reagents not in the asked plan; nothing left prints no "Bought" line. The chat line lists what was bought.
- [x] 1.3 Tests in `test_ammo` and `test_reagents`: bought by hand before Yes (partial top-up), already full or stocked at Yes (nothing bought, no line), money gained before Yes never raises the spend above the asked price, buying at once unchanged. Break each new branch to see its test fail.

## 2. Extended cost by return count

- [x] 2.1 `Adapter.merchantItem`: pack the `GetMerchantItemInfo` returns with `select("#", ...)`; take extended cost from value 8 when there are 8 or more values, else value 7.
- [x] 2.2 `test_adapter`: an 8-value mock (`isPurchasable`, `isUsable` true, `extendedCost` false) keeps the item; an 8-value mock with `extendedCost` true leaves it out; the existing 7-value tests still pass.

## 3. Unread item kind is partial

- [x] 3.1 `Adapter.merchantScan`: an item with a link whose class cannot be read sets `partial` (the merchant list is read again on any item arrival, so the id need not be marked).
- [x] 3.2 Tests in `test_adapter` (partial flag) and `test_core` (a known arrow vendor keeps its arrow flag, and is updated after `GET_ITEM_INFO_RECEIVED`).

## 4. Unknown required level waits for data

- [x] 4.1 `Adapter.merchantAmmo`: a non-number `minLevel` marks the id not loaded.
- [x] 4.2 `Ammo.OnMerchant`: mode "best", no pick and an offer of the kind with no `minLevel`: log "item data not loaded", print nothing, return 0.
- [x] 4.3 Tests in `test_ammo` (no chat line, returns 0) and `test_core` (the purchase runs once after the item arrives).

## 5. Docs and checks

- [x] 5.1 `docs/test-plan.md`: add "## 31. Merchant purchases" with these checks:
  - With ammo buying on and "ask first" on, open an arrow vendor. Before Yes, buy some arrows by hand. Click Yes: it buys only the room left, and chat names that amount.
  - Repeat until the quiver is full before Yes: nothing is bought, no "Bought" line.
  - Same two checks for reagents (amount 20, asking on).
  - With asking off, on Classic Era and on WoW Forever, open an arrow vendor and a reagent vendor: the purchase happens as before (proves usable items are no longer left out).
  - "Best usable" right after a fresh login at an arrow vendor: one purchase, no "does not sell" line first. Hard to cause, fine to skip.
- [x] 5.2 `make test` and `make check` pass; `openspec validate fix-merchant-purchases --strict` passes.
