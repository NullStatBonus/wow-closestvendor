## ADDED Requirements

### Requirement: Closest by true distance
The addon SHALL compare an auctioneer and a vendor by their exact distance, not by distances rounded to whole yards.

#### Scenario: Same whole yards
- **WHEN** a vendor is 30 yards away and an auctioneer is 29.6 yards away
- **THEN** the auctioneer is the closer one

