## Context

See proposal.md - Why. `Ammo.OnMerchant` and `Reagents.OnMerchant` build a plan when the merchant opens. With asking on, the Yes callback checks only that each planned slot still holds the same item (`env.sells`), then buys the old plan. `Adapter.merchantItem` reads `GetMerchantItemInfo` by fixed positions, and the tests mock a 7-value return. `merchantScan` sets `partial` only for a missing item link. `merchantAmmo` reads `minLevel` from `GetItemInfo` but never marks the item as not loaded.

## Goals / Non-Goals

**Goals:** fix the four faults in the proposal, with no change to settings, saved data or what a player sees when nothing went wrong.

**Non-Goals:** the other review findings (later groups); changing how much is bought when the question is answered at once.

## Decisions

### Re-plan on Yes, capped by the asked plan
On Yes, after the slot check, run the same plan code again with fresh reads (room or bags, carried counts, money), then buy the smaller of the new plan and the asked plan for each item. The chat line reports what was actually bought.
- Why not only re-check counts: the plan already combines room, stock, batches and money. Running it again keeps one rule for "how much".
- Why cap by the asked plan: the player agreed to a price. A later Yes must never spend more than the dialog said, even if money arrived in between.
- `Ammo.OnMerchant`: `buy()` calls `env.space(o.id, kind)` and `env.money()` again and runs `M.Plan`; `n = min(new, asked)`. Nothing to buy: log "nothing left to buy" and return.
- `Reagents.OnMerchant`: `buy()` calls `env.watched()`, `env.slots()`, `env.money()` and runs `R.BuyPlan` again. Each new line is matched to its asked line by item id, and purchases take the minimum. A reagent not in the asked plan is not added.
- Buying at once (no question) keeps today's path: the reads are fresh already.

### Extended cost by return count
Read `GetMerchantItemInfo` into a packed table with its return count. With 8 or more values (`name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, ...`), extended cost is value 8. With 7 values (`..., numAvailable, isUsable, extendedCost`), it is value 7. `C_MerchantFrame.GetItemInfo` stays first when present.
- Why not pick one signature: the review could not confirm which form Classic Era returns. Counting values handles both, and the 7-value tests keep passing. A new test covers the 8-value form.

### Unread kind is partial
In `merchantScan`, an item with a link whose `A.itemClass` returns nil sets `partial = true`. The existing re-read on `GET_ITEM_INFO_RECEIVED` then updates the record.

### Unknown required level is "not loaded"
In `merchantAmmo`, when `minLevel` is not a number, add the id to `uncached`. In `Ammo.OnMerchant`, with mode "best" and no pick, if any offer of the kind has no `minLevel`, log "item data not loaded" and return 0 without the chat line. Nothing was asked or bought, so Core's existing retry runs it again when the item arrives.

## Risks / Trade-offs

- [The re-plan on Yes reads bags just after the player bought by hand, and the server may not have answered yet] → The bags then show less than was bought, so Yes may buy a little too much. This is the same timing the merchant-open plan already has, and buying by hand during an open question is rare. The cap still holds the spend to the dialog's price.
- [Return-count detection could misread a client that adds a trailing nil] → `select("#", ...)` counts trailing nils too, and both known forms end with a non-nil value or have extended cost at a fixed place. Covered by tests for both forms.
