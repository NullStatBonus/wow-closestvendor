# diagnostics Specification

## Purpose
Let a player capture what the addon saw and decided, so problems can be reported and in-game unknowns settled.

## Requirements

### Requirement: Debug log switch
The addon SHALL keep a debug log that is off by default, toggled with `/cvn debug on` and `/cvn debug off`, persisted between sessions, and holds at most 300 entries, dropping the oldest.

#### Scenario: Off by default
- **WHEN** the addon runs for the first time
- **THEN** nothing is recorded

#### Scenario: Bounded
- **WHEN** more than 300 entries are recorded
- **THEN** only the newest 300 are kept

### Requirement: What is recorded
While the log is on, the addon SHALL record the game events it reacts to, failures of guarded game calls, trigger decisions, the vendor found or why none was, and whether the question was shown, accepted or dismissed.

#### Scenario: Ammo use
- **WHEN** the log is on and inventory events arrive
- **THEN** each event name and its first argument are recorded

#### Scenario: Adapter failure
- **WHEN** a guarded game call fails
- **THEN** the failing call and its error text are recorded, once per kind of failure

### Requirement: Copyable report
`/cvn log` SHALL show a report that can be selected and copied, containing the addon version, client interface and build, locale, the navigation method in use, vendor counts, current settings, and the recorded entries. If a window cannot be created, it SHALL print the most recent entries to chat.

#### Scenario: Report with the log off
- **WHEN** the player runs `/cvn log` with the log off
- **THEN** the report is shown with the header and a note that the log is off

#### Scenario: No window available
- **WHEN** creating the window fails
- **THEN** the latest entries are printed to chat and no error is raised

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

### Requirement: Report lists supply settings
The report header SHALL have a line with food, water, pet food and the healthstone reminder each on or off, with the thresholds of food, water and pet food, and with the debug log on SHALL log each supply question or reminder decision (what was low, the count, and the target or why none).

#### Scenario: Header
- **WHEN** the player runs `/cvn log`
- **THEN** the header shows "supplies: food on (5), water on (5), pet food on (5), healthstone reminder on" on default settings

#### Scenario: Decision logged
- **WHEN** a food question is shown with the debug log on
- **THEN** the log records food, the count and the chosen vendor
