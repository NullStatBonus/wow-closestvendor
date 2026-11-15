# Recommendation coverage and reconciliation

Every approved recommendation and related review suggestion is accounted for below. The implementation/evidence record below distinguishes completed code/harness work from pending client verification. DDT remains excluded. No normative requirement is satisfied solely by this table: the named delta or retained canonical requirement owns the behavior.

| ID | Recommendation | Disposition | Requirement / destination | Verification |
| --- | --- | --- | --- | --- |
| A1 | Spacing, font objects, neutral ink and native controls | Incorporated | shared-presentation / Local visual contract | Standalone install; missing controls |
| A2 | Semantic colors with visible labels; no brand-color conflation | Incorporated | shared-presentation / Meaningful color and readable content | Long content; category distinction |
| A3 | Black persistent surfaces, no decoration at alpha zero, independent dimming | Incorporated | shared-presentation / Independent visual dimming | Background off; new elements; upgrade |
| A4 | Compact 280×40 family, icons and variable height | Incorporated | notification-presentation / Compact toast presentation | Long route or subtitle |
| A5 | Native tooltip chrome and coexistence; no duplicate suite framework | Incorporated | shared-presentation / Local visual contract; design.md | Missing control API; independent install |
| B1 | AceConfig migration plus Home, feature pages, Appearance, Advanced, About | Incorporated | settings-interaction / Settings landmarks | Common landmarks; feature retention |
| B2 | Shared labels and disabled dependent controls with reasons | Incorporated | settings-interaction / Consistent control vocabulary | Disabled dependency |
| B3 | Accurate settings scope and immediate UI/CLI parity | Incorporated | settings-interaction / Settings scope and immediate parity | Two characters; scope switch; UI and CLI agree |
| B4 | Preserve domain pages and defaults | Retained with explicit regression coverage | vendor-trigger / Settings panel; status-window | Feature retention; old saved data |
| C1 | Common verbs; old commands and bare behavior | Incorporated | slash-interface / Common command discovery | Legacy entry point; grouped help |
| C2 | Typed public keys, bounds, scope and refresh callbacks | Incorporated | slash-interface / Allowlisted setting registry; Initial public settings | Invalid mutation; read/write primary key |
| C3 | Case preservation, surplus-argument rejection, concise replies | Incorporated | slash-interface / Allowlisted setting registry | Preserve names; invalid mutation; single acknowledgement |
| C4 | Copyable logs and confirmed diagnostic-only clear | Incorporated | slash-interface / Common command discovery | Report clearing |
| C5 | Every new setting included in diagnostics and docs | Incorporated | diagnostics / Presentation diagnostics | Report presentation; doc/check review |
| C6 | Public broad demo; focused previews retain integration tests | Incorporated | visual-preview / Broad synthetic demo; Focused visual previews | No side effects; repeat and restore; unknown kind |
| D1 | DDT compact banner, pinned explanations and purchase guards | Excluded by user | reference.md | No DDT files modified |
| D2 | CV selectable Warning/Toast, Toast default | Incorporated | notification-presentation / Per-character notification style | Default; Toast; persistent choice; interactive questions |
| E1 | Safe demo/preview accepts with inert callbacks; live restore | Incorporated | visual-preview / Broad synthetic demo | No side effects; repeat and restore |
| E2 | Explicit Move/Done/Cancel; Escape rollback; lock; clamp; reset only position | Incorporated | visual-preview / Transactional Move mode | Done; Cancel or Escape; Locked; profile change |
| E3 | Retain normal toast mouse transparency or HUD row clicks | Incorporated | visual-preview / Transactional Move mode | Normal input regression and in-game checks |
| F1 | Shared runtime library or suite launcher | Deferred / out of scope | design.md / Goals and Decisions | Independent install; reconsider only with measured duplication |
| F2 | Cross-addon tooltip ordering integration | Deferred | design.md; shared-presentation retains coexistence | No coupling or sibling hooks; future integration requires separate change |
| F3 | Profile system unification and changed bare /cvn behavior | Rejected for this change | settings-interaction; slash-interface | Two characters; Legacy entry point |
| F4 | Old screenshot material links and truncation | Evaluate current build; no speculative redesign | shared-presentation / Meaningful color and readable content; tasks 5.3–5.4 | Long-label in-game review; retain current material improvements |
| F5 | Tests, captures, fallback, docs, TOCs and archive/version workflow | Incorporated | tasks.md sections 2 and 5; design.md / Validation | Runtime verification remains unchecked |

| B5 | User amendment: migrate CV to AceConfig to match siblings | Incorporated | settings-interaction / Embedded AceConfig migration; design.md | Standalone release; saved data; missing library; unified entry points; color-picker cancellation |

