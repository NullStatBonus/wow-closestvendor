## ADDED Requirements

### Requirement: Test settings are recorded
While the log is on, the addon SHALL record `test settings: on (own settings put aside)`, `test settings: reset to defaults` and `test settings: off (own settings restored)` after each switch, `test settings: not on` for a refused `off`, and `test settings: on at login` after the login marker while the mode is on. A switch SHALL NOT be recorded as setting changes. The report header SHALL have the line `test settings: on` or `test settings: off`.

#### Scenario: Switch is not a setting change
- **WHEN** test settings are turned on with a bag threshold of 4 and the player then types `/cvn dur 100`
- **THEN** the log records `setting changed: durThreshold 20 -> 100` and no line for the bag threshold

#### Scenario: Report
- **WHEN** the player runs `/cvn log` with test settings on
- **THEN** the header has `test settings: on`
