## MODIFIED Requirements

### Requirement: Demo
The addon SHALL accept and document `/cvn demo` in help and README as the real routing tour defined in visual-preview. While it runs, the status window SHALL show representative made-up rows, including supplies and at least one low row; a click on one SHALL stop the tour and route that row's kind for real, as in notification-presentation. When the tour ends, current live rows SHALL return. Sample counts, modes and settings SHALL never persist. Legacy integration `test` commands SHALL retain their separate documented behavior.

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
