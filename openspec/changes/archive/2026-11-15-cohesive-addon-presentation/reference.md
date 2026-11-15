# Approved design provenance

Approved by Paul on 2026-11-15: A shared style, B shared settings landmarks, C common CLI, D compact warning presentation, E safe previews and explicit positioning. Amendments: retain demo for broad visual tests; CV offers Warning / Toast (default) as a per-character choice. DDT is explicitly excluded from this work.

Local review: /Users/pauly/projects/wow-addon-style-review/REVIEW.md
Local handoff: /Users/pauly/projects/wow-addon-style-review/CLAUDE-HANDOFF.md
Illustrative visual: /Users/pauly/projects/wow-addon-style-review/shared-addon-preview.html

These are provenance references, not required runtime or spec dependencies. This change is self-contained. Written deltas include the approved amendments and take precedence over older visual or handoff wording. A sibling addon need not be installed. DDT-specific tiers, marks, pinned reasons, banners and purchase-button relabeling are excluded; CV’s existing interactive prompts retain semantics rather than being replaced by toasts.

Shared contract version: 1. Keep the equivalent requirements in the two repos aligned during implementation. Any intentional divergence must be recorded in coverage.md with a reason and supporting acceptance scenario.

Later user amendment: Closest Vendor SHALL migrate settings to AceConfig to match the other addons. This supersedes all earlier recommendations to retain native settings builders. Preserve existing SavedVariables and character/account scopes.

User amendment: Toast is the default for new users and missing/invalid notification-style values. Existing saved Warning or Toast choices remain unchanged; notification enablement remains independent.


Slash entry amendment: by user request, bare `/cvn` now opens settings on Home, `/cvn help` displays addon information and commands, and `/cvn status` owns the current-value summary. This supersedes earlier retention/rejection statements about bare-command behavior; profile unification remains excluded.


Demo audio amendment: by user request, demo toasts preview the saved reminder sound once (None stays silent), preserving the saved choice and production cooldowns. Live route notices remain silent. Core tests cover selected sounds, replacement demos, None and unavailable audio APIs; real-client audio remains a manual check.


Upgrade/Move correction: Toast defaults only on fresh installs with neither account nor character SavedVariables. Existing users missing a valid style keep Warning, and valid saved choices remain untouched. Previously persisted automatic Toast values cannot safely be distinguished from deliberate choices; select Warning once to change those. Move placeholders temporarily use TOOLTIP strata above AceGUI FULLSCREEN_DIALOG and restore their normal layer on Done/Cancel. Existing lock behavior remains intact. Tests cover fresh/account/character upgrades, saved choices and visible toast Move layering.


Position/sound amendment: only the status window retains Lock position. Toast has no lock control or public lock key; legacy toastLocked data is ignored so it cannot prevent Move. Appearance > Toast now exposes Demo sound (shared with reminders), backed by the existing remindSound value also edited in Supplies or `/cvn sound`. None stays silent and live route notices remain silent. Regression tests cover a legacy locked toast entering Move and shared sound UI parity.


Settings layout amendment: visual consistency across the three addons is a primary user constraint. Inspected KeepThat/Options/Options.lua read-only as the concrete reference; edits remain confined to Closest Vendor. All CV pages now use full-width standard controls, grouped section headings, full-row gaps and neutral/muted text. Appearance separates Notices and previews, Status window and Toast into standard tabs. Standalone defaults to 900×700 with normal user resizing. About matches KT's large name, small grey version, purpose sentence and individual command rows with grey explanations. Repeated per-page This character text is removed; the title shows only Closest Vendor and Advanced explains scope. No settings, defaults or actions are removed. Actual cross-addon visual comparison at matching scale remains an in-game check.


Title amendment: by user request, the settings title is only Closest Vendor, without This character or Shared Settings. Scope explanation remains in Advanced.

Supersedes the Demo audio and Position/sound amendments above (2026-11-15): every notification follows the chosen style and plays the one notification sound; the sound control lives only on Appearance > Notifications; route notices are no longer silent; `/cvn demo` is the real routing tour that restores the previous waypoint. See coverage.md.
