## Context

See proposal.md - Why. `Triggers` holds one open-or-active request (`active`, `activeReagent`), a `handled` latch per condition and `coveredSell`. `Controller` asks or pins for it, and `asking` records the warning question that may still be open, so `OnPlaceChange` can withdraw it. A row click or seller choice goes through `pinTarget` or `pinAuction`. Both close any question (`cancelPrompt`), pin, then call `triggers.Take`. `release` (after No) schedules `self.Evaluate()` through `env.after`. Core's own `evaluate()` wraps `controller.Evaluate()` and arms the position retry timer when `pending` is set.

## Goals / Non-Goals

**Goals:** fix the five #39 faults with the rule chosen for clicks: a closed warning comes back after the clicked trip, or at the next check when the click took nothing.

**Non-Goals:** group 3 and 4 faults (#40, #41); any change to what is asked when the player does not click.

## Decisions

### A click re-arms what it replaces, and its own trip is kept
- `Triggers.Take(kind, id)`: before taking, re-arm the request it replaces. A reagent clears `handledReagent[activeReagent]`, others set `handled[active] = false`, and `coveredSell` gives selling back. This is the same thing `Update` already does when a higher request replaces a lower one. A taken repair or ammo trip then covers selling, as an asked one does ("Trips that cover selling"). Then set a new `taken` flag.
- `Triggers.Update`: `if active and (taken or PRIORITY[want] <= PRIORITY[active]) then return nil end`. A clicked trip is never replaced. `taken` is cleared everywhere `active` is cleared or set by `Update` (clear, Release, OnMerchantShow, go).
- Controller, when `Take` returns false (the clicked need is not low, or a trainer, which never takes): if a warning request is open or active (`triggers.Active()` now also returns the reagent id), call `triggers.Release(act, actId, true)`. The click already closed its question or replaced its pin, so the request is asked again at the next check instead of blocking.
- One helper, `handOver(takeKind, takeId, demo)`, used by `pinTarget` and `pinAuction`, keeps the rule in one place.
- Alternative considered: keep `Take` as is and re-ask at once. The player just chose a route, and an immediate higher question would replace it. That is why the decision was "after the trip".

### Retry after No goes through Core
Core passes `evaluate = evaluate` in the controller env. `release` schedules `env.evaluate or self.Evaluate`, so a pending request arms the poll timer like any other.

### Trainer questions are tracked
`offer` records `asking` for `kind == "trainer"` as well as for warnings. `OnPlaceChange` then withdraws it; its `Release("trainer")` is a no-op because trainers have no latch, and the next skill change or craft asks again.

### Selling coverage survives a replaced trip
In `Update`, where a higher request replaces the active one, restore `handled.sell = false` when `coveredSell` was set, before computing the new `coveredSell`. Then the new repair trip covers selling again, and a later No gives it back.

### A request follows its weapon or pet
The controller remembers what each placed ammo or pet food request was for: `placedFor.ammo = ammoKind`, `placedFor.pet = dietList(diets)`. At the start of `Evaluate`, after reading the new state, it checks whether `triggers.Active()` is `ammo` (or `pet`) and the remembered value differs from the current one. If so, it closes the question if `asking` is that request, clears that waypoint (`clearVendorNav("ammo")`, `clearVendorNav("supply", "pet")`) and calls `triggers.Release(trigger, nil, true)`. The same `Evaluate` then asks again for the new kind or diet when it is low. No weapon, or no pet, still ends the request the usual way (its condition clears).

## Risks / Trade-offs

- [A clicked trip blocks a real higher need, such as repair, until the trip ends] → This is the chosen rule. The trip ends at the next merchant or when its need clears. The status window still shows the higher row, and the player can click it.
- [A click on a row that is not low re-asks the warning at once] → Accepted in the decision. The next check comes with the next bag, gear or zone event, not on a timer.
- [Diet comparison by the label string] → `dietList` is built in table order from the diet set, so equal sets give equal strings.
