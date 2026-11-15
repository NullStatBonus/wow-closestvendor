## Why

Paul approved the shared addon experience A–E on 2026-11-15, retaining broad `demo` commands and adding Closest Vendor Warning/Toast presentation choice. Closest Vendor needs explicit, testable requirements for that design rather than implementation inferred from a mockup.

## What Changes

- Introduce local shared visual tokens, accessible semantic cues and native-control-first presentation.
- Organize settings around Home, feature pages, Appearance, Advanced and About; migrate settings to AceConfig/AceConfigDialog with AceGUI, matching the other addons, while retaining saved scope.
- Add explicit settings/status/help/preview and allowlisted get/set commands while preserving valid legacy commands.
- Make demo a tour of real routes, questions and notifications that restores the previous waypoint; keep `preview` as the safe synthetic sample; keep integration test commands separate.
- Provide deliberate Move/Done/Cancel, independent opacity, position-only reset, and regression requirements.
- Add per-character Warning / Toast (default) for every notification (routes, reminders, tests), with one notification sound, without altering HUD, confirmations or navigation.

## Capabilities

### New Capabilities
- `shared-presentation`: Local style contract, semantic cues and resilient content layout.
- `settings-interaction`: AceConfig migration, common landmarks, existing persistence and safe editing behavior.
- `slash-interface`: Common verbs and typed public setting registry.
- `visual-preview`: Broad demos, focused previews and transactional positioning.
- `notification-presentation`: Warning/Toast choice for transient notices.

### Modified Capabilities
- `status-window`: HUD readability, Move mode, safe discoverable demo and OLED rules.
- `vendor-trigger`: Settings organization and notification controls.
- `vendor-navigation`: Selectable notice presentation with existing timing and routing.
- `diagnostics`: Report the new presentation settings.

## Impact

Spec preparation only; runtime changes are future unchecked tasks. No new shared runtime dependency, no Don’t Do That changes, no canonical sync, version bump, release or commit in this pass. Read `design.md`, `coverage.md` and `reference.md` before implementation.
