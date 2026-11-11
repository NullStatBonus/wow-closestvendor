## ADDED Requirements

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
When a watched, enabled reagent is at or below the reagent threshold, and the master "Ammo and reagents" switch is on, the addon SHALL ask about navigating to the nearest vendor that sells that reagent, using the same question, map-or-distance choice, automatic mode and on-screen notice as other triggers. The count SHALL be the number carried in the player's bags. If the count cannot be read, the reagent SHALL NOT count as low.

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

### Requirement: Reagent master switch and thresholds
"Ammo and reagents" SHALL be one on/off switch for both ammo and reagent questions. Ammo SHALL keep its own count threshold (default 200). All reagents SHALL share one count threshold, default 5, from 1 to 40, saved per account.

#### Scenario: Switch off
- **WHEN** the player turns the master switch off
- **THEN** neither ammo nor reagent questions are asked

#### Scenario: Separate scales
- **WHEN** the player sets the ammo threshold to 300 and the reagent threshold to 10
- **THEN** ammo asks at 300 or fewer and reagents at 10 or fewer

#### Scenario: Existing settings
- **WHEN** a player who switched ammo off in an earlier version loads the addon
- **THEN** reagent questions are off too, with no other settings lost

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
