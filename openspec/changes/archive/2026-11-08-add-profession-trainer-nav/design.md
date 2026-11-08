## Context

Triggers today are bag, durability and ammo. Each is a condition with a latch: ask once, ask again only after the condition clears. All game reads live in `Adapter.lua`; logic modules are plain Lua tested under luajit. Vendor data is shipped (pfQuest) plus learned on merchant windows. No source we can license has trainer locations, so trainers are learned only.

## Goals / Non-Goals

**Goals:** ask when a profession is near its current tier cap; navigate to the closest known trainer for it; learn trainers from trainer windows; keep the existing "one question at a time, higher priority wins" behavior.

**Non-Goals (v1):** shipped trainer data; player-level requirement checks; `/cvn test` for trainers; class trainers; weapon skills; per-profession thresholds.

## Decisions

**1. Which skill lines are professions.** Read from Blizzard UI source (branches `forever`, `classic_era`), the clients differ:
- Forever: `C_SkillInfo.GetSkillLineInfo(index)` returns a table with `skillID`, `name`, `isHeader`, `rank`, `maxRank`, `parentSkillLineID`, `skillLineCategoryID`; `C_SkillInfo.GetNumSkillLines()` counts them. Weapon skills have fixed skill IDs and the class category is `7`; the profession category ids are not in the shipped source.
- Era: only the old global `GetSkillLineInfo(index)` exists (returns name, header, isExpanded, rank, tempPoints, modifier, maxRank, ... , minLevel); the Era documentation stubs list no `C_SkillInfo` functions. No skill id.
- Neither source exposes a language-free "is profession" flag we can rely on in both clients.

So a skill line counts as a profession only if the addon has seen its name in a profession context: a trainer window that teaches it (`GetTrainerServiceSkillLine`), or an open tradeskill or craft window for it. The name is the key, taken from the same API in the same game language. This needs no profession list, never mistakes a weapon skill for a profession, and works the same on both clients. Cost: the "no known trainer" notice can only appear for professions the addon has seen in a crafting window, and gathering professions learned before the addon was installed stay silent until their trainer is opened once. The Forever category ids are a possible later improvement.

**2. Cap and final tier.** Remaining = `maxRank - rank` from the skill line (both clients). Neither client says whether a higher tier exists. v1 rule: no higher tier when `maxRank >= 300`. If Forever goes above 300 the rule is wrong only in that the top-tier question is useless; a question is never missed below it. Era's `minLevel` (the level a skill step needs) is returned by `GetSkillLineInfo`, so level gating is possible later but is out of scope for v1.

**3. Events.**
- Skill change: `SKILL_LINES_CHANGED` exists on both clients (documented in `C_SkillInfo`). The addon compares ranks with the last known ones; the first read after login only stores ranks and asks nothing.
- Craft: `UNIT_SPELLCAST_SUCCEEDED` for `player` while a tradeskill window is open. The window is detected at cast time, not by events: Era has no documented open/close event for the craft window (Enchanting uses `CraftFrame`, other professions `TradeSkillFrame`; frame shown state is what the Blizzard code itself relies on). The profession name comes from the window: `GetTradeSkillLine()` or `GetCraftDisplaySkillLine()` on Era, `C_TradeSkillUI.GetBaseProfessionInfo().professionName` on Forever.
- Forever also documents `TRADE_SKILL_CRAFT_BEGIN` (recipe spell id) and `TRADE_SKILL_ITEM_CRAFTED_RESULT`, which Era does not have. They are not used in v1, because one event path for both clients is simpler and a wrong guess about when they fire would cost more than it saves.
- Trainer: `TRAINER_SHOW` on both clients, `TRAINER_UPDATE` when services load late. `IsTradeskillTrainer()` is a global on both; Forever additionally has `C_Trainer.GetTrainerType()` with `Enum.TrainerType.Tradeskills`. The profession a trainer teaches is `GetTrainerServiceSkillLine(index)` for `index` in `1..GetNumTrainerServices()`.

**4. Re-ask without a latch.** The Controller keeps its latch for vendor kinds. Trainer requests skip the latch but obey: no stacking (a same-profession question already open stays, no flicker), a higher-priority open or active request wins, a lower one never replaces, and an active trainer waypoint for the profession suppresses new questions. Combat suppresses the question but not the check, so the next event after combat asks.

**5. Request carries the profession.** The request kind becomes `trainer` with a profession key, the skill line name as the game reports it. Skill lines, tradeskill windows and trainers all give that name in the same game language, so the keys match. A player who changes game language starts with no matching trainers; that is accepted for v1 and noted in the README.

**6. Trainer records live in their own table.** Not the vendor shape: `learnedTrainers[npcId] = { npcId, name, uiMapID, mx, my, faction, trades = { [key] = true } }`, with world coordinates added at load like vendors. `Search.Nearest` gains a trainer lookup over that table. A trainer that is also a merchant is two independent records (one per table), which keeps shipped-vendor merging untouched and avoids a format change in saved vendor data.

**7. Merchant window no longer clears a trainer pin.** `OnMerchantShow` clears only vendor-kind requests. A trainer window (for the active profession) clears the trainer pin and any open trainer question.

**8. No known trainer.** Checked before asking. One chat line per profession per session explaining that trainers are learned by visiting them; no dialog.

**9. Settings.** Two new saved settings: `tradeThreshold` (default 10, limits 0 to 300) and `tradeEnabled` (default true). Same command parser, same options-page pattern, `/cvn` report line, README and listing updated. The limits are asserted against the README by the existing doc test.

## Risks / Trade-offs

- [Two skill-line APIs] -> the Adapter hides the difference (table on Forever, multiple returns on Era); either missing returns nil, so the feature goes quiet instead of erroring.
- [Questions on every craft can annoy] -> requested behavior; mitigated by "no stacking", combat suppression and the on/off switch.
- [Cap above 300 on Forever] -> costs only a useless question at the top tier; recorded in the test plan.
- [Learned-only data means an empty start] -> chat notice says how to fill it; shipped data is a later change.
- [Level requirements] -> a trainer may refuse a character who is too low; out of scope, noted in the README.

## Migration Plan

Additive: new saved-variable table created on first use; no existing data changes. Bump the minor version at archive.

## Open Questions

- Does `UNIT_SPELLCAST_SUCCEEDED` fire once per craft on Forever when crafting through its profession window (and per item in a Craft All)? Does a trainer window have its services loaded by `TRAINER_SHOW`, or only after `TRAINER_UPDATE`? Both settle in game; the code reads trainer data on both events to cover either answer.
- Are there profession tiers above 300 on Forever?
