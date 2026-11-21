## ADDED Requirements

### Requirement: An unread item kind makes the list partly read
When the merchant list has an item whose kind (arrow, bullet or other) the game cannot tell yet, the list SHALL count as partly read, as for an item link not loaded: a known vendor's record SHALL NOT be replaced, and the list SHALL be read again when item data arrives while the window is open.

#### Scenario: Arrow kind not loaded yet
- **WHEN** the player opens a known arrow vendor and the game cannot yet tell that one of its items is an arrow
- **THEN** the vendor still counts as selling arrows, and the record is updated once the items load
