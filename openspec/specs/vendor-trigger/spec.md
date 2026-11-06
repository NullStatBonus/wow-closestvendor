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
When several triggers are active, the addon SHALL handle them one at a time in the order repair, ammo, sell. A repair or ammo trip also covers selling, and a lower-priority request SHALL NOT replace a higher-priority one that is still open or active.

#### Scenario: Both conditions active
- **WHEN** bags are at threshold and durability is below threshold
- **THEN** the target is the nearest repair vendor

#### Scenario: Repair and ammo both low
- **WHEN** gear needs repair and ammo is low
- **THEN** the repair question is asked first, and the ammo question only after it resolves

#### Scenario: Lower priority does not replace
- **WHEN** a repair question is open and the sell condition becomes true
- **THEN** the repair question stays

### Requirement: Quiet behavior
The addon SHALL NOT start navigation while the player is in combat, and SHALL NOT re-request navigation for a condition until that condition has cleared and recurred.

#### Scenario: Condition crossed in combat
- **WHEN** a threshold is crossed during combat
- **THEN** navigation starts only after combat ends, if the condition still holds

#### Scenario: No repeat after dismissal
- **WHEN** navigation was started and the condition has not cleared
- **THEN** it is not started again on later bag or durability events

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
The addon SHALL clear its waypoint when a merchant window opens at a vendor or when the triggering condition clears.

#### Scenario: Player vends
- **WHEN** the player sells items and free slots rise above the threshold
- **THEN** the waypoint is removed

### Requirement: Settings panel
The addon SHALL add a "Closest Vendor" page under Options, AddOns, with an on/off checkbox and a threshold slider for each trigger (bags, durability, ammo). Changes SHALL edit the same saved settings as the slash commands, take effect at once, and the panel SHALL honor the same limits as the commands. `/cvn config` SHALL open the page.

#### Scenario: Change a threshold in the panel
- **WHEN** the player moves the bag slider to 4
- **THEN** the saved bag threshold is 4 and `/cvn` reports it

#### Scenario: Slash command and panel agree
- **WHEN** the player runs `/cvn ammo 500` and then opens the panel
- **THEN** the ammo slider shows 500

#### Scenario: Switch a trigger off
- **WHEN** the player clears a trigger's checkbox
- **THEN** that trigger stops asking and its slider is disabled

#### Scenario: Panel unavailable
- **WHEN** the client lacks the settings API
- **THEN** the addon still loads and the slash commands work

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
The addon SHALL persist a bag-slot threshold, a durability-percent threshold and an ammo-count threshold per account, settable via slash command, and SHALL allow disabling each trigger independently.

#### Scenario: Custom bag threshold
- **WHEN** the user sets the bag threshold to 5
- **THEN** navigation is requested when free slots are 5 or fewer
