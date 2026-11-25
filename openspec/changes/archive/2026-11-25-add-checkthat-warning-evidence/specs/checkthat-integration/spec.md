## ADDED Requirements

### Requirement: Active warning entry
The addon SHALL register an `active` entry that returns the warning request open or active now (`sell`, `repair`, `ammo`, `food`, `water`, `pet`, or `reagent <item id>`), and nothing when there is none. It SHALL follow the same rules as the other entries.

#### Scenario: Sell question open
- **WHEN** the sell question is open and CheckThat calls `active`
- **THEN** it returns `sell`

#### Scenario: No request
- **WHEN** no warning request is open or active
- **THEN** `active` returns no value
