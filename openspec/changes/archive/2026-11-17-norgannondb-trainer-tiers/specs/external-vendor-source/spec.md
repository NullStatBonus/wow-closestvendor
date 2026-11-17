## ADDED Requirements

### Requirement: NorgannonDB profession trainers
When NorgannonDB (schema 1.4 or later) is installed, the addon SHALL read, on every map, the trainers whose English title is a rank (Journeyman, Expert, Artisan, Master) and a crafting profession noun, with the highest tier taught by the pre-2.3 rule (the tiers below the title), position, faction and the professions of the recipes they teach, in the player's language. Nothing SHALL be copied or saved.

#### Scenario: Master trainer
- **WHEN** NorgannonDB lists a trainer titled "Master Blacksmith" that teaches Blacksmithing recipes
- **THEN** it is a Blacksmithing trainer that teaches Artisan

#### Scenario: Specialization master
- **WHEN** a trainer is titled "Master Gnome Engineer"
- **THEN** it is not read from NorgannonDB

#### Scenario: Learned trainer
- **WHEN** a trainer the player opened is also in NorgannonDB
- **THEN** it keeps the learned position and gains the tier

#### Scenario: Report and late load
- **WHEN** NorgannonDB loads after login and the player runs `/cvn log`
- **THEN** its trainers are read without a reload, and the report counts the trainers with a tier
