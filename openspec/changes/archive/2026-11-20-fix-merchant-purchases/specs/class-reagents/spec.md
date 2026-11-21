## ADDED Requirements

### Requirement: A later reagent Yes buys only what is still needed
When the player answers Yes to the reagent purchase question, the addon SHALL read the reagents carried, the bags and the money again and buy only what still brings each reagent to the amount and fits, never more of a reagent than the question named. When nothing is needed any more it SHALL buy nothing and print no "Bought" line.

#### Scenario: Bought by hand before Yes
- **WHEN** the amount is 20, the question offers 20 Arcane Powder, and the player buys 15 by hand before clicking Yes
- **THEN** Yes buys 5 Arcane Powder and the chat line names 5 and their cost

#### Scenario: Already stocked at Yes
- **WHEN** the player carries the amount of every reagent by the time they click Yes
- **THEN** nothing is bought and no "Bought" line is printed
