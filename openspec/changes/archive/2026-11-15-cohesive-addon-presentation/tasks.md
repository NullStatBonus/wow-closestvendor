## 1. Specification preparation

- [x] 1.1 Recheck current active/archive state and canonical requirements.
- [x] 1.2 Record A–E approval, demo amendment, CV style amendment and DDT exclusion.
- [x] 1.3 Evaluate each recommendation in coverage.md; write explicit deltas for overlapping requirements.
- [x] 1.4 Run strict OpenSpec validation and inspect artifact completeness; record results in coverage.md.

## 2. Implementation planning and standard controls

- [x] 2.1 Inspect actual Blizzard/Ace controls and fallback patterns; record the source and API contract measured.
- [x] 2.2 Map each new public key to actual stored values, units, validator, scope and refresh callback; document aliases and supported page/topic/kind names.
- [x] 2.3 Review coverage.md against every implemented requirement and scenario; resolve remaining implementation choices without expanding scope.

## 3. Presentation and settings

- [x] 3.0 Migrate native builders to one AceConfig tree; embed minimal libraries with licenses/version records, load before Options in both TOCs, update packaging/checks, preserve existing DB storage, wire cog/slash/game-options entry points and graceful failure.

- [x] 3.1 Implement local visual tokens, neutral titles, readable semantic cues and long-content layout without global reskinning.
- [x] 3.2 Add approved settings landmarks, common labels, accurate scope and dependent-control explanations while preserving feature pages.
- [x] 3.3 Add independent opacity/scale where specified; migrate old alpha and preserve profiles, enabled states, colors and positions.
- [x] 3.4 Implement per-character Warning/Toast preference, default Toast, with the same event meaning and exactly one presentation.
- [x] 3.5 Preserve HUD modes/click behavior, reminder semantics, confirmation guards and silent automatic notices.

## 4. Commands and interactions

- [x] 4.1 Implement common verbs, grouped help and typed get/set registry; preserve bare and valid legacy commands.
- [x] 4.2 Implement broad safe demo and focused previews with no real side effects; preserve legacy test behavior.
- [x] 4.3 Implement Move/Done/Cancel/Escape, lock enforcement, position-only reset and scope-change cancellation.
- [x] 4.4 Update debug reports for every new setting and presentation state; ensure log clearing affects diagnostics only.

## 5. Verification and documentation

- [ ] 5.0 Verify standalone package contains all Ace dependencies and licenses; test both clients, no native Settings, unavailable libraries, repeated registration, old SavedVariables and color-picker cancellation.
- [x] 5.1 Add meaningful harness coverage for invalid/missing/surplus input, aliases, UI/CLI parity, scope/migration, demo isolation and Move rollback.
- [x] 5.2 Run required repository checks and tests; record results and any existing failures separately.
- [ ] 5.3 Verify in game: all owned surfaces, long localized content, missing APIs/integrations, combat interactions, opacity 0/80/100, scale and locked/unlocked movement.
- [ ] 5.4 Capture comparable screenshots and complete every coverage.md verification row.
- [x] 5.5 Update README, applicable listing text, manual test plan, localization, debug reports and both TOCs for new files.
- [x] 5.6 After implementation and validation, follow repo sync/archive/version/changelog rules; do not commit an active change.

## Implementation notes (2026-11-15)

- Source/API inspection, key/storage/units/refresh mapping and scenario reconciliation are recorded in implementation.md and README's Presentation commands table.
- 5.0: standalone dependency order, notices/licenses, real registry validation, missing libraries/native registration, repeated registration, old character data and guarded picker cancel are automated. Actual Classic Era/Forever loading and native controls remain unchecked until in-game acceptance.
- 5.3–5.4: require the user's game clients and captures; see docs/test-plan.md section 20 and coverage.md. No synthetic screenshots are claimed as client verification.
- 5.6: explicitly deferred at the user's request. Do not sync canonical specs, archive, bump versions, write the release changelog, commit or release in this pass.


Version amendment: the user explicitly requested a minor bump after implementation. Both TOCs now use 1.6.0 and CHANGELOG.md has the matching entry. This supersedes the earlier version/changelog deferral; the change remains active, with no canonical sync, archive, commit or release.


Slash entry amendment: by user request, bare `/cvn` now opens settings on Home, `/cvn help` displays addon information and commands, and `/cvn status` owns the current-value summary. This supersedes earlier retention/rejection statements about bare-command behavior; profile unification remains excluded.


Position/sound amendment: only the status window retains Lock position. Toast has no lock control or public lock key; legacy toastLocked data is ignored so it cannot prevent Move. Appearance > Toast now exposes Demo sound (shared with reminders), backed by the existing remindSound value also edited in Supplies or `/cvn sound`. None stays silent and live route notices remain silent. Regression tests cover a legacy locked toast entering Move and shared sound UI parity.


Settings layout amendment: visual consistency across the three addons is a primary user constraint. Inspected KeepThat/Options/Options.lua read-only as the concrete reference; edits remain confined to Closest Vendor. All CV pages now use full-width standard controls, grouped section headings, full-row gaps and neutral/muted text. Appearance separates Notices and previews, Status window and Toast into standard tabs. Standalone defaults to 900×700 with normal user resizing. About matches KT's large name, small grey version, purpose sentence and individual command rows with grey explanations. Repeated per-page This character text is removed; the title retains scope and Advanced explains it. No settings, defaults or actions are removed. Actual cross-addon visual comparison at matching scale remains an in-game check.


Context-first UX review: every page and Appearance tab now explains its purpose in player terms. Visible section notes precede the related choices and explain warning versus purchase counts, automatic buying consequences, applicable class behavior, routing/provider/instance rules, safe samples, position transactions, shared sound use and the diagnostic workflow. Threshold/action labels name the actual decision; deeper detail stays in tooltips. About retains KT's hierarchy with command-purpose rows. Tests check page/tab context and purchase/preview/diagnostic consequence placement; actual readability and first-use comprehension remain in-game acceptance.


Report/control-width correction: matched the real KT Debug/Export.lua read-only reference using standard AceGUI Frame + MultiLineEditBox, title, status copy hint, Fill layout, no submit button, read-only text and proper release/reopen handling. Existing native report and chat fallback remain available if AceGUI is missing or fails. Dropdowns now use bounded content widths (255 units for short choices, up to 374 for longer labels) instead of full-page stretch; section guidance and other readable rows are retained. Required tests now pass across 23 Lua test files and 52 Python tests; new report tests cover copy/read-only/close/reopen and existing Core tests cover library-unavailable fallback. In-game matching-scale comparison remains pending.


Screenshot review (Screenshot 2026-11-15 164445.png): confirmed CV's 900×700 default was much larger than KT's current 600×460. CV now uses the same 600×460 initial size and 1.5-unit standard control widths for dropdowns/sliders/buttons, with full-width text and checkbox labels. Longer labels were shortened while retaining their visible section context. Found and fixed introduction order: AceConfig sorts negative orders last, so intro order is now zero. Tests cover the matched default dimensions, compact widths and intro-before-controls ordering. User resizing remains under AceConfig; no saved gameplay/appearance values are reset. Actual updated matching-scale screenshot review remains pending.

Supersedes the Demo audio and Position/sound amendments above (2026-11-15): every notification follows the chosen style and plays the one notification sound; the sound control lives only on Appearance > Notifications; route notices are no longer silent; `/cvn demo` is the real routing tour that restores the previous waypoint. See coverage.md.
