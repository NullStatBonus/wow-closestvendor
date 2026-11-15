## ADDED Requirements

### Requirement: Presentation diagnostics
The report SHALL list notification enabled state, selected warning/toast style, toast position and appearance, HUD appearance and active character scope, and whether demo/preview/Move mode is active. Preview sample state SHALL be distinguishable from live state and SHALL NOT overwrite recorded real decisions.

#### Scenario: Report presentation
- **WHEN** `/cvn log` is run after selecting Toast
- **THEN** the report names Toast, notice enabled state and effective visual settings without changing them
