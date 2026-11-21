## ADDED Requirements

### Requirement: Trainer questions end with the place
When the player changes zone or enters an instance while a trainer question asked by a skill change or craft is open, the addon SHALL withdraw that question unanswered. The trainer SHALL be asked about again at the next skill change or craft where questions are allowed. Questions from `/cvn test` and the demo SHALL NOT be withdrawn this way.

#### Scenario: Enter a dungeon with a trainer question open
- **WHEN** the trainer question is open and the player enters a dungeon
- **THEN** the question closes and no trainer waypoint can be set from it
