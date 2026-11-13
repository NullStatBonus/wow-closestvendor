## ADDED Requirements

### Requirement: Report lists supply settings
The report header SHALL have a line with food, water, pet food and the healthstone reminder each on or off, with the thresholds of food, water and pet food, and with the debug log on SHALL log each supply question or reminder decision (what was low, the count, and the target or why none).

#### Scenario: Header
- **WHEN** the player runs `/cvn log`
- **THEN** the header shows "supplies: food on (5), water on (5), pet food on (5), healthstone reminder on" on default settings

#### Scenario: Decision logged
- **WHEN** a food question is shown with the debug log on
- **THEN** the log records food, the count and the chosen vendor
