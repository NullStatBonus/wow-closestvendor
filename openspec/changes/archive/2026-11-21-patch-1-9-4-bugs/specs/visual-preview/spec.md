## ADDED Requirements

### Requirement: Demo end is safe
When a step timer cannot be scheduled, the demo SHALL end and the made-up status window rows SHALL go away. When the game waypoint cannot be read at the end, the addon SHALL NOT set the noted waypoint again and SHALL log why.

#### Scenario: Timer fails mid-tour
- **WHEN** the demo cannot schedule its next step
- **THEN** the demo ends and the real status window rows are back

#### Scenario: Unreadable game waypoint
- **WHEN** the game waypoint read fails at the end of the demo
- **THEN** no waypoint is set and the log says it was not set again

