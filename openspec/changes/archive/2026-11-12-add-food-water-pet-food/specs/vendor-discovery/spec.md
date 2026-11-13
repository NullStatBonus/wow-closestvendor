## ADDED Requirements

### Requirement: Record supplies sold
When a merchant window opens, the addon SHALL also record whether the merchant offers food, offers water, and which pet diets it offers an item for, and SHALL keep that information when the merchant replaces a shipped record.

#### Scenario: Baker opened
- **WHEN** the player opens a merchant that offers bread
- **THEN** it is stored as a seller of food and of the Bread diet and becomes a target for them

#### Scenario: Shipped record kept
- **WHEN** the player opens a merchant that the shipped data lists as a food seller
- **THEN** its learned record still marks food

#### Scenario: Stock changes
- **WHEN** a merchant is opened again and its food offer differs
- **THEN** the stored record is updated
