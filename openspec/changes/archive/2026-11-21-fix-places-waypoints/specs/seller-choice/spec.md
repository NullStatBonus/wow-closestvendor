## ADDED Requirements

### Requirement: Picked seller still fits
When the player picks a vendor or trainer entry, the addon SHALL check that it still fits the row: the vendor sells what the row needs now, or the trainer teaches the row's profession. If it does not fit, or the row no longer applies (no ranged weapon, pet or near-cap profession), the addon SHALL pin nothing, leave the waypoint and warning as they are, and say in chat to open the list again.

#### Scenario: Weapon changed while the list was open
- **WHEN** the player opens the arrow seller list, equips a gun, and picks a vendor that sells only arrows
- **THEN** nothing is pinned and chat says to open the list again

#### Scenario: Weapon put away
- **WHEN** the player opens the arrow seller list, unequips the bow, and picks a vendor
- **THEN** nothing is pinned and chat says to open the list again

#### Scenario: Seller still fits
- **WHEN** the player picks a vendor that sells what the row needs
- **THEN** it is pinned as before
