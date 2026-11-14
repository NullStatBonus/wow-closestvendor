# Spec Delta

## ADDED Requirements

### Requirement: No needless reads
The addon SHALL ignore events about units other than the player (a party or raid member's pet, gear or casts) and SHALL NOT read the bags for supplies while the master "Ammo and reagents" switch is off or every supply warning and the healthstone reminder is off.

#### Scenario: A party member's pet changes
- **WHEN** the game reports a pet change for `party1`
- **THEN** the addon evaluates nothing and reads no bag slot

#### Scenario: Every supply warning off
- **WHEN** bags change while food, water, pet food and the healthstone reminder are all off
- **THEN** no bag slot is read for supplies
