# diagnostics Specification

## Purpose
Let a player capture what the addon saw and decided, so problems can be reported and in-game unknowns settled.

## Requirements

### Requirement: Debug log switch
The addon SHALL keep a debug log that is off by default, toggled with `/cvn debug on` and `/cvn debug off`, persisted between sessions, and holds at most 1000 entries, dropping the oldest.

#### Scenario: Off by default
- **WHEN** the addon runs for the first time
- **THEN** nothing is recorded

#### Scenario: Bounded
- **WHEN** more than 1000 entries are recorded
- **THEN** only the newest 1000 are kept

### Requirement: What is recorded
While the log is on, the addon SHALL record the game events it reacts to (except worn-gear events, which are folded into one line per check), failures of guarded game calls, trigger decisions, the vendor found or why none was, and whether the question was shown, accepted or dismissed.

#### Scenario: Bag event
- **WHEN** the log is on and a bag event arrives
- **THEN** the event name is recorded

#### Scenario: Gear events
- **WHEN** the log is on and durability or inventory events arrive in a burst
- **THEN** no line is recorded per event, and one line gives how many were folded into one check

#### Scenario: Adapter failure
- **WHEN** a guarded game call fails
- **THEN** the failing call and its error text are recorded, once per kind of failure

### Requirement: Warning decisions are recorded
While the log is on, the addon SHALL record each warning decision a test plan checks, once per change so bursts do not fill the log: a request held back (in an instance, while dead, in combat, in that order), a vendor question closed because the merchant window opened, a purchase question closed with the merchant, the ammo it watches (or why none), and what a purchase bought. A failed purchase call, or a question still shown after the addon tried to close it, is recorded with `FAILED:`.

#### Scenario: Held in combat
- **WHEN** bags are nearly full while the player is in combat
- **THEN** one line `trigger held in combat: sell` is recorded, not one per bag event

#### Scenario: Dead and in combat
- **WHEN** a request is held while the player is dead and in combat
- **THEN** the line names death: `trigger held while dead: <kind>`

#### Scenario: Question closed by the merchant
- **WHEN** a sell question is open and the player opens a merchant
- **THEN** `question closed: merchant opened (sell)` is recorded once the question is gone; an open trainer question stays and writes nothing

#### Scenario: Purchase
- **WHEN** an ammo purchase goes through for some batches and a game call fails for another
- **THEN** the bought line counts only the batches the game took, and the failure is recorded with `FAILED:`

### Requirement: Vendor, trainer and waypoint decisions are recorded
While the log is on, the addon SHALL record each vendor, trainer and waypoint decision a test plan checks, after its effect: vendors and trainers learned or not, waypoints cleared, kept or not confirmed, trainer searches, profession checks skipped or skills left out, the choice between two candidates, and why a direct pin is not routed. A line repeats only when its text without ranks changes or after a quiet time. A clear that raises an error is recorded with `FAILED:`.

#### Scenario: Vendor learned
- **WHEN** the player opens a merchant the addon does not know
- **THEN** one line `vendor learned: <name> (npc <id>), new` is recorded

#### Scenario: Waypoint clear not confirmed
- **WHEN** the addon removes its waypoint but the waypoint method cannot confirm the removal
- **THEN** `waypoint clear not confirmed: ...` is recorded, not `waypoint cleared:`

#### Scenario: Skill-ups do not flood the log
- **WHEN** a weapon skill rises point by point near its cap
- **THEN** its left-out line is recorded once, not once per point

### Requirement: Status window, settings and purchase questions are recorded
While the log is on, the addon SHALL record when the status window is shown or hidden and which rows it shows, only when that changes (never for a count alone, never during a demo, preview or Move); each setting change with its old and new value, once per change; a purchase question asked (after the game shows it) or declined, and a purchase that bought fewer than asked; a reminder held back (combat, instance, dead); and an auctioneer learned. A logging failure SHALL NOT switch the window off.

