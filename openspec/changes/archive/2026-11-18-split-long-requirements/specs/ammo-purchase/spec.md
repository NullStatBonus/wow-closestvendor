## MODIFIED Requirements

### Requirement: Ammo grade selection
The addon SHALL choose which item to buy by a grade mode set separately for arrows and for bullets: "same as equipped" (the default) buys the item in the ammo slot; "best usable" buys the merchant's ammo of the right kind with the highest required level the character meets; "cheapest" buys the lowest price per unit.

#### Scenario: Same as equipped
- **WHEN** Jagged Arrows are equipped, the mode is "same as equipped", and the merchant sells them
- **THEN** Jagged Arrows are bought

#### Scenario: Best usable
- **WHEN** the mode is "best usable", the character is level 30, and the merchant sells arrows requiring levels 1, 10, 25 and 40
- **THEN** the level 25 arrows are bought

#### Scenario: Separate modes
- **WHEN** arrows are set to "cheapest" and bullets to "same as equipped"
- **THEN** a bow buys the cheapest arrows and a gun buys the equipped bullets

#### Scenario: Item not sold
- **WHEN** the chosen item is not sold at this merchant
- **THEN** nothing is bought and a chat line says so

## ADDED Requirements

### Requirement: Ammo grade fallback
If the grade mode finds no item, or the equipped ammo is unknown, the addon SHALL fall back to the equipped item, and if the merchant does not sell that either, SHALL buy nothing and say so in chat.

#### Scenario: Equipped item not sold either
- **WHEN** neither the mode's item nor the equipped item is sold at this merchant
- **THEN** nothing is bought and a chat line says so
