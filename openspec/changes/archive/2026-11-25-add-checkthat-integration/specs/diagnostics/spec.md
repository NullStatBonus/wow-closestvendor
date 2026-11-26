## MODIFIED Requirements

### Requirement: Copyable report
`/cvn log` SHALL show a report that can be selected and copied, containing the addon version, client interface and build, locale, the waypoint method in use and the chosen preference, vendor counts, current settings, the CheckThat status (`working`, `not detected`, `too old` or `failed: <why>`), and the recorded entries. If a window cannot be created, it SHALL print the most recent entries to chat.

#### Scenario: Report with the log off
- **WHEN** the player runs `/cvn log` with the log off
- **THEN** the report is shown with the header and a note that the log is off

#### Scenario: No window available
- **WHEN** creating the window fails
- **THEN** the latest entries are printed to chat and no error is raised

#### Scenario: CheckThat status in the report
- **WHEN** the player runs `/cvn log` without CheckThat installed
- **THEN** the header has the line `CheckThat: not detected`
