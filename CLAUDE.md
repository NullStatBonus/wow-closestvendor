# Closest Vendor

## Delegation
- Use subagents for self-contained work that would clutter the main context: broad codebase searches, independent research threads, parallel edits across unrelated files, and reviews.
- Pick the subagent model by difficulty: haiku for search and lookup, sonnet for routine implementation, opus (or inherit) for design, debugging, and anything requiring judgment.
- When delegating UI work, tell the subagent to check the Blizzard UI source and popular addons for the standard control first (see Conventions).
- Do small or tightly coupled work inline. Don't delegate just to delegate.

## Releases

Bump the addon's semantic version every time a change's specs are applied to `openspec/specs/` (at `/opsx:sync` or `/opsx:archive`).

- Set `## Version:` in **both** `ClosestVendor/ClosestVendor_Vanilla.toc` and `ClosestVendor/ClosestVendor_Camelot.toc` to the same value. Do not hard-code the version anywhere else.
- Below 1.0.0: a change that adds a capability or user-visible feature raises the minor number (0.2.0 -> 0.3.0); a change that only modifies or fixes existing behavior raises the patch number (0.2.0 -> 0.2.1). From 1.0.0, use the usual major.minor.patch meaning, and a change that breaks saved settings or data is a major bump.
- Make the bump part of the same commit as the archive, name the new version in the commit message, and add a `## X.Y.Z` section to `CHANGELOG.md` in that commit (`tools/check-version.sh` fails without it).
- To publish, tag the archive commit `vX.Y.Z` (the version without the `v` must equal the TOC version) and push the tag; see `docs/publishing.md`.

## Git and PRs

- **Archive before git.** Before any commit, push or PR for a change, run `/opsx:archive` first (sync specs, bump the version, write the CHANGELOG section), so the archive and the code ship in the same commit/PR. Commit nothing for a change that is still active in `openspec/changes/`.

## Documentation

Update the supporting docs in the same change as any user-visible addon behavior, setting or command:

- `README.md`: features, settings page, command list (`tests/test_readme.lua` checks the commands), and "Good to know" limits.
- `docs/listing.md`: the CurseForge/Wago listing text, including the summary line if the headline behavior changes.
- `docs/test-plan.md`: manual in-game checks for the new behavior; keep section numbers unique and in order.
- The debug report header in `Core.lua` (`reportText`) lists any new setting.
- `CHANGELOG.md` is written at archive (see Releases), not before.

## Conventions

- **Game calls live in `Adapter.lua` only.** Every function the game provides is read there, guarded and in `pcall`, returning nil when missing; nothing else calls `C_Map`, `C_Container`, unit or inventory functions. Unknown data is nil, never 0 or false.
- **Logic is plain Lua.** `Triggers`, `Professions`, `Search`, `Discovery`, `Controller`, `Commands`, `Nav` and `Log` have no game globals, so they run under `luajit tests/run.lua`.
- **Every player-facing sentence is `L["The whole English sentence"]`.** No concatenation, no variable keys, and `say(L["..."])` rather than `say("...")`. `tests/test_locale.lua` enforces this. See `docs/localization.md`.
- **New files go in both TOC files in the same order** (`make check` fails otherwise). The `Locales` files load first.
- **Tests:** `make test`. Each module has a `tests/test_*.lua`; new behavior needs a test, and a test is only trusted once breaking the code makes it fail.
- **Chat text** never contains a raw `|`; `Core.lua` doubles it.
- **Persistent visuals are OLED-safe.** Anything that stays on screen (the status window, any future HUD) defaults to a pure black background (never grey; the user may pick another color), draws nothing (no fill, border or texture) when its opacity is 0, keeps text and icons dimmable, and avoids bright fixed-position fills, so static elements do not burn in.
- **Use the game's own UI patterns before inventing one.** For any new control or screen (settings rows, color pickers, buttons, frames), find how the Blizzard UI or popular addons already do it and use that. Build a custom control only when no standard one exists, and then keep the standard control as the fallback where the custom one is unavailable.
