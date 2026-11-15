# Implementation record — 2026-11-15

Implementation is confined to this repository. No canonical spec sync, archive, version bump, changelog entry, commit or release was performed. In-game acceptance and screenshots remain open.

## Inspected standard controls and API contracts

Inspected the actual bundled upstream Ace3 source at `ac3d122`, including AceConfigDialog minor 93, AceConfigRegistry minor 22, AceGUI minor 41 and the standard widget constructors. Source and licenses: `ClosestVendor/Libs/PROVENANCE.md`. Primary API references: https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables and https://www.wowace.com/projects/ace3/pages/api/ace-config-dialog-3-0 .

- Registry `RegisterOptionsTable(appName, table)` is the minimal AceConfig registration entry point; `NotifyChange(appName)` refreshes open controls. The real bundled registry validates the generated table in `tests/test_options.lua`.
- Dialog `Open(appName)` and `SelectGroup(appName, page)` own standalone navigation. `AddToBlizOptions(appName, name)` uses `Settings.RegisterCanvasLayoutCategory`/`RegisterAddOnCategory` in this upstream revision. It is attempted once under pcall; its failure does not disable standalone access. No native builder/editor is retained.
- Standard AceGUI toggle, range, select, execute, description, header, inline group and tree controls are used. Disabled predicates retain stored values. Native button chrome is reused by Move controls; native StaticPopup drawing is reused with separate synthetic dialog IDs and inert callbacks.
- Existing Adapter picker uses guarded `SetupColorPickerAndShow` with swatch/cancel callbacks or the older `func`/`cancelFunc` fallback. The Appearance color action uses that same adapter, restoring the original RGB on cancel. It does not depend on unverified Ace color cancellation behavior. No picker means explanatory text plus the existing color command.
- Font creation tries the preferred existing client template, then GameFontHighlight/GameFontNormal under pcall. No global font or tooltip edits, sibling hooks, or tooltip-order framework are introduced.
- Escape registration enters UISpecialFrames only during Move and removes the frame afterward. OnHide calls the same transactional Cancel; normal Escape does not hide the HUD through this registration.

These are source/harness contracts, not claims of measured Classic Era/Forever client behavior. Actual controls, combat, fonts, native registration, popup coexistence and rendering must still be verified on both clients (test plan section 20).

## Public registry, units and scope

`Presentation.KEYS` declares stable public keys, storage mapping, type, enum/bounds, default, character scope, getter, setter and refresh. README's Presentation commands table documents every initial key and storage field. All values are whole percentages except boolean locks, the warning/toast enum and the bag count. Bounds reference `Commands.LIMITS`. UI public-key controls call the same `Presentation.Set` validator as CLI; Core's refresh evaluates normal features and redraws owned surfaces, and Ace NotifyChange updates open settings.

Home/Ammo/Reagents/Supplies/Navigation retain domain controls and existing storage. Character `hud` and `toast` hold separate anchors; learned places stay account-wide. CV already had split HUD alpha and had no old whole-toast alpha setting: existing effective HUD brightness is retained and toast gets new defaults. The KT whole-toast migration recommendation therefore requires no CV data conversion. No scope/profile switching exists; no new switch was invented.

Settings/config/options default Home; status-window aliases Appearance. Page/topic/kind names and key bounds are listed by commands and README. Only command words/enums are normalized; legacy reagent text remains mixed-case until its normal lookup. Legacy bare `/cvn` and live integration `test` commands retain their roles.

## Runtime boundaries and recommendation reconciliation

Synthetic HUD rows are generated through Status with a copied configuration. Core samples use the real Tracker, warning and Toast renderers with independent sample instances, timers and a dedicated native prompt; no controller, nav, purchase, learning or acceptance callback enters this path. The obsolete controller demo implementation was removed. Real row refreshes continue during samples; expiry draws current live rows. Replacement tokens prevent stale sample timers from ending newer samples or Move.

Movement uses a plain-Lua position transaction and each surface's clamped real frame. Tentative drags do not mutate saved anchors; only Done writes. Cancel/Escape/locking rolls back; reset changes only position. The fixed character scope means there is no user-accessible scope-change action to cancel; beginning a different Move cancels the prior transaction. Normal HUD title/Shift-drag and row click behavior remain covered.

Warnings and toasts use the same live route text and existing notice gates; the presentation choice does not enable notices. Class reminders have a separate warning notifier so style changes do not change their meaning. Real notices remain five seconds; isolated visual samples last ten. Interactive production questions and buying guards are unchanged.

No material detail pages exist in CV; F4 is addressed by retaining existing row/item content and quality formatting, adding bounded wrapping/growing layout, and leaving long-label client acceptance open. DDT, shared runtime/suite launcher, cross-addon tooltip ordering, profile unification and changed bare-command behavior remain excluded/deferred/rejected exactly as coverage.md specifies.

## Validation

See coverage.md for the final executed-check record. Tests include upstream option-table validation, missing libraries/registration/native APIs, immediate UI/CLI parity, character migration, invalid and surplus input, normal row interactions, safe sample acceptance and route retention, replacement timing, transactional save/cancel/lock/reset, font fallback, wrapping, mouse transparency and independent opacity. Mutation checks deliberately disabled registry rejection and Move saving; their corresponding tests failed, then the original code was restored.

Actual clients, combat restrictions, localization geometry, icon loading, native tooltip coexistence and screenshot comparison remain manual acceptance in `docs/test-plan.md` section 20. No screenshots are represented as captured by the automated harness.


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

Supersedes the Demo audio and Position/sound amendments above (2026-11-15): every notification follows the chosen style and plays the one notification sound; the sound control lives only on Appearance > Notifications; route notices are no longer silent; `/cvn demo` is the real routing tour that restores the previous waypoint. See coverage.md.
