## ADDED Requirements

### Requirement: Own waypoint check is exact
When navigation ends, the addon SHALL clear the game waypoint only when it holds the point the addon set, with a tolerance of 0.00001 of the map; a nearby waypoint of the player SHALL stay.

#### Scenario: Waypoint 0.0005 away
- **WHEN** the player replaced the addon's game waypoint with one 0.0005 away on the same map
- **THEN** navigation ending leaves it alone

