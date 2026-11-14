# Proposal

## Why

The addon shows a waypoint with the first method available: TomTom, then WaypointUI, then the game's own waypoint, then chat. A WoW Forever player who has TomTom installed for other reasons cannot use the game's own 3D waypoint and map pin.

## What Changes

- A setting `navProvider` (auto, tomtom, waypointui, native), default auto. A chosen method is tried first; if it is missing or refuses, the usual order applies.
- `/cvn nav [name]` shows or sets it. A dropdown on the main settings page does the same. The `/cvn` status and the debug report show it.

## Capabilities

### Modified Capabilities
- `vendor-navigation`: adds the waypoint choice.

## Impact

`Nav.lua`, `Core.lua`, `Commands.lua`, `Options.lua`, tests, README, test plan, CHANGELOG. Saved per character like the other settings.
