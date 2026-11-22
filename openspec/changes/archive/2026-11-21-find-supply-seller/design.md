# Design

## Context

Vendor records hold categories, not item lists (`Search.lua` header): repair flag, ammo code, a reagent bitmask over `Reagents.ITEMS`, and supply bits (1 food, 2 drink, 4-128 pet diets). `ns.SupplyItems` maps item id to those bits. #35 shipped the choice list, the chevron menu and `pinTarget`; `direct(kind, id)` resolves a query with its anchor, eligibility and auctioneer rule. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:** one lookup shared by `/cvn find` and Home; reuse the choice list and pin path; truthful answers.
**Non-Goals:** per-item stock (#56), ammo or repair lookup, thresholds, buying, any new saved setting or data file.

## Decisions

1. **Resolve item to need, then reuse the existing search.** An item id maps to a need: `{ supply = bit }` or `{ reagent = item }`. A supply item that has the food or drink bit searches that bit only; an item with diet bits only searches those diets (pet food). Alternative, a per-item index, needs data that does not exist (#56).
2. **Candidates are bounded.** Names come only from `ns.SupplyItems` (minus healthstone, bit 256, which no vendor record carries) plus the class reagents via the existing `Reagents.Find`. Text match is a case-insensitive plain substring on `A.itemName(id)`, skipping ids with no name. Link parsing extracts the id first, so matching by id never depends on English text. Reuse the project's accented/Cyrillic case-folding (`Reagents.Lower`).
3. **Pure matching in plain Lua.** The matcher takes text, a candidate id list and a `nameOf` function and returns ids. No game calls, so it runs under `tests/run.lua`. Game reads (name, icon, menu at cursor) go in `Adapter.lua`, guarded and in `pcall`.
4. **Controller entry `Find(text)`** builds the same query record `resolve` builds for a row (start place or instance anchor, need), then calls the existing choice-list builder and `pinTarget` on pick. `Commands.lua` returns `{ "find", text }`; Home's input calls the same entry.
5. **Menu at the cursor** uses the context menu where it exists (`MenuUtil.CreateContextMenu` with the cursor as anchor), else the classic drop-down opened at the cursor, chosen by checking the function exists. Neither: print the nearest seller and pin nothing.
6. **Narrowing limit is 8.** Above it, ask for more text; no scrolling list.
7. **Home input is an AceConfig `input`** (standard edit box), placed in a last section. It stores nothing: its setter runs the lookup and returns.

## Risks / Trade-offs

- [Seller may not stock the exact item] -> the category note in the chat line; exact stock is #56.
- [Uncached item names do not match by text] -> a link always works; accept.
- [Menu over the open AddOns panel] -> manual in-game check in the test plan.
- [Home is meant for feature choices] -> the section is last; the settings-interaction delta records it.
- [Reagent query is class-only] -> assumption: reagents of the player's class, as `Reagents.Find` already does.
