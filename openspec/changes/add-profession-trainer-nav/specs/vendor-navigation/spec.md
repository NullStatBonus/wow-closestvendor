## MODIFIED Requirements

### Requirement: Nearest eligible vendor
The addon SHALL choose the target with the smallest straight-line distance to the player among those on the player's continent that are not hostile-faction and that satisfy the required capability (sell, repair, or the ammo kind), or, for a profession trigger, among known trainers for that profession.

#### Scenario: Sell target
- **WHEN** a sell trigger fires
- **THEN** the nearest friendly-or-neutral vendor of any kind is chosen

#### Scenario: Repair target
- **WHEN** a repair trigger fires
- **THEN** only repair-capable vendors are considered

#### Scenario: Ammo target
- **WHEN** an arrow or bullet trigger fires
- **THEN** only vendors selling that ammo are considered

#### Scenario: Trainer target
- **WHEN** a profession trigger fires for Mining
- **THEN** only known Mining trainers are considered and the nearest is chosen

#### Scenario: Other professions ignored
- **WHEN** the nearest trainer teaches Herbalism and a farther one teaches Mining
- **THEN** the Mining trainer is chosen for a Mining trigger

#### Scenario: Hostile faction excluded
- **WHEN** the nearest vendor or trainer belongs to the opposing faction
- **THEN** it is skipped in favor of the nearest eligible one
