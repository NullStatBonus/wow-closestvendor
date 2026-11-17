## MODIFIED Requirements

### Requirement: Repair takes priority
When several triggers are active, the addon SHALL handle them one at a time in the order repair, ammo, reagent, food, water, pet food, sell, profession trainer. A repair or ammo trip also covers selling, and a lower-priority request SHALL NOT replace a higher-priority one that is still open or active. A reagent, food, water, pet food or trainer trip does not cover selling. A request resolves when its condition clears, a merchant opens for it, the player answers No, or no vendor serves it. A request that a higher one replaces SHALL be asked again after that one resolves, if its condition still holds.

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

#### Scenario: Replaced request returns
- **WHEN** a sell question is open, repair replaces it, and the player answers No to repair while bags are still full
- **THEN** the sell question is asked again

## ADDED Requirements

### Requirement: A declined request yields
When the player answers No (or Escape) to a route question, or no vendor serves the need, that request SHALL end: it SHALL NOT be asked again until its condition clears and recurs, and the next need SHALL be asked. A question replaced or withdrawn by the addon SHALL NOT count as an answer. Selling, which a declined repair or ammo trip would have covered, SHALL be asked if bags are still low.

#### Scenario: No to repair
- **WHEN** gear is worn and bags are full, and the player answers No to the repair question
- **THEN** the selling question is asked shortly after, and repair is not asked again until durability recovers and drops again

#### Scenario: No vendor for the need
- **WHEN** no known vendor serves the highest need
- **THEN** the next need is asked instead of waiting

#### Scenario: Replaced question
- **WHEN** the addon replaces or withdraws a question
- **THEN** that is not treated as No

### Requirement: Held while dead
While the player is dead or a ghost, the addon SHALL NOT ask route or trainer questions, set automatic routes, or use up a warning. Coming back to life SHALL check again.

#### Scenario: Durability lost on death
- **WHEN** dying drops durability below the threshold
- **THEN** no question is used up while dead, and the repair question is asked once the player is alive
