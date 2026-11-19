## MODIFIED Requirements

### Requirement: Repair takes priority
When several triggers are active, the addon SHALL handle them one at a time in the order repair, ammo, reagent, food, water, pet food, sell, profession trainer. A lower-priority request SHALL NOT replace a higher-priority one that is still open or active.

#### Scenario: Both conditions active
- **WHEN** bags are at threshold and durability is below threshold
- **THEN** the target is the nearest repair vendor

#### Scenario: Repair and ammo both low
- **WHEN** gear needs repair and ammo is low
- **THEN** the repair question is asked first, and the ammo question only after it resolves

#### Scenario: Ammo before reagent
- **WHEN** ammo and a reagent are both low
- **THEN** the ammo question is asked first, and the reagent question only after it resolves

#### Scenario: Reagent before sell
- **WHEN** a reagent is low and bags are at threshold
- **THEN** the reagent question is asked first, and the sell question only after it resolves

#### Scenario: Reagent before food
- **WHEN** a reagent and food are both low
- **THEN** the reagent question is asked first, and the food question only after it resolves

#### Scenario: Food before water before pet food
- **WHEN** food, water and pet food are all low
- **THEN** they are asked in that order, each only after the previous resolves

#### Scenario: Pet food before sell
- **WHEN** pet food is low and bags are at threshold
- **THEN** the pet food question is asked first, and the sell question only after it resolves

#### Scenario: Lower priority does not replace
- **WHEN** a repair question is open and the sell condition becomes true
- **THEN** the repair question stays

#### Scenario: Trainer is lowest
- **WHEN** a sell question is open and a profession comes within its threshold
- **THEN** the sell question stays

#### Scenario: Trainer yields
- **WHEN** a trainer question is open and the sell condition becomes true
- **THEN** the sell question replaces it

#### Scenario: Replaced request returns
- **WHEN** a sell question is open, repair replaces it, and the player answers No to repair while bags are still full
- **THEN** the sell question is asked again

### Requirement: Settings panel
The addon SHALL expose Home, Restock (Ammo, Reagents, Supplies), Navigation, Appearance (Notifications, Status window, Sound), Advanced and About using AceConfig/AceConfigDialog and AceGUI, following settings-interaction. Changes SHALL use the same saved values, limits and immediate refresh as slash commands. Game-options entries SHALL use AceConfigDialog registration where supported; without native Settings the standalone Ace dialog and slash commands SHALL continue working.

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

## ADDED Requirements

### Requirement: Trips that cover selling
A repair or ammo trip SHALL also cover selling. A reagent, food, water, pet food or trainer trip SHALL NOT cover selling.

#### Scenario: Repair covers selling
- **WHEN** a repair trip is active and bags reach their threshold
- **THEN** no separate sell question is asked

#### Scenario: Reagent does not cover selling
- **WHEN** a reagent trip is active and bags reach their threshold
- **THEN** the sell question is asked after the reagent request resolves

### Requirement: When a request resolves
A request SHALL resolve when its condition clears, a merchant opens for it, the player answers No, or no vendor serves it. A request that a higher one replaces SHALL be asked again after that one resolves, if its condition still holds.

#### Scenario: Answer No
- **WHEN** the player answers No to a repair question while ammo is also low
- **THEN** the repair request resolves and the ammo question is asked

### Requirement: Settings page contents
Home SHALL hold every switch that decides whether the addon acts: the warning switches with bag, durability and profession thresholds, Destination on another map with Preferred target, and On-screen notice. Ammo, Reagents and Supplies SHALL retain all existing feature, threshold, grade and buying controls. Navigation SHALL contain waypoint method, instance anchor and auction routing.

#### Scenario: Home holds the switches
- **WHEN** the player opens Home
- **THEN** it shows the warning switches with their thresholds, Destination on another map, Preferred target and On-screen notice

#### Scenario: Navigation page
- **WHEN** the player opens Navigation
- **THEN** it shows waypoint method, instance anchor and auction routing

### Requirement: Appearance, Advanced and About contents
Appearance SHALL contain notification style, Status window controls with Lock position first, visibility modes, visual previews and positioning. The notification sound SHALL be on the Appearance Sound tab. Advanced SHALL show character scope and diagnostics; About SHALL show version and purpose.

#### Scenario: Sound tab
- **WHEN** the player opens Appearance
- **THEN** the notification sound is on its Sound tab

#### Scenario: About page
- **WHEN** the player opens About
- **THEN** it shows the version and the purpose

### Requirement: Opening a settings page
`/cvn config`, `/cvn options` and `/cvn settings` SHALL open Home; `/cvn settings <page>` SHALL open a child page or tab by its own name.

#### Scenario: Open Home
- **WHEN** the player runs `/cvn settings`
- **THEN** Home opens

#### Scenario: Open a page by name
- **WHEN** the player runs `/cvn settings navigation`
- **THEN** the Navigation page opens
