# In-game test plans

The in-game checks live in CheckThat test plans. This file only points there, so it cannot drift from the plans.

| Plan | Kind | Sections | Covers |
| --- | --- | --- | --- |
| [`plans/closestvendor.yaml`](../plans/closestvendor.yaml) | release gate | s0 to s6 | the systems everything else depends on, with one ordinary character: a real bag threshold to a question, the waypoint on each client, the status window's low Bag space row, learning a vendor and a trainer, vendor and trainer questions from real data, a learned vendor after `/reload`, and no Lua error |

The unit tests (`make test`) prove the logic. The plans keep only what a fake game cannot prove: real game data and events, end-to-end wiring, drawing, sound, other addons and saved variables across `/reload`. Each plan stays under 25 steps.

## The release gate

The core plan proves six systems. If one fails, everything fails.

- **Reads:** the real bag and durability counts on the `trigger go sell` line, and the food count on the food question.
- **Wiring:** a real bag threshold crossing starts the warning, and putting it back ends it.
- **Search:** the question names the closest vendor or trainer, with where it came from (`learned`, `NorgannonDB` or `shipped`) and its distance in yards.
- **Waypoint:** the game waypoint on WoW Forever, the chat line on Classic Era, and the waypoint going away at the vendor.
- **Learning and persistence:** a vendor and a trainer learned from their windows, and the vendor still known after `/reload`.
- **Clean load:** no Lua error on either client.

It also checks that the status window shows the low Bag space row, because the window is the part of the addon people see.

One ordinary character runs it, once on each client. Any class and any level works, and the character needs no profession. It stands in a capital city, such as Stormwind or Orgrimmar, where a vendor and a profession trainer are both within about 30 yards. It has at least 3 free bag slots and no addon except ClosestVendor and CheckThat. Test settings are on for the whole run, so the player's own settings do not matter.

## Feature plans

A feature plan goes deep on one feature. Write one when you build or change a feature, as `plans/closestvendor.<feature>.yaml`, and run it then. It may need a character with a class, a profession or an addon, and each step says so first. Feature plans are not part of the release gate. There is none now: the earlier status window and other-addons plans were removed, and their sections s10 to s29 stay retired. A new feature plan takes its sections from s30 on.

Class and profession checks that are not in the gate (ammo, reagents, pet food, reminders, buying, the combat and dungeon holds) are covered by the unit tests. Checks that need real game data move to the offline block with recorded calls (#74).

## Running them

- **When:** run the core plan before each release, on WoW Forever and on Classic Era. Run a feature plan when you change its feature.
- **Check and build them:** `make plan` (needs the installed `ct` tools; see AGENTS.md, CheckThat). It writes `build/<plan name>.ct` for each plan, and runs each plan's offline block in the fake client twice, once as Classic Era and once as WoW Forever.
- **Run one** with the CheckThat addon in game: type `/ct import`, paste the contents of one `.ct` file, type `/ct start ClosestVendor` and finish the run. Then type `/ct export` and `/reload` before you import another plan: a run uses the last plan imported. Steps marked automatic are judged from the debug log, CheckThat facts and ClosestVendor's entries; the others ask the player.
- **Read a run back** with `ct collect --plan <plan file> --dest evidence` (the evidence folder is kept out of Git), or the `/ct-verify` skill.
- **How a step reads:** the action text opens with one fixed sentence: "A question appears. Click Yes.", "A question appears. Click No.", "Nothing appears. CheckThat checks by itself." or "Look, then press Pass or Fail.". The debug log, facts and entries decide the result; only a step that asks you to look or listen waits for Pass or Fail. A step that needs something says `Needs:` first and has no timeout: it waits for you, and Skip wins. In the core plan, the action text has no slash command: the commands sit behind Run. Only a step with a required absence check has a timeout.
- **Numbers:** "test plan check 2.1" means step `cv.s2.1`; "test plan section 2" means section `s2`. Each plan owns its section range, so a number names one step across the plans. Step ids are fixed: never renumber or reuse one. The core plan keeps s3, s4 and s5 unused, because their steps moved out of the gate.

## Not covered yet

- Walking distance. The addon chooses vendors by straight-line distance.
- Warlock shards and rogue poisons.
- Requirements no plan step and no unit test covers end to end are listed in `openspec/changes/archive/2026-11-25-reduce-checkthat-plan-scope/design.md`.
