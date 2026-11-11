## ADDED Requirements

### Requirement: Display-only items
Reagent-table entries MAY be flagged display-only (no vendor sells them). A display-only item SHALL NOT be watched by the warning trigger, SHALL NOT get a vendor flag, and SHALL appear only as a status window row.

#### Scenario: No warning for shards
- **WHEN** a warlock has no soul shards
- **THEN** no question is asked

### Requirement: Warning and window are separate
A reagent's warning switch (Reagents page) and its window mode (Status window page) SHALL be independent: switching a reagent's warning off SHALL NOT hide its window row, and a window mode of `never` SHALL NOT stop its warning.

#### Scenario: Warning off, row always
- **WHEN** the Arcane Powder warning is off and its window mode is `always`
- **THEN** no question is asked about it and its row is shown

### Requirement: Buy reagents at a merchant
When a merchant window opens and reagent buying is on (`reagentBuyEnabled`, off by default), the addon SHALL buy each watched class reagent the merchant sells until the player carries `reagentBuyTarget` of it (0-100, default 20, one amount for every reagent), counting what the bags already hold with the warning's own count. An amount of 0 SHALL buy none.

#### Scenario: Stock up counting what is carried
- **WHEN** reagent buying is on with the amount 20, the player carries 7 Arcane Powder and no Rune of Teleportation, and the merchant sells both
- **THEN** 13 Arcane Powder and 20 Rune of Teleportation are bought

#### Scenario: Already stocked
- **WHEN** the player already carries the amount of every watched reagent
- **THEN** nothing is bought and nothing is said

#### Scenario: Amount 0
- **WHEN** the amount is 0
- **THEN** nothing is bought

### Requirement: Only watched vendor reagents are bought
Reagent buying SHALL cover only the reagents the warning watches (a known spell uses it, it is not switched off, its count can be read). Display-only items SHALL never be bought, and a class without vendor-sold reagents SHALL buy nothing.

#### Scenario: Not watched
- **WHEN** a reagent is switched off, or the player knows no spell that uses it
- **THEN** it is not bought

#### Scenario: Display-only item
- **WHEN** a warlock opens a merchant
- **THEN** no Soul Shard is bought

### Requirement: Never above the amount
The addon SHALL never buy more of a reagent than brings it to the amount: an item sold in batches SHALL be bought only in whole batches that stay within it, and a limited merchant stock SHALL cap it.

#### Scenario: Batches
- **WHEN** a reagent is sold 10 per purchase and 25 are needed
- **THEN** 20 are bought

### Requirement: Ask before buying reagents
By default (`reagentBuyPrompt` on) the addon SHALL show a dialog naming each reagent with its count and the total price, in a dialog of its own so an ammo purchase question is not replaced, and SHALL buy only if the player accepts. With asking off it SHALL buy at once. With nothing to buy no dialog SHALL be shown.

#### Scenario: Ask first
- **WHEN** a merchant opens with reagents to buy and asking is on
- **THEN** a dialog shows the reagents, counts and price, and nothing is bought until the player accepts

#### Scenario: Buy at once
- **WHEN** asking is off
- **THEN** the reagents are bought with no dialog

### Requirement: Reagent purchases fit money and bags
A reagent purchase SHALL be limited to the money held, less what an ammo purchase at the same merchant just spent, and to the room in the general-purpose bags: partial stacks of the same item plus empty slots at its stack size, a slot filled by one reagent no longer free for the next. Quivers, ammo pouches and other special bags SHALL NOT count. When not everything fits, reagents SHALL be bought in table order.

#### Scenario: Short of gold
- **WHEN** the reagents to buy cost more than the player holds
- **THEN** only what can be afforded is bought, in table order, and the chat line says it was all the player could afford

#### Scenario: Bags full
- **WHEN** the general bags have no free slot and no partial stack of the reagent
- **THEN** nothing is bought and chat says the bags have no room

### Requirement: Reagent purchase report and unknown data
The addon SHALL print one chat line naming each reagent bought with its count and the total cost, saying when money or bag room cut it short, or saying why nothing was bought when that was money or bag room. Single items SHALL be bought in as few calls as the merchant allows. Unreadable bags, money or merchant data SHALL cause no purchase; a reagent whose count, stack size or price cannot be read SHALL be skipped.

#### Scenario: Report
- **WHEN** 5 Arcane Powder and 10 Rune of Teleportation are bought
- **THEN** one chat line names both with their counts and the cost

#### Scenario: Unreadable data
- **WHEN** the bag contents or the money cannot be read
- **THEN** nothing is bought

### Requirement: Reagent buying settings
The Reagents settings page SHALL end with a "Buy reagents" checkbox, an "Ask before buying reagents" checkbox and a slider for the amount of each reagent to carry (0-100), the last two greyed while buying is off. For a class without vendor-sold reagents all three SHALL be shown greyed out with the tooltip "Your class does not use reagents.". A saved amount outside 0-100 SHALL be held to that range at load.

#### Scenario: Class without reagents
- **WHEN** a hunter opens the Reagents page
- **THEN** the three buying controls are greyed out and their tooltip says the class does not use reagents

### Requirement: Reagent buying commands
`/cvn reagentbuy on|off`, `/cvn reagentbuy ask|auto` and `/cvn reagentbuy <0-100>` SHALL edit the same saved settings as the page, a value outside 0-100 SHALL be refused with a message naming the range, a class without vendor-sold reagents SHALL be told it does not use reagents, and `/cvn` and help SHALL list reagent buying.

#### Scenario: Command and page agree
- **WHEN** the player runs `/cvn reagentbuy 35`
- **THEN** the amount slider shows 35 and `/cvn` reports it

#### Scenario: Out of range
- **WHEN** the player runs `/cvn reagentbuy 101`
- **THEN** the amount is unchanged and a message names the range
