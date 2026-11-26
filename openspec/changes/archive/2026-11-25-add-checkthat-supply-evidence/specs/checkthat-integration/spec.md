## ADDED Requirements

### Requirement: Window, config and reagent entries
The addon SHALL register `window([group])` (`hidden`, `demo`, `shown: <rows>`, only that group's rows when a group is given, or nothing when unknown), `config(name)` (an allowlisted saved setting or `hudRow.<group>`, nothing for other names) and `reagents([id])` (the watched reagents and counts from the last check, nothing when the class is unknown). Each SHALL read values the addon keeps and never the game, and follow the same rules as the other entries.

#### Scenario: Window hidden
- **WHEN** the status window is hidden and CheckThat calls `window`
- **THEN** it returns `hidden`

#### Scenario: Name not allowed
- **WHEN** CheckThat calls `config` with a name that is not on the list
- **THEN** it returns no value
