# localization Specification

## Purpose
Allow the addon's own text to be translated without changing code, while always falling back to English.

## Requirements

### Requirement: English text is the key
Every player-facing sentence SHALL be looked up as `L["English sentence"]`; a sentence without a translation SHALL appear as written, and a missing entry SHALL never raise an error.

#### Scenario: No translation
- **WHEN** a sentence has no entry for the client's language
- **THEN** the English sentence is shown

#### Scenario: Translation present
- **WHEN** a locale file defines a sentence
- **THEN** the translated text is shown on a client in that language

### Requirement: Translator files
The addon SHALL ship an example locale file and a guide, and a test SHALL fail when the example (or a locale file) defines a sentence that does not exist in the code.

#### Scenario: Misspelled key
- **WHEN** a locale file contains a sentence that no code uses
- **THEN** the test fails

### Requirement: Safe chat text
Translated text printed to chat SHALL have any `|` character doubled so it cannot start a chat escape.

#### Scenario: Pipe in a translation
- **WHEN** a translation contains `|`
- **THEN** the printed line contains `||`

### Requirement: Labels for game data are translated
Names the addon shows for game data SHALL be in the player's language: pet diet names SHALL come from the translation table, and reagent names SHALL use the game's item name when it is loaded, English before. Matching SHALL stay by id (item id, pet family id), never by displayed text.

#### Scenario: Pet food question in another language
- **WHEN** a translation gives "Fleisch" for Meat and a Meat-eating pet needs food
- **THEN** the question says "pet food (Fleisch)"

#### Scenario: Reagent checkbox
- **WHEN** the game has loaded Arcane Powder's name in the player's language
- **THEN** the Reagents page shows that name on its checkbox
