# Closest Vendor

## Documentation

When player-visible behavior, a setting, or a command changes, update the supporting docs in the same change.

- Cover affected features, settings, commands, and “Good to know” limits in `README.md`.
- Update the CurseForge/Wago text in `docs/listing.md`. Update its summary when the headline behavior changes.
- Update `docs/test-plan.md` with the relevant manual checks. Keep section numbers unique and in order.
- Document every new setting in the README and include its value in the debug report.
- The report header is built by `reportText` in `ClosestVendor/Core.lua`.
- `tests/test_readme.lua` checks the README command list.

## Testing

- Cover each new behavior with an automated test. Temporarily break the behavior, verify the test fails for the expected reason, then restore the behavior and verify it passes.
- Run the focused test during implementation. Use `make test` for the full suite and `make check` for packaging and version checks.
- Keep manual checks short and few. Give each check one player action followed by a `Check:` line stating the expected result. Log a distinct line for each behavior the check verifies.
- Give only essential setup before the action. Avoid old versions, disabled addons, and staged characters or items.
- Verify the result from debug logs or saved variables wherever possible. Add missing evidence in the same change.
- Keep raw saved variables and debug output out of Git. Anonymize any fixture derived from them.
- Each module has a `tests/test_*.lua` file.
- Use only the commands the check needs, usually `/cvn debug on` at the start and `/reload` at the end. Verify saved data in `ClosestVendorCharDB`. Mark destructive steps optional and identify behavior with no in-game check.

## Conventions

- **Game calls live in `Adapter.lua` only.** Every function the game provides is read there, guarded and in `pcall`, returning nil when missing; nothing else calls `C_Map`, `C_Container`, unit or inventory functions. Unknown data is nil, never 0 or false.
- **Logic is plain Lua.** `Triggers`, `Professions`, `Search`, `Discovery`, `Controller`, `Commands`, `Nav` and `Log` have no game globals, so they run under `luajit tests/run.lua`.
- **Every player-facing sentence is `L["The whole English sentence"]`.** No concatenation, no variable keys, and `say(L["..."])` rather than `say("...")`. `tests/test_locale.lua` enforces this. See `docs/localization.md`.
- **New files go in both TOC files in the same order** (`make check` fails otherwise). The `Locales` files load first.
- **Chat text** never contains a raw `|`; `Core.lua` doubles it.
- Choose game API code paths by checking whether the function exists, never by the client's name.
- Persistent visuals default to a pure black background, with a user-selectable color. Draw no fill, border, or texture at zero opacity. Keep text and icons dimmable and avoid bright fixed-position fills.
- For each new UI control or screen, check Blizzard UI source and popular addons for an established pattern. Use a standard control when available. If a custom control is necessary, keep the standard fallback where the custom control is unavailable.

## OpenSpec, Git, and releases

- Follow the matching workflow under `.claude/skills/`. The archive procedure is in `.claude/skills/openspec-archive-change/SKILL.md` (`/opsx:archive` in Claude Code).
- Bump the version once per OpenSpec change when its specs are applied to `openspec/specs/` during sync or archive. If `/opsx:sync` already set the version, keep it at archive.
- Set the same `## Version:` in `ClosestVendor/ClosestVendor_Vanilla.toc` and `ClosestVendor/ClosestVendor_Camelot.toc`. These are the only files that hard-code the addon version.
- Before 1.0, bump minor for a new capability or player-visible feature and patch for a fix or modification to existing behavior. From 1.0 onward, follow semantic versioning. Breaking saved settings or data requires a major bump from 1.0 onward.
- Archive before committing, pushing, or opening a PR for the change. Keep the code, synced specs, archive, version bump, and matching `## X.Y.Z` changelog section in the same commit. Name the new version in the commit message. A change still active in `openspec/changes/` is ineligible for commit.
- Write `CHANGELOG.md` at archive. Order entries by `New:`, `Changed:`, `Fixed:`, and `Removed:`. Bold the main item. For each fix, say what players saw before. Write one short line per entry in ASD-STE100 Simplified Technical English. Use active voice, simple tenses, common words, one fact per sentence, and at most 20 words per sentence. Describe what players see. Put settings-page, debug-report, and implementation details in the README.
- To publish, tag the archive commit `vX.Y.Z`, matching the TOC version, and push the tag as described in `docs/publishing.md`.
