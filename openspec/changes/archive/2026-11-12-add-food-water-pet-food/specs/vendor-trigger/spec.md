## MODIFIED Requirements

### Requirement: Repair takes priority
When several triggers are active, the addon SHALL handle them one at a time in the order repair, ammo, reagent, food, water, pet food, sell, profession trainer. A repair or ammo trip also covers selling, and a lower-priority request SHALL NOT replace a higher-priority one that is still open or active. A reagent, food, water, pet food or trainer trip does not cover selling.

#### Scenario: Both conditions active
- **WHEN** bags are at threshold and durability is below threshold
- **THEN** the target is the nearest repair vendor

#### Scenario: Repair and ammo both low
- **WHEN** gear needs repair and ammo is low
- **THEN** the repair question is asked first, and the ammo question only after it resolves

#### Scenario: Ammo before reagent
- **WHEN** ammo and a reagent are both low
- **THEN** the ammo question is asked first, and the reagent question only after it resolves

#### Scenario: Reagent before sell
- **WHEN** a reagent is low and bags are at threshold
- **THEN** the reagent question is asked first, and the sell question only after it resolves

#### Scenario: Reagent before food
- **WHEN** a reagent and food are both low
- **THEN** the reagent question is asked first, and the food question only after it resolves

#### Scenario: Food before water before pet food
- **WHEN** food, water and pet food are all low
- **THEN** they are asked in that order, each only after the previous resolves

#### Scenario: Pet food before sell
- **WHEN** pet food is low and bags are at threshold
- **THEN** the pet food question is asked first, and the sell question only after it resolves

#### Scenario: Lower priority does not replace
- **WHEN** a repair question is open and the sell condition becomes true
- **THEN** the repair question stays

#### Scenario: Trainer is lowest
- **WHEN** a sell question is open and a profession comes within its threshold
- **THEN** the sell question stays

#### Scenario: Trainer yields
- **WHEN** a trainer question is open and the sell condition becomes true
- **THEN** the sell question replaces it
