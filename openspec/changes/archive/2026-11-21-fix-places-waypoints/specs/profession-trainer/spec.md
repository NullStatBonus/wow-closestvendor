## ADDED Requirements

### Requirement: Unlearned profession
The addon SHALL count a profession that is no longer in the player's skills as a skill change. Its trainer waypoint SHALL end at the next readable skill update, as when a profession is no longer near its cap, also when profession warnings are off and on the first skill read of the session.

#### Scenario: Unlearn with a trainer waypoint
- **WHEN** a trainer waypoint for Mining is active and the player unlearns Mining
- **THEN** the waypoint ends at the next skill update

#### Scenario: Warnings off
- **WHEN** profession warnings are off, the player pinned a Mining trainer from the status window, and unlearns Mining
- **THEN** the waypoint ends
