# Tasks

## 1. Verify client behavior

- [x] 1.1 Confirm `BuyMerchantItem` quantity vs vendor batch size, `GetMerchantItemMaxStack`, and that the merchant list is readable on `MERCHANT_SHOW`; note findings in design.md

## 2. Pure logic

- [x] 2.1 Add `Ammo.lua` (both TOCs, after `Triggers.lua`): `ToBuy`, `Pick` (equipped/best/cheapest with fallback), `Plan` (gold and batch limits)
- [x] 2.2 Add `tests/test_ammo.lua` covering full, partial, no quiver, unknown data, each grade mode, fallback, short of gold; confirm each fails when the code is broken

## 3. Adapter

- [x] 3.1 Add reads: ammo-family slot counts, stack size, carried count of an item, merchant offers (id, price, quantity, required level), player level and money
- [x] 3.2 Add `Adapter.buy` in `pcall`, returning nil when unavailable

## 4. Wiring and settings

- [x] 4.1 Call the plan from merchant open (`Controller`/`Core`); chat line for result or reason
- [x] 4.2 Add DEFAULTS and slash command support for `ammoBuyEnabled`, `ammoBuyPrompt`, `arrowGrade`, `bulletGrade`
- [x] 4.3 Options page: two checkboxes and two dropdowns; confirm popup for ask-first
- [x] 4.4 Add all strings as whole `L["..."]` sentences; run `make test` and `make check`

## 5. Release

- [x] 5.1 Update README/docs for the new settings; on archive bump both TOCs to 0.2.0 and add CHANGELOG `## 0.2.0`
