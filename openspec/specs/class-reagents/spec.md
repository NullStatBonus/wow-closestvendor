# class-reagents Specification

## Purpose
Remind casters when a class reagent they use runs low and navigate to the closest vendor that sells it, with per-reagent settings.

## Requirements

### Requirement: Reagents per class
The addon SHALL know the reagents of Mage, Rogue, Priest, Paladin, Shaman and Druid, and SHALL watch only the reagents of the player's own class. Warlocks, hunters and warriors SHALL have none.

#### Scenario: Mage reagents
- **WHEN** the player is a mage
- **THEN** the watched reagents are Arcane Powder, Rune of Teleportation and Rune of Portals

#### Scenario: Class without reagents
- **WHEN** the player is a hunter, a warrior or a warlock
- **THEN** no reagent is watched and no reagent question is asked

### Requirement: Watched only when usable
A reagent SHALL be watched only when the player knows a spell that uses it. For reagents tied to spell ranks, only the reagent of the highest known rank SHALL be watched.

#### Scenario: Spell not known
- **WHEN** a mage does not know any Portal spell and has no Rune of Portals
- **THEN** no question is asked about Rune of Portals

#### Scenario: Spell learned
- **WHEN** the mage learns a Portal spell and has no Rune of Portals
- **THEN** Rune of Portals counts as low

#### Scenario: Lower rank reagent
- **WHEN** a druid knows the highest Rebirth rank and has no seed of a lower rank
- **THEN** the lower-rank seed is not asked about

### Requirement: Reagent trigger
When a watched, enabled reagent is at or below the reagent threshold, and the reagents switch is on, the addon SHALL ask about navigating to the nearest vendor that sells that reagent, using the same question, map-or-distance choice, automatic mode and on-screen notice as other triggers. The count SHALL be the number carried in the player's bags. If the count cannot be read, the reagent SHALL NOT count as low.

#### Scenario: Reagent runs low
- **WHEN** a mage's Arcane Powder drops to 5 with the default threshold of 5
- **THEN** one question names the reagent, the count and the nearest vendor that sells it

#### Scenario: What to buy is stated
- **WHEN** the question is shown for a reagent
- **THEN** its text names the reagent to buy, both where it reports the count and where it names the vendor

#### Scenario: Automatic pin says what to buy
- **WHEN** a reagent target is chosen without asking
- **THEN** the chat line and the on-screen message name the reagent to buy, the vendor with zone and distance, and the other choice when there was one

#### Scenario: No repeat until cleared
- **WHEN** the question was answered No and the count stays low
- **THEN** it is not asked again until the count rises above the threshold and falls again

#### Scenario: Several low at once
- **WHEN** two watched reagents are low
- **THEN** one question is asked, and the second only after the first resolves

#### Scenario: Unknown count
- **WHEN** bags cannot be read
- **THEN** no reagent question is asked

#### Scenario: No known seller
- **WHEN** no known vendor on this continent sells the reagent
- **THEN** the addon prints one line in chat and shows no dialog

#### Scenario: Arrival ends the request
- **WHEN** the player opens a merchant window while a reagent question or pin is active
- **THEN** the question closes or the pin is removed

### Requirement: Reagent thresholds
Ammo SHALL keep its own count threshold (default 200). All reagents SHALL share one count threshold, default 5, from 1 to 40, saved per character.

#### Scenario: Separate scales
- **WHEN** the player sets the ammo threshold to 300 and the reagent threshold to 10
- **THEN** ammo asks at 300 or fewer and reagents at 10 or fewer

#### Scenario: Existing settings
- **WHEN** a player who switched ammo off in an earlier version loads the addon
- **THEN** reagent questions start off too, with no other settings lost

### Requirement: Individual reagents can be disabled
Each watched reagent SHALL have its own on/off setting, on by default. The settings page SHALL list only the player's class reagents, each with a checkbox. A reagent the player has not switched off SHALL be on, including reagents added in later versions.

#### Scenario: Disable one reagent
- **WHEN** the player clears the Rune of Portals checkbox
- **THEN** no question is asked about Rune of Portals and the other mage reagents still ask

#### Scenario: Only own class
- **WHEN** a paladin opens the settings page
- **THEN** it lists Symbol of Kings and Symbol of Divinity and no mage reagents

#### Scenario: Defaults
- **WHEN** a new player opens the page
- **THEN** every listed reagent is on

### Requirement: Reagent commands
The addon SHALL provide `/cvn reagent <count>` to set the reagent threshold, `/cvn reagents` to list the player's class reagents with their on/off state, `/cvn reagent on <name>` and `/cvn reagent off <name>` to switch one reagent, and `/cvn test reagent` to show the question now for the first watched reagent regardless of count, combat or settings. A name SHALL match case-insensitively. An unknown name or a count outside 1 to 40 SHALL print a message and change nothing.

#### Scenario: Switch off by name
- **WHEN** the player runs `/cvn reagent off arcane powder`
- **THEN** Arcane Powder is off and `/cvn reagents` shows it off

#### Scenario: Unknown name
- **WHEN** the player runs `/cvn reagent off nonsense`
- **THEN** a message says the reagent is unknown and nothing changes

#### Scenario: Threshold out of range
- **WHEN** the player runs `/cvn reagent 99`
- **THEN** a message says the range is 1 to 40 and the threshold is unchanged

#### Scenario: Test with nothing to watch
- **WHEN** the player runs `/cvn test reagent` with no watched reagent
- **THEN** chat says there is nothing to ask about and no dialog appears

#### Scenario: Settings report
- **WHEN** the player runs `/cvn`
- **THEN** the report shows the reagent threshold and any reagents switched off

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

### Requirement: Reagents have their own switch
Reagent questions SHALL have an on/off setting of their own, on by default and saved per character, shown as a "Reagents" checkbox in the Warnings section of the main settings page (the reagent threshold and the per-reagent checkboxes are on the Reagents page), and set by `/cvn reagents on|off`. The ammo switch SHALL NOT affect reagents, and the reagents switch SHALL NOT affect ammo. A character saved before this setting existed SHALL start with its ammo switch's value.

#### Scenario: Ammo off, reagents on
- **WHEN** the player switches ammo off and reagents are on and low
- **THEN** the reagent question is still asked and no ammo question is

#### Scenario: Reagents off, ammo on
- **WHEN** the player runs `/cvn reagents off`
- **THEN** no reagent question is asked and ammo questions still are

#### Scenario: Earlier settings
- **WHEN** a character saved with the ammo switch off loads the addon
- **THEN** its reagents switch starts off
