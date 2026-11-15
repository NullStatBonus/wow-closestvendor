## MODIFIED Requirements

### Requirement: Moving and locking
The window SHALL move when the title is dragged, or when Shift is held and the window is dragged anywhere. It SHALL stay on screen. The position SHALL be saved and restored. A "Lock position" setting SHALL block all moving, Shift-drag included, and SHALL be the first control in Appearance’s Status window section. The addon SHALL additionally provide transactional Move mode under visual-preview: Done saves, Cancel or Escape restores the starting position without writes, and a locked window cannot enter movement until explicitly unlocked. Existing title and Shift-drag shortcuts outside Move mode SHALL retain their immediate-save behavior.

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

### Requirement: OLED-safe appearance
The window SHALL default to a pure black background, SHALL draw no border and no bright fixed fill, and SHALL mark a low row with red row text, a red warning symbol and a visible low label; rows that are not low use neutral text. At background opacity 0 it SHALL draw nothing behind the text (no fill, border or texture), whatever the color. Text opacity SHALL apply to the title, the cog and every row, including rows added later, and not to the background.

#### Scenario: Background off
- **WHEN** the background opacity is 0, with any color
- **THEN** only the title, the cog and the row text are drawn

#### Scenario: Dimmed text
- **WHEN** the text opacity is 40
- **THEN** the title, the cog and every row are drawn at 40 percent, and the background keeps its own opacity

#### Scenario: Default color
- **WHEN** the player never chose a color, or the saved one is not a color
- **THEN** the background is pure black

### Requirement: Demo
The addon SHALL accept and document `/cvn demo` in help, About and README as the real routing tour defined in visual-preview. While it runs, the status window SHALL show representative made-up rows, including supplies and at least one low row; a click on one SHALL go nowhere. When the tour ends, current live rows SHALL return. Sample counts, modes and settings SHALL never persist. Legacy integration `test` commands SHALL retain their separate documented behavior.

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
