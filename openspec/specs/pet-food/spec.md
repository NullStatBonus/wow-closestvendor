# pet-food Specification

## Purpose
Remind hunters when they carry little food their current pet eats and navigate to the closest vendor that sells such food.

## Requirements

### Requirement: Pet food follows the active pet
The addon SHALL watch pet food only for a hunter whose pet is out and whose creature family the game reports. The pet's diet SHALL come from a fixed table keyed by the family id, never from text. The count SHALL be the number of items in the bags that the diet covers. With no pet or an unknown family, nothing SHALL be watched.

#### Scenario: Bread and cheese eater
- **WHEN** a hunter's pet eats Bread and Cheese and the bags hold 3 Darnassian Bleu and 2 Mutton Chop
- **THEN** the pet food count is 3

#### Scenario: No pet out
- **WHEN** the hunter has no pet out
- **THEN** no pet food question is asked

#### Scenario: Pet changed
- **WHEN** the hunter dismisses a meat eater and calls a fruit eater
- **THEN** the watched items become fruit and the count follows

#### Scenario: Any client language
- **WHEN** the client language is not English and the hunter's pet is a Bear
- **THEN** the watched diet is the Bear's and pet food is asked as usual

#### Scenario: Unknown family
- **WHEN** the game reports a family id that the table does not hold
- **THEN** nothing is watched for pet food

#### Scenario: Other classes
- **WHEN** the player is not a hunter
- **THEN** pet food is not watched

### Requirement: Pet food trigger
When pet food is watched, enabled, and at or below its threshold, and the master "Ammo and reagents" switch is on, the addon SHALL ask about navigating to the nearest vendor that sells any item the pet eats, using the same question, map-or-distance choice, automatic mode and on-screen notice as other triggers. The question SHALL name the pet's diet and the count. An unreadable count SHALL NOT count as low.

#### Scenario: Pet food runs low
- **WHEN** a hunter's fruit-eating pet has 5 fruit items in the bags with the default threshold of 5
- **THEN** one question names pet food, the count and the nearest vendor that sells fruit

#### Scenario: Several diets
- **WHEN** the pet eats Bread and Cheese and one nearby vendor sells only cheese
- **THEN** that vendor is a valid target

#### Scenario: No repeat until cleared
- **WHEN** the question was answered No and the count stays low
- **THEN** it is not asked again until the count rises above the threshold and falls again

### Requirement: No vendor sells the pet's food
When no known vendor on this continent sells any item the pet eats, the addon SHALL print one line in chat saying so and SHALL show no dialog and set no pin.

#### Scenario: Meat-only pet
- **WHEN** the pet eats only Meat and no known vendor sells meat
- **THEN** one chat line says no known vendor sells food this pet eats

### Requirement: Pet food settings and commands
Pet food SHALL have an on/off setting, on by default, and its own count threshold from 1 to 40, default 5, saved per character. The addon SHALL provide `/cvn petfood <count>`, `/cvn petfood on|off` and `/cvn test petfood`. A count outside 1 to 40 SHALL print a message and change nothing. The settings page SHALL show the pet food controls only to hunters.

#### Scenario: Switch off
- **WHEN** the player runs `/cvn petfood off`
- **THEN** no pet food question is asked

#### Scenario: Test without a pet
- **WHEN** a hunter with no pet out runs `/cvn test petfood`
- **THEN** chat says there is no pet to feed and no dialog appears

#### Scenario: Non-hunter
- **WHEN** a mage opens the settings page
- **THEN** no pet food controls are shown
