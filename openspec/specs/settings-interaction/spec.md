# settings-interaction Specification

## Purpose
How the settings window is organized and behaves: the six-page AceConfig tree, page context, control sizing and saved-setting safety.

## Requirements

### Requirement: Settings landmarks
The addon SHALL expose six top-level pages in this order: Home, Restock (with Ammo, Reagents and Supplies as child pages), Navigation, Appearance (with Notifications, Status window and Sound tabs), Advanced and About, using AceConfig/AceConfigDialog and AceGUI. Home SHALL emphasize feature choices, Appearance SHALL own visuals/positioning, Advanced SHALL show diagnostics/scope, and About SHALL show version/purpose/commands. Existing feature controls SHALL remain reachable.

#### Scenario: Common landmarks
- **WHEN** the settings UI opens
- **THEN** Home, Appearance, Sound, Advanced and About are reachable alongside feature-specific pages

#### Scenario: Feature retention
- **WHEN** a player uses an existing feature page after upgrading
- **THEN** its settings remain reachable and retain their gameplay effect

#### Scenario: AceConfig and domain content
- **WHEN** settings are reorganized
- **THEN** AceConfig provides the standalone settings tree and game-options entries where supported; Appearance keeps a recognizable Status window section with Lock position first and old entry points resolve to an equivalent destination

#### Scenario: Game options registration unavailable
- **WHEN** native Settings or game-options registration APIs are missing
- **THEN** the standalone AceConfigDialog remains accessible through settings commands and the HUD cog without errors

### Requirement: Settings scope and immediate parity
The title SHALL show only Closest Vendor, without scope suffixes. Advanced SHALL explain character settings and account-wide learned places. Persistence defaults SHALL remain unchanged. UI and slash setters SHALL share validation and refresh, applying valid changes without reload. A supported scope switch SHALL explain its effect, preserve both profiles and never silently copy or reset data.

#### Scenario: UI and CLI agree
- **WHEN** a public setting is changed by slash command while its page is open
- **THEN** the effective value and page agree and live visuals refresh without reload

#### Scenario: Two characters
- **WHEN** a setting changes on one character
- **THEN** the existing account/profile or character scoping rules are preserved after relog

#### Scenario: Scope switch
- **WHEN** a player selects a different supported profile scope
- **THEN** the effect is explained and switching back restores prior profile values

### Requirement: Consistent control vocabulary
Applicable controls SHALL use Background opacity, Text and icon opacity, Scale, Preview, Move, Lock position, Reset position, Record debug information and Show debug report. Dependent controls SHALL retain their values while disabled and explain the enabling prerequisite. Unsupported features SHALL NOT gain inert controls. Irreversible data-clearing UI actions SHALL require explicit confirmation; changing appearance SHALL NOT clear gameplay data.

#### Scenario: Disabled dependency
- **WHEN** a feature is off and its appearance controls are shown
- **THEN** the saved values remain visible with an explanation and cannot be accidentally overwritten

#### Scenario: Reset scope
- **WHEN** Reset position is used
- **THEN** only position resets and colors, scale, opacity, thresholds and profile data remain unchanged

### Requirement: Embedded AceConfig migration
The addon SHALL embed the required AceConfig, AceConfigDialog, AceGUI, LibStub and CallbackHandler dependencies with version and license provenance. Both TOCs SHALL load libraries before Options. Settings SHALL use the existing character configuration and shared validation/refresh, without converting persistence to AceDB or requiring sibling addons. Native control builders SHALL be replaced rather than duplicated.

#### Scenario: Standalone release
- **WHEN** a packaged release runs without sibling addons or externally installed Ace3
- **THEN** settings open and work through the bundled libraries on both supported clients

#### Scenario: Existing saved data
- **WHEN** a player upgrades from the native settings version and relogs
- **THEN** thresholds, buying choices, colors, alpha, row modes, position, character isolation and account-wide learned places are retained

#### Scenario: Missing settings library
- **WHEN** required libraries cannot load or settings registration fails
- **THEN** existing gameplay, events and slash commands still work and opening settings explains the failure without raising a Lua error

#### Scenario: Unified settings entry points
- **WHEN** /cvn settings, /cvn config, /cvn options or the HUD cog is used repeatedly
- **THEN** one Ace settings tree opens on Home with no duplicate game categories or callbacks, and optional game-options entries show the same effective values

#### Scenario: Color picker and dependent controls
- **WHEN** a background color change is cancelled or a feature disables its dependent controls
- **THEN** the original color is restored and disabled controls retain values and explain prerequisites using supported Ace controls

### Requirement: Consistent and spacious settings layout
Settings SHALL start at 600×460 like KeepThat and remain resizable. Pages SHALL use compact standard controls, readable headings and section gaps. Dropdowns SHALL fit their labels and choices. Appearance SHALL have Notifications, Status window and Sound tabs. About SHALL match KeepThat's hierarchy: large name, muted version, purpose sentence and command rows with muted explanations.

#### Scenario: Scan and resize
- **WHEN** any settings page is opened or resized
- **THEN** related controls remain grouped, complete labels are readable, and scrolling keeps every action reachable

#### Scenario: About consistency
- **WHEN** About is compared with KeepThat at matching UI scale
- **THEN** both share title, version, body and command-row hierarchy without a dense command paragraph

### Requirement: Context before settings decisions
Every page and Appearance tab SHALL explain its purpose before its controls in player language. Visible section guidance SHALL precede choices with material consequences, including automatic purchases, warning thresholds versus buying targets, shared sound behavior, safe previews and diagnostic clearing. Labels SHALL state the decision; tooltips MAY provide further detail.

#### Scenario: Understand without hovering
- **WHEN** a player opens any page without prior documentation
- **THEN** its purpose and related decisions are explained visibly, including confirmation consequences before enabling automatic buying

### Requirement: Consistent debug report window
The debug report SHALL use the standard AceGUI Frame and MultiLineEditBox presentation used by KeepThat: titled chrome, scrolling, a close button, visible copy instructions and selected read-only text. Missing or failed AceGUI SHALL retain the existing native-window/chat fallback.

#### Scenario: Copy and reopen
- **WHEN** the report is opened, edited accidentally, closed and opened again
- **THEN** its text remains unchanged and copyable, and reopening shows current diagnostics without leaving duplicate windows
