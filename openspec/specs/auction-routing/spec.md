# auction-routing Specification

## Purpose
Lets the player opt in to navigating to the closest auctioneer for a tradeable reagent or ammo when it is nearer than any vendor, using shipped and learned auctioneer locations, without changing the automatic warnings.

## Requirements

### Requirement: Auction house routing setting
The addon SHALL have a setting `ahEnabled`, off by default, with a checkbox on the main settings page and `/cvn ah on` and `/cvn ah off`. When on, a row click for an item that is not soulbound SHALL pin the nearest auctioneer instead of the nearest vendor if the auctioneer is closer. A soulbound item SHALL never be routed to an auctioneer.

#### Scenario: Off by default
- **WHEN** the player has not changed any setting
- **THEN** row clicks go to vendors only

#### Scenario: Auction house closer
- **WHEN** the setting is on and an auctioneer is closer than the nearest vendor for a tradeable item
- **THEN** the auctioneer is pinned and the notice says to buy at the auction house

#### Scenario: Vendor closer
- **WHEN** the setting is on and a vendor is closer than any auctioneer
- **THEN** the vendor is pinned

#### Scenario: No vendor known
- **WHEN** the setting is on and no vendor is known for the item but an auctioneer is
- **THEN** the auctioneer is pinned

#### Scenario: Not in instances
- **WHEN** the player is in an instance
- **THEN** the setting has no effect

### Requirement: Automatic triggers unaffected
Automatic warnings (the questions and automatic pins) SHALL keep choosing vendors only.

#### Scenario: Question stays vendor-only
- **WHEN** the setting is on and ammo runs low
- **THEN** the question offers vendors only
