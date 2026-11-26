# Closest Vendor

## Documentation

When player-visible behavior, a setting, or a command changes, update the supporting docs in the same change.

- Cover affected features, settings, commands, and “Good to know” limits in `README.md`.
- Update the CurseForge/Wago text in `docs/listing.md`. Update its summary when the headline behavior changes.
- Update the in-game plan that covers the change (`plans/closestvendor*.yaml`, see CheckThat below) with the relevant checks.
- Document every new setting in the README and include its value in the debug report.
- The report header is built by `reportText` in `ClosestVendor/Core.lua`.
- `tests/test_readme.lua` checks the README command list.

## Testing

- Cover each new behavior with an automated test. Temporarily break the behavior, verify the test fails for the expected reason, then restore the behavior and verify it passes.
- Run the focused test during implementation. Use `make test` for the full suite and `make check` for packaging and version checks.
- Keep player steps short and few. Give each step one player action (`action`), then an `expect` that states the result in words a player understands. Put the log line that proves it in `assertions` (or `reviewer` while it is a player step). Never ask the player to read or interpret a log line. Log a distinct line for each behavior the step verifies.
- Give only essential setup before the action, but name everything the check depends on: a profession, an installed addon, and turning on debug logging followed by `/reload`. Avoid old versions, disabled addons, and staged characters or items.
- Verify the result from debug logs or saved variables wherever possible. Add missing evidence in the same change.
- Keep raw saved variables and debug output out of Git. Anonymize any fixture derived from them.
- Each module has a `tests/test_*.lua` file.
- Use only the commands the check needs, usually `/cvn debug on` and `/reload` before the first check and `/reload` at the end. Verify saved data in `ClosestVendorCharDB`. Mark destructive steps optional and identify behavior with no in-game check.

## CheckThat

CheckThat runs the in-game test plans. Write plans with the `/ct-test-plan` skill and read finished runs with `/ct-verify`. Install the skills once with `make install-skill BIN_DIR=$HOME/bin` in the CheckThat checkout, so `ct <command>` works from this repository. Never point ClosestVendor's files at a CheckThat checkout. CheckThat's docs are the contract: `docs/debug-logging.md`, `docs/features.md` ("Facts from other addons", "Entry points", "Automatic steps", "Unit-test checks") and `docs/authoring-plans.md`.

- **The plans live here.** Three plans are the plan of record. `plans/closestvendor.yaml` (core; sections s0 to s9) is the release gate and runs before each release, on both clients. `plans/closestvendor.ui.yaml` (status window, visuals and settings; s10 to s19) and `plans/closestvendor.addons.yaml` (TomTom, WaypointUI, NorgannonDB, sound packs; s20 to s29) are feature plans: run one when you change that feature. A new feature gets its own feature plan, written when the feature is built.
- **The core plan is the foundation.** It proves the systems that everything else depends on, with one ordinary character: any class and level, no profession, in a capital beside a vendor and a profession trainer. The systems are real game reads, event wiring from a real threshold, search for the closest vendor or trainer, the waypoint on each client, learning and persistence across `/reload`, and a clean load. It also checks that the status window shows the low Bag space row. A step that needs a class, a profession, a dungeon, a fight or another addon never goes in the core plan: it goes in a feature plan, an offline step or a unit test (`tests/test_plan.lua` enforces this). In the core plan, the action text is one player sentence with no slash command, and no step only puts a setting back. Change a plan in the same change as the log line, fact or entry it matches. Each plan starts with its own setup section: a version step (`entry.version`, `op: ge`), then Lua errors, debug logging and test settings (`/cvn testsettings on`) with one `/reload`; each ends with the no-Lua-error step, which runs `/cvn testsettings off` first. The plans run under test settings, so a tester's own settings neither fail a step nor get overwritten by a Run command. Step `cv.s<N>.<M>` is "test plan check N.M", unique across the three plans. Never renumber or rename a step id: add a new step at the end of its section, and never reuse the id of a removed step.
- **Keep each plan under 25 steps.** A plan checks only what the unit tests cannot: real game data and events, end-to-end wiring, drawing, sound, other addons and saved variables across `/reload`. Logic a unit test proves gets no plan step. A plan that would reach 25 steps is split into another plan with its own section range. Each step is one player action; a step that needs a class, a profession or an addon says so and asks the player to press Skip otherwise. Section intros are not on the card, so each step carries its own setup. In a feature plan, a step that changes a setting is followed by a visible step that types it back; the core plan relies on test settings instead.
- **Prefer automatic steps.** A check proven by a log line, a fact or an entry is an `auto: true` step. Keep a player step only for what the log cannot show: drawing, sound, position, feel. Each player step follows the Testing rules above.
- **Log lines.** Each behavior a plan checks writes one line at its decision point with the values that prove it. Log refusals and skips too, mark failures `FAILED:`, log toggles in both directions, and keep the wording stable: a reworded line is a plan change. Assert the literal text in the source (`pattern` with `%d`/`%a` for values, or `contains` on the literal part); do not retag lines to please `ct lines`. Never log character names or chat text.
- **Facts.** Report a value with `ns.CheckThat.Report(key, value)` once, where the code decides it, never in a loop or an update handler. Report numbers as numbers.
- **Entries.** Expose pure functions a plan should call with `CheckThat.Entry`, registered at `PLAYER_LOGIN` from `start()`, never at file scope. Each is side-effect free and returns scalars of at most 100 characters, never a character name. Cover them in the plan's `offline:` block, with only the cases a unit test cannot prove: real load order, saved variables, timers and the client's surface.
- **One integration file.** All CheckThat calls sit in `ClosestVendor/CheckThat.lua`, which reads the `CheckThat` global only through `A.checkThat()` and guards each call, so ClosestVendor works when CheckThat is missing or old. Do not add CheckThat to `OptionalDeps`: CheckThat lists ClosestVendor, so ClosestVendor loads first. `make test` and `make check` never need CheckThat.
- **Before a tester runs a plan:** `make plan` runs `ct validate`, `ct compile` (to `build/<plan name>.ct`), `ct replay-flow`, `ct lines --addon-src ClosestVendor` and `ct offline --client both` (the offline block at `level: 6`, once with each TOC in `tocs`) on each of the three plans, and stops at the first failure. Then review the plans against what the card shows. Fix every finding. Read each run back with `ct collect --plan <plan file> --dest evidence` (kept out of Git) before asking for more in-game steps.
- **Contracts.** A new log format, saved variable, entry or fact key goes in `docs/contracts.md` and in each plan's `logs:` block. Mark a line or entry that no plan step checks "Diagnostic, no plan step".
- **Stay in this repository.** Run the tools; do not edit, create or leave files in CheckThat's. Write temporary copies only to the session scratchpad and delete them. When CheckThat lacks something, file an issue (`gh issue create -R NullStatBonus/wow-checkthat`) and note it in the change, instead of patching locally.

