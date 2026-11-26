## ADDED Requirements

### Requirement: Test settings mode
`/cvn testsettings on` SHALL put the character's settings, status window position and toast position aside and use the defaults a new character gets. While on, every setting change, Move and the settings panel SHALL change only the test set. `/cvn testsettings off` SHALL restore the set put aside exactly. Learned places, the hearthstone point, professions, standings and the debug log SHALL NOT be affected.

#### Scenario: Own settings kept
- **WHEN** a character with "Navigate without asking" and bag threshold 4 types `/cvn testsettings on`, then `/cvn bags 200`, then `/cvn testsettings off`
- **THEN** the character has "Navigate without asking" and bag threshold 4 again

### Requirement: Repeated and refused switches
`on` while the mode is on SHALL reset the test set to the defaults and keep the set put aside. `off` while the mode is off SHALL change nothing and say so.

#### Scenario: Fresh defaults while on
- **WHEN** test settings are on and the player types `/cvn testsettings on` again after changing the bag threshold
- **THEN** the bag threshold is the default and `off` still restores the player's own settings

#### Scenario: Off when not on
- **WHEN** test settings are off and the player types `/cvn testsettings off`
- **THEN** chat says test settings are not on and no setting changes

### Requirement: Test settings last until turned off
The mode SHALL last across `/reload` and logout. While it is on, a chat line at login SHALL say so and name `/cvn testsettings off`.

#### Scenario: Across a reload
- **WHEN** test settings are on and the player reloads
- **THEN** the test set is still in use and chat says test settings are on

### Requirement: Switching ends what is open
Before switching, the addon SHALL end any open question, demo, preview, Move and pending color pick, so nothing begun under one set changes the other.

#### Scenario: Open question at the switch
- **WHEN** a purchase question is open and the player turns test settings off
- **THEN** the question closes and nothing is bought
