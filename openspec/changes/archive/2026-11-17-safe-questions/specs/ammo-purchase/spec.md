## ADDED Requirements

### Requirement: Ammo purchase question ends with its merchant
The ammo purchase question SHALL use a dialog of its own and SHALL close when the merchant window closes. Yes SHALL buy only if the open merchant still offers the chosen item at the same slot; otherwise it SHALL buy nothing and report no purchase.

#### Scenario: Merchant closed before Yes
- **WHEN** the merchant window closes while the ammo question is open
- **THEN** the question closes and nothing is bought

#### Scenario: Different merchant
- **WHEN** Yes is answered while a merchant offers a different item at that slot
- **THEN** nothing is bought and no "Bought" line is printed
