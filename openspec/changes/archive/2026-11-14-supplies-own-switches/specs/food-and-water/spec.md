# Spec Delta

## ADDED Requirements

### Requirement: Supplies do not depend on the ammo switch
Food, water, pet food and the healthstone reminder SHALL each be controlled only by their own on/off setting. The "Ammo and reagents" switch SHALL NOT turn them on or off, and their settings controls SHALL NOT be disabled with it.

#### Scenario: Ammo off, food on
- **WHEN** the player switches ammo and reagents off and food is on with 3 food items carried
- **THEN** the food question is still asked

#### Scenario: Food off, ammo on
- **WHEN** the player switches food off and ammo on
- **THEN** no food question is asked and ammo questions still are
