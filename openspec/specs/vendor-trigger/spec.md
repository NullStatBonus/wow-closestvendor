# vendor-trigger Specification

## Purpose
Detect low bag space or low equipment durability and decide when navigation to a vendor starts and stops, using user-configurable thresholds.

## Requirements

### Requirement: Bag space trigger
The addon SHALL request navigation to a sell vendor when the player's free bag slots are less than or equal to the configured bag threshold (default 2).

#### Scenario: Bags reach threshold
- **WHEN** free bag slots drop to 2 or fewer with the default threshold
- **THEN** navigation to the nearest sell vendor is requested

#### Scenario: Bags above threshold
- **WHEN** free bag slots are 3 or more with the default threshold
- **THEN** no sell navigation is requested

### Requirement: Durability trigger
The addon SHALL request navigation to a repair vendor when the lowest durability percentage among equipped items is below the configured durability threshold (default 20%).

#### Scenario: One item below threshold
- **WHEN** any equipped item is below 20% durability and others are higher
- **THEN** navigation to the nearest repair vendor is requested

#### Scenario: Items without durability
- **WHEN** an equipped item has no durability
- **THEN** it is ignored when computing the lowest percentage

### Requirement: Ammo trigger
When a bow, crossbow or gun is equipped, the addon SHALL request navigation to a vendor selling that kind of ammo (arrows for bows and crossbows, bullets for guns) when the count of the equipped ammo is at or below the configured ammo threshold (default 200). Thrown weapons and wands, and characters with no ranged weapon, are not monitored.

#### Scenario: Ammo at threshold
- **WHEN** a gun is equipped and its equipped bullets drop to 200 or fewer
- **THEN** navigation to the nearest vendor selling bullets is requested

#### Scenario: No ammo equipped
- **WHEN** a bow is equipped and no arrows are equipped
- **THEN** the count is 0 and navigation to the nearest arrow vendor is requested

#### Scenario: Wrong ammo kind
- **WHEN** a gun is equipped but the equipped ammo is arrows
- **THEN** the count is 0

#### Scenario: Not monitored
- **WHEN** no ranged weapon, a thrown weapon or a wand is equipped
- **THEN** no ammo navigation is requested

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

### Requirement: Quiet behavior
The addon SHALL NOT start navigation while the player is in combat, and SHALL NOT re-request navigation for a vendor condition (sell, repair, ammo) until that condition has cleared and recurred. Profession trainer questions are the exception: they are asked again on each skill change or craft, as set out in `profession-trainer`.

#### Scenario: Condition crossed in combat
- **WHEN** a threshold is crossed during combat
- **THEN** navigation starts only after combat ends, if the condition still holds

#### Scenario: No repeat after dismissal
- **WHEN** navigation was started and the condition has not cleared
- **THEN** it is not started again on later bag or durability events

#### Scenario: Trainer question in combat
- **WHEN** a profession event fires during combat
- **THEN** no question is shown, and the next event after combat asks as usual

### Requirement: Confirm before navigating
The addon SHALL ask the player, in a dialog naming the reason and the closest vendor, before starting navigation, and SHALL navigate only if the player accepts.

#### Scenario: Player accepts
- **WHEN** a trigger fires and a vendor is found
- **THEN** a dialog names the vendor and asks whether to navigate, and navigation starts only after the player accepts

#### Scenario: Player declines
- **WHEN** the player declines the dialog
- **THEN** no navigation starts and the same condition does not ask again until it has cleared and recurred

#### Scenario: Condition resolves while the dialog is open
- **WHEN** the condition clears, or a merchant window opens, while the dialog is showing
- **THEN** the dialog closes without navigating

### Requirement: Navigation ends on resolution
The addon SHALL clear a vendor waypoint when a merchant window opens at a vendor or when the triggering condition clears. A profession trainer waypoint SHALL instead be cleared when a trainer window for that profession opens, or when the profession is no longer within its threshold. Opening a merchant window SHALL NOT clear a trainer waypoint.

#### Scenario: Player vends
- **WHEN** the player sells items and free slots rise above the threshold
- **THEN** the waypoint is removed

#### Scenario: Player reaches the trainer
- **WHEN** the player opens a trainer window for the profession being navigated to
- **THEN** the waypoint is removed

#### Scenario: Merchant opened on the way
- **WHEN** the player opens a merchant window while navigating to a trainer
- **THEN** the trainer waypoint stays

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

