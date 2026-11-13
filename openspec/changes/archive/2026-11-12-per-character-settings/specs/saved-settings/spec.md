# saved-settings Specification

## Purpose
Keep each character's settings separate while sharing what the addon learns about the world.

## ADDED Requirements

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
