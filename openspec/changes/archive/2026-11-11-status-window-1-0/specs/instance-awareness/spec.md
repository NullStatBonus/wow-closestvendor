## ADDED Requirements

### Requirement: Instance detection
The addon SHALL know whether the player is in a dungeon, raid, battleground or the open world. When the game cannot say, the addon SHALL treat the player as in the open world.

#### Scenario: Unknown state
- **WHEN** the instance state cannot be read
- **THEN** the addon behaves as in the open world

### Requirement: Triggers wait in instances
While the player is in a dungeon, raid or battleground, triggers SHALL NOT ask or pin, and SHALL NOT consume their one-time latch, so the question is asked once the player is back in the open world and the condition still holds.

#### Scenario: Full bags in a battleground
- **WHEN** bags cross the threshold inside a battleground and the player later leaves it with full bags
- **THEN** the question is asked after leaving

#### Scenario: Dungeon
- **WHEN** a trigger fires inside a dungeon
- **THEN** nothing is asked there, and it is asked after leaving if the condition holds

### Requirement: Last outdoor position
While in the open world with a known position, the addon SHALL remember the continent and position as the last outdoor position, and SHALL NOT update it while in an instance.

#### Scenario: Not updated inside
- **WHEN** the player is inside an instance
- **THEN** the last outdoor position is unchanged

### Requirement: Hearthstone point
The addon SHALL read the hearthstone's bind location name, and when it differs from the saved one and the player has a position, SHALL save that position as the hearthstone point. A hearthstone bound before the addon was installed is unknown until it is bound again.

#### Scenario: Rebind
- **WHEN** the player binds at a new inn
- **THEN** the hearthstone point becomes the player's position there

### Requirement: Anchor setting
A setting `instanceAnchor`, `hearth` (default) or `last`, SHALL choose where a row click searches from while the player is in a dungeon or raid. A battleground SHALL always use the last outdoor position. If the chosen anchor is unknown, the other known one SHALL be used; if neither is known, chat SHALL say that no target is known yet. `/cvn anchor hearth` and `/cvn anchor last` SHALL set it, and the settings page SHALL have a matching dropdown.

#### Scenario: Hearth anchor in a dungeon
- **WHEN** the player clicks a row in a dungeon with `hearth` set and a known hearthstone point
- **THEN** the closest vendor to the hearthstone point is pinned

#### Scenario: Fallback
- **WHEN** `hearth` is set but the hearthstone point is unknown and a last outdoor position exists
- **THEN** the vendor closest to the last outdoor position is pinned

#### Scenario: Battleground
- **WHEN** the player clicks a row in a battleground
- **THEN** the search starts from the last outdoor position whatever `instanceAnchor` is

#### Scenario: No anchor
- **WHEN** neither anchor is known
- **THEN** chat says no target is known yet and nothing is pinned

#### Scenario: Message says where
- **WHEN** a target is pinned from an anchor inside an instance
- **THEN** the chat line says the player is in an instance and which anchor was used
