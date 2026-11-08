## ADDED Requirements

### Requirement: Two-target question
When two candidates exist and the map choice mode is `ask`, the addon SHALL show one question with three buttons: the current-map target, the closer target, and Cancel. The question SHALL name both targets with their zones and distances, and the preferred target SHALL be the first button. Choosing a target SHALL start navigation to it; Cancel and Esc SHALL start nothing and SHALL count as declining.

#### Scenario: Choose the closer target
- **WHEN** the question shows two targets and the player picks the closer one
- **THEN** navigation starts at that target only

#### Scenario: Choose the current-map target
- **WHEN** the question shows two targets and the player picks the current-map one
- **THEN** navigation starts at that target only

#### Scenario: Cancel
- **WHEN** the player presses Cancel or Esc
- **THEN** no navigation starts and the same condition does not ask again until it has cleared and recurred

#### Scenario: Button order follows the preference
- **WHEN** the preference is `distance`
- **THEN** the closer target is the first button

#### Scenario: Single candidate keeps the plain question
- **WHEN** only one candidate exists
- **THEN** the usual Yes/No question names that target

### Requirement: Map choice settings
The addon SHALL provide a mode (`ask`, the default, or `auto`) and a preference (`map`, the default, or `distance`) for choosing between a current-map and a closer other-map target. Both SHALL be saved, shared by vendor and trainer questions, settable by slash command and by the settings page, take effect at once, and appear in the debug report.

#### Scenario: Defaults
- **WHEN** the addon loads with no saved choice
- **THEN** the mode is `ask` and the preference is `map`

#### Scenario: Change by command
- **WHEN** the player runs the command to set the mode to `auto`
- **THEN** the saved mode is `auto` and `/cvn` reports it

#### Scenario: Command and page agree
- **WHEN** the player sets the preference by command and opens the settings page
- **THEN** the page shows the same preference

#### Scenario: Invalid value
- **WHEN** the player gives a value other than the listed choices
- **THEN** nothing changes and the valid choices are printed
