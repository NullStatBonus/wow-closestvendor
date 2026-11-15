## Context

A–E were approved on 2026-11-15 with broad demo commands and CV Warning/Toast choice. This preparation changes specifications only. Don’t Do That is excluded. Runtime tasks remain unchecked. The browser sketch predates the amendments; normative delta requirements take precedence.

## Goals / Non-Goals

Goals: consistent visual roles and settings vocabulary, safe discoverable demonstrations, typed CLI access, accessible cues and deliberate positioning. Preserve gameplay, defaults, saved data, optional integrations and independent installation. Non-goals: suite launcher, new shared runtime library, global Blizzard reskin, DDT work, release or implementation in this pass.

## Decisions

1. Migrate from native Settings builders to AceConfig/AceConfigDialog with AceGUI, following KeepThat’s tree and game-options registration patterns. Use a stable namespaced application key and one option table for both entry points. Embed the minimal required Ace3 modules, LibStub and CallbackHandler with licenses and version provenance in the release; do not require either sibling addon. Keep the existing DB tables and scopes; adopting AceConfig does not authorize AceDB conversion or replacing the event/command architecture. Verify the bundled standard controls and actual client registration fallbacks before implementation.
2. Keep a versioned local style contract in each repo (shared contract version 1). Use 4-unit spacing and existing font objects; baseline toasts 280×40 with 28-unit icons, but grow for long copy. Use neutral content and small textual/symbolic semantic cues. Preserve item-quality titles on material detail pages.
3. UI and new get/set commands share a typed registry and refresh hooks. Public keys differ from storage keys; adapters normalize units at the boundary. Read existing command limits instead of duplicating them. Existing valid commands remain available.
4. Preview/demo use the real drawing components with injected synthetic state and inert side-effect callbacks. They must not enter production pin/buy/accept paths. Keep integration test commands separate. Do not persist samples or consume real deduplication/cooldowns. Restore current live state after the demo.
5. Move is a transaction: start snapshot, tentative drag, commit Done, restore Cancel/Escape. Scope change cancels. Existing unlocked CV title/Shift-drag shortcuts still save normally outside Move. All movement is blocked while locked.
6. New opacity controls separate surface and text/icon alpha. For KT old toastOpacity, preserve the effective alpha of both layers when splitting it; do not simply reset either to a brighter default. Black remains the default. Background alpha zero also hides decorative accents.
7. Keep existing settings scopes. CV stores new presentation values per character and keeps learned places account-wide. Toast is the default transient notice style; Toast is an independent presentation choice, not a switch enabling notifications. Retain the separate status window and interactive questions. Newer notices replace older notices with the existing five-second lifetime.

## Reconciliation and conflicts

- No active changes existed at preparation. Canonical specs are the baseline.
- status-window Demo formerly required hidden, randomized demos through real question/pin paths. The delta explicitly replaces that with discoverable synthetic drawing and inert callbacks; this is an intentional safety/interaction change authorized by the approved handoff, not a silent compatibility claim.
- status-window OLED-safe appearance formerly required text-color-only low state. The delta replaces this with neutral text plus a small warning symbol and visible low label, while keeping no-fill OLED behavior.
- vendor-trigger Settings panel previously put Status window last and omitted inapplicable reagent rows; status-window already requires disabled groups with explanations. The delta reconciles both to the approved landmarks and existing disabled-group rule.
- vendor-navigation Automatic pin keeps silent notices, timing, alternate-candidate content and replacement behavior, while routing each notice through the selected presentation.

## AceConfig migration details

Replace the native Settings registration/control builders rather than maintaining two competing editors. Slash settings entry points and the HUD cog open the AceConfigDialog Home tree. Register equivalent game Options > AddOns entries through AceConfigDialog where supported; lack of native Settings must not prevent the standalone Ace dialog. Avoid duplicate categories or callback registration across opens and refreshes. Option-table getters read existing character config; setters use shared validation/refresh, including guarded color-picker cancel behavior, dependent controls and row-mode restrictions. Embed only necessary libraries, record versions/licenses, load them before Options in both TOCs, and update packaging comments/checks that currently assume no libraries. Missing or failed libraries must leave events, commands and gameplay working and report why settings cannot open.

## Risks and migration

Long localized copy, absent settings registration or Ace controls, combat constraints and stale SavedVariables require explicit handling. Preserve previous values, validate only new public input with the existing bounds, and use guarded adapter APIs. Do not infer client APIs from the browser preview. Add new files to both TOCs when implementation begins. Tooltip coexistence must preserve native and third-party content without sibling dependencies.

## Validation and rollout

Run OpenSpec strict validation now. Later implement using the existing plain-Lua harness for validation, aliases, migration, preview side effects and Move transactions. Run repository-required checks and capture in-game Home, Appearance, tooltip, notice/toast and prompt at matching UI scale, long text, missing integrations/APIs, alpha 0/80/100 and supported addon scales 100/150. Compare against coverage.md. Update README, listing where relevant, manual test plan, localization and debug reports. Only then follow the repository sync/archive/version workflow; canonical specs are deliberately not synced during this preparation.
