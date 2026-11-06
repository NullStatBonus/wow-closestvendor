# Proposal

## Why

The addon works against fake game APIs and in a first in-game run, but it has no release pipeline, calls game functions directly (a changed or missing function on Forever would throw), cannot report what it sees when something goes wrong, and hard-codes English. The sibling addon `wow-dontdothat` already solves each of these.

## What Changes

- **Release pipeline:** `.pkgmeta`, a tag-triggered release workflow (tests, checks, package, CurseForge, Wago, GitHub release), a CI workflow for pushes and pull requests, TOC/version check scripts, `CHANGELOG.md`, `docs/publishing.md`, a fuller `.gitignore`.
- **Store listing:** `docs/listing.md` with copy-ready text and field values for the CurseForge and Wago projects.
- **Process docs:** `CLAUDE.md` (version and release rules), `CONTRIBUTING.md`, `docs/test-plan.md` (in-game checklist), README "Problems?" and developer sections.
- **Test infrastructure:** one runner with a pattern filter and a single exit status (`luajit tests/run.lua [pattern]`) and a shared harness, replacing the per-file loop.
- **Adapter layer:** every game call goes through one `Adapter` that guards and `pcall`s it. A missing or throwing function means "no data", never an error, and unknown bag data is never treated as "zero free slots".
- **Diagnostics:** an optional bounded debug log (`/cvn debug on|off`) and a copyable report (`/cvn log`) with version, client, settings and recent events and decisions.
- **Localization:** all player-facing text goes through `L["English sentence"]`, with an example locale file, a translator guide and a test that keeps translation keys honest.

Out of scope: store project IDs (the owner creates the projects first), alert banner and sounds, saved-variable migration, a settings model with validation.

## Capabilities

### New Capabilities
- `api-resilience`: Game calls are guarded so API differences degrade to missing data instead of errors.
- `diagnostics`: Optional debug log and a copyable report for bug reports.
- `localization`: Player-facing text is translatable and falls back to English.

### Modified Capabilities

None. (`add-closest-vendor-nav` is not archived yet, so these are new, separate capabilities.)

## Impact

- New files: `Adapter.lua`, `Log.lua`, `Locales/`, `.pkgmeta`, `.github/workflows/`, `tools/check-*.sh`, `docs/`, `CLAUDE.md`, `CONTRIBUTING.md`, `CHANGELOG.md`.
- `Core.lua` stops calling game functions directly; most player-facing strings are wrapped in `L[...]`.
- `Triggers.FreeSlots` returns nil when no bag reports data; `Triggers.Update` treats a nil bag count as unknown.
- Tests move to one runner; a few modules need the locale loaded in tests.
