# external-vendor-source Specification

## Purpose
Let the addon use vendors from an optional addon installed alongside it, so players in zones the shipped list does not cover are directed to a vendor before they have opened one.

## Requirements

### Requirement: Optional NorgannonDB source
When NorgannonDB is installed and reports a supported data schema (major 1, minor 4 or later), the addon SHALL read vendors from it. The addon SHALL work unchanged when it is missing, disabled or reports another schema, SHALL raise no error in those cases, and SHALL NOT copy, ship or save any of its data.

#### Scenario: Not installed
- **WHEN** NorgannonDB is not installed
- **THEN** the addon behaves as before and the debug report says it was not found

#### Scenario: Unsupported schema
- **WHEN** NorgannonDB reports a schema the addon does not support
- **THEN** no vendor is read from it and the debug report says the schema is not supported

#### Scenario: Malformed record
- **WHEN** one of its vendor records is missing a name, a position or a map
- **THEN** that record is skipped and the others are still used

### Requirement: Only the Forever-only maps are read
The addon SHALL read only vendors that have a position on Mount Hyjal, Riverglades, Shen'dralas, Zephras Isle or the Darkspear Islands, and SHALL NOT read the rest of the database.

#### Scenario: New zone vendor
- **WHEN** NorgannonDB lists a vendor in Riverglades
- **THEN** that vendor is available to the nearest-vendor search

#### Scenario: Older zone vendor
- **WHEN** NorgannonDB lists a vendor in Elwynn Forest
- **THEN** that vendor is ignored and the shipped list is used for Elwynn Forest

### Requirement: Converted vendor record
Each vendor read SHALL become a record with its NPC id, name, map, position on that map (0 to 1), faction, whether it repairs, which ammo it sells, which class reagents it sells and which food, water and pet food it sells. The faction SHALL come from the database's reaction code. What it sells SHALL be worked out from its stock. A vendor whose map or position cannot be worked out SHALL be skipped.

#### Scenario: Repairer that sells food
- **WHEN** a vendor has the repair flag and sells bread
- **THEN** it is a repair vendor and a seller of food

### Requirement: Sources are one pool
Shipped, external and learned vendors SHALL be searched together and the nearest eligible vendor SHALL win, whatever its source. A source SHALL decide only which data is used when the same NPC id appears in more than one.

#### Scenario: Nearest wins across sources
- **WHEN** an external vendor is nearer than a shipped vendor and both are eligible
- **THEN** the external vendor is chosen

#### Scenario: Same vendor twice
- **WHEN** the same NPC id comes from two sources
- **THEN** it appears once in the search data

### Requirement: Precedence for the same vendor
For one NPC id, the external source SHALL take precedence over the shipped list. A learned record SHALL supply the flags (repair, ammo, reagents, supplies) and the faction when it has them, ahead of the external and shipped values. The position SHALL come from the external source, then the shipped list, unless a learned position differs from it by more than 3% of the map, in which case the learned position SHALL be used.

#### Scenario: Learned agrees
- **WHEN** a learned position is within 3% of the external position
- **THEN** the external position is used

#### Scenario: Vendor moved
- **WHEN** a learned position is more than 3% of the map from the external position
- **THEN** the learned position is used

#### Scenario: Observed flags win
- **WHEN** the external source says a vendor does not repair and the player opened it and saw it repair
- **THEN** it is treated as a repair vendor

### Requirement: Report line
The debug report SHALL say whether NorgannonDB was found, which schema it reports, and how many vendors it added.

#### Scenario: Found
- **WHEN** NorgannonDB is installed and 76 vendors were added
- **THEN** the report shows it found with its schema and 76 vendors

### Requirement: Cheap to read
The addon SHALL read the external source once after login, and once more if NorgannonDB finishes loading later, and SHALL NOT read it again on bag, merchant or movement events.

#### Scenario: Late load
- **WHEN** NorgannonDB finishes loading after the addon
- **THEN** its vendors are added without a reload

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
