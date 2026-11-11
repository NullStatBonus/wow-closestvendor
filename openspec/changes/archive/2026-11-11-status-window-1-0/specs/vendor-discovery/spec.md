## ADDED Requirements

### Requirement: Record auctioneers
Opening an auction house window SHALL record that auctioneer, in the same way as a merchant, with the same replace-and-bound rules, and learned auctioneers SHALL win over shipped ones with the same id.

#### Scenario: Learn an auctioneer
- **WHEN** the player opens an auction house
- **THEN** that auctioneer is saved and used for later searches

#### Scenario: Learned wins
- **WHEN** a shipped auctioneer is opened
- **THEN** the learned record replaces the shipped one
