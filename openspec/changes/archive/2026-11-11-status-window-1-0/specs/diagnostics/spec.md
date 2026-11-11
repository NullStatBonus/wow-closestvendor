## ADDED Requirements

### Requirement: Report lists window settings
The report header SHALL list the status window settings (lock, scale, background opacity, background color, text opacity and each row mode that is not the default), the dungeon and raid anchor, and the auction house setting, and one line saying whether the color picker and settings button exist and whether the background color swatch was built (and what was missing if not), and the log SHALL record instance state changes and row clicks.

#### Scenario: Header
- **WHEN** the player runs `/cvn log`
- **THEN** the header shows the window, anchor and auction settings

#### Scenario: Click logged
- **WHEN** the player clicks a row
- **THEN** the log records which row and what was pinned

### Requirement: Report lists reagent buying
The report header SHALL have a line with reagent buying on or off, whether it asks first, and the amount of each reagent to carry, and with the debug log on each merchant visit SHALL log what reagent buying decided (off, amount 0, nothing watched, nothing sold, unreadable data, or the plan with its cost and why it fell short).

#### Scenario: Header
- **WHEN** the player runs `/cvn log`
- **THEN** the header shows "reagent buying: off, asks first, up to 20 of each" on default settings
