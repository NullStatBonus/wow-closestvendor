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
