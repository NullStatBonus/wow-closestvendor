# Contributing

Thanks for helping. Closest Vendor is a WoW Classic Era and WoW Forever addon (Lua) that points players at the nearest vendor to sell to, repair at, or buy ammo from.

## Ways to help

- **Report a bug.** Type `/cvn debug on`, do the thing that went wrong, then `/cvn log`, copy the report (Ctrl+A, Ctrl+C) and attach it with a short description and your client (Classic Era or Forever).
- **Correct the vendor data.** A vendor in the wrong place, one that should repair or sell ammo and does not, or a missing zone. Say which vendor, where it really is, and your client. The data is generated (see below), so a fix is a change to the source or the build, not an edit of `Data/Vendors.lua`.
- **Translate.** See [docs/localization.md](docs/localization.md).
- **Fix or build something.** For anything bigger than a small fix, open an issue first so we agree on the approach.

## Setup

1. Clone the repository and link or copy `ClosestVendor/` into your AddOns folder (`_classic_era_` or the Forever folder).
2. Install [LuaJIT](https://luajit.org) and Python 3, then from the repository root:

   ```
   make test                      # everything
   luajit tests/run.lua adapter   # test files whose name contains "adapter"
   make check                     # TOC, version and changelog checks
   ```

3. In game, `/reload` after a change, and `/console scriptErrors 1` so errors show as popups. `docs/test-plan.md` lists what to check by hand.

## How changes are made

Behavior is specified in `openspec/specs/`. A change to behavior goes through an OpenSpec change under `openspec/changes/` (proposal, design, spec deltas, tasks), is implemented against its tasks, and is archived when done. Archiving applies the deltas to the main specs and bumps the version (see `CLAUDE.md`). Bug fixes that restore specified behavior can skip the proposal; add a test that fails without the fix.

## Code

- **Match the surrounding code**: naming, comment density and idiom. Keep changes small and focused.
- **Keep the game out of the logic.** All game reads go through `ClosestVendor/Adapter.lua`, guarded and in `pcall`, so a missing or changed function degrades to "no data" instead of an error. Everything else is plain Lua and testable.
- **Unknown is not zero.** If the game cannot say how many bag slots are free, or how much ammo there is, the answer is nil and the trigger does not fire.
- **Write tests** in `tests/` for every behavior change. Check a new test by breaking the code it covers: it should fail.
- **Player-facing text** goes through `L["..."]` with the whole sentence as the key; see `CLAUDE.md`.
- **New files** go in both TOC files in the same order. `make check` fails if they differ or a file is missing.
- **Plain language.** Player-facing text has no internal terms.

## The vendor data

`ClosestVendor/Data/Vendors.lua` is generated from the [pfQuest](https://github.com/shagu/pfQuest) database (MIT) and wago.tools map data by `tools/fetch_data.py` and `tools/build_vendors.py`; the addon also learns vendors as players open them. Do not copy data from GPL-licensed projects (Questie, vmangos, cmangos, TrinityCore, AzerothCore) into this MIT repository.
