## ADDED Requirements

### Requirement: On-screen notice setting
The addon SHALL provide an on/off setting for the on-screen message shown when it pins a target automatically. It SHALL be on by default, saved, settable by `/cvn notice on` and `/cvn notice off` and by a checkbox on the settings page, take effect at once, and appear in the debug report. The chat line SHALL NOT depend on it.

#### Scenario: Default
- **WHEN** the addon loads with no saved choice
- **THEN** the on-screen message is on

#### Scenario: Switched off
- **WHEN** the player runs `/cvn notice off` and a target is pinned in `auto` mode
- **THEN** no on-screen message is shown and the chat line is still printed

#### Scenario: Switched back on
- **WHEN** the player runs `/cvn notice on` and a target is pinned in `auto` mode
- **THEN** the on-screen message is shown

#### Scenario: Command and page agree
- **WHEN** the player runs `/cvn notice off` and opens the settings page
- **THEN** the checkbox is cleared

#### Scenario: Invalid value
- **WHEN** the player runs `/cvn notice` with anything other than `on` or `off`
- **THEN** nothing changes and the valid choices are printed
