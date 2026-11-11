## ADDED Requirements

### Requirement: Shipped auctioneers
The shipped data SHALL include a separate list of auctioneers (name, map, position, faction) built from the same pinned pfQuest source, reproducibly, and records without coordinates SHALL be dropped as for vendors.

#### Scenario: Auctioneer list
- **WHEN** the data is built
- **THEN** the auctioneer list holds the pfQuest auctioneers that have coordinates, and neutral ones are marked for both factions

#### Scenario: Reproducible
- **WHEN** the build runs twice
- **THEN** the output is byte-identical
