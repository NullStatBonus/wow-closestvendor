## ADDED Requirements

### Requirement: Worn-gear events are batched
Durability and inventory-change events for the player SHALL start one check shortly after the first of a burst, however many arrive before it runs. A client without timers SHALL check at once.

#### Scenario: Durability burst
- **WHEN** five durability events and one inventory event arrive within the delay
- **THEN** one check runs, and it finds a low durability

