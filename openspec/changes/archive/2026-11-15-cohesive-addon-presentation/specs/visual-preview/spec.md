## ADDED Requirements

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
