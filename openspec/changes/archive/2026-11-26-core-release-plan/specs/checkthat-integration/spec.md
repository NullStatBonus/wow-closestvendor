## MODIFIED Requirements

### Requirement: Plan of record
The repository SHALL hold one core plan, `plans/closestvendor.yaml`, as the release gate. A feature plan, `plans/closestvendor.<feature>.yaml`, MAY be added when a feature is built or changed; it is not part of the release gate. Each plan SHALL stay under 25 steps with its own section range, start with a version check and end with a Lua error check. Step ids `cv.s<N>.<M>` SHALL be unique, in order, and never renumbered or reused, and every "test plan" reference SHALL name a step a plan has.

#### Scenario: Reference check
- **WHEN** a doc cites a numbered plan check (as "test plan" and a step number) that no plan step has
- **THEN** the automated tests fail

#### Scenario: Plan too long
- **WHEN** a plan has 25 steps or more
- **THEN** the automated tests fail

#### Scenario: Plan set
- **WHEN** the core plan is missing, a plan file is not in the plan list, or a plan does not start with its version step
- **THEN** the automated tests fail

#### Scenario: Retired id reused
- **WHEN** a plan has a step id that an earlier version of the plans removed, or a section from s10 to s29 (the removed ui and addons plans)
- **THEN** the automated tests fail

### Requirement: Plans run under test settings
Each plan's setup step SHALL turn the debug log on, then test settings on, then reload, and SHALL assert the debug log, the login marker and `test settings: on at login` in that order. Each plan's last step SHALL turn test settings off and assert `test settings: off (own settings restored)` in that attempt. The core plan's version step SHALL require 1.13.0 or newer; a feature plan's version step SHALL require the version that has what it checks.

#### Scenario: Tester with own settings
- **WHEN** a tester whose settings say "Navigate without asking" runs the core plan
- **THEN** the sell question appears in check 1.1 or check 1.2, and after the last step the tester's settings are as before

## ADDED Requirements

### Requirement: Core plan needs one ordinary character
The core plan SHALL be runnable by one character of any class and any level with no profession, standing in a capital city near a vendor, a repair vendor and a profession trainer, with at least 3 free bag slots and no addon besides ClosestVendor and CheckThat. No core plan step SHALL need a class, a profession, an instance, combat or another addon. A step for one client SHALL be limited to that client.

#### Scenario: Class-gated step
- **WHEN** a core plan step's setup names a class, a profession, a dungeon, a fight or another addon
- **THEN** the automated tests fail

#### Scenario: Either client
- **WHEN** the core plan runs on WoW Forever or on Classic Era
- **THEN** each step is either shown for that client or limited to the other client, and no step is blocked for this character

### Requirement: Core plan proves the foundation
The core plan SHALL prove, in the real game, that: a real bag threshold crossing asks the sell question, and the waypoint shows on Forever and as a chat line on Era; the status window shows the low Bag space row; opening the vendor clears the waypoint and learns it; restoring the threshold removes the Bag space row; the repair, food and trainer questions name a target that fits (the food question with the real count); and a learned vendor survives `/reload`.

#### Scenario: Real reads
- **WHEN** the sell warning starts in the core plan
- **THEN** its `trigger go sell` line carries the real `bags=` count and a `durability=` value

#### Scenario: Learned vendor survives reload
- **WHEN** the tester reloads after the vendor was learned and opens that vendor again
- **THEN** its learned line says updated or unchanged, not new

### Requirement: Core plan reads like player steps
Each core plan step's action text SHALL be one player-language sentence after its fixed opener, without slash commands or color codes; the commands SHALL appear only behind Run. Each Expect SHALL describe what the player sees, not what is logged. No step SHALL exist only to restore a setting.

#### Scenario: Command in action text
- **WHEN** a core plan step's action text contains `/cvn` or a `|cff` color code
- **THEN** the automated tests fail
