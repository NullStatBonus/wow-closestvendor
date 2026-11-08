# vendor-navigation Specification

## Purpose
Select the nearest eligible vendor to the player and present it through whichever waypoint/arrow addon is available.

## Requirements

### Requirement: Nearest eligible vendor
The addon SHALL choose the target with the smallest straight-line distance to the player among those on the player's continent that are not hostile-faction and that satisfy the required capability (sell, repair, or the ammo kind), or, for a profession trigger, among known trainers for that profession.

#### Scenario: Sell target
- **WHEN** a sell trigger fires
- **THEN** the nearest friendly-or-neutral vendor of any kind is chosen

#### Scenario: Repair target
- **WHEN** a repair trigger fires
- **THEN** only repair-capable vendors are considered

#### Scenario: Ammo target
- **WHEN** an arrow or bullet trigger fires
- **THEN** only vendors selling that ammo are considered

#### Scenario: Trainer target
- **WHEN** a profession trigger fires for Mining
- **THEN** only known Mining trainers are considered and the nearest is chosen

#### Scenario: Other professions ignored
- **WHEN** the nearest trainer teaches Herbalism and a farther one teaches Mining
- **THEN** the Mining trainer is chosen for a Mining trigger

#### Scenario: Hostile faction excluded
- **WHEN** the nearest vendor or trainer belongs to the opposing faction
- **THEN** it is skipped in favor of the nearest eligible one

### Requirement: No target available
If no eligible vendor exists on the player's continent, or the player's position is unavailable (for example inside an instance), the addon SHALL NOT set a waypoint and SHALL NOT raise an error.

#### Scenario: Inside a dungeon
- **WHEN** a trigger fires while the player has no map position
- **THEN** nothing is set and the trigger is retried when position becomes available

### Requirement: TomTom support
When TomTom is loaded, the addon SHALL set the vendor as a TomTom waypoint titled with the vendor name, and SHALL remove it when navigation ends.

#### Scenario: TomTom present
- **WHEN** TomTom is loaded and a target is chosen
- **THEN** a TomTom waypoint exists at the vendor and the arrow points to it

### Requirement: WaypointUI support
When TomTom is not loaded and WaypointUI's navigation API is available, the addon SHALL set the vendor as a WaypointUI destination titled with the vendor name, and SHALL clear it when navigation ends.

#### Scenario: WaypointUI present
- **WHEN** TomTom is absent, WaypointUI is loaded, and a target is chosen
- **THEN** WaypointUI navigates to the vendor

#### Scenario: Incompatible WaypointUI
- **WHEN** WaypointUI is loaded but lacks a method the addon needs
- **THEN** the addon falls back to the next available method without raising an error

### Requirement: Blizzard waypoint fallback
When neither TomTom nor WaypointUI is usable and the client supports user waypoints, the addon SHALL set the Blizzard user waypoint and super-track it, and SHALL clear it when navigation ends.

#### Scenario: Native waypoint only
- **WHEN** no arrow addon is usable and the client supports user waypoints
- **THEN** the Blizzard user waypoint is set at the vendor

### Requirement: Chat fallback
When no navigation method is available, the addon SHALL print the vendor name, zone and coordinates to chat.

#### Scenario: Era without TomTom
- **WHEN** the client lacks user waypoints and TomTom is not loaded
- **THEN** the vendor name, zone and coordinates are printed to chat

### Requirement: Low-cost evaluation
The addon SHALL evaluate vendors only when a trigger fires, not per frame, and SHALL compute distance without converting coordinates for non-selected vendors.

#### Scenario: Idle gameplay
- **WHEN** no bag or durability event fires
- **THEN** no vendor search runs

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
When the map choice mode is `auto`, the addon SHALL set the waypoint without asking: with two candidates, the current-map one if the preference is `map` and the closer one if it is `distance`; with one, that one. It SHALL announce the target in chat and as a silent on-screen message shown for about five seconds, naming it with its zone and distance, and the other candidate when there were two.

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