## Baseline and dependencies

Canonical specs are the baseline; no active change existed at preparation. Explicit MODIFIED deltas reconcile hidden/side-effectful demo, color-only HUD low state, settings page order, and notice routing. Existing trigger priorities, timers, sounds and waypoint providers remain unchanged.

## Verification record

- Runtime implementation: implemented; completed tasks and remaining client/release work are recorded in tasks.md and implementation.md.
- Canonical specs: intentionally unchanged until implementation and normal sync/archive workflow.
- OpenSpec strict validation: PASS (`openspec validate cohesive-addon-presentation --strict --no-interactive`, 2026-11-15), no warnings. Planning artifacts complete according to `openspec status --change cohesive-addon-presentation --json`. Modified requirement names match canonical baseline; every delta requirement has scenarios.
- Browser visual is illustrative and predates CV style/demo amendments; written deltas control.


## Implementation evidence and remaining client acceptance — 2026-11-15

All recommendation IDs are reconciled below. “Pending client” is deliberate: automated assertions do not substitute for rendering, native control behavior or screenshots. Manual steps are in `docs/test-plan.md` section 20; earlier settings/color instructions were updated for AceConfig.

| IDs | Implemented / retained evidence | Remaining acceptance |
| --- | --- | --- |
| A1, A5 | Presentation contract v1; preferred client fonts with guarded fallbacks; AceGUI standard controls; native button template with functional text-button fallback; no tooltip/global reskin or sibling hooks. `test_options`, `test_presentation`; embedded dependency checks. | Pending client: standalone on both clients, preferred control/font absence, native/third-party tooltip coexistence. |
| A2 | Neutral HUD/toast titles and rows; low HUD rows restored to red text and symbol plus Low label (user request 2026-11-15); existing item text/quality escapes retained; HUD and toast wrap/grow. `test_tracker`, `test_toast`. | Pending client: long localized text, meaningful cues, full action labels and uncached icons. |
| A3 | Existing HUD black/color/independent alpha retained; new black toast has independent background and title/body/icon alpha, zero fill at alpha zero. CV had no legacy whole-toast alpha; KT migration does not apply here. `test_core`, `test_tracker`, `test_toast`. | Pending client: 0/80/100 alpha, 100/150 scale, newly created rows/icons. |
| A4 | Toast baseline 280×40, 28-unit icon, content-driven height, separate anchor/scale/opacity. `test_toast`. | Pending client: long target/zone/distance/reason/alternative layout. |
| B1, B5 | Replaced native builders with one namespaced AceConfig registry/dialog tree, standard AceGUI controls, ordered landmarks, shared entry points, optional native registration, existing DB and guarded Adapter picker. Bundled pinned libraries, licenses and both TOCs; packaging checks now require license/provenance and dependency order. `test_options` validates with the actual upstream registry; `test_core` covers UI refresh. | Pending client: actual Era/Forever loading, native registration, picker cancellation/repeated opens, combat and unavailable APIs. |
| B2 | Shared labels; disabled predicates retain values and explain feature/buying/class prerequisites. `test_options`. | Pending client: visual disabled states and explanations. |
| B3, B4 | Public settings UI/CLI share registry validation and refresh; existing per-character cfg/hud retained, new toast anchor character-local, learned data account-wide. No profile switch introduced. Domain feature controls/defaults preserved. `test_core`, `test_commands`, `test_options`, `test_presentation`, existing gameplay tests. | Pending client: two-character relog/upgrade, feature availability and normal buying/reminder behavior. |
| C1 | Bare command and valid legacy commands retained; settings/config/options/Home and status-window alias; grouped topic help, status with actual class availability; public demo in help/About/README. `test_commands`, `test_readme`, `test_presentation`. | Pending client: entry-point discoverability and installed providers. |
| C2, C3 | Nine typed keys, existing command bounds, explicit scope/get/set/refresh, whole-input validation, read-only get, one setter acknowledgement; legacy reagent names retain case until lookup. `test_presentation`, `test_commands`. Invalid-input mutation check fails when rejection is removed. | Pending client: open settings agree with CLI. |
| C4 | Existing copyable report retained; dedicated confirmation for diagnostic-only clearing. `test_core`, `test_log`. | Pending client: copy/paste and cancel/accept diagnostic confirmation. |
| C5 | Report includes all new effective values, style/notice gate, toast position, character scope and sample/Move state, separately from controller decisions. README, listing, localization guide, manual plan, TOCs, publishing/package notes updated. | Pending client: inspect report while demo/Move is active. |
| C6, E1 | Removed obsolete controller demo path. Core injects samples into real drawing components with separate sample warning/toast instances and native inert prompt, generation timers and current live HUD restoration. Class-specific focused preview explains absence. Legacy `test` remains live. `test_core`, `test_presentation`, `test_tracker`. | Pending client: all kinds, repeated demos, existing route/question, disabled features, class reminders and no real cooldown/sound/purchase changes. |
| D1 | DDT excluded: no DDT code or sibling repository modified. | No DDT work required. |
| D2 | Per-character toast default/warning enum independent from autoNotice. Route notifications use exactly the selected renderer with the original text/gates; class reminders use their separate warning notifier; production questions remain unchanged. Existing controller/nav tests retained. | Pending client: one/two candidates, silent five-second replacement, off state, real interactive questions and two-character persistence. |
| E2 | Plain-Lua Move transaction plus clamped HUD/toast placeholders with Done/Cancel; temporary Escape registration; lock cancellation; reset position only; starting another Move/preview cancels prior movement. Fixed character scope has no profile-switch UI. `test_presentation`, `test_tracker`, `test_toast`. Mutation disabling Done save is detected. | Pending client: screen-edge clamp, Escape and combat, lock mid-drag, reload persistence, normal Escape outside Move. |
| E3 | Normal toast mouse transparency restored after Move; HUD rows still forward real clicks and title/Shift-drag still saves outside Move. `test_toast`, `test_tracker`, `test_core`. | Pending client: actual mouse hit-testing and shortcuts. |
| F1, F2, F3 | Shared runtime/suite launcher and cross-addon tooltip ordering remain deferred; profile unification and bare-command change remain rejected. Ace libraries are embedded external UI dependencies, not a new suite runtime. | Future changes only; no sibling dependency. |
| F4 | Existing material/item content retained; no speculative material-page redesign. CV has no owned material detail pages. Bounded wrapping/growing HUD/toast layout added. | Pending client: long labels/item-quality text; capture current build for review. |
| F5 | Automated required checks run; matching TOCs and standalone notices/order verified. Source/API record in implementation.md. User-requested archive/version/changelog/commit/release workflow is deferred. | Pending client screenshots and both-client acceptance; no release actions performed. |

