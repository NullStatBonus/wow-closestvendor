# saved-settings Specification

## Purpose
Keep each character's settings separate while sharing what the addon learns about the world.

## Requirements

### Requirement: Settings are saved per character
The addon SHALL save every setting the player can change, the status window position, the known professions, the hearthstone point and the debug log (with its on/off state) separately for each character. Changing one on a character SHALL NOT change it on another.

#### Scenario: Two characters
- **WHEN** one character sets the bag threshold to 30 and another character on the same account logs in
- **THEN** the other character does not see 30

### Requirement: Learned places are shared by the account
The addon SHALL keep the vendors, trainers and auctioneers it learns in account-wide saved variables, so every character on the account uses them.

#### Scenario: A vendor learned by one character
- **WHEN** one character opens a merchant the addon did not know
- **THEN** another character on the account can be directed to it

### Requirement: A new character starts from the earlier settings
A character with no saved settings SHALL start from a copy of the account-wide settings and window position saved before settings were per character, or from the defaults when there are none. The copy SHALL NOT share tables with the original. A character that already has saved settings SHALL keep them.

#### Scenario: First login after the update
- **WHEN** a character logs in for the first time and the account holds old settings with a bag threshold of 7
- **THEN** its bag threshold is 7, and changing it later leaves the account copy and other characters alone

### Requirement: Retired saved keys are dropped
At load the addon SHALL remove the account-level `hearth`, `lastOutside`, `professions` and `log` keys that settings per character replaced, and the retired `toastLocked` setting. It SHALL keep the account-level `cfg` and `hud` as the seed for a new character.

#### Scenario: Old account keys
- **WHEN** a character logs in and the account still holds `hearth`, `lastOutside`, `professions` or `log`
- **THEN** those keys are removed and the seed settings stay

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
