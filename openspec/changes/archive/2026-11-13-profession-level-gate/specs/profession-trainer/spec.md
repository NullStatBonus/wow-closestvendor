# Spec Delta

## ADDED Requirements

### Requirement: Trainers are not suggested below the tier's level
The addon SHALL NOT ask about a profession near its cap, nor mark it low in the status window, while the player's level is below the level the next tier requires: 10 for a cap of 75, 20 for 150, and 35 for 225. When the player's level cannot be read, the addon SHALL NOT apply this check.

#### Scenario: Too low for Expert
- **WHEN** a level 15 character reaches 150/150 in Cooking
- **THEN** no trainer question is asked

#### Scenario: Level reached
- **WHEN** the character is level 20 at 150/150
- **THEN** the trainer question is asked

#### Scenario: Level unreadable
- **WHEN** the player's level cannot be read
- **THEN** the profession is treated as before, with no level check
