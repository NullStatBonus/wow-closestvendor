## ADDED Requirements

### Requirement: Supply rows
The status window SHALL have a sixth row group, Supplies, listed after Reagents on the settings page, with one mode dropdown (`low`, `always`, `never`, default `low`) and `/cvn hud row supplies low|always|never`. It SHALL hold a Food row for every class, a Water row for classes that use mana, and a Pet food row for a hunter whose pet's family is known. Each row SHALL show the count of matching items in the bags.

#### Scenario: Water for a warrior
- **WHEN** a warrior's Supplies group is `always`
- **THEN** there is a Food row and no Water row

#### Scenario: Pet food without a pet
- **WHEN** a hunter has no pet out and Supplies is `always`
- **THEN** there is no Pet food row

#### Scenario: Next to the conjured rows
- **WHEN** a mage has Reagents set to `always` and Supplies set to `always`
- **THEN** the window shows the Conjured Food and Conjured Water rows and the Food and Water rows

### Requirement: Supply rows follow the warnings
A supply row SHALL be marked low by the same test as the warning for that item, including the master switch. A count the game cannot read SHALL hide its row, and a group set to `never` SHALL not read the bags. Clicking a supply row SHALL pin the nearest seller of that item without a question.

#### Scenario: Low food shown
- **WHEN** a warrior has 3 food items and Supplies is `low`
- **THEN** the window shows a Food row marked low

#### Scenario: Not low and mode low
- **WHEN** the warrior has 20 food items and Supplies is `low`
- **THEN** no Food row is shown

#### Scenario: Row follows the warning
- **WHEN** food is switched off or the master switch is off
- **THEN** no supply row is marked low

#### Scenario: Never reads
- **WHEN** the Supplies group is `never`
- **THEN** the bags are not read for it

#### Scenario: Click a supply row
- **WHEN** the player clicks the Water row
- **THEN** the nearest water seller is pinned with no question; with no known seller, chat says so

## MODIFIED Requirements

### Requirement: Row groups
Every row SHALL belong to one of six groups, keyed `ammo`, `reagents` (each class reagent and display-only item), `supplies` (the food, water and pet food rows), `bags`, `durability` and `professions` (each profession row). The Status window settings page SHALL list one mode dropdown per group in the order Ammo, Reagents, Supplies, Bag space, Durability, Professions, and `/cvn hud row <ammo|reagents|supplies|professions|bags|durability> low/always/never` SHALL set a group's mode. A saved mode under any other key SHALL be ignored.

#### Scenario: One mode for every profession
- **WHEN** the character has Mining near its cap and Cooking far from it, and Professions is `always`
- **THEN** both profession rows are shown; with Professions `low` only Mining is shown, and with `never` neither

#### Scenario: Stale per-row keys
- **WHEN** the saved row modes hold `prof:Mining = always` from an earlier build
- **THEN** it is ignored and the Professions group keeps its own mode

### Requirement: Demo
The addon SHALL accept a `/cvn demo` command that is not listed in help, the README or the listing. Each use SHALL roll a random window setup (random rows, including the food, water and pet food rows, counts and modes, with at least one row low) and one random outcome: a warning for any kind of vendor, including food, water and pet food, shown through the real notice, question and pin paths, or a reminder with its sound, for 10 seconds, then restore the real window and clear anything the demo pinned. A new use SHALL re-roll and restart the 10 seconds. The demo SHALL NOT change saved settings.

#### Scenario: Demo shows and restores
- **WHEN** the player runs `/cvn demo`
- **THEN** a random window is shown with a random warning and, after 10 seconds, the real window state returns

#### Scenario: Demo does not save
- **WHEN** a demo has finished
- **THEN** saved settings are exactly as before it

#### Scenario: Repeat
- **WHEN** the player runs `/cvn demo` again during a demo
- **THEN** a new setup replaces the old one and the 10 seconds restart

#### Scenario: Demo covers supplies
- **WHEN** the player runs `/cvn demo` repeatedly
- **THEN** the window sometimes has food, water and pet food rows, and the outcome is sometimes a food, water or pet food question or pin (with a made-up count and, when no pet is out, a made-up diet) or a reminder that plays the reminder sound

