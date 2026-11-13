## ADDED Requirements

### Requirement: Supply seller flags
Each vendor record SHALL say whether the vendor sells food, sells water, and which pet diets (Meat, Fish, Bread, Cheese, Fruit, Fungus) it sells an item for, taken from the source's sold-by lists and the shipped item table.

#### Scenario: Food vendor
- **WHEN** the source lists a vendor as selling an item the table marks as food
- **THEN** its record marks food

#### Scenario: Cheese vendor
- **WHEN** the source lists a vendor as selling an item the table marks as Cheese for pets
- **THEN** its record marks the Cheese diet

#### Scenario: Non-seller
- **WHEN** a vendor sells no listed food, drink or diet item
- **THEN** its record marks no supply

#### Scenario: Kind without any seller
- **WHEN** the source lists no vendor for a diet
- **THEN** the build reports it so the diet can be reviewed

### Requirement: Shipped item table
The addon SHALL ship a generated table of food, drink and pet diet items, built reproducibly from a pinned source by a tool, with each item's kind and diet. The build SHALL fail on an item with no kind or an unknown diet, and the table SHALL be checked against the same client data version as the reagent items.

#### Scenario: Reproducible
- **WHEN** the table is built twice from the same pinned inputs
- **THEN** the two results are identical

#### Scenario: Bad entry
- **WHEN** the source gives an item an unknown diet
- **THEN** the build fails and names the item
