## MODIFIED Requirements

### Requirement: Hearthstone point
The addon SHALL note the player's position when an innkeeper asks to bind the hearthstone, with the place it names. When the bind location then matches that place, the noted position SHALL become the hearthstone point (at once where the client reports the bind, else at the next login or zone change), whether the name differs from the saved one or is the same (a bind again at the same inn). With the same name, only a question that named that place SHALL count. A question that named another place SHALL be forgotten once the bind location is read, so it cannot place a later bind. A bind the addon did not see SHALL be saved by name only, never at the position the player happens to have. A hearthstone bound before the addon was installed is unknown until it is bound again.

#### Scenario: Rebind
- **WHEN** the player binds at a new inn
- **THEN** the hearthstone point becomes the position where the innkeeper asked, even if the player walks away before the next zone change

#### Scenario: Rebind at the same inn
- **WHEN** the hearthstone point is saved by name only and the player binds again at that same inn
- **THEN** the hearthstone point gets the position where the innkeeper asked

#### Scenario: Bind not seen
- **WHEN** the bind location changes without an innkeeper question the addon saw, or the question named another place
- **THEN** the new point is saved by name with no position, and a dungeon search uses the last outdoor position until the player binds again

#### Scenario: Same name, no innkeeper question
- **WHEN** the player logs in or changes zone, the bind name is the saved one, and no innkeeper question for that place was seen
- **THEN** the saved point does not change
