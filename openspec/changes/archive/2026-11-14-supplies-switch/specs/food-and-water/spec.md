# Spec Delta

## ADDED Requirements

### Requirement: Supplies switch
The main settings page SHALL show a "Supplies" checkbox in its Warnings section, and `/cvn supplies on|off` SHALL set it. It SHALL be on by default, saved per character, and SHALL turn food, water, pet food and the healthstone reminder off together when it is off, without changing their own switches. `/cvn` SHALL show its state.

#### Scenario: Supplies off
- **WHEN** the player switches Supplies off while food is on and low
- **THEN** no food question, reminder or red supply row appears, and the food switch is still on

#### Scenario: Back on
- **WHEN** the player switches Supplies on again
- **THEN** each item uses its own switch and threshold as before
