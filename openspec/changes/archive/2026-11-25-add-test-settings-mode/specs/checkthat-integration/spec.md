## ADDED Requirements

### Requirement: Plans run under test settings
Each plan's setup step SHALL turn the debug log on, then test settings on, then reload, and SHALL assert the debug log, the login marker and `test settings: on at login` in that order. Each plan's last step SHALL turn test settings off and assert `test settings: off (own settings restored)` in that attempt. Each version step SHALL require 1.12.0 or newer.

#### Scenario: Tester with own settings
- **WHEN** a tester whose settings say "Navigate without asking" runs the core plan
- **THEN** the sell question appears in check 1.1, and after the last step the tester's settings are as before
