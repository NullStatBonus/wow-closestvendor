## MODIFIED Requirements

### Requirement: Repair takes priority
When several triggers are active, the addon SHALL handle them one at a time in the order repair, ammo, reagent, sell, profession trainer. A repair or ammo trip also covers selling, and a lower-priority request SHALL NOT replace a higher-priority one that is still open or active. A reagent or trainer trip does not cover selling.

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

#### Scenario: Lower priority does not replace
- **WHEN** a repair question is open and the sell condition becomes true
- **THEN** the repair question stays

#### Scenario: Trainer is lowest
- **WHEN** a sell question is open and a profession comes within its threshold
- **THEN** the sell question stays

#### Scenario: Trainer yields
- **WHEN** a trainer question is open and the sell condition becomes true
- **THEN** the sell question replaces it

### Requirement: Settings panel
The addon SHALL add a "Closest Vendor" page under Options, AddOns, with an on/off checkbox and a threshold slider for bags, durability, ammo and reagents, and professions. The ammo checkbox SHALL be labelled "Ammo and reagents" and SHALL switch both. Changes SHALL edit the same saved settings as the slash commands, take effect at once, and the panel SHALL honor the same limits as the commands. `/cvn config` SHALL open the page.

#### Scenario: Change a threshold in the panel
- **WHEN** the player moves the bag slider to 4
- **THEN** the saved bag threshold is 4 and `/cvn` reports it

#### Scenario: Slash command and panel agree
- **WHEN** the player runs `/cvn ammo 500` and then opens the panel
- **THEN** the ammo slider shows 500

#### Scenario: Profession slider
- **WHEN** the player moves the profession slider to 25
- **THEN** the saved profession threshold is 25 and `/cvn` reports it

#### Scenario: Reagent slider
- **WHEN** the player moves the reagent slider to 10
- **THEN** the saved reagent threshold is 10 and `/cvn` reports it

#### Scenario: Switch a trigger off
- **WHEN** the player clears a trigger's checkbox
- **THEN** that trigger stops asking and its slider is disabled

#### Scenario: Master switch off
- **WHEN** the player clears "Ammo and reagents"
- **THEN** the ammo slider, the reagent slider and the reagent checkboxes stop having an effect

#### Scenario: Panel unavailable
- **WHEN** the client lacks the settings API
- **THEN** the addon still loads and the slash commands work
