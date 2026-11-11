## ADDED Requirements

### Requirement: Direct pin
The addon SHALL offer a direct pin for a chosen condition and item that finds the nearest eligible target and sets the waypoint without asking, whatever the map choice mode is. It SHALL work in combat, being an explicit player action, and SHALL use the map preference to choose between candidates. It SHALL record what each pin was for, so that a trigger clearing removes only a pin of its own kind, while any merchant window still clears every vendor pin.

#### Scenario: Ask mode
- **WHEN** a direct pin is requested while the choice mode is `ask`
- **THEN** the waypoint is set and no question is shown

#### Scenario: Combat allowed
- **WHEN** a direct pin is requested in combat
- **THEN** the waypoint is set

#### Scenario: Other trigger clears
- **WHEN** a sell pin was declined and an ammo direct pin is set, then the sell condition clears
- **THEN** the ammo pin remains

#### Scenario: Merchant window
- **WHEN** any merchant window opens
- **THEN** every vendor pin is cleared, as before
