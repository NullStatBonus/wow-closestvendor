## MODIFIED Requirements

### Requirement: Common command discovery
The addon SHALL expose settings, status, help, demo, preview, typed get/set, debug and log commands. Bare `/cvn` SHALL open Home; `/cvn help` SHALL display addon purpose, scope and commands; `/cvn status` SHALL report current settings. Existing valid domain commands SHALL remain available. Help and README SHALL document safe demo. Visual-preview supersedes old demo side effects.

#### Scenario: Legacy entry point
- **WHEN** `/cvn` is used without arguments
- **THEN** settings opens on Home; the previous summary remains available through `/cvn status` and existing valid domain commands retain their behavior

#### Scenario: Grouped help
- **WHEN** `/cvn help appearance` is used
- **THEN** targeted examples, valid keys and preview kinds are shown instead of a monolithic command line

#### Scenario: Report clearing
- **WHEN** `/cvn log clear` is requested then cancelled
- **THEN** no diagnostic entries or gameplay data are cleared

#### Scenario: Explicit pages
- **WHEN** settings is used with no page or a case-insensitive page slug
- **THEN** no page opens Home; valid slugs match settings-interaction; status-window opens the Status window tab and notifications opens the Notifications tab of Appearance; invalid pages list valid choices without writes

#### Scenario: Topic help and status
- **WHEN** help or status is requested
- **THEN** help groups appearance, diagnostics and domain topics and rejects unknown topics with valid choices; status reports scope, effective values and feature availability

#### Scenario: Log purpose
- **WHEN** log or log clear is used
- **THEN** log opens a copyable report; new log clear confirms irreversible diagnostic-only clearing and never clears gameplay data

