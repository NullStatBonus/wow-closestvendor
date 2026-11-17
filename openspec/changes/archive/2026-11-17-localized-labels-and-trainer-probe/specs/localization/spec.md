## ADDED Requirements

### Requirement: Labels for game data are translated
Names the addon shows for game data SHALL be in the player's language: pet diet names SHALL come from the translation table, and reagent names SHALL use the game's item name when it is loaded, English before. Matching SHALL stay by id (item id, pet family id), never by displayed text.

#### Scenario: Pet food question in another language
- **WHEN** a translation gives "Fleisch" for Meat and a Meat-eating pet needs food
- **THEN** the question says "pet food (Fleisch)"

#### Scenario: Reagent checkbox
- **WHEN** the game has loaded Arcane Powder's name in the player's language
- **THEN** the Reagents page shows that name on its checkbox
