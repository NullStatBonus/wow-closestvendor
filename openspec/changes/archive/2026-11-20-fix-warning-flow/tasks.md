# Tasks

## 1. A click keeps the warning it closes

- [x] 1.1 `Triggers.Take`: re-arm the request it replaces (reagent: clear `handledReagent[activeReagent]`; others: `handled[active] = false`; `coveredSell`: `handled.sell = false`), then set `taken = true`.
- [x] 1.2 `Triggers.Update`: do not replace a request while `taken`; clear `taken` wherever `active` is cleared or set (clear branches, `Release`, `OnMerchantShow`, a new go).
- [x] 1.3 `Triggers.Active` also returns the active reagent id.
- [x] 1.4 `Controller`: a `handOver` helper used by `pinTarget` and `pinAuction`. When `Take` fails or the target is a trainer, and a warning request is open or active, call `triggers.Release(act, actId, true)`. A demo still hands over nothing.
- [x] 1.5 Tests (`test_triggers`, `test_controller`):
  - A low row clicked while a higher question is open: no higher question during the trip, asked after a merchant opens.
  - A row that is not low clicked: the closed warning is asked at the next Evaluate, and lower warnings follow after No.
  - A seller choice behaves the same as a row click.
  - Auto mode: a click replaces an active pinned warning trip.

## 2. Retry after No goes through Core

- [x] 2.1 `Core` passes `evaluate = evaluate` in the controller env; `Controller.release` schedules `env.evaluate or self.Evaluate`.
- [x] 2.2 `test_core`: after No, the next warning finds no position, then a position comes back with no other event; the poll timer runs and the question is asked.

## 3. Trainer questions end with the place

- [x] 3.1 `Controller.offer` records `asking` for an automatic trainer question.
- [x] 3.2 `test_controller`: a trainer question open on zone change is withdrawn, and its late Yes sets no waypoint; `/cvn test` questions are still not withdrawn.

## 4. Selling coverage survives a replaced trip

- [x] 4.1 `Triggers.Update`: when replacing the active request, set `handled.sell = false` if `coveredSell`, before computing the new coverage.
- [x] 4.2 `test_triggers`: full bags and low ammo, repair replaces the ammo question, No to repair, then No to ammo: sell is asked.

## 5. A request follows its weapon or pet

- [x] 5.1 `Controller`: remember `placedFor.ammo` (ammo kind) and `placedFor.pet` (diet label) when the request is placed. In `Evaluate`, when the active request is `ammo` or `pet` and the value changed, close its question if `asking` is that request, clear its waypoint and call `triggers.Release(trigger, nil, true)` before `triggers.Update`.
- [x] 5.2 `test_controller`:
  - Bow to gun with both low: the arrow question or pin ends and the bullet question is asked.
  - Pet with a different diet: the waypoint ends and the new diet's vendor is asked.
  - Same diet: the pin stays.

## 6. Docs and checks

- [x] 6.1 `docs/test-plan.md`: add "## 32. Warning flow" with these checks:
  - Repair question open, click a low reagent or food row. Expected: no repair question during that trip, and repair is asked after the merchant.
  - Repair question open, click a row that is not low. Expected: repair is asked again soon, then No lets the next warning through.
  - Trainer question open, enter a dungeon. Expected: the question closes.
  - Full bags and low ammo, then wear gear down. Expected: after No to repair and No to ammo, the sell question comes.
  - Bow to gun, both ammo low. Expected: the bullet question. Hunter: swap to a pet with another diet. Expected: the new diet's vendor.
- [x] 6.2 `make test` and `make check` pass; `openspec validate fix-warning-flow --strict` passes.
