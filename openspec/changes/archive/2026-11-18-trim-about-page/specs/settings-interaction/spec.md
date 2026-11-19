## MODIFIED Requirements

### Requirement: Settings landmarks
The addon SHALL expose six top-level pages in this order: Home, Restock (with Ammo, Reagents and Supplies as child pages), Navigation, Appearance (with Notifications, Status window and Sound tabs), Advanced and About, using AceConfig/AceConfigDialog and AceGUI. Home SHALL emphasize feature choices, Appearance SHALL own visuals/positioning, Advanced SHALL show diagnostics/scope, and About SHALL show name, version and purpose only. Existing feature controls SHALL remain reachable.

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

### Requirement: Consistent and spacious settings layout
Settings SHALL start at 600×460 like KeepThat and remain resizable. Pages SHALL use compact standard controls, readable headings and section gaps. Dropdowns SHALL fit their labels and choices. Appearance SHALL have Notifications, Status window and Sound tabs. About SHALL show a large name, a muted version and one purpose sentence, with no command list.

#### Scenario: Scan and resize
- **WHEN** any settings page is opened or resized
- **THEN** related controls remain grouped, complete labels are readable, and scrolling keeps every action reachable

#### Scenario: About consistency
- **WHEN** About opens
- **THEN** it shows the name, the version and the purpose sentence, and no commands; `/cvn help` and the README list the commands
