## Purpose

Let a player capture what the addon saw and decided, so problems can be reported and in-game unknowns settled.

## ADDED Requirements

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
