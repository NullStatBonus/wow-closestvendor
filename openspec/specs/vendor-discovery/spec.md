# vendor-discovery Specification

## Purpose
Learn vendors that the shipped data lacks or has wrong, by recording merchants the player actually opens, and use them for navigation.

## Requirements

### Requirement: Record opened merchants
When a merchant window opens, the addon SHALL record that merchant's NPC id, name, repair capability, faction group, and the player's map position, keyed by NPC id, in saved variables.

#### Scenario: New vendor
- **WHEN** the player opens a merchant that is not yet known
- **THEN** it is stored and becomes eligible as a navigation target

#### Scenario: Repair vendor
- **WHEN** the merchant can repair
- **THEN** it is stored as repair-capable

### Requirement: Record ammo sold
When a merchant window opens, the addon SHALL also record whether the merchant sells arrows, bullets, both or neither, from the items it offers.

#### Scenario: Bullet vendor
- **WHEN** the player opens a merchant that offers bullets
- **THEN** it is stored as a bullet seller

#### Scenario: Stock changes
- **WHEN** a merchant is opened again and its ammo offer differs
- **THEN** the stored record is updated

### Requirement: Learned data wins
A learned vendor SHALL replace a shipped vendor with the same NPC id when building the search data.

#### Scenario: Moved or mispositioned vendor
- **WHEN** a learned record and a shipped record share an NPC id
- **THEN** only the learned position is used

### Requirement: Ignore non-targets
The addon SHALL NOT record merchants it cannot identify (no NPC id) and SHALL NOT raise an error when the player's position is unavailable.

#### Scenario: Unidentifiable merchant
- **WHEN** a merchant window opens and no NPC id can be read
- **THEN** nothing is recorded

### Requirement: Learned data persists and is bounded
Learned vendors SHALL persist across sessions, with at most one record per NPC id.

#### Scenario: Repeat visit
- **WHEN** the player opens the same merchant again
- **THEN** the record is updated, not duplicated

### Requirement: Record profession trainers
When a trainer window for a profession opens, the addon SHALL record that trainer's NPC id, name, faction group, the player's map position and the professions it teaches, keyed by NPC id, in saved variables shared by the account. Trainers that do not teach a profession SHALL NOT be recorded, and a trainer that cannot be identified (no NPC id) SHALL NOT be recorded.

#### Scenario: New trainer
- **WHEN** the player opens a Mining trainer window for the first time
- **THEN** the trainer is stored and becomes eligible as a navigation target for Mining

#### Scenario: Repeat visit
- **WHEN** the player opens the same trainer again
- **THEN** the record is updated, not duplicated

#### Scenario: Class trainer
- **WHEN** the player opens a class trainer window
- **THEN** nothing is recorded

#### Scenario: Position unavailable
- **WHEN** a profession trainer window opens and the player has no map position
- **THEN** nothing is recorded and no error is raised

#### Scenario: Shared across characters
- **WHEN** one character records a trainer and another character of the account needs that profession
- **THEN** the trainer is a candidate for the second character

### Requirement: Record reagents sold
When a merchant window opens, the addon SHALL also record which watched reagents the merchant offers, and SHALL keep that information when the merchant replaces a shipped record.

#### Scenario: Reagent vendor opened
- **WHEN** the player opens a merchant that offers Holy Candles
- **THEN** it is stored as a seller of that reagent and becomes a target for it

#### Scenario: Shipped reagent vendor opened
- **WHEN** the player opens a merchant that the shipped data lists as a reagent seller
- **THEN** its learned record still marks the reagents it sells

#### Scenario: Stock changes
- **WHEN** a merchant is opened again and its reagent offer differs
- **THEN** the stored record is updated