### Executed checks

- `make test`: PASS — 22 Lua test files, 52 Python tests; no remaining failures and no baseline failures identified.
- `make check`: PASS — both client TOCs, all shipped Lua entries, embedded notices/dependency order, matching file lists, unchanged 1.5.0 TOC versions and existing changelog consistency.
- `openspec validate cohesive-addon-presentation --strict --no-interactive`: PASS.
- `openspec status --change cohesive-addon-presentation --json`: planning artifacts complete (this is not in-game acceptance).
- All 51 shipped Lua files parse with LuaJIT `loadfile`.
- `git diff --check`: PASS.
- Mutation verification: disabling typed-set rejection fails `test_presentation`; disabling Move save fails `test_tracker`. Originals restored afterward; normal tests pass.

No in-game sessions or screenshot captures were available in this environment. Tasks 5.0 (actual clients), 5.3 and 5.4 remain open. Task 5.6 remains deferred by explicit user instruction. Canonical specs, release versions and changelog are unchanged.


Version amendment: the user explicitly requested a minor bump after implementation. Both TOCs now use 1.6.0 and CHANGELOG.md has the matching entry. This supersedes the earlier version/changelog deferral; the change remains active, with no canonical sync, archive, commit or release.


Slash entry amendment: by user request, bare `/cvn` now opens settings on Home, `/cvn help` displays addon information and commands, and `/cvn status` owns the current-value summary. This supersedes earlier retention/rejection statements about bare-command behavior; profile unification remains excluded.


Demo audio amendment: by user request, demo toasts preview the saved reminder sound once (None stays silent), preserving the saved choice and production cooldowns. Live route notices remain silent. Core tests cover selected sounds, replacement demos, None and unavailable audio APIs; real-client audio remains a manual check.


Upgrade/Move correction: Toast defaults only on fresh installs with neither account nor character SavedVariables. Existing users missing a valid style keep Warning, and valid saved choices remain untouched. Previously persisted automatic Toast values cannot safely be distinguished from deliberate choices; select Warning once to change those. Move placeholders temporarily use TOOLTIP strata above AceGUI FULLSCREEN_DIALOG and restore their normal layer on Done/Cancel. Existing lock behavior remains intact. Tests cover fresh/account/character upgrades, saved choices and visible toast Move layering.


Position/sound amendment: only the status window retains Lock position. Toast has no lock control or public lock key; legacy toastLocked data is ignored so it cannot prevent Move. Appearance > Toast now exposes Demo sound (shared with reminders), backed by the existing remindSound value also edited in Supplies or `/cvn sound`. None stays silent and live route notices remain silent. Regression tests cover a legacy locked toast entering Move and shared sound UI parity.


