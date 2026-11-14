# Spec Delta

## ADDED Requirements

### Requirement: Waypoint method choice
The addon SHALL let the player choose the waypoint method: automatic (the default), TomTom, WaypointUI or the game's own waypoint, with `/cvn nav [name]` and a setting on the main settings page. A chosen method SHALL be tried first. When it is not available or does not set a waypoint, the addon SHALL use the usual order (TomTom, WaypointUI, game waypoint, chat). The choice SHALL be saved per character and shown by `/cvn` and in the debug report.

#### Scenario: Game waypoint with TomTom installed
- **WHEN** the player chooses the game waypoint and TomTom is also loaded
- **THEN** a vendor is shown with the game waypoint and not with TomTom

#### Scenario: Chosen method missing
- **WHEN** the player chose WaypointUI and it is not installed
- **THEN** the usual order is used
