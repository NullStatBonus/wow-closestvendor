# Design

## Context

Mirrors the sibling addon `wow-dontdothat` (release workflow, packager config, check scripts, test runner, adapter, debug log, localization), adapted to this addon: no Ace libraries, one data file, per-flavor TOCs `ClosestVendor_Vanilla.toc` (Era) and `ClosestVendor_Camelot.toc` (Forever).

## Decisions

1. **One adapter.** `Adapter.lua` is the only file that reads game state (`C_Container`, `C_Map`, inventory, units, merchant, items, addon loaded checks). Each function checks the API exists, runs it in `pcall`, and returns nil on failure after reporting once per failure kind through `Adapter.onError(name, err)`. Core wires `onError` to the log. UI calls (frames, popups, settings, slash registration) stay in `Core.lua` and `Options.lua` and are already guarded.
2. **Unknown, not zero.** `Triggers.FreeSlots` returns nil when no bag reported; `Triggers.Update` treats a nil bag count as "unknown" (no sell request).
3. **Log.** `Log.lua` is a pure bounded ring buffer over a saved sub-table `{enabled, entries}`; `Add` is a no-op when disabled. `Controller` takes an optional `env.log`. The report text is built by a pure function; Core shows it in a plain `EditBox` frame (no templates) with a chat fallback.
4. **Localization.** `Locales/enUS.lua` creates `ns.L` as a table whose missing keys return the key. Locale files assign `ns.L["English"] = "Translated"` when `GetLocale()` matches. `Locales/Example.lua` is a template, not in the TOC. `docs/localization.md` is the guide. Format strings stay inside `L[...]` so word order can change. A locale test scans the source for `L["..."]` keys and checks the example and any locale file only use existing keys.
5. **Test runner.** `tests/run.lua [pattern]` runs each `tests/test_*.lua` in its own `luajit` process (no shared global state), prints failures only, a summary, and exits non-zero on any failure. `tests/harness.lua` holds the shared `eq`/counter. `make test` runs the Lua runner then the Python tests. `make check` runs the `tools/check-*.sh` scripts.
6. **CI.** `ci.yml` on push and pull request: install `luajit`, run tests and checks. `release.yml` on `v*` tags: same, then the BigWigs packager (CurseForge, Wago) and a GitHub release. Both skip a store whose project ID is absent from the TOCs.
7. **Packaging.** `.pkgmeta` moves `ClosestVendor/ClosestVendor` to the zip top, uses `CHANGELOG.md`, and ignores dev files; `LICENSE` and `THIRD_PARTY.md` ship so the pfQuest notice travels with the data.
8. **Release rules** live in `CLAUDE.md`: same `## Version:` in both TOCs, bumped when a change's specs are applied (archive), recorded in `CHANGELOG.md`, tagged `vX.Y.Z`.
9. **Listing.** `docs/listing.md` holds the text and field values for the CurseForge and Wago project forms; IDs are added to both TOCs afterwards (documented in `docs/publishing.md`).

## Risks / Trade-offs

- [Wrapping every call hides real bugs] -> failures are logged (once per kind) and visible in `/cvn log`.
- [Wrapping strings changes many files] -> tests cover every message; the locale test catches typos.
- [Report window code is not testable in game here] -> built from plain frames inside `pcall`, with a chat fallback; checked in the in-game test plan.
- [Store category names and limits are from memory] -> `docs/listing.md` marks them as suggestions to confirm in the site forms.

## Open Questions

- CurseForge and Wago project IDs (owner creates the projects).
