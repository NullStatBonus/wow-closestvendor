# In-game test plans

The in-game checks live in three CheckThat test plans. This file only points there, so it cannot drift from the plans.

| Plan | Sections | Covers |
| --- | --- | --- |
| [`plans/closestvendor.yaml`](../plans/closestvendor.yaml) | s0 to s6 | core: each warning from a real threshold to the vendor, the waypoint on each client, combat and dungeon holds, learning a vendor and a trainer, buying at a merchant, the report, find, and a learned vendor after `/reload` |
| [`plans/closestvendor.ui.yaml`](../plans/closestvendor.ui.yaml) | s10 to s13 | the status window (low rows, row click, seller menu, Move, color, opacity), the demo, automatic waypoints and the notice, the preview, the AddOns list and settings pages, and settings across `/reload` |
| [`plans/closestvendor.addons.yaml`](../plans/closestvendor.addons.yaml) | s20 to s21 | TomTom, WaypointUI, NorgannonDB and sound packs; each step asks you to press Skip when the addon is not installed |

The unit tests (`make test`) prove the logic. The plans keep only what a fake game cannot prove: real game data and events, end-to-end wiring, drawing, sound, other addons and saved variables across `/reload`. Each plan stays under 25 steps.

- **When:** run all three plans before each release, on WoW Forever and on Classic Era.
- **Check and build them:** `make plan` (needs the installed `ct` tools; see AGENTS.md, CheckThat). It writes `build/closestvendor.ct`, `build/closestvendor.ui.ct` and `build/closestvendor.addons.ct`.
- **Run them** with the CheckThat addon in game, one plan at a time: type `/ct import`, paste the contents of one `.ct` file, type `/ct start ClosestVendor` and finish the run. Then type `/ct export` and `/reload` before you import the next plan: a run uses the last plan imported. Steps marked automatic are judged from the debug log, CheckThat facts and ClosestVendor's entries; the others ask the player.
- **Read a run back** with `ct collect --plan <plan file> --dest evidence` for each plan (the evidence folder is kept out of Git), or the `/ct-verify` skill.
- **Numbers:** "test plan check 4.1" means step `cv.s4.1`; "test plan section 20" means section `s20`. Each plan owns its section range, so a number names one step across the three plans. Step ids are fixed from this version of the plans on: never renumber or reuse one.

## Not covered yet

- Walking distance. The addon chooses vendors by straight-line distance.
- Warlock shards and rogue poisons.
- Requirements no plan step and no unit test covers end to end are listed in `openspec/changes/archive/2026-11-25-reduce-checkthat-plan-scope/design.md`.
