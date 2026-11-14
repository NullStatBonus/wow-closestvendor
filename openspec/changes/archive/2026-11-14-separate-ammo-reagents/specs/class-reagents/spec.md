# Spec Delta

## ADDED Requirements

### Requirement: Reagents have their own switch
Reagent questions SHALL have an on/off setting of their own, on by default and saved per character, shown as a "Reagents" checkbox on the Reagents settings page with the reagent threshold and the per-reagent checkboxes below it, and set by `/cvn reagents on|off`. The ammo switch SHALL NOT affect reagents, and the reagents switch SHALL NOT affect ammo. A character saved before this setting existed SHALL start with its ammo switch's value.

#### Scenario: Ammo off, reagents on
- **WHEN** the player switches ammo off and reagents are on and low
- **THEN** the reagent question is still asked and no ammo question is

#### Scenario: Reagents off, ammo on
- **WHEN** the player runs `/cvn reagents off`
- **THEN** no reagent question is asked and ammo questions still are

#### Scenario: Earlier settings
- **WHEN** a character saved with the ammo switch off loads the addon
- **THEN** its reagents switch starts off
