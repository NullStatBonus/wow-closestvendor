# Proposal

## Why

After the four phases of #61, `plans/closestvendor.yaml` had 507 steps in 36 sections named by release (for example "Patches 1.9.4 and 1.9.5"); one section alone had 119 steps. Most steps checked, one at a time, logic the unit tests already prove (93.1% of executable Lua lines; 106 of the 228 spec requirements need no game at all). A tester cannot finish such a plan before a release, so it was not run.

## What Changes

- The plan of record becomes three plans, each under 25 steps, and all three run before each release:
  - `plans/closestvendor.yaml`: core (24 steps, sections s0 to s6): each warning from a real threshold to the vendor, the waypoint on each client, combat and dungeon holds, learning, buying with the count read back, the report, find, and a learned vendor after `/reload`.
  - `plans/closestvendor.ui.yaml`: status window, visuals and settings (22 steps, s10 to s13).
  - `plans/closestvendor.addons.yaml`: TomTom, WaypointUI, NorgannonDB and sound packs (13 steps, s20 to s21).
- Each plan starts with its own version step and one setup reload, and ends with an automatic no-Lua-error step. Steps are renumbered once, now, before any run; the ids are fixed from here on.
- The old steps are removed (Git history keeps them). Their best-formed steps and assertions are reused.
- Three unit tests close the gaps no test covered: the water controls only for mana classes, the pet food controls only for hunters, and the presentation lines of the report header.
- `tests/test_plan.lua` checks the plan set, `make plan` runs every gate on each plan, and the docs name the three plans. `docs/contracts.md` marks the lines and entries no plan step checks now.
- No addon code, setting, command or saved data changes.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `checkthat-integration`: "Plan of record" names the three plans, the step limit, and the version and Lua error steps of each plan.

## Impact

`plans/`, `tests/`, `Makefile`, `docs/`, `AGENTS.md`, `CONTRIBUTING.md`, `DESIGN.md`, `README.md` (one line in "Good to know") and `openspec/specs/checkthat-integration`. The package leaves all of these out (`.pkgmeta` `ignore:`) and no addon file changes, so there is no version bump, no tag and no CHANGELOG section.
