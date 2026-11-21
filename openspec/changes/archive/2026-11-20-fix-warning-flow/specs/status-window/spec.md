## ADDED Requirements

### Requirement: A click keeps the warning it closes
When a row click or a seller choice closes a warning's open question, or replaces a warning trip that is active, that warning SHALL NOT be lost or left blocking. When the click made its own condition the handled request, the closed warning SHALL be asked again after the clicked trip resolves, if its condition still holds. Otherwise it SHALL be asked again at the next check. While a clicked trip is active, a higher warning SHALL NOT replace it.

#### Scenario: Click a low row while a higher question is open
- **WHEN** the repair question is open, the player clicks the low Arcane Powder row, and then opens a merchant
- **THEN** no repair question is shown during the reagent trip, and the repair question is asked after the merchant window opens if gear is still worn

#### Scenario: Click a row that is not low
- **WHEN** the repair question is open and the player clicks the food row while food is not low
- **THEN** the food vendor is pinned, the repair question closes, and it is asked again at the next check

#### Scenario: Lower warnings are not blocked
- **WHEN** the player clicks a row that is not low while a repair question is open, and then answers No to the repair question when it is asked again
- **THEN** the next low warning is asked as usual
