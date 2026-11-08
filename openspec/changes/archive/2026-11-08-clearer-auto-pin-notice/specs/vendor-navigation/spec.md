## MODIFIED Requirements

### Requirement: Automatic pin
When the map choice mode is `auto`, the addon SHALL set the waypoint without asking: with two candidates, the current-map one if the preference is `map` and the closer one if it is `distance`; with one, that one. It SHALL announce the chosen target in chat and as a silent on-screen message, naming it with its zone and distance, and also the other candidate when there were two.

#### Scenario: Auto with map preference
- **WHEN** the mode is `auto`, the preference is `map`, and both candidates exist
- **THEN** the waypoint is set at the current-map vendor and no question is shown

#### Scenario: Auto with distance preference
- **WHEN** the mode is `auto`, the preference is `distance`, and both candidates exist
- **THEN** the waypoint is set at the closer vendor and no question is shown

#### Scenario: Auto respects the usual gates
- **WHEN** the mode is `auto` and the player is in combat or another vendor or trainer question or trip is active
- **THEN** nothing is pinned, as in `ask` mode

#### Scenario: Notice names the target
- **WHEN** a target is pinned in `auto` mode
- **THEN** the chat line and the on-screen message both name it with its zone and its distance in yards

#### Scenario: Notice names the other candidate
- **WHEN** two candidates existed
- **THEN** the notice also names the one that was not chosen, with its zone and distance

#### Scenario: Single candidate
- **WHEN** only one candidate existed
- **THEN** the notice names only the pinned target

#### Scenario: Silent on screen
- **WHEN** the on-screen message is shown
- **THEN** the addon plays no sound of its own

#### Scenario: No on-screen message available
- **WHEN** the client cannot show an on-screen message
- **THEN** the chat line is still printed and no error is raised

#### Scenario: Trainers
- **WHEN** a profession trigger is pinned in `auto` mode
- **THEN** the notice follows the same rules
