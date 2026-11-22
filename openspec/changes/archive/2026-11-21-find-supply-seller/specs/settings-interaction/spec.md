# Spec Delta

## ADDED Requirements

### Requirement: Find supplies on Home
Home SHALL end with a Find supplies section holding one standard text input labeled with its purpose. Submitting it SHALL run the same lookup as `/cvn find`. It SHALL store no setting and the other Home controls SHALL stay as they are.

#### Scenario: Submit from Home
- **WHEN** the player types an item name in Find supplies and confirms
- **THEN** the lookup runs and no saved setting changes

#### Scenario: Feature choices stay first
- **WHEN** Home is opened
- **THEN** the warning toggles and ranges come before the Find supplies section
