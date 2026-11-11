# Contributing

Thank you for your help. Closest Vendor is a Lua addon for WoW Classic Era and WoW Forever. It points players at the closest vendor to sell to, repair at, or buy ammo from.

## Ways to help

- **Report a bug.**
  1. Type `/cvn debug on`.
  2. Do the action that went wrong.
  3. Type `/cvn log`.
  4. Copy the report (Ctrl+A, Ctrl+C).
  5. Attach the report to your issue. Add a short description and your client (Classic Era or Forever).
- **Correct the vendor data.** Report a vendor in the wrong place, a vendor that does not repair or sell ammo when it must, or a missing zone. Say which vendor it is, where it really is, and which client you use. The data is generated (see "The vendor data"). Change the source or the build. Do not edit `Data/Vendors.lua` by hand.
- **Translate.** Read [docs/localization.md](docs/localization.md).
- **Fix or build something.** For a big change, open an issue first. We then agree on the approach.

## Setup

1. Clone the repository.
2. Link or copy `ClosestVendor/` into your AddOns folder (`_classic_era_` or the Forever folder).
3. Install [LuaJIT](https://luajit.org) and Python 3.
4. From the repository root, run these commands:

   ```
   make test                      # everything
   luajit tests/run.lua adapter   # test files whose name contains "adapter"
   make check                     # TOC, version and changelog checks
   ```

5. After a change, type `/reload` in the game.
6. Type `/console scriptErrors 1` to show errors as popups.
7. Use `docs/test-plan.md` for the manual checks.

## How changes are made

Behavior is specified in `openspec/specs/`.

1. For a behavior change, make an OpenSpec change in `openspec/changes/`. It has a proposal, a design, spec deltas and tasks.
2. Implement the change against its tasks.
3. Archive the change when it is done. The archive applies the deltas to the main specs and bumps the version (see `CLAUDE.md`).

A bug fix that restores specified behavior does not need a proposal. Add a test that fails without the fix.

## Code

- **Match the surrounding code.** Use the same naming, comment density and idiom. Keep each change small and focused.
- **Keep the game out of the logic.** Every game call is in `ClosestVendor/Adapter.lua`. Each call is guarded and in `pcall`. If a game function is missing or changed, the addon has "no data" and raises no error. All other code is plain Lua that tests can run.
- **Unknown is not zero.** If the game cannot give a value, the value is nil. Example: free bag slots or the amount of ammo. When the value is nil, the trigger does not fire.
- **Write tests** in `tests/` for every behavior change. To check a new test, break the code that it covers. The test must fail.
- **Player-facing text** uses `L["..."]`. The key is the whole English sentence. See `CLAUDE.md`.
- **New files** go in both TOC files in the same order. `make check` fails if the TOC files differ or a file is missing.
- **Use plain language.** Player-facing text has no internal terms.

## The vendor data

`ClosestVendor/Data/Vendors.lua` is generated. The inputs are the [pfQuest](https://github.com/shagu/pfQuest) database (MIT) and wago.tools map data. The tools are `tools/fetch_data.py` and `tools/build_vendors.py`. The addon also learns vendors when the player opens them.

Do not copy data from GPL-licensed projects into this MIT repository. These projects are Questie, vmangos, cmangos, TrinityCore and AzerothCore.
