## ADDED Requirements

### Requirement: Reagent purchase question ends with its merchant
The reagent purchase question SHALL close when the merchant window closes. Yes SHALL buy only if the open merchant still offers every planned reagent at its slot; otherwise it SHALL buy nothing and report no purchase.

#### Scenario: Merchant closed before Yes
- **WHEN** the merchant window closes while the reagent question is open
- **THEN** the question closes and nothing is bought

#### Scenario: A slot changed
- **WHEN** Yes is answered and any planned slot now holds another item
- **THEN** nothing is bought and no "Bought" line is printed
