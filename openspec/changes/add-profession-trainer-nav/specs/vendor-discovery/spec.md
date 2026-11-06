## ADDED Requirements

### Requirement: Record profession trainers
When a trainer window for a profession opens, the addon SHALL record that trainer's NPC id, name, faction group, the player's map position and the professions it teaches, keyed by NPC id, in saved variables shared by the account. Trainers that do not teach a profession SHALL NOT be recorded, and a trainer that cannot be identified (no NPC id) SHALL NOT be recorded.

#### Scenario: New trainer
- **WHEN** the player opens a Mining trainer window for the first time
- **THEN** the trainer is stored and becomes eligible as a navigation target for Mining

#### Scenario: Repeat visit
- **WHEN** the player opens the same trainer again
- **THEN** the record is updated, not duplicated

#### Scenario: Class trainer
- **WHEN** the player opens a class trainer window
- **THEN** nothing is recorded

#### Scenario: Position unavailable
- **WHEN** a profession trainer window opens and the player has no map position
- **THEN** nothing is recorded and no error is raised

#### Scenario: Shared across characters
- **WHEN** one character records a trainer and another character of the account needs that profession
- **THEN** the trainer is a candidate for the second character
