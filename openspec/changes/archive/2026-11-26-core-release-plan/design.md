# Design

## Context

See proposal.md, "Why". Facts from the code that shape the approach:

- `Controller.lua` writes `trigger go <kind> (bags=… durability=… ammo=… combat=…)` when a real threshold starts a request. That one line already proves the real bag and durability reads for any class, so no extra readings line is needed.
- `question shown:` is written in `ask` (`Controller.lua`). It has three forms (plain, supply or reagent with a count, trainer with points left) and names only the target and its npc id.
- `Search.Nearest` and `NearestTrainer` compare squared world distances. World x,y are yards. Vendor records keep world x,y at [9],[10] and trainer records at [8],[9].
- Learned places live in `ClosestVendorDB` (`DB.vendors`, `DB.trainers`). NorgannonDB records are merged in `Core.lua`, and shipped data comes from `Data`.
- `Controller.Test(kind)` already backs `/cvn test sell|repair|arrows|bullets|food|water|petfood|reagent|remind`. `Commands.lua` parses those kinds.
- Opening any profession trainer window lets the addon learn that trainer (`learnTrainer` in `Core.lua`), with or without the profession.
- Plan steps can be limited to one client (`clients:`), and each plan's setup and last steps are fixed by the "Plans run under test settings" requirement.

## Goals / Non-Goals

**Goals:**
- A release gate that one ordinary character finishes in about 10 minutes.
- Every step proves one foundation system, with evidence from the log.
- Each player step is a look at something drawn (the map waypoint, the status window).

**Non-Goals:**
- Rewriting the UI and addons plans. They become feature plans as they are. Their wording is revised the next time their feature changes.
- Moving class-specific checks into the offline block now. That is #74, with recorded calls.
- New CheckThat features. NullStatBonus/wow-checkthat#219 tracks the skill guidance and #218 the checklist Expect.

## Decisions

### The core plan's steps

The setup names one character. It runs once per client, and test settings stay on for the whole run. Ids are kept where the behavior is the same. A new step goes at the end of its section.

| Id | Step (player words) | Kind | Proves |
|---|---|---|---|
| cv.s0.1 | Check the version (1.13.0) | auto | clean load |
| cv.s0.2 | Turn on debug logging and test settings, then reload | auto | clean load |
| cv.s1.1 | Forever: make bag space low and click Yes; look at the map | player + log | reads, wiring, search, waypoint |
| cv.s1.2 | Era: make bag space low and click Yes | auto | reads, wiring, search, waypoint (chat) |
| cv.s1.3 | Open that vendor | auto | waypoint cleared, learning |
| cv.s1.4 | Look at the status window | player + log | status window shows the low Bag space row |
| cv.s1.5 | Put bag space back to normal | auto | wiring (`trigger clear sell`, the row leaves) |
| cv.s2.1 | Ask for a repair vendor, click No | auto | search with the capability filter |
| cv.s2.4 | Ask for a food vendor, click No | auto | real read of food items, search |
| cv.s2.5 | Open a profession trainer | auto | trainer learning |
| cv.s2.7 | Ask for a trainer, click No | auto | trainer search names the learned trainer (`learned`, a few yards) |
| cv.s6.1 | Reload the game | auto | learning and persistence (the reload between learning and asking) |
| cv.s6.2 | After the reload, ask for a sell vendor, click No | auto | the learned vendor persists (`learned`, a few yards) |
| cv.s6.3 | Turn test settings off | auto | no Lua errors |

