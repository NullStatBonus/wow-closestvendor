## ADDED Requirements

### Requirement: Small moves keep the saved position
When the player opens the window of a vendor, trainer or auctioneer the account already learned, on the same map and within 0.005 of the saved position on both axes, the addon SHALL keep the saved position. The record SHALL change only when the position moved further, the map differs, or another recorded field differs; a visit with no such change SHALL be logged as `unchanged`.

#### Scenario: Standing a step away
- **WHEN** the player opens a known vendor's window 0.002 from its saved position, and its stock is the same
- **THEN** the saved record is not changed and the learned line says unchanged

#### Scenario: The vendor moved
- **WHEN** the player opens a known vendor's window 0.02 from its saved position
- **THEN** the saved position becomes the new one and the learned line says updated

#### Scenario: Stock changed, position nearly the same
- **WHEN** a known vendor now sells arrows and the player stands 0.002 from its saved position
- **THEN** the record is updated with the arrows and keeps its saved position
