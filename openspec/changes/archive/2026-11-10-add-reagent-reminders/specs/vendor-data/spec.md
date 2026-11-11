## ADDED Requirements

### Requirement: Reagent seller flags
Each record SHALL say which of the watched class reagents the vendor sells, taken from the source's sold-by lists for those items.

#### Scenario: Reagent vendor
- **WHEN** the source lists a vendor as selling Arcane Powder
- **THEN** its record marks that reagent

#### Scenario: Non-seller
- **WHEN** a vendor sells none of the watched reagents
- **THEN** its record marks no reagent

#### Scenario: Reagent without any seller
- **WHEN** the source lists no vendor for a watched reagent
- **THEN** the build reports it so the reagent can be reviewed
