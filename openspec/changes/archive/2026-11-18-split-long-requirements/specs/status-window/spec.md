## MODIFIED Requirements

### Requirement: Row groups
Every row SHALL belong to one of six groups, keyed `ammo`, `reagents` (each class reagent and display-only item), `supplies` (the food, water and pet food rows), `bags`, `durability` and `professions` (each profession row). A saved mode under any other key SHALL be ignored.

#### Scenario: One mode for every profession
- **WHEN** the character has Mining near its cap and Cooking far from it, and Professions is `always`
- **THEN** both profession rows are shown; with Professions `low` only Mining is shown, and with `never` neither

#### Scenario: Stale per-row keys
- **WHEN** the saved row modes hold `prof:Mining = always` from an earlier build
- **THEN** it is ignored and the Professions group keeps its own mode

### Requirement: Moving and locking
The window SHALL move when the title is dragged, or when Shift is held and the window is dragged anywhere. It SHALL stay on screen. The position SHALL be saved and restored. A "Lock position" setting SHALL block all moving, Shift-drag included, and SHALL be the first control in Appearance's Status window section.

#### Scenario: Drag the title
- **WHEN** the window is unlocked and the player drags the title
- **THEN** the window moves and the position is saved

#### Scenario: Shift-drag
- **WHEN** the window is unlocked and the player holds Shift and drags a row
- **THEN** the window moves

#### Scenario: Locked
- **WHEN** the window is locked
- **THEN** neither dragging the title nor Shift-drag moves it

#### Scenario: Reset
- **WHEN** the player runs `/cvn hud reset`
- **THEN** the window returns to its default position

### Requirement: Demo
The addon SHALL accept and document `/cvn demo` in help and README as the real routing tour defined in visual-preview. While it runs, the status window SHALL show representative made-up rows, including supplies and at least one low row. When the tour ends, current live rows SHALL return. Sample counts, modes and settings SHALL never persist. Legacy integration `test` commands SHALL retain their separate documented behavior.

#### Scenario: Demo shows and restores
- **WHEN** `/cvn demo` runs
- **THEN** made-up rows show and when the tour ends current live HUD state returns

#### Scenario: Demo does not save
- **WHEN** a demo has finished
- **THEN** saved settings are unchanged

#### Scenario: Repeat
- **WHEN** demo is run during an existing demo
- **THEN** new rows replace old ones and the newer tour runs

#### Scenario: Demo covers supplies
- **WHEN** demo runs
- **THEN** the made-up rows include supplies, and the tour routes to a food seller and to water or pet food when the class uses them

#### Scenario: Existing route
- **WHEN** a real waypoint exists before a demo
- **THEN** the tour may replace it while running and restores it when the tour ends

## ADDED Requirements

### Requirement: Setting a group's mode
The Status window settings page SHALL list one mode dropdown per group in the order Ammo, Reagents, Supplies, Bag space, Durability, Professions, and `/cvn hud row <ammo|reagents|supplies|professions|bags|durability> low/always/never` SHALL set a group's mode.

#### Scenario: Dropdown order
- **WHEN** the player opens the Status window settings
- **THEN** the six mode dropdowns are listed as Ammo, Reagents, Supplies, Bag space, Durability, Professions

#### Scenario: Command sets a mode
- **WHEN** the player runs `/cvn hud row bags always`
- **THEN** the Bag space group is `always` and its dropdown shows it

### Requirement: Move mode
The addon SHALL also provide transactional Move mode under visual-preview: Done saves, Cancel or Escape restores the starting position without writes, and a locked window cannot enter movement until explicitly unlocked. Title and Shift-drag outside Move mode SHALL keep their immediate-save behavior.

#### Scenario: Done saves
- **WHEN** the player moves the window in Move mode and presses Done
- **THEN** the new position is saved

#### Scenario: Cancel restores
- **WHEN** the player moves the window in Move mode and presses Cancel or Escape
- **THEN** the window returns to where it started and nothing is saved

#### Scenario: Locked window
- **WHEN** the window is locked and the player chooses Move
- **THEN** Move mode does not start until the window is unlocked

### Requirement: Demo row click
A click on a made-up row during `/cvn demo` SHALL stop the tour and route that row's kind for real, as in notification-presentation.

#### Scenario: Click a demo row
- **WHEN** the tour is running and the player clicks a made-up repair row
- **THEN** the tour stops and the nearest repair vendor is pinned