#### Scenario: Count change
- **WHEN** the free bag slots change but the rows and low flags stay the same
- **THEN** no status window line is recorded

#### Scenario: Setting changed
- **WHEN** the player types `/cvn bags 3` with the threshold at 2
- **THEN** `setting changed: bagThreshold 2 -> 3` is recorded once

#### Scenario: Replaced question
- **WHEN** a purchase question is replaced by a new one
- **THEN** no `declined` line is recorded

### Requirement: Copyable report
`/cvn log` SHALL show a report that can be selected and copied, containing the addon version, client interface and build, locale, the waypoint method in use and the chosen preference, vendor counts, current settings, the CheckThat status (`working`, `not detected`, `too old` or `failed: <why>`), and the recorded entries. If a window cannot be created, it SHALL print the most recent entries to chat.

#### Scenario: Report with the log off
- **WHEN** the player runs `/cvn log` with the log off
- **THEN** the report is shown with the header and a note that the log is off

#### Scenario: No window available
- **WHEN** creating the window fails
- **THEN** the latest entries are printed to chat and no error is raised

#### Scenario: CheckThat status in the report
- **WHEN** the player runs `/cvn log` without CheckThat installed
- **THEN** the header has the line `CheckThat: not detected`

### Requirement: Report lists window settings
The report header SHALL list the status window settings (lock, scale, background opacity, background color, text opacity and each row mode that is not the default), the dungeon and raid anchor, and the auction house setting, and one line saying whether the color picker and settings button exist and whether the background color swatch was built (and what was missing if not), and the log SHALL record instance state changes and row clicks.

#### Scenario: Header
- **WHEN** the player runs `/cvn log`
- **THEN** the header shows the window, anchor and auction settings

#### Scenario: Click logged
- **WHEN** the player clicks a row
- **THEN** the log records which row and what was pinned

### Requirement: Report lists reagent buying
The report header SHALL have a line with reagent buying on or off, whether it asks first, and the amount of each reagent to carry, and with the debug log on each merchant visit SHALL log what reagent buying decided (off, amount 0, nothing watched, nothing sold, unreadable data, or the plan with its cost and why it fell short).

#### Scenario: Header
- **WHEN** the player runs `/cvn log`
- **THEN** the header shows "reagent buying: off, asks first, up to 20 of each" on default settings

### Requirement: Report lists supply settings
The report header SHALL have a line with food, water, pet food and the healthstone reminder each on or off, with the thresholds of food, water and pet food, and with the debug log on SHALL log each supply question or reminder decision (what was low, the count, and the target or why none).

#### Scenario: Header
- **WHEN** the player runs `/cvn log`
- **THEN** the header shows "supplies: food on (5), water on (5), pet food on (5), healthstone reminder on" on default settings

#### Scenario: Decision logged
- **WHEN** a food question is shown with the debug log on
- **THEN** the log records food, the count and the chosen vendor

### Requirement: Presentation diagnostics
The report SHALL list notification enabled state, selected warning/toast style, toast position and appearance, HUD appearance and active character scope, and whether demo/preview/Move mode is active. Preview sample state SHALL be distinguishable from live state and SHALL NOT overwrite recorded real decisions.

#### Scenario: Report presentation
- **WHEN** `/cvn log` is run after selecting Toast
- **THEN** the report names Toast, notice enabled state and effective visual settings without changing them

### Requirement: Trainer service probe
With debugging on, opening a profession trainer window SHALL log the number of listed services and the trainer filter states, then one line per service with its skill line, name, rank text, type, level requirement and skill requirement. Values the client does not provide SHALL be logged as nil. The addon SHALL NOT change the trainer filters. With debugging off, nothing SHALL be logged.

#### Scenario: Capture a trainer
- **WHEN** debugging is on and the player opens a Mining trainer
- **THEN** the log lists each service the window shows, with its requirements, and the filters are unchanged
