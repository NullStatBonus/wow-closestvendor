## ADDED Requirements

### Requirement: A later Yes buys only what is still needed
When the player answers Yes to the ammo purchase question, the addon SHALL read the room in the quivers or pouches and the money again and buy only what still fits and can be afforded, never more than the question named. When nothing is needed any more it SHALL buy nothing and print no "Bought" line.

#### Scenario: Bought by hand before Yes
- **WHEN** the question offers 400 arrows and the player buys 300 by hand before clicking Yes
- **THEN** Yes buys only the room left, at most 100 arrows, and the chat line names that amount and its cost

#### Scenario: Already full at Yes
- **WHEN** the quiver is full by the time the player clicks Yes
- **THEN** nothing is bought and no "Bought" line is printed

### Requirement: Required level not loaded yet
In "best usable" mode, an offered ammo item whose required level the game has not loaded SHALL count as item data not loaded yet. When no other offer can be chosen, the addon SHALL buy nothing, say nothing in chat, and try again when that item's data arrives, as for any item data not loaded yet.

#### Scenario: Level arrives after the merchant opens
- **WHEN** the mode is "best usable", the only arrows offered have a required level not loaded yet, and the data arrives a moment later
- **THEN** the purchase is made (or asked) once, with no "does not sell" line before it