- **Retired:** cv.s2.2, cv.s2.3, cv.s2.6, cv.s3.1, cv.s3.3, cv.s4.1, cv.s4.2, cv.s5.1 and cv.s5.2. They join the `RETIRED` list in `tests/test_plan.lua`. Sections s3, s4 and s5 leave the core plan, and their numbers stay reserved.
- **cv.s6.1 stays, as the reload.** It used to put settings back and then reload. The put-back part is gone and the reload stays, because cv.s6.2 needs a reload between learning the vendor and asking for it.
- **Steps with a new meaning keep their ids,** because the topic is the same. cv.s2.1 is still repair and cv.s2.4 still food. They now use `/cvn test` instead of a staged threshold, because a staged worn item or food count is what made the gate need a prepared character.
- **Why not a real repair or food threshold:** the bag threshold already proves the threshold-to-question wiring once. Repeating it per kind retests the same code. The real reads still show: `durability=` sits on the `trigger go sell` line, and the food question carries the real count.
- **The waypoint is forced per client.** The steps use `/cvn nav native` on Forever and `/cvn nav chat` on Era, so an installed TomTom or WaypointUI cannot change the result. Under test settings, `off` restores the player's choice.

### Source and distance on the question line

Format: `question shown: <kind>, <target> (npc <id>), <source>, <n> yd`. The count, or the points left, follows after it as today: `question shown: supply food, <item>, <vendor> (npc <id>), learned, 6 yd, 12 left`.

- **Distance:** reuse the controller's existing `yards(v, i, x, y)` (whole yards, rounded, from the search start to the record's world x,y), which the two-target question already uses. The search's own comparison stays on squared distance. No new helper in `Search.lua`.
- **Source:** `Core.lua` passes `env.sourceOf(kind, npcId)` to the controller. It returns `"learned"` when `DB.vendors` or `DB.trainers` has the id, `"NorgannonDB"` when only the external merge gave it, and `"shipped"` otherwise. The controller logs it and does nothing else with it. The controller stays free of game globals.
- **Alternative considered: a separate `target: …` line after the question.** Rejected: plans already pair `question shown:` with the answer in log sequences, and one line keeps that pairing.
- **Compatibility:** existing plan patterns match `question shown: sell, ` or `question shown: trainer for ` by prefix. A task checks every plan assertion and `docs/contracts.md` for patterns that anchor after `(npc %d)`.

### `/cvn test trainer`

- Parse `test trainer` in `Commands.lua` like the other kinds. Add a `"trainer"` branch in the controller's `test(kind)`.
- **The profession:** take the first known profession, in `CHAR.professions` order, that a nearby trainer teaches. With none, take the nearest trainer of any profession and the first profession it teaches. Use `Search.NearestTrainer` with no tier need.
- **Asking:** call `ask("trainer", …)` with the trade and no points. The line then ends after the distance. A test question is already exempt from the zone-change withdrawal ("Trainer questions end with the place").
- **Nothing to ask:** with no position or no trainer, reply in chat with `L[...]` sentences and log `test command: nothing asked: <why>`, as the other kinds do.

### Plan rules in `tests/test_plan.lua`

- **Core plan only:** reject an action text that holds `/cvn` or `|cff`. Reject a `setup` that names a class word (Hunter, Mage and others), "profession", "dungeon", "fight" or a third-party addon. Require the step list from the table above.
- **All plans:** keep the existing opener, timeout and retired-id checks.
- **The `RETIRED` list:** add the nine ids above.

## Risks / Trade-offs

- **[Class-specific reads leave the gate]** The ammo slot, pet diet and reagent spells are read only by those classes. A broken read there is not caught at release. → Unit tests cover the logic now. #74 moves the reads to the offline block with game calls recorded in game. A feature plan runs when that code changes.
- **[Holds leave the gate]** The combat and instance holds depend on real events. → They are feature behavior, with unit tests on the hold logic. A later feature plan covers them when that code changes.
- **[Feature plans go stale]** If no one runs them, they rot. → `make plan` still validates, replays and runs the offline block for all three plans on every change.
- **[A capital lacks one target]** → Every capital has a general goods vendor, a repair vendor and profession trainers. The preamble names Stormwind or Orgrimmar as the example.
- **[The line format changes]** → It only adds text after the npc id. Patterns are checked by a task and `ct lines`.

## Migration Plan

- Release 1.13.0 with the new command and line, and the core plan's version step at 1.13.0.
- Testers import only `build/closestvendor.ct` for a release. They run the feature plans when a change names them.
- **Rollback:** revert the commit. The retired ids stay retired either way.
