## ADDED Requirements

### Requirement: Current-map and other-map candidates
For every vendor or trainer search the addon SHALL find, among targets eligible under the usual rules, the nearest one on the player's current map and the nearest one on any other map of the continent, and SHALL treat the two as separate candidates only when the other-map candidate is strictly closer than the current-map one.

#### Scenario: Other-map target is closer
- **WHEN** the nearest eligible vendor is on another map and a farther eligible vendor is on the player's map
- **THEN** both are candidates

#### Scenario: Current-map target is also nearest
- **WHEN** the nearest eligible vendor is on the player's map
- **THEN** it is the only candidate

#### Scenario: Nothing on the current map
- **WHEN** no eligible target is on the player's map
- **THEN** the nearest eligible target on the continent is the only candidate

#### Scenario: Map unknown
- **WHEN** the player's map cannot be read but a position is available
- **THEN** the nearest eligible target on the continent is the only candidate

#### Scenario: Trainers follow the same rule
- **WHEN** a profession trigger fires and the nearest trainer for that profession is on another map
- **THEN** the nearest trainer on the player's map, if any, is the other candidate

### Requirement: Automatic pin
When the map choice mode is `auto` and two candidates exist, the addon SHALL set the waypoint without asking, using the current-map candidate if the preference is `map` and the closer candidate if it is `distance`, and SHALL print one line naming the chosen target. With a single candidate, `auto` SHALL pin it without asking.

#### Scenario: Auto with map preference
- **WHEN** the mode is `auto`, the preference is `map`, and both candidates exist
- **THEN** the waypoint is set at the current-map vendor and no question is shown

#### Scenario: Auto with distance preference
- **WHEN** the mode is `auto`, the preference is `distance`, and both candidates exist
- **THEN** the waypoint is set at the closer vendor and no question is shown

#### Scenario: Auto respects the usual gates
- **WHEN** the mode is `auto` and the player is in combat or another vendor or trainer question or trip is active
- **THEN** nothing is pinned, as in `ask` mode
