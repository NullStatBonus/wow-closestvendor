## ADDED Requirements

### Requirement: Test settings follow the CheckThat run
When CheckThat offers a run callback, the addon SHALL register it at login. A run start of a ClosestVendor plan SHALL turn test settings on, once per run. A run end SHALL turn them off and restore the tester's settings. At login, test settings that a run turned on SHALL be turned off when CheckThat reports no open ClosestVendor run. Test settings turned on by command SHALL NOT be turned off at login. Without the callback nothing SHALL change.

#### Scenario: Run ended early
- **WHEN** test settings were turned on by a run and the tester ends that run before the last step
- **THEN** test settings are off and the tester's own settings are back

#### Scenario: Reload after the last step
- **WHEN** the last step turned test settings off and the tester reloads while the run is still open
- **THEN** test settings stay off

#### Scenario: Run gone at login
- **WHEN** test settings were turned on by a run, and at the next login CheckThat reports no open ClosestVendor run
- **THEN** test settings are off and the tester's own settings are back

#### Scenario: Another run at login
- **WHEN** a run left test settings on and changed them, it ended while the addon was not loaded, and another run is open at the next login
- **THEN** the new run uses fresh defaults and the tester's own settings stay put aside

#### Scenario: Turned on by hand
- **WHEN** the player typed `/cvn testsettings on` and no run is open at login
- **THEN** test settings stay on

#### Scenario: Old CheckThat
- **WHEN** CheckThat has no run callback
- **THEN** test settings change only by command

## MODIFIED Requirements

### Requirement: Window, config and reagent entries
The addon SHALL register `window([group])` (`hidden`, `demo`, `shown: <rows>`, only that group's rows when a group is given, or nothing when unknown), `config(name)` (an allowlisted saved setting or `hudRow.<group>`, nothing for other names) and `reagents([id])` (the watched reagents and counts from the last check, nothing when the class or a count is unknown). Each SHALL read values the addon keeps and never the game, and follow the same rules as the other entries.

#### Scenario: Window hidden
- **WHEN** the status window is hidden and CheckThat calls `window`
- **THEN** it returns `hidden`

#### Scenario: Name not allowed
- **WHEN** CheckThat calls `config` with a name that is not on the list
- **THEN** it returns no value

#### Scenario: Reagent count unread
- **WHEN** the last check could not read the count of a watched reagent and CheckThat calls `reagents`
- **THEN** it returns no value, never `none`
