# slash-interface Specification

## Purpose
The common slash-command verbs and the typed public setting keys that commands and settings share.

## Requirements

### Requirement: Common command discovery
The addon SHALL expose settings, status, help, demo, preview, typed get/set, debug and log commands. Bare `/cvn` SHALL open Home; `/cvn help` SHALL display addon purpose, scope and commands; `/cvn status` SHALL report current settings. Existing valid domain commands SHALL remain available. Help, About and README SHALL document safe demo. Visual-preview supersedes old demo side effects.

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
- **THEN** no page opens Home; valid slugs match settings-interaction; status-window opens Appearance; invalid pages list valid choices without writes

#### Scenario: Topic help and status
- **WHEN** help or status is requested
- **THEN** help groups appearance, diagnostics and domain topics and rejects unknown topics with valid choices; status reports scope, effective values and feature availability

#### Scenario: Log purpose
- **WHEN** log or log clear is used
- **THEN** log opens a copyable report; new log clear confirms irreversible diagnostic-only clearing and never clears gameplay data

### Requirement: Allowlisted setting registry
Public keys SHALL be stable identifiers independent of SavedVariables paths. Entries SHALL declare type, enum/bounds, scope, getter, setter and refresh callback. UI and CLI SHALL share validation and effects. Arbitrary Lua paths or executable input SHALL be rejected. Get SHALL be read-only; invalid, missing or surplus input SHALL not write. New setters SHALL give one concise acknowledgement; valid legacy commands SHALL remain compatible.

#### Scenario: Invalid mutation
- **WHEN** an unknown key, invalid enum, fractional integer, out-of-range number or trailing argument is supplied
- **THEN** no value changes and the reply states valid syntax and values

#### Scenario: Single acknowledgement
- **WHEN** one new setter succeeds
- **THEN** one concise acknowledgement names the effective value

#### Scenario: Preserve names
- **WHEN** an existing find or named-item command receives mixed-case text
- **THEN** only command words are normalized and name/search behavior remains intact

#### Scenario: Parsing names
- **WHEN** a name/search command contains mixed-case text
- **THEN** only command words and enums are normalized; user-entered names/search text are preserved

#### Scenario: Targeted validation
- **WHEN** invalid input is rejected
- **THEN** the reply gives exact syntax and allowed values/bounds and no setting changes

### Requirement: Initial public settings
The initial public registry SHALL provide the keys, types, bounds, defaults and scopes in the Public key registry scenario. Existing saved values SHALL override new-install defaults. Existing numeric limits SHALL come from the shared command limits rather than copied constants. Additional keys SHALL be documented with validation and scenarios.

#### Scenario: Read and write the primary key
- **WHEN** `/cvn set bags.threshold 2` is followed by get for that key
- **THEN** get returns the same effective value and existing UI reflects it

#### Scenario: Public key registry
- **WHEN** a supported public key is read or written
- **THEN** the following registry applies; old stored alpha is migrated without changing effective brightness:

| Key | Type / bounds | New-install default | Scope |
| --- | --- | --- | --- |
| bags.threshold | integer, current Commands.LIMITS.bag bounds | 2 | character |
| appearance.notification-style | enum warning/toast | toast | character |
| appearance.hud.background-opacity | integer 0–100 | 80 | character |
| appearance.hud.text-opacity | integer 20–100 | 100 | character |
| appearance.hud.scale | integer 50–200 | 100 | character |
| appearance.hud.locked | boolean on/off | off | character |
| appearance.toast.background-opacity | integer 0–100 | 100 | character |
| appearance.toast.text-opacity | integer 0–100 | 100 | character |
| appearance.toast.scale | integer 50–200 | 100 | character |
