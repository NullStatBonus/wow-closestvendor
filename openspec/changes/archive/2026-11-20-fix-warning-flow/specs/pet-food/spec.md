## ADDED Requirements

### Requirement: A pet food request follows the pet's diet
When the active pet changes to one with a different diet while a pet food request is open or active, the addon SHALL close its question and its waypoint and SHALL ask again for the new pet's diet if its food is also low. A new pet with the same diet SHALL keep the request.

#### Scenario: Meat eater swapped for a bread eater
- **WHEN** a meat vendor is pinned for low pet food and the hunter calls a pet that eats Bread and Fruit but not Meat, with little of either in the bags
- **THEN** the meat vendor waypoint ends and the question names a vendor that sells bread or fruit

#### Scenario: Same diet
- **WHEN** the hunter swaps one meat-eating pet for another while a meat vendor is pinned
- **THEN** the waypoint stays
