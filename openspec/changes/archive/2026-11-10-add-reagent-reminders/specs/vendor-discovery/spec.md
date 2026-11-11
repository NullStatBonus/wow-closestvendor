## ADDED Requirements

### Requirement: Record reagents sold
When a merchant window opens, the addon SHALL also record which watched reagents the merchant offers, and SHALL keep that information when the merchant replaces a shipped record.

#### Scenario: Reagent vendor opened
- **WHEN** the player opens a merchant that offers Holy Candles
- **THEN** it is stored as a seller of that reagent and becomes a target for it

#### Scenario: Shipped reagent vendor opened
- **WHEN** the player opens a merchant that the shipped data lists as a reagent seller
- **THEN** its learned record still marks the reagents it sells

#### Scenario: Stock changes
- **WHEN** a merchant is opened again and its reagent offer differs
- **THEN** the stored record is updated