## Conventions

- **Game calls live in `Adapter.lua` only.** Every function the game provides is read there, guarded and in `pcall`, returning nil when missing; nothing else calls `C_Map`, `C_Container`, unit or inventory functions. Unknown data is nil, never 0 or false. One exception: `Nav.lua` receives the `C_Map`, `C_SuperTrack` and `UiMapPoint` tables from `A.navApi` and calls them, each call guarded and in `pcall`; this keeps waypoint logic testable with fake tables.
- **Logic is plain Lua.** `Triggers`, `Professions`, `Search`, `Discovery`, `Controller`, `Commands`, `Nav` and `Log` have no game globals, so they run under `luajit tests/run.lua`.
- **Every player-facing sentence is `L["The whole English sentence"]`.** No concatenation, no variable keys, and `say(L["..."])` rather than `say("...")`. `tests/test_locale.lua` enforces this. See `docs/localization.md`.
- **New files go in both TOC files in the same order** (`make check` fails otherwise). The `Locales` files load first.
- **Chat text** never contains a raw `|`; `Core.lua` doubles it.
- Choose game API code paths by checking whether the function exists, never by the client's name.
- Persistent visuals default to a pure black background, with a user-selectable color. Draw no fill, border, or texture at zero opacity. Keep text and icons dimmable and avoid bright fixed-position fills.
- For each new UI control or screen, check Blizzard UI source and popular addons for an established pattern. Use a standard control when available. If a custom control is necessary, keep the standard fallback where the custom control is unavailable.

## OpenSpec, Git, and releases

- Follow the matching workflow under `.claude/skills/`. The archive procedure is in `.claude/skills/openspec-archive-change/SKILL.md` (`/opsx:archive` in Claude Code).
- Bump the version once per OpenSpec change when its specs are applied to `openspec/specs/` during sync or archive. If `/opsx:sync` already set the version, keep it at archive. Exception: a change that touches only files the package leaves out (the `ignore:` list in `.pkgmeta`, such as `plans/`, `tests/`, `tools/`, `docs/` and `openspec/`) gets no version bump, no tag and no CHANGELOG section; it ships with the next addon release.
- Set the same `## Version:` in `ClosestVendor/ClosestVendor_Vanilla.toc` and `ClosestVendor/ClosestVendor_Camelot.toc`. These are the only files that hard-code the addon version.
- Before 1.0, bump minor for a new capability or player-visible feature and patch for a fix or modification to existing behavior. From 1.0 onward, follow semantic versioning. Breaking saved settings or data requires a major bump from 1.0 onward.
- Archive before committing, pushing, or opening a PR for the change. Keep the code, synced specs, archive, version bump, and matching `## X.Y.Z` changelog section in the same commit. Name the new version in the commit message. A change still active in `openspec/changes/` is ineligible for commit.
- Write `CHANGELOG.md` at archive. Order entries by `New:`, `Changed:`, `Fixed:`, and `Removed:`. Bold the main item. For each fix, say what players saw before. Write one short line per entry in ASD-STE100 Simplified Technical English. Use active voice, simple tenses, common words, one fact per sentence, and at most 20 words per sentence. Describe what players see. Put settings-page, debug-report, and implementation details in the README.
- To publish, tag the archive commit `vX.Y.Z`, matching the TOC version, and push the tag as described in `docs/publishing.md`.
