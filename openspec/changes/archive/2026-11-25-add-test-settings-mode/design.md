# Design

## Context
Fix for in-game plan runs failing on a tester's own settings (vendorMode auto). Plan reviewed by Opus and Codex; their findings are folded in below.

## Decisions

**D1. Swap in place.** `CHAR.cfg`, `CHAR.hud` and `CHAR.toast` are held by reference (Controller, Triggers, Options, Tracker, both toasts). The swap empties and refills these three tables and never reassigns them, so no reload is needed. Nested tables (`hudRow`, `reagentOff`) are read through `cfg.` at call time and may be replaced. The stash `CHAR.realSettings = { cfg, hud, toast }` holds deep copies.

**D2. Shared normalization.** init()'s default fill, clamps, colour and hudRow cleanup, `Presentation.Migrate` and `toastLocked = nil` move to `normalize(cfg, existingUser)`. The test set is normalized with `existingUser = false`, so it gets the Toast style a new character gets (UI check 13.4 needs `toast -> warning`). Restore normalizes with `true`, so a default added since the stash is filled. The `x = x or {}` lines stay in init().

**D3. The swap is pure.** `Commands.SwapSettings(char, on, freshCfg)` does the copy, wipe and refill and returns what happened (`on`, `reset`, `off`, `not on`); Core passes defaults and normalize. Covered by `tests/test_commands.lua`.

**D4. End everything that holds old settings first.** Core's action handler, before the swap: `endShows()` (demo, preview), cancel Move on tracker and toast, bump a settings generation that color-picker callbacks check (both entry points, so a late Cancel cannot write into the other set), withdraw the route question, and close the ammo and reagent purchase questions. After: `ns.Options.Refresh()`, `refreshNav()`, `evaluate()`, `applyWindow()`, then `cfgSeen = flatSettings()` without logging, so the swap is not reported as setting changes.

**D5. `on` while on resets the test set.** An abandoned run can leave changed test settings; a new run's `on` must give a clean baseline. The stash is never overwritten.

**D6. Plan proof is a login line.** `Log.Add` drops lines while debug is off, so the setup step runs `/cvn debug on` before `/cvn testsettings on`. After the reload, `start()` logs `test settings: on at login`; the setup step asserts debug on, login, that line. No CheckThat entry: an entry runs when the step opens, before Run.

**D7. Teardown.** Each last step gets Run text and the command `/cvn testsettings off`, with an attempt-scoped assertion on the off line. The addons plan's `remindSound` config check samples when the card opens, before Run, so it still checks the test set.

## Risks
- A tester who abandons a run keeps test settings until `off`; the login chat line says so.
- The status window and toast sit at their default positions during a run.
