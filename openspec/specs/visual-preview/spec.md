# visual-preview Specification

## Purpose
Safe samples of each surface, the real routing demo that restores the previous waypoint, and transactional Move positioning.

## Requirements

### Requirement: Real routing demo
`/cvn demo` SHALL run a tour of real outcomes through the production code, one step every five seconds, using real vendor data, waypoints, questions and the chosen notification style and sound. Each step SHALL take back the previous step's waypoint and question. At the end, the player's previous waypoint SHALL be restored. Demo SHALL NOT change settings, buy, or mark a warning as handled.

#### Scenario: Range of outcomes
- **WHEN** demo runs on a character with known vendors
- **THEN** in turn: a route pinned without asking with its notification, a navigation question, food, water (mana classes) or pet food (hunters), arrows, a status-window row click for the first watched class reagent (auction house when closer) or repair, and a class reminder or test notification

#### Scenario: Restore context
- **WHEN** the player had a waypoint before the demo and the tour ends
- **THEN** that waypoint is set again and no setting has changed

#### Scenario: Notice off
- **WHEN** the on-screen notice is off and demo runs
- **THEN** its notifications still show in the chosen style with the sound

#### Scenario: Restart
- **WHEN** demo is run again before the tour ends
- **THEN** the older tour's timers do nothing and the newer tour runs

### Requirement: Focused visual previews
`/cvn preview` SHALL list supported kinds: notice, hud, prompt. `preview <kind>` and an Appearance Preview action SHALL show one isolated synthetic visual using current appearance for ten seconds; `notice` SHALL use the chosen style and play the notification sound. Samples SHALL NOT buy, navigate or change settings. Existing test commands SHALL retain their integration-test semantics, separate from safe previews.

#### Scenario: Notice sample
- **WHEN** `/cvn preview notice` runs with Style Warning and the notice off
- **THEN** a sample Warning shows with the notification sound and no setting changes

#### Scenario: Unknown kind
- **WHEN** an unsupported preview kind is supplied
- **THEN** valid kinds are listed and no gameplay action occurs

### Requirement: Transactional Move mode
Appearance SHALL offer clamped placeholder Move mode with visible Done and Cancel above the settings window. Move SHALL snapshot the start, commit only on Done and restore on Cancel/Escape. The status-window Lock position SHALL block HUD movement until explicitly unlocked. Toast SHALL have no lock and SHALL move only through Move mode. Reset position SHALL change only position. Positions SHALL use existing profile/character scope.

#### Scenario: Done
- **WHEN** a placeholder is moved and Done is chosen
- **THEN** the clamped position is saved and later visuals use it

#### Scenario: Cancel or Escape
- **WHEN** a placeholder is moved and Cancel or Escape is used
- **THEN** the starting position returns and persisted position is unchanged

#### Scenario: Locked
- **WHEN** the status-window position is locked and Move or drag is attempted
- **THEN** the position does not change and the UI explains how to unlock

#### Scenario: Profile change while moving
- **WHEN** the active scope changes during Move mode
- **THEN** the old move is cancelled without writing its tentative position into either scope

#### Scenario: Move targets
- **WHEN** Move is chosen
- **THEN** the player can move the status window or separately saved toast anchor

#### Scenario: Normal input
- **WHEN** Move mode is not active
- **THEN** unlocked title-drag/Shift-drag shortcuts keep their normal saving behavior and routable rows retain navigation clicks

### Requirement: Demo keeps the game waypoint
When the game's own map waypoint holds the player's point (not one this addon set) before `/cvn demo` or between its steps, the addon SHALL note the newest such point. At the end of the tour (or when the tour is stopped), if the slot is empty or holds a point this addon set, the addon SHALL set the noted point again; if the slot holds the player's point, the addon SHALL leave it, and SHALL NOT put its own earlier waypoint over it.

#### Scenario: Game waypoint before the demo
- **WHEN** the player has a map waypoint of their own, the addon uses the game waypoint, and the demo runs to the end
- **THEN** the player's map waypoint is set again

#### Scenario: New waypoint during the demo
- **WHEN** the player sets a new map waypoint while the demo runs, and a later step uses the game waypoint
- **THEN** at the end the player's new waypoint is set again, not the one from before the demo

#### Scenario: New waypoint in the last step
- **WHEN** the addon had its own game waypoint before the demo and the player sets a new one in the last step
- **THEN** the player's waypoint stays and the addon's earlier waypoint is not set again

### Requirement: Demo end is safe
When a step timer cannot be scheduled, the demo SHALL end and the made-up status window rows SHALL go away. When the game waypoint cannot be read at the end, the addon SHALL NOT set the noted waypoint again and SHALL log why.

#### Scenario: Timer fails mid-tour
- **WHEN** the demo cannot schedule its next step
- **THEN** the demo ends and the real status window rows are back

#### Scenario: Unreadable game waypoint
- **WHEN** the game waypoint read fails at the end of the demo
- **THEN** no waypoint is set and the log says it was not set again

### Requirement: Demo ends without overwriting the player's point
At the end of the demo the addon SHALL NOT set its own earlier game waypoint when the game waypoint cannot be read. The demo and the waypoint clear SHALL use the same tolerance (0.00001 of the map) to tell the addon's point from the player's, so a point the player sets very near a demo pin stays.

#### Scenario: Unreadable slot at the end
- **WHEN** the addon had its own game pin, the player sets a waypoint in the last step, and the game cannot read the slot at the end
- **THEN** the player's waypoint stays

#### Scenario: Stop with a nearby player point
- **WHEN** the player sets a waypoint 0.0005 from a demo pin and the demo is stopped
- **THEN** the player's waypoint stays
