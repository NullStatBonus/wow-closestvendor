## MODIFIED Requirements

### Requirement: Repair takes priority
When several triggers are active, the addon SHALL handle them one at a time in the order repair, ammo, sell, profession trainer. A repair or ammo trip also covers selling, and a lower-priority request SHALL NOT replace a higher-priority one that is still open or active. A trainer trip does not cover selling.

#### Scenario: Both conditions active
- **WHEN** bags are at threshold and durability is below threshold
- **THEN** the target is the nearest repair vendor

#### Scenario: Repair and ammo both low
- **WHEN** gear needs repair and ammo is low
- **THEN** the repair question is asked first, and the ammo question only after it resolves

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
The addon SHALL add a "Closest Vendor" page under Options, AddOns, with an on/off checkbox and a threshold slider for each trigger (bags, durability, ammo, profession). Changes SHALL edit the same saved settings as the slash commands, take effect at once, and the panel SHALL honor the same limits as the commands. `/cvn config` SHALL open the page.

#### Scenario: Change a threshold in the panel
- **WHEN** the player moves the bag slider to 4
- **THEN** the saved bag threshold is 4 and `/cvn` reports it

#### Scenario: Slash command and panel agree
- **WHEN** the player runs `/cvn ammo 500` and then opens the panel
- **THEN** the ammo slider shows 500

#### Scenario: Profession slider
- **WHEN** the player moves the profession slider to 25
- **THEN** the saved profession threshold is 25 and `/cvn` reports it

#### Scenario: Switch a trigger off
- **WHEN** the player clears a trigger's checkbox
- **THEN** that trigger stops asking and its slider is disabled

#### Scenario: Panel unavailable
- **WHEN** the client lacks the settings API
- **THEN** the addon still loads and the slash commands work

### Requirement: Configurable thresholds
The addon SHALL persist a bag-slot threshold, a durability-percent threshold, an ammo-count threshold and a profession-points threshold per account, settable via slash command, and SHALL allow disabling each trigger independently.

#### Scenario: Custom bag threshold
- **WHEN** the user sets the bag threshold to 5
- **THEN** navigation is requested when free slots are 5 or fewer

#### Scenario: Settings report
- **WHEN** the player runs `/cvn`
- **THEN** the report includes the profession threshold and whether it is on
