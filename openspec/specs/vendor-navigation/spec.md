# vendor-navigation Specification

## Purpose
Select the nearest eligible vendor to the player and present it through whichever waypoint/arrow addon is available.

## Requirements

### Requirement: Nearest eligible vendor
The addon SHALL choose the vendor with the smallest straight-line distance to the player among vendors on the player's continent that are not hostile-faction and that satisfy the required capability (sell, or repair).

#### Scenario: Sell target
- **WHEN** a sell trigger fires
- **THEN** the nearest friendly-or-neutral vendor of any kind is chosen

#### Scenario: Repair target
- **WHEN** a repair trigger fires
- **THEN** only repair-capable vendors are considered

#### Scenario: Ammo target
- **WHEN** an arrow or bullet trigger fires
- **THEN** only vendors selling that ammo are considered

#### Scenario: Hostile faction excluded
- **WHEN** the nearest vendor belongs to the opposing faction
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
