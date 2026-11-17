## MODIFIED Requirements

### Requirement: Hearthstone point
The addon SHALL note the player's position when an innkeeper asks to bind the hearthstone, with the place it names. When the bind location name then differs from the saved one and matches that place, the noted position SHALL become the hearthstone point, at once where the client reports the bind. A bind the addon did not see SHALL be saved by name only, never at the position the player happens to have. A hearthstone bound before the addon was installed is unknown until it is bound again.

#### Scenario: Rebind
- **WHEN** the player binds at a new inn
- **THEN** the hearthstone point becomes the position where the innkeeper asked, even if the player walks away before the next zone change

#### Scenario: Bind not seen
- **WHEN** the bind location changes without an innkeeper question the addon saw, or the question named another place
- **THEN** the new point is saved by name with no position, and a dungeon search uses the last outdoor position until the player binds again
