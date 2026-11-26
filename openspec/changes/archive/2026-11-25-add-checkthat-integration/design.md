# Design

## Context

Issue #61 Phase 1. KeepThat did the same retrofit (`../wow-keepthat`, `KeepThat/Integrations/CheckThat.lua`). ClosestVendor has no integrations gate, no AceAddon, one event frame in `Core.lua`, and a debug log that records nothing while it is off. The build plan was reviewed by Opus and Codex before work started.

## Decisions

**D1. One file, `ClosestVendor/CheckThat.lua`, loaded before `Core.lua`.** It holds every CheckThat call. It reads the `CheckThat` global only through `A.checkThat()` in `Adapter.lua` (guarded, returns the table or nil). It keeps its own status (`not detected`, `working`, `failed` with a reason) because `Log.Add` drops lines while debug is off; the report must still show a failure.

**D2. Started from Core's PLAYER_LOGIN.** `start()` calls `CT.Start(ctx)` last, inside `pcall`, so a bug in the integration never stops the addon from starting. CheckThat accepts `Entry` at any time, so ClosestVendor needs no extra event handler and no OptionalDeps (CheckThat lists ClosestVendor, so ClosestVendor loads first). `ctx` gives functions, not tables: `cfg()` returns the current `CHAR.cfg` (it can be replaced), `version()` returns `A.addonVersion()`, `log` is the debug log. Registration runs once per session (`CT.registered`).

**D3. Failure handling.** A false return from `Entry` or `Report` is normal. A raised error marks the integration failed, keeps the reason, logs `checkthat: FAILED: <why>`, and blocks every later `Entry` and `Report` call. An error inside an entry function is caught by a wrapper that keeps the number of return values and returns `error: <msg>` cut to 100 characters; it logs nothing (entries have no side effects) and the integration stays on. A CheckThat with no `Entry` shows as `too old`.

**D4. Entries.** `version`: number from the TOC version read once at Start (so an entry call never reaches the game, whose failure path logs), zero values when unknown (the offline client has none). `setting(key)`: `P.Value(cfg, key)` for a key in `P.KEYS` (lower-cased, as `/cvn get` does), zero values otherwise. `integration()`: the status text. All results are cut to 100 characters (CheckThat's `Entries.TEXT`).

**D5. Plan ids.** `plans/closestvendor.yaml` starts from CheckThat's `plans/full/closestvendor.yaml` (a fresh `ct from-md` differs only in one assertion and the position of three `clients` keys). The only renumber is s0: the version step is `cv.s0.1`, the three setup steps become `cv.s0.2`-`cv.s0.4`. The 13.x and 14.x markdown subsections stay flat in the YAML (`cv.s13.N` numbers straight through), so "13.2" means `cv.s13.2` once `docs/test-plan.md` is a pointer. Steps removed for #60 never get an id reused.

**D6. #59 dropped.** Regrouping renumbers every step and step text cites section numbers ("Sections 3 and 17", "fallback in section 20"); whole-section moves would still leave section 13 mixed. Ids freeze now, so #59 is closed as won't do by the owner after a comment.

**D7. Version step.** `cv.s0.1` asserts only the fact `entry.version ge 11100`. It needs no debug log, so it can come first. No log assertion: registration happens at login, before the tester can turn the log on.

**D8. `cv.s2.1` stays a player step.** `test command: sell` only proves the command ran; the visual question is the check. Its diagnostic assertion uses `pattern` on the literal source text so `ct lines` finds it.

**D9. Debug off is logged.** Review found `debug log turned off` was never written: the log stopped before the line. The line is now written first, so the plan can assert both toggles.

## Risks

- `ct coverage` cannot read `Commands.lua` (CheckThat looks in `Slash*.lua`): NullStatBonus/wow-checkthat#143.
- `ct lines` reports a false miss for `contains: 'test command: sell'` (the source concatenates the value): NullStatBonus/wow-checkthat#144. Reviewed by hand: `Controller.lua:592` writes it.
- CheckThat still holds copies of the ClosestVendor plans: NullStatBonus/wow-checkthat#142.
- A tester who runs CheckThat older than the entry API gets an unverified version step; the step's notes say so.
