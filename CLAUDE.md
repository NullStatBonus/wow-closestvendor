# Closest Vendor

## Releases

Bump the addon's semantic version every time a change's specs are applied to `openspec/specs/` (at `/opsx:sync` or `/opsx:archive`).

- Set `## Version:` in **both** `ClosestVendor/ClosestVendor_Vanilla.toc` and `ClosestVendor/ClosestVendor_Camelot.toc` to the same value. Do not hard-code the version anywhere else.
- Below 1.0.0: a change that adds a capability or user-visible feature raises the minor number (0.2.0 -> 0.3.0); a change that only modifies or fixes existing behavior raises the patch number (0.2.0 -> 0.2.1). From 1.0.0, use the usual major.minor.patch meaning, and a change that breaks saved settings or data is a major bump.
- Make the bump part of the same commit as the archive, name the new version in the commit message, and add a `## X.Y.Z` section to `CHANGELOG.md` in that commit (`tools/check-version.sh` fails without it).
- To publish, tag the archive commit `vX.Y.Z` (the version without the `v` must equal the TOC version) and push the tag; see `docs/publishing.md`.

## Conventions

- **Game calls live in `Adapter.lua` only.** Every function the game provides is read there, guarded and in `pcall`, returning nil when missing; nothing else calls `C_Map`, `C_Container`, unit or inventory functions. Unknown data is nil, never 0 or false.
- **Logic is plain Lua.** `Triggers`, `Professions`, `Search`, `Discovery`, `Controller`, `Commands`, `Nav` and `Log` have no game globals, so they run under `luajit tests/run.lua`.
- **Every player-facing sentence is `L["The whole English sentence"]`.** No concatenation, no variable keys, and `say(L["..."])` rather than `say("...")`. `tests/test_locale.lua` enforces this. See `docs/localization.md`.
- **New files go in both TOC files in the same order** (`make check` fails otherwise). The `Locales` files load first.
- **Tests:** `make test`. Each module has a `tests/test_*.lua`; new behavior needs a test, and a test is only trusted once breaking the code makes it fail.
- **Chat text** never contains a raw `|`; `Core.lua` doubles it.
