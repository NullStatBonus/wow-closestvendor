## MODIFIED Requirements

### Requirement: Settings panel
The addon SHALL add a "Closest Vendor" page under Options, AddOns. The main page SHALL hold, under "Warnings", an on/off checkbox and a threshold slider for bags, durability, ammo and reagents, and professions, with the ammo checkbox labelled "Ammo and reagents" switching both; and, under "Navigation", the target choice, the target preference, the on-screen message checkbox, the dungeon and raid anchor, and the auction house checkbox. Three subcategories SHALL follow: "Reagents" (a warning checkbox for each of the player's class reagents, then the reagent buying controls: buy, ask first and the amount to carry), "Ammo" (buy, ask first, arrow and bullet grade), and "Status window" (first the Lock checkbox, then scale, opacity, and a visibility dropdown `low`, `always` or `never` for each row that applies to the player). Changes SHALL edit the same saved settings as the slash commands, take effect at once, and the panel SHALL honor the same limits as the commands. `/cvn config` SHALL open the main page. If subcategories are unavailable, all controls SHALL appear on the one page under section headers.

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

#### Scenario: Subcategories
- **WHEN** the client supports subcategories
- **THEN** Reagents, Ammo and Status window appear under Closest Vendor

#### Scenario: Subcategories unavailable
- **WHEN** the client lacks subcategories
- **THEN** every control appears on the one page under section headers

#### Scenario: Lock first
- **WHEN** the Status window page opens
- **THEN** the Lock window position checkbox is its first control

#### Scenario: Only the player's rows
- **WHEN** a warrior opens the Status window page
- **THEN** no reagent rows are listed
