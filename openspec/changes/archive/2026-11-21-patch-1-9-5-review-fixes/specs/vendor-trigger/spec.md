## ADDED Requirements

### Requirement: A waiting gear check runs before a merchant opens
When a merchant window opens while a batched worn-gear check is waiting, the addon SHALL run that check first, so a repair question it makes is the one the merchant answers.

#### Scenario: Merchant within the delay
- **WHEN** durability drops below the threshold and a merchant opens within the batching delay
- **THEN** no repair question is left open
