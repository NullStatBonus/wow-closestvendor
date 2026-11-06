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
