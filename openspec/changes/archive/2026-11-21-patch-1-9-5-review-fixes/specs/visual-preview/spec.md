## ADDED Requirements

### Requirement: Demo ends without overwriting the player's point
At the end of the demo the addon SHALL NOT set its own earlier game waypoint when the game waypoint cannot be read. The demo and the waypoint clear SHALL use the same tolerance (0.00001 of the map) to tell the addon's point from the player's, so a point the player sets very near a demo pin stays.

#### Scenario: Unreadable slot at the end
- **WHEN** the addon had its own game pin, the player sets a waypoint in the last step, and the game cannot read the slot at the end
- **THEN** the player's waypoint stays

#### Scenario: Stop with a nearby player point
- **WHEN** the player sets a waypoint 0.0005 from a demo pin and the demo is stopped
- **THEN** the player's waypoint stays
