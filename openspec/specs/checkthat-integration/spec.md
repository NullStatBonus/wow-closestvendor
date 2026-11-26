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

### Requirement: Failure turns the integration off
If a CheckThat call raises an error, the addon SHALL stop calling CheckThat for the rest of the session and keep the reason, so the report shows `CheckThat: failed: <why>` even with the debug log off.

#### Scenario: Registration raises
- **WHEN** CheckThat raises while an entry is registered
- **THEN** no further CheckThat calls are made and the report shows the failure

### Requirement: Plan of record
The repository SHALL hold the in-game test plan as `plans/closestvendor.yaml`. Its first step SHALL check the version under test. Step ids `cv.s<N>.<M>` SHALL be unique, in order, and never renumbered or reused; every "test plan" reference in the code and docs SHALL name a step or section the plan has.

#### Scenario: Reference check
- **WHEN** a doc cites "test plan 3.2" and the plan has no `cv.s3.2`
- **THEN** the automated tests fail
