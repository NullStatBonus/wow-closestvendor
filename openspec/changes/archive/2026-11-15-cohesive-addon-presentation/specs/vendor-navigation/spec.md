## MODIFIED Requirements

### Requirement: Automatic pin
When the map choice mode is `auto`, the addon SHALL set the waypoint without asking: with two candidates, the current-map one if the preference is `map` and the closer one if it is `distance`; with one, that one. It SHALL announce the target in chat and when notices are enabled, once as a notification in the selected Warning or Toast style, with the notification sound, for about five seconds, naming it with its zone and distance, and the other candidate when there were two.

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
- **THEN** the chat line and, when enabled, the selected on-screen presentation both name it with its zone and its distance in yards

#### Scenario: Notice names the other candidate
- **WHEN** two candidates existed
- **THEN** the notice also names the one that was not chosen, with its zone and distance

#### Scenario: Single candidate
- **WHEN** only one candidate existed
- **THEN** the notice names only the pinned target

#### Scenario: Notification sound
- **WHEN** the on-screen message is shown
- **THEN** the notification sound plays once (none when the sound is None)

#### Scenario: Silent on screen
- **WHEN** notices are off and the waypoint is set without asking
- **THEN** only the chat line appears and no notification sound plays

#### Scenario: Stays about five seconds
- **WHEN** the on-screen message is shown
- **THEN** it remains visible for about five seconds and then disappears

#### Scenario: Newer message replaces the older
- **WHEN** a second message is shown while the first is still visible
- **THEN** the second replaces it and stays for its own full time

#### Scenario: Game errors unaffected
- **WHEN** the game shows one of its own error messages
- **THEN** it keeps its usual appearance and duration

#### Scenario: No on-screen message available
- **WHEN** the client cannot show an on-screen message
- **THEN** the chat line is still printed and no error is raised

#### Scenario: Trainers
- **WHEN** a profession trigger is pinned in `auto` mode
- **THEN** the notice follows the same rules
