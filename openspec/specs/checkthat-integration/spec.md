# checkthat-integration Specification

## Purpose

Let the CheckThat test runner read what ClosestVendor decides, without making CheckThat a dependency.

## Requirements

### Requirement: Works without CheckThat
The addon SHALL behave the same whether CheckThat is missing, too old to offer entries, or installed and working. It SHALL NOT change settings or learned data because of CheckThat; it MAY add debug log lines at login and on a failure.

#### Scenario: CheckThat missing
- **WHEN** the player logs in without CheckThat
- **THEN** the addon starts as usual and the report says `CheckThat: not detected`

#### Scenario: Old CheckThat
- **WHEN** CheckThat is loaded but offers no way to register entries
- **THEN** the addon starts as usual, registers nothing, and the report says `CheckThat: too old`

### Requirement: Entries at login
When CheckThat is loaded at login, the addon SHALL register its entries once: `version` (major*10000 + minor*100 + patch, nothing when unknown), `setting` (the value `/cvn get <key>` prints, nothing for an unknown key) and `integration` (the CheckThat status). Entries SHALL have no side effects (not even a debug log line), return scalars of at most 100 characters, and never return character names.

#### Scenario: Version
- **WHEN** CheckThat calls `version` on ClosestVendor 1.11.0
- **THEN** it returns 11100

#### Scenario: Setting
- **WHEN** CheckThat calls `setting` with `bags.threshold` at its default
- **THEN** it returns `2`

#### Scenario: Entry error
- **WHEN** an entry raises an error
- **THEN** it returns `error: <message>` and the integration stays on

### Requirement: Active warning entry
The addon SHALL register an `active` entry that returns the warning request open or active now (`sell`, `repair`, `ammo`, `food`, `water`, `pet`, or `reagent <item id>`), and nothing when there is none. It SHALL follow the same rules as the other entries.

#### Scenario: Sell question open
- **WHEN** the sell question is open and CheckThat calls `active`
- **THEN** it returns `sell`

#### Scenario: No request
- **WHEN** no warning request is open or active
- **THEN** `active` returns no value

### Requirement: Vendor and navigation entries
The addon SHALL register the entries `learned(kind[, npcId])` (a count of learned vendors, trainers or auctioneers, or `true` when that npc is learned; nothing for an unknown kind or npc), `standing(npcId)` (`true`, `false` or nothing), `nav()` (the waypoint method in use now: `tomtom`, `waypointui`, `native` or `chat`, from a value kept current without reading the game in the entry) and `external()` (the NorgannonDB state the report shows). They SHALL follow the same rules as the other entries.

#### Scenario: Learned count
- **WHEN** CheckThat calls `learned` with `vendors` before any vendor is learned
- **THEN** it returns 0

#### Scenario: Waypoint method after a settings change
- **WHEN** the player picks the game waypoint on the settings page and CheckThat calls `nav`
- **THEN** it returns `native`

### Requirement: Window, config and reagent entries
The addon SHALL register `window([group])` (`hidden`, `demo`, `shown: <rows>`, only that group's rows when a group is given, or nothing when unknown), `config(name)` (an allowlisted saved setting or `hudRow.<group>`, nothing for other names) and `reagents([id])` (the watched reagents and counts from the last check, nothing when the class is unknown). Each SHALL read values the addon keeps and never the game, and follow the same rules as the other entries.

#### Scenario: Window hidden
- **WHEN** the status window is hidden and CheckThat calls `window`
- **THEN** it returns `hidden`

#### Scenario: Name not allowed
- **WHEN** CheckThat calls `config` with a name that is not on the list
- **THEN** it returns no value

### Requirement: Failure turns the integration off
If a CheckThat call raises an error, the addon SHALL stop calling CheckThat for the rest of the session and keep the reason, so the report shows `CheckThat: failed: <why>` even with the debug log off.

#### Scenario: Registration raises
- **WHEN** CheckThat raises while an entry is registered
- **THEN** no further CheckThat calls are made and the report shows the failure

### Requirement: Plan of record
The repository SHALL hold the in-game test plans as `plans/closestvendor.yaml` (core), `plans/closestvendor.ui.yaml` and `plans/closestvendor.addons.yaml`, each under 25 steps with its own section range. Each plan SHALL start with a version check and end with a Lua error check. Step ids `cv.s<N>.<M>` SHALL be unique across the plans, in order, and never renumbered or reused; every "test plan" reference SHALL name a step or section a plan has.

#### Scenario: Reference check
- **WHEN** a doc cites "test plan 3.2" and the plans have no `cv.s3.2`
- **THEN** the automated tests fail

#### Scenario: Plan too long
- **WHEN** one of the three plans has 25 steps or more
- **THEN** the automated tests fail

#### Scenario: Plan set
- **WHEN** one of the three plans is missing, or a plan does not start with its version step
- **THEN** the automated tests fail

### Requirement: Plans run under test settings
Each plan's setup step SHALL turn the debug log on, then test settings on, then reload, and SHALL assert the debug log, the login marker and `test settings: on at login` in that order. Each plan's last step SHALL turn test settings off and assert `test settings: off (own settings restored)` in that attempt. Each version step SHALL require 1.12.0 or newer.

#### Scenario: Tester with own settings
- **WHEN** a tester whose settings say "Navigate without asking" runs the core plan
- **THEN** the sell question appears in check 1.1, and after the last step the tester's settings are as before