Settings layout amendment: visual consistency across the three addons is a primary user constraint. Inspected KeepThat/Options/Options.lua read-only as the concrete reference; edits remain confined to Closest Vendor. All CV pages now use full-width standard controls, grouped section headings, full-row gaps and neutral/muted text. Appearance separates Notices and previews, Status window and Toast into standard tabs. Standalone defaults to 900×700 with normal user resizing. About matches KT's large name, small grey version, purpose sentence and individual command rows with grey explanations. Repeated per-page This character text is removed; the title shows only Closest Vendor and Advanced explains scope. No settings, defaults or actions are removed. Actual cross-addon visual comparison at matching scale remains an in-game check.


Context-first UX review: every page and Appearance tab now explains its purpose in player terms. Visible section notes precede the related choices and explain warning versus purchase counts, automatic buying consequences, applicable class behavior, routing/provider/instance rules, safe samples, position transactions, shared sound use and the diagnostic workflow. Threshold/action labels name the actual decision; deeper detail stays in tooltips. About retains KT's hierarchy with command-purpose rows. Tests check page/tab context and purchase/preview/diagnostic consequence placement; actual readability and first-use comprehension remain in-game acceptance.


Title amendment: by user request, the settings title is only Closest Vendor, without This character or Shared Settings. Scope explanation remains in Advanced.


Report/control-width correction: matched the real KT Debug/Export.lua read-only reference using standard AceGUI Frame + MultiLineEditBox, title, status copy hint, Fill layout, no submit button, read-only text and proper release/reopen handling. Existing native report and chat fallback remain available if AceGUI is missing or fails. Dropdowns now use bounded content widths (255 units for short choices, up to 374 for longer labels) instead of full-page stretch; section guidance and other readable rows are retained. Required tests now pass across 23 Lua test files and 52 Python tests; new report tests cover copy/read-only/close/reopen and existing Core tests cover library-unavailable fallback. In-game matching-scale comparison remains pending.


Screenshot review (Screenshot 2026-11-15 164445.png): confirmed CV's 900×700 default was much larger than KT's current 600×460. CV now uses the same 600×460 initial size and 1.5-unit standard control widths for dropdowns/sliders/buttons, with full-width text and checkbox labels. Longer labels were shortened while retaining their visible section context. Found and fixed introduction order: AceConfig sorts negative orders last, so intro order is now zero. Tests cover the matched default dimensions, compact widths and intro-before-controls ordering. User resizing remains under AceConfig; no saved gameplay/appearance values are reset. Actual updated matching-scale screenshot review remains pending.

Notification simplification (user request 2026-11-15): a notification is a notification. Every route message, class reminder and test message goes through one Controller `notice` path, shows in the chosen Style (Toast or Warning) and plays the one notification sound (`remindSound`); a batch plays once; notice off means chat only and no sound. Appearance now has two tabs, Notifications (On-screen notice, Style, Sound, Preview, Toast controls hidden for Warning) and Status window; the Supplies and Toast sound duplicates and per-kind preview buttons are removed. Preview kinds are notice, hud, prompt. Tests: `test_controller` (route sound, notice-off silence, batch), `test_options` (tabs, single sound control, Warning hides Toast controls), `test_core` (sound end to end). Mutation checks: disabling the sound and the notice-off gate each failed tests.

Real demo restored (user request 2026-11-15): `/cvn demo` again runs real outcomes through the production code, now as a tour of seven steps every five seconds (auto pin with notification, question, food, water or pet food, arrows, repair row click, reminder or test notification), showing notifications even with notice off, removing each step's waypoint and question before the next, and restoring the player's previous waypoint at the end. Settings are only read; no trigger is marked handled. `test_core` covers real waypoint, question, sound, restore, unchanged settings, restart and missing timers; disabling the restore and the demo notice override each failed tests. Pending client: real vendor coverage per class and waypoint-provider restore with TomTom, WaypointUI and the game waypoint.

Settings layout (user request 2026-11-15): six top-level pages: Home, Restock (Ammo, Reagents, Supplies as child pages), Navigation, Appearance (Notifications, Status window, Sound tabs), Advanced, About. Home holds every switch that decides whether the addon acts: warning switches and thresholds, Destination on another map with Preferred target, and On-screen notice. Buying stays on Restock pages beside its consequence text. `/cvn settings <page>` opens child pages and tabs by name (`Options.PATHS`). `test_options` covers order, nesting, Home placement, no duplicate controls and path opening; upstream AceConfig validation passes.
