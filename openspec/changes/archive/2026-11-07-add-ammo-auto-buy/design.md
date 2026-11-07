# Design

## Context

The addon only reads the game and navigates. `Triggers.AmmoNeeded` already maps weapon to kind; `Adapter.ammoStatus` reads the equipped ammo; `Controller.OnMerchantShow` runs on merchant open. All game calls live in `Adapter.lua`; logic is pure Lua under `luajit tests/run.lua`.

## Goals / Non-Goals

**Goals:**
- Fill matching quiver/pouch at the merchant with no clicks by default.
- Per-kind grade mode; optional confirm.

**Non-Goals:**
- Filling general bags, comparing ammo DPS, per-item allow lists, buying other goods.

## Decisions

- **New pure module `Ammo.lua`** (after `Triggers.lua` in both TOCs): `Ammo.ToBuy(capacity, have)`, `Ammo.Pick(mode, offers, equippedID, level)`, `Ammo.Plan(...)` clamping to gold and stack limits. Keeps the Adapter thin and the logic testable. Alternative (put in `Triggers.lua`) rejected: that file is about deciding *when* to navigate.
- **Capacity** = sum over bags whose family matches the kind of `GetContainerNumSlots` times the item's stack size. Have = count of that ammo across bags plus the ammo slot. Capacity unknown -> nil -> no purchase.
- **Grade "best usable"** uses item required level from the item info as the proxy; the API does not expose ammo DPS. Ties broken by cheaper price. Known limitation.
- **Settings** `ammoBuyEnabled` (true), `ammoBuyPrompt` (false), `arrowGrade` and `bulletGrade` ("equipped"|"best"|"cheapest", default "equipped"). Options page gets a checkbox, a checkbox and two dropdowns; slash command mirrors them, as the existing settings do.
- **Prompt** reuses the existing confirm-dialog pattern with `L[...]` text.
- **Purchase** is `Adapter.buy(index, count)` wrapping `BuyMerchantItem` in `pcall`; it is not a protected call so it can run from `MERCHANT_SHOW`.
- **Interaction with ammo trigger:** unchanged. Buying raises the count, so the trigger condition clears and its waypoint is already cleared on merchant open.

- **Implemented purchase shape:** one `BuyMerchantItem(index)` call per purchase (one vendor batch), repeated N times, so the quantity-argument semantics never matter. Whole batches only: a top-up smaller than one batch buys nothing. Room is counted slot by slot (empty slot = a stack, same item tops up, other ammo blocks), so quivers holding another grade are not over-counted. The stack in the ammo slot is ignored.

## Risks / Trade-offs

- `BuyMerchantItem` quantity and vendor batch semantics on this client are unverified; task 1 confirms them before relying on them. The purchase loop must never exceed the computed need.
- The merchant list may not be loaded at the instant of `MERCHANT_SHOW`; if so, read it on first `MERCHANT_UPDATE` instead.
- Auto-spending gold: mitigated by capping at capacity, affordability, one chat line per purchase, and the on/off and ask-first settings.
