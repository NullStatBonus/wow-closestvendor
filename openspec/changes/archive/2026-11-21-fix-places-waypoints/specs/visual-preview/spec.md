## ADDED Requirements

### Requirement: Demo keeps the game waypoint
When the game's own map waypoint holds the player's point (not one this addon set) before `/cvn demo` or between its steps, the addon SHALL note the newest such point. At the end of the tour (or when the tour is stopped), if the slot is empty or holds a point this addon set, the addon SHALL set the noted point again; if the slot holds the player's point, the addon SHALL leave it, and SHALL NOT put its own earlier waypoint over it.

#### Scenario: Game waypoint before the demo
- **WHEN** the player has a map waypoint of their own, the addon uses the game waypoint, and the demo runs to the end
- **THEN** the player's map waypoint is set again

#### Scenario: New waypoint during the demo
- **WHEN** the player sets a new map waypoint while the demo runs, and a later step uses the game waypoint
- **THEN** at the end the player's new waypoint is set again, not the one from before the demo

#### Scenario: New waypoint in the last step
- **WHEN** the addon had its own game waypoint before the demo and the player sets a new one in the last step
- **THEN** the player's waypoint stays and the addon's earlier waypoint is not set again
