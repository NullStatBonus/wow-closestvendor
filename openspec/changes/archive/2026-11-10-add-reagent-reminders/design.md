# Design

## Context

See proposal.md. Today `Triggers.New` knows sell, ammo and repair; ammo is one count compared with `ammoThreshold`; vendors are `{npcId, name, map, mx, my, faction, repair, ammo}` on disk, with world `wx, wy` appended in memory at indices 9 and 10; a learned record replaces a shipped one with the same id. Trainers are a separate learned store.

## Goals / Non-Goals

**Goals:**
- Watch each class's reagents, ask for the nearest seller, let the player switch single reagents off.
- One master switch with ammo; two separate quantity scales.
- Reuse the question, the two-target choice, auto mode and the notice unchanged.

**Non-Goals:**
- Auto-buying reagents (needs a fill-to quantity per reagent; a follow-up).
- Warlock shards, rogue poisons, hunter and warrior items, bank or mail contents.
- A per-reagent threshold.

## Decisions

**Data table in a pure module.** `Reagents.lua` holds, per class token (`MAGE`, `ROGUE`, `PRIEST`, `PALADIN`, `SHAMAN`, `DRUID`), a list of `{ id = itemId, name = "Arcane Powder", spells = { spellIds }, rank = n? }`, plus pure functions: `Reagents.ForClass(class)`, `Reagents.Watched(class, knowsSpell, off)` (spell known and not switched off), `Reagents.Low(watched, count, threshold)` and `Reagents.Find(class, text)` for commands. No game globals, tested under luajit. The English `name` is the command key and the fallback label; the question names the item with the game's own item name when the client has it cached, else the English name.

**Candidate items** (item ids checked against the shipped pfQuest sold-by lists, which gave sellers for all but two): Arcane Powder 17020, Rune of Teleportation 17031, Rune of Portals 17032, Flash Powder 5140, Holy Candle 17028, Sacred Candle 17029, Symbol of Kings 21177, Symbol of Divinity 17033, Ankh 17030, druid seeds 17034 to 17038, Wild Thornroot 17026. Blinding Powder 5530 and Flintweed Seed 22147 show no seller in the data: the first is dropped unless a seller is found, the second is a later-era item and is not included. Spell ids per reagent were confirmed against wago's `SpellReagents` and `SpellName` tables for both Classic Era (1.15.9) and WoW Forever (1.60.1): each listed spell consumes its reagent, and the data is identical for these items on both clients. Whether `IsPlayerSpell` reports lower ranks as known after a higher rank is learned still needs a real client (test plan section 12).

**Spell gating, highest rank only.** `Adapter.knowsSpell(id)` wraps `IsPlayerSpell` (fallback `IsSpellKnown`) in the usual guard; unknown (nil) means "do not watch", not "watch". A reagent with `rank` is watched only when its rank is the highest known among that spell's ranks (Rebirth seeds, priest candles, paladin symbols where ranks differ), so a high-level druid is not nagged for the rank 1 seed.

**Counts.** `Adapter.itemCount(id)` already exists for ammo (bags included). A nil count (bags unreadable) is not low. Reagents in the bank are not counted.

**Settings keys.** `ammoEnabled` stays the master switch (renamed in the UI only), so no saved-data migration. New: `reagentThreshold` (default 5, limits 1 to 40 in `Commands.LIMITS.reagent`) and `reagentOff = {}` set of item ids. A reagent is on unless its id is in `reagentOff`, so later additions default on.

**Trigger.** `Triggers.Update` gets a fifth argument: the sorted list of low reagent item ids (the controller computes it from `Reagents` and the adapter, already filtered by the master switch, spell gating and `reagentOff`). Reagent becomes a kind with priority between ammo and sell (`sell 1, reagent 2, ammo 3, repair 4`; order repair, ammo, reagent, sell). Handling is per item: a set `handledReagent[id]`, cleared when that id is no longer low, so one question per reagent and no repeat until it recovers. The `go` action carries the id: `{ "go", "reagent", id }`. A repair or ammo trip still covers selling; a reagent trip does not.

**Search.** `Search.Nearest` gets `need = "reagent"` plus the item id through a small bit lookup on the record's reagent mask (runtime index 11), with the same faction rule and the same `onMap` second result, so the two-target question works unchanged.

**Record layout.** On disk the vendor record gains a 9th field, `reagents`, a bitmask over the table's items in a fixed order (stable ids: each reagent has a permanent bit number in the data file, never reused). In memory the bucket build copies it to index 11, keeping `wx, wy` at 9 and 10 so `Search` indexes do not move. `Discovery.Record` stores field 9 and compares it for changes. The shipped learned-wins rule is kept, so the merchant scan must set the bits or opening a shipped reagent vendor would erase them.

**Merchant scan.** `A.merchant()` scans offered item links (as `merchantAmmoCode` does) for ids in the reagent table and returns the mask; `learnMerchant` passes it to `Discovery.Record`. The scan covers every class's reagents, not only the player's, so a vendor learned by a mage is still right for a paladin alt on the same account.

**Build tool.** `tools/build_vendors.py` computes the mask from `parse_item_sellers` for the table's item ids and writes the 9th field; the generated file's header comment and the "reagent with no seller" report are updated. `Data/Vendors.lua` is regenerated, so the shipped file changes in one commit with the generator. The bit order lives in one place both sides read (a small generated or checked-in table, with a test that the two agree).

**Settings page.** The ammo row's label becomes "Ammo and reagents"; a reagent slider follows the ammo slider; below them a heading and one checkbox per class reagent, built at `PLAYER_LOGIN` from `Reagents.ForClass` (the class token is a guarded adapter read; with no class, no list). Each checkbox is bound to `reagentOff[id]` through a custom getter and setter (the Settings API binds a variable to a table key; the off-list is inverted, so a proxy table maps `on` to `not reagentOff[id]`). Slider and checkboxes follow the master switch.

**Commands.** `/cvn reagent <n>` sets the threshold; `/cvn reagent on|off <name>` and `/cvn reagents` act on the off-list; `/cvn test reagent` goes through `Controller.Test("reagent")` and `offer`, like the other tests. `/cvn` shows the threshold and the switched-off names; the report header does too.

**Question text.** One new sentence: "You are low on %s (%d left).\n\nNavigate to the closest vendor that sells it, %s?" plus the two-target variants, all as whole `L[...]` sentences, with the reagent name as a `%s`.

## Risks / Trade-offs

- [Wrong spell ids make the feature silent or noisy] → verify early, log the watched list in the debug report, ship only confirmed ids.
- [Reagent vendors are few; the nearest may be a city far away] → same behavior as ammo; the two-target question helps.
- [Learned data can disagree with shipped data] → learned wins, as for ammo.
- [Record shape change touches the data generator and tests] → one new trailing field, existing indexes unchanged, regenerated file reviewed by diff.
- [One reagent threshold for all] → accepted; 5 fits powders, candles, symbols, seeds and Ankhs; a per-reagent number is a possible follow-up.

## Migration Plan

Saved settings need none: new keys fall back to defaults. Learned vendors recorded before this version have no reagent field and read as "none" until the merchant is opened again; shipped data supplies most of them at once. Version 0.5.0 at archive.

## Open Questions

- Whether `IsPlayerSpell` returns true for lower ranks once a higher rank is known (the data uses `unless` lists so either answer works for the seeds and candles; checked in game).
- Resolved: Blinding Powder has no seller in the data and is dropped; Wild Berries (17021) was added for Gift of the Wild rank 1 beside Wild Thornroot.
