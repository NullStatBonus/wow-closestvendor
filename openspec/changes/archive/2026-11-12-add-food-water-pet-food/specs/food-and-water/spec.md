## Purpose
Remind players when the food or drink they carry runs low and navigate to the closest vendor that sells it, with separate settings for food and for water.

## ADDED Requirements

### Requirement: Food is watched for every class
The addon SHALL watch the number of food items in the player's bags for every class. Any food item counts: vendor goods, cooked or looted food, and conjured food. Items that restore only mana (drink) do not count as food.

#### Scenario: Mixed food counted
- **WHEN** the player carries 3 Tough Jerky, 2 cooked Spider Sausages and 1 Conjured Muffin
- **THEN** the food count is 6

#### Scenario: Warrior
- **WHEN** the player is a warrior with 2 food items
- **THEN** food is watched and counted as 2

### Requirement: Water is watched for mana classes only
The addon SHALL watch the number of drink items in the bags for Mage, Priest, Paladin, Shaman, Druid, Warlock and Hunter. Warriors and rogues SHALL have no water watched and SHALL never be asked about it. Any drink item counts, including conjured water.

#### Scenario: Rogue
- **WHEN** the player is a rogue with no drink
- **THEN** no water question is asked

#### Scenario: Conjured water counted
- **WHEN** a mage carries 4 Conjured Water and 2 Refreshing Spring Water
- **THEN** the water count is 6

### Requirement: Food and water trigger
When food or water is watched, enabled, and at or below its own threshold, and the master "Ammo and reagents" switch is on, the addon SHALL ask about navigating to the nearest vendor that sells that kind, using the same question, map-or-distance choice, automatic mode and on-screen notice as other triggers. The question SHALL name what to buy and the count. If the count cannot be read, it SHALL NOT count as low.

#### Scenario: Food runs low
- **WHEN** a warrior's food drops to 5 with the default threshold of 5
- **THEN** one question names food, the count and the nearest vendor that sells food

#### Scenario: Water and food low together
- **WHEN** both food and water are low
- **THEN** one question is asked, and the second only after the first resolves

#### Scenario: No repeat until cleared
- **WHEN** the food question was answered No and the count stays low
- **THEN** it is not asked again until the count rises above the threshold and falls again

#### Scenario: Unknown count
- **WHEN** bags cannot be read
- **THEN** no food or water question is asked

#### Scenario: No known seller
- **WHEN** no known vendor on this continent sells food
- **THEN** the addon prints one line in chat and shows no dialog

#### Scenario: Arrival ends the request
- **WHEN** the player opens a merchant window while a food or water question or pin is active
- **THEN** the question closes or the pin is removed

### Requirement: Food and water settings
Food and water SHALL each have an on/off setting, on by default, and their own count threshold from 1 to 40, default 5, saved per account. The master "Ammo and reagents" switch SHALL turn both off when it is off. The settings page SHALL show food and water controls; a class without water SHALL NOT be shown the water controls.

#### Scenario: Separate thresholds
- **WHEN** the player sets the food threshold to 10 and the water threshold to 3
- **THEN** food asks at 10 or fewer and water at 3 or fewer

#### Scenario: Water off
- **WHEN** the player switches water off
- **THEN** no water question is asked and food still asks

#### Scenario: Existing settings
- **WHEN** a player upgrades from a version without these settings
- **THEN** food and water are on, and no other setting changes

### Requirement: Food and water commands
The addon SHALL provide `/cvn food <count>` and `/cvn water <count>` to set the thresholds, `/cvn food on|off` and `/cvn water on|off` to switch them, and `/cvn test food` and `/cvn test water` to show the question now regardless of count, combat or settings. A count outside 1 to 40 SHALL print a message and change nothing.

#### Scenario: Set threshold
- **WHEN** the player runs `/cvn food 10`
- **THEN** the food threshold is 10

#### Scenario: Out of range
- **WHEN** the player runs `/cvn water 99`
- **THEN** a message says the range is 1 to 40 and the threshold is unchanged

#### Scenario: Water test for a rogue
- **WHEN** a rogue runs `/cvn test water`
- **THEN** chat says water is not used by this class and no dialog appears