### Requirement: Test commands
The addon SHALL provide `/cvn test sell`, `/cvn test repair`, `/cvn test arrows` and `/cvn test bullets`, which ask the same question as a real trigger for the nearest sell or repair vendor, regardless of bag space, durability, combat state or trigger settings, and SHALL set the destination if the player accepts.

#### Scenario: Test sell accepted
- **WHEN** the player runs `/cvn test sell` and accepts
- **THEN** the nearest sell vendor becomes the destination

#### Scenario: Test ammo accepted
- **WHEN** the player runs `/cvn test arrows` or `/cvn test bullets` and accepts
- **THEN** the nearest vendor selling that ammo becomes the destination

#### Scenario: Test repair accepted
- **WHEN** the player runs `/cvn test repair` and accepts
- **THEN** the nearest repair vendor becomes the destination

#### Scenario: Nothing to show
- **WHEN** no map position is available or no eligible vendor is known
- **THEN** the addon says why in chat and shows no dialog

#### Scenario: Real triggers unaffected
- **WHEN** a test is run
- **THEN** the real triggers still ask when their own conditions are met

### Requirement: Configurable thresholds
The addon SHALL persist a bag-slot threshold, a durability-percent threshold, an ammo-count threshold and a profession-points threshold per account, settable via slash command, and SHALL allow disabling each trigger independently.

#### Scenario: Custom bag threshold
- **WHEN** the user sets the bag threshold to 5
- **THEN** navigation is requested when free slots are 5 or fewer

#### Scenario: Settings report
- **WHEN** the player runs `/cvn`
- **THEN** the report includes the profession threshold and whether it is on

### Requirement: Two-target question
When two candidates exist and the map choice mode is `ask`, the addon SHALL show one question with three buttons: the current-map target, the closer target, and Cancel. The question SHALL name both targets with their zones and distances, and the preferred target SHALL be the first button. Choosing a target SHALL start navigation to it; Cancel and Esc SHALL start nothing and SHALL count as declining.

#### Scenario: Choose the closer target
- **WHEN** the question shows two targets and the player picks the closer one
- **THEN** navigation starts at that target only

#### Scenario: Choose the current-map target
- **WHEN** the question shows two targets and the player picks the current-map one
- **THEN** navigation starts at that target only

#### Scenario: Cancel
- **WHEN** the player presses Cancel or Esc
- **THEN** no navigation starts and the same condition does not ask again until it has cleared and recurred

#### Scenario: Button order follows the preference
- **WHEN** the preference is `distance`
- **THEN** the closer target is the first button

#### Scenario: Single candidate keeps the plain question
- **WHEN** only one candidate exists
- **THEN** the usual Yes/No question names that target

### Requirement: Map choice settings
The addon SHALL provide a mode (`ask`, the default, or `auto`) and a preference (`map`, the default, or `distance`) for choosing between a current-map and a closer other-map target. Both SHALL be saved, shared by vendor and trainer questions, settable by slash command and by the settings page, take effect at once, and appear in the debug report.

#### Scenario: Defaults
- **WHEN** the addon loads with no saved choice
- **THEN** the mode is `ask` and the preference is `map`

#### Scenario: Change by command
- **WHEN** the player runs the command to set the mode to `auto`
- **THEN** the saved mode is `auto` and `/cvn` reports it

#### Scenario: Command and page agree
- **WHEN** the player sets the preference by command and opens the settings page
- **THEN** the page shows the same preference

#### Scenario: Invalid value
- **WHEN** the player gives a value other than the listed choices
- **THEN** nothing changes and the valid choices are printed

### Requirement: On-screen notice setting
The addon SHALL provide an on/off setting for the on-screen message shown when it pins a target automatically. It SHALL be on by default, saved, settable by `/cvn notice on` and `/cvn notice off` and by a checkbox on the settings page, take effect at once, and appear in the debug report. The chat line SHALL NOT depend on it.

#### Scenario: Default
- **WHEN** the addon loads with no saved choice
- **THEN** the on-screen message is on

#### Scenario: Switched off
- **WHEN** the player runs `/cvn notice off` and a target is pinned in `auto` mode
- **THEN** no on-screen message is shown and the chat line is still printed

#### Scenario: Switched back on
- **WHEN** the player runs `/cvn notice on` and a target is pinned in `auto` mode
- **THEN** the on-screen message is shown

#### Scenario: Command and page agree
- **WHEN** the player runs `/cvn notice off` and opens the settings page
- **THEN** the checkbox is cleared

#### Scenario: Invalid value
- **WHEN** the player runs `/cvn notice` with anything other than `on` or `off`
- **THEN** nothing changes and the valid choices are printed
