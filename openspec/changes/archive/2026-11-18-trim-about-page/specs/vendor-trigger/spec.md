## MODIFIED Requirements

### Requirement: Settings panel
The addon SHALL expose Home, Restock (Ammo, Reagents, Supplies), Navigation, Appearance (Notifications, Status window, Sound), Advanced and About using AceConfig/AceConfigDialog and AceGUI, following settings-interaction. Home SHALL hold every switch that decides whether the addon acts: the warning switches with bag, durability and profession thresholds, Destination on another map with Preferred target, and On-screen notice. Ammo, Reagents and Supplies SHALL retain all existing feature, threshold, grade and buying controls. Navigation SHALL contain waypoint method, instance anchor and auction routing. Appearance SHALL contain notification style, Status window controls with Lock position first, visibility modes, visual previews and positioning. The notification sound SHALL be on the Appearance Sound tab. Advanced SHALL show character scope and diagnostics; About SHALL show version and purpose. `/cvn config`, `/cvn options` and `/cvn settings` SHALL open Home; `/cvn settings <page>` SHALL open a child page or tab by its own name. Changes SHALL use the same saved values, limits and immediate refresh as slash commands. Game-options entries SHALL use AceConfigDialog registration where supported; without native Settings the standalone Ace dialog and slash commands SHALL continue working.

#### Scenario: Change a threshold in the panel
- **WHEN** the player moves the bag slider to 4
- **THEN** the saved bag threshold is 4 and `/cvn` reports it

#### Scenario: Slash command and panel agree
- **WHEN** the player runs `/cvn ammo 500` and then opens the panel
- **THEN** the ammo slider shows 500

#### Scenario: Profession slider
- **WHEN** the player moves the profession slider to 25
- **THEN** the saved profession threshold is 25 and `/cvn` reports it

#### Scenario: Reagent slider
- **WHEN** the player moves the reagent slider to 10
- **THEN** the saved reagent threshold is 10 and `/cvn` reports it

#### Scenario: Switch a trigger off
- **WHEN** the player clears a trigger's checkbox
- **THEN** that trigger stops asking and its slider is disabled

#### Scenario: Ammo switch off
- **WHEN** the player clears "Ammo" in the Warnings section
- **THEN** ammo questions stop and the ammo slider has no effect and the reagent settings are unaffected

#### Scenario: Panel unavailable
- **WHEN** the client lacks native Settings registration
- **THEN** the addon still loads, slash commands work and the standalone Ace dialog opens

#### Scenario: Subcategories
- **WHEN** the client supports subcategories
- **THEN** the approved landmarks appear under Closest Vendor with a recognizable Status window section in Appearance

#### Scenario: Subcategories unavailable
- **WHEN** the client lacks subcategories
- **THEN** the standalone Ace tree contains every page and control without requiring native subcategories

#### Scenario: Lock first
- **WHEN** Appearance’s Status window section opens
- **THEN** the Lock position checkbox is its first control

#### Scenario: Only the player's rows
- **WHEN** a warrior opens the Status window page
- **THEN** the Reagents visibility mode remains visible but disabled with a reason when no class reagent or display-only item applies, consistent with status-window; irrelevant item-specific controls are not actionable
