# Tasks

## 1. Spike: what the clients give us

- [x] 1.1 Read the Blizzard UI source (`Gethe/wow-ui-source`, branches `forever` and `classic_era`) for the skill-line, trainer-window and craft-completion APIs and events; write the findings in `design.md` under Open Questions (verify: `design.md` decisions 1 to 3 name the call or event per client; done).
- [x] 1.2 Add an in-game checklist for what source reading cannot settle (events on Forever, final-tier detection, language-free profession detection) to `docs/test-plan.md` (verify: `tests/test_docs.py` still passes and the list is in the file).

## 2. Profession check (pure logic)

- [x] 2.1 Add a profession check module taking a list of `{key, rank, max}`, the threshold and the last known ranks, returning the profession to ask about or nil; unreadable input returns nil (verify: `luajit tests/run.lua prof` covers near cap, at cap, far, final tier, unreadable, first read stores only, off).
- [x] 2.2 Mutation-check the module: break the comparison, the final-tier rule and the first-read rule one at a time (verify: each break makes a test fail).

## 3. Trainer data and search

- [x] 3.1 Add trainer recording to `Discovery.lua`: one record per NPC id, professions merged, no record without NPC id or position (verify: `tests/test_discovery.lua` covers new, repeat, class trainer, missing position).
- [x] 3.2 Add the trainer lookup to `Search.lua`: nearest by world distance on the continent, matching profession, faction filter (verify: `tests/test_search.lua` covers other-profession-nearer, hostile faction, wrong continent, none known).
- [x] 3.3 Build trainer buckets with world coordinates at load, beside the vendor buckets, and persist the table (verify: `tests/test_core.lua` shows a recorded trainer becomes a target after reload).

## 4. Controller

- [x] 4.1 Add the `trainer` kind carrying the profession: lowest priority, no latch, same-profession question stays open, active trainer waypoint suppresses new questions, combat suppresses (verify: `tests/test_controller.lua` for each rule plus "sell replaces an open trainer question" and "trainer never replaces higher").
- [x] 4.2 Make the merchant window clear vendor kinds only, and add a trainer-window handler that clears the trainer pin and question for that profession (verify: tests for merchant-keeps-trainer-pin and trainer-window-clears).
- [x] 4.3 Add the no-known-trainer notice, once per profession per session (verify: test shows one message for repeated events and one per profession).
- [x] 4.4 Add prompt text for the trainer question, all through `L` (verify: `tests/test_locale.lua` passes).

## 5. Adapter and Core wiring

- [x] 5.1 Add Adapter reads (`C_SkillInfo.GetSkillLineInfo` with the global `GetSkillLineInfo` fallback, `IsTradeskillTrainer`, `GetNumTrainerServices`, `GetTrainerServiceSkillLine`, the tradeskill and craft window profession name), guarded, returning nil when unavailable (verify: the table-driven API-failure test in `tests/test_core.lua` includes the new calls and nothing errors).
- [x] 5.2 Register `SKILL_LINES_CHANGED`, `UNIT_SPELLCAST_SUCCEEDED` (player) and `TRAINER_SHOW`/`TRAINER_UPDATE`, and keep the set of known profession names (trainer windows and tradeskill windows), saved with the account, in `Core.lua` and route them (verify: `tests/test_core.lua` drives each event through the fake game and checks the dialog, the chat notice and the learned record).
- [x] 5.3 Log the trainer decisions in the debug log with the values behind them (verify: a test reads the log lines after an event).

## 6. Settings

- [x] 6.1 Add `tradeThreshold` (10) and `tradeEnabled` (true) defaults, `/cvn trade <points>|on|off` with limits 0 to 300, and the line in the `/cvn` report (verify: `tests/test_commands.lua` for accept, bounds, out of range, on and off).
- [x] 6.2 Add the checkbox and slider to the options page (verify: `tests/test_options.lua` for binding, greyed slider and agreement with the command).

## 7. Docs and release

- [x] 7.1 Update README (feature, commands with the new limits, limitations: learned-only, level requirements, language), `docs/listing.md` and `docs/test-plan.md` (verify: `luajit tests/run.lua readme` and `python3 -m unittest` doc tests pass).
- [ ] 7.2 Add a `## 0.2.0` section to `CHANGELOG.md` and bump `## Version:` in both TOCs at archive (verify: `make check`).
- [x] 7.3 Run `make test`, `make check` and `openspec validate --all --strict` (verify: all pass).
- [ ] 7.4 Play-test in game: learn a trainer, reach the threshold, accept, arrive, confirm the pin clears (verify: the checklist items in `docs/test-plan.md` ticked).
