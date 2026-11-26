# Proposal

## Why

The release gate is three CheckThat plans with 53 steps, and no single character can run it. Ten steps need a Hunter, a reagent class, a profession at a set skill, a dungeon and a fight, or another addon. Most of the rest retest one system: four warning types go through the same path from threshold to question to route, and unit tests already prove that path. The step text is technical (slash commands, color codes, "the addon logs") and includes steps that only put settings back.

The gate should prove the few systems that make the addon work at all, in the real game, with one ordinary character. Each feature gets its own deep plan when it is built or changed (NullStatBonus/wow-checkthat#219 asks the CheckThat skill to work this way).

## What Changes

- **One core plan is the release gate.** `plans/closestvendor.yaml` becomes a foundation plan of 14 steps, 13 for each client. Any class at any level with no profession can run it in a capital, standing near a vendor, a repair vendor and a profession trainer, with 3 free bag slots and test settings on. It proves six systems:
  - real reads (bags, durability, food in the bags);
  - event wiring (a real threshold crossed and cleared);
  - search (the closest eligible vendor or trainer);
  - the waypoint on each client;
  - learning and persistence across `/reload`;
  - a clean load.

  It also has one status-window step, because the owner depends on the window.
- **The UI and other-addons plans become feature plans.** `plans/closestvendor.ui.yaml` and `plans/closestvendor.addons.yaml` stay, still checked by `make plan`. They run when their code changes, not before every release.
- **Steps leave the gate.** The ammo, reagent and real-food warnings, buying, the combat and dungeon holds, the report and find leave the core plan. They are covered by unit tests, the offline block or feature plans. Their step ids are retired and never reused.
- **Plain wording.** Each action is one sentence in player words, and the commands stay behind Run. Each Expect says only what is on screen. No step exists only to put a setting back, because `/cvn testsettings off` restores the player's settings.
- **New `/cvn test trainer`.** It asks the trainer question now for the nearest known profession trainer. Any character can then prove trainer routing.
- **The question log line names the source and the distance.** Each `question shown:` line adds where the target came from (`learned`, `NorgannonDB` or `shipped`) and its distance in whole yards. A plan can then prove that the addon chose the vendor or trainer next to the player.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `checkthat-integration`: the plan of record is one core plan as the release gate, plus feature plans. The core plan rules: one character, no class or addon needs, and its step list.
- `profession-trainer`: a trainer test command.
- `diagnostics`: the `question shown:` line records the target's source and distance.

## Impact

- Addon code: `ClosestVendor/Commands.lua` (parse `test trainer`), `ClosestVendor/Controller.lua` (the trainer test, the source and distance on the question line), `ClosestVendor/Core.lua` (pass a source lookup to the controller), `ClosestVendor/Search.lua` (distance in yards). New chat text goes in `ClosestVendor/Locales`.
- Plans: `plans/closestvendor.yaml` rewritten. The `.ui` and `.addons` plans are relabeled as feature plans (preamble only).
- Tests: `tests/test_plan.lua` (core plan rules), plus the controller, command and readme tests.
- Docs: `AGENTS.md` (release rule), `docs/test-plan.md`, `docs/contracts.md` (the line format and the plan steps), `README.md` (the test command), `docs/listing.md` (the command list).
- Version: minor bump to 1.13.0, because `/cvn test trainer` is a new player-visible command. The core plan's version step requires 1.13.0.
