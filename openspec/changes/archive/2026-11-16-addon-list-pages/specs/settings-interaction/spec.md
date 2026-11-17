## ADDED Requirements

### Requirement: AddOns list pages
Where the game supports addon settings categories, the Closest Vendor entry in Options > AddOns SHALL open Home, and Restock, Navigation, Appearance, Advanced and About SHALL be listed under it in tree order, each opening that page of the same settings tree. A failure to register these entries SHALL leave the standalone settings window working.

#### Scenario: Pages under the entry
- **WHEN** the player opens Options > AddOns
- **THEN** Closest Vendor shows its pages under its name, like KeepThat and Don't Do That, and selecting the entry shows Home

#### Scenario: Same values in both places
- **WHEN** the player changes a setting on a page in the AddOns list and then opens `/cvn settings`
- **THEN** the standalone window shows the same value
