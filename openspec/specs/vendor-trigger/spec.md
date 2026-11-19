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
The addon SHALL expose Home, Restock (Ammo, Reagents, Supplies), Navigation, Appearance (Notifications, Status window, Sound), Advanced and About using AceConfig/AceConfigDialog and AceGUI, following settings-interaction. Home SHALL hold every switch that decides whether the addon acts: the warning switches with bag, durability and profession thresholds, Destination on another map with Preferred target, and On-screen notice. Ammo, Reagents and Supplies SHALL retain all existing feature, threshold, grade and buying controls. Navigation SHALL contain waypoint method, instance anchor and auction routing. Appearance SHALL contain notification style, Status window controls with Lock position first, visibility modes, visual previews and positioning. The notification sound SHALL be on the Appearance Sound tab. Advanced SHALL show character scope and diagnostics; About SHALL show version and purpose. `/cvn config`, `/cvn options` and `/cvn settings` SHALL open Home; `/cvn settings <page>` SHALL open a child page or tab by its own name. Changes SHALL use the same saved values, limits and immediate refresh as slash commands. Game-options entries SHALL use AceConfigDialog registration where supported; without native Settings the standalone Ace dialog and slash commands SHALL continue working.

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

#### Scenario: Ammo switch off
- **WHEN** the player clears "Ammo" in the Warnings section
- **THEN** ammo questions stop and the ammo slider has no effect and the reagent settings are unaffected

#### Scenario: Panel unavailable
- **WHEN** the client lacks native Settings registration
- **THEN** the addon still loads, slash commands work and the standalone Ace dialog opens

#### Scenario: Subcategories
- **WHEN** the client supports subcategories
- **THEN** the approved landmarks appear under Closest Vendor with a recognizable Status window section in Appearance

#### Scenario: Subcategories unavailable
- **WHEN** the client lacks subcategories
- **THEN** the standalone Ace tree contains every page and control without requiring native subcategories

#### Scenario: Lock first
- **WHEN** Appearance’s Status window section opens
- **THEN** the Lock position checkbox is its first control

#### Scenario: Only the player's rows
- **WHEN** a warrior opens the Status window page
- **THEN** the Reagents visibility mode remains visible but disabled with a reason when no class reagent or display-only item applies, consistent with status-window; irrelevant item-specific controls are not actionable

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
The addon SHALL persist a bag-slot threshold, a durability-percent threshold, an ammo-count threshold and a profession-points threshold per character, settable via slash command, and SHALL allow disabling each trigger independently.

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
The addon SHALL provide an on/off setting for the on-screen message shown when it pins a target automatically. It SHALL be on by default, saved, settable by `/cvn notice on` and `/cvn notice off` and by a checkbox on Home, take effect at once, and appear in the debug report. The chat line SHALL NOT depend on it. The Warning/Toast presentation choice SHALL be independent of this enabled state; a style change SHALL NOT enable notices.

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

### Requirement: No needless reads
The addon SHALL ignore events about units other than the player (a party or raid member's pet, gear or casts) and SHALL NOT read the bags for supplies while the Supplies switch is off or every supply warning and the healthstone reminder is off.

#### Scenario: A party member's pet changes
- **WHEN** the game reports a pet change for `party1`
- **THEN** the addon evaluates nothing and reads no bag slot

#### Scenario: Every supply warning off
- **WHEN** bags change while food, water, pet food and the healthstone reminder are all off
- **THEN** no bag slot is read for supplies

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

### Requirement: Questions end with the place
When the player changes zone or enters an instance while a warning's question is open, the addon SHALL withdraw that question unanswered and SHALL ask the warning again at the next check where questions are allowed, from the new place. Combat SHALL NOT withdraw a question, and the player MAY answer it and route in combat. Questions from `/cvn test` and the demo SHALL NOT be withdrawn this way.

#### Scenario: Enter a dungeon with a question open
- **WHEN** the sell question is open and the player enters a dungeon
- **THEN** the question closes, nothing is asked inside, and the sell question is asked again after leaving

#### Scenario: Zone change
- **WHEN** the repair question is open and the player crosses into another zone
- **THEN** the question is asked again with the closest repair vendor from the new zone

#### Scenario: Combat
- **WHEN** a question is open and combat starts
- **THEN** the question stays open and Yes still sets the waypoint
