## ADDED Requirements

### Requirement: Questions end with the place
When the player changes zone or enters an instance while a warning's question is open, the addon SHALL withdraw that question unanswered and SHALL ask the warning again at the next check where questions are allowed, from the new place. Combat SHALL NOT withdraw a question, and the player MAY answer it and route in combat. Questions from `/cvn test` and the demo SHALL NOT be withdrawn this way.

#### Scenario: Enter a dungeon with a question open
- **WHEN** the sell question is open and the player enters a dungeon
- **THEN** the question closes, nothing is asked inside, and the sell question is asked again after leaving

#### Scenario: Zone change
- **WHEN** the repair question is open and the player crosses into another zone
- **THEN** the question is asked again with the closest repair vendor from the new zone

#### Scenario: Combat
- **WHEN** a question is open and combat starts
- **THEN** the question stays open and Yes still sets the waypoint
