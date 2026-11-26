## MODIFIED Requirements

### Requirement: Debug log switch
The addon SHALL keep a debug log that is off by default, toggled with `/cvn debug on` and `/cvn debug off`, persisted between sessions, and holds at most 1000 entries, dropping the oldest.

#### Scenario: Off by default
- **WHEN** the addon runs for the first time
- **THEN** nothing is recorded

#### Scenario: Bounded
- **WHEN** more than 1000 entries are recorded
- **THEN** only the newest 1000 are kept

## ADDED Requirements

### Requirement: Status window, settings and purchase questions are recorded
While the log is on, the addon SHALL record when the status window is shown or hidden and which rows it shows, only when that changes (never for a count alone, never during a demo, preview or Move); each setting change with its old and new value, once per change; a purchase question asked (after the game shows it) or declined, and a purchase that bought fewer than asked; a reminder held back (combat, instance, dead); and an auctioneer learned. A logging failure SHALL NOT switch the window off.

#### Scenario: Count change
- **WHEN** the free bag slots change but the rows and low flags stay the same
- **THEN** no status window line is recorded

#### Scenario: Setting changed
- **WHEN** the player types `/cvn bags 3` with the threshold at 2
- **THEN** `setting changed: bagThreshold 2 -> 3` is recorded once

#### Scenario: Replaced question
- **WHEN** a purchase question is replaced by a new one
- **THEN** no `declined` line is recorded
