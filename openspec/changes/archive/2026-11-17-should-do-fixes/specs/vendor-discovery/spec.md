## MODIFIED Requirements

### Requirement: Record opened merchants
When a merchant window opens, the addon SHALL record that merchant's NPC id, name, repair capability, faction group, and the player's map position, keyed by NPC id, in saved variables. When the merchant list is only partly readable (an item link the game has not loaded), the addon SHALL NOT replace a known vendor's record, and SHALL read the list again when item data arrives while the window is open; a vendor not known yet SHALL be recorded from what could be read.

#### Scenario: New vendor
- **WHEN** the player opens a merchant that is not yet known
- **THEN** it is stored and becomes eligible as a navigation target

#### Scenario: Repair vendor
- **WHEN** the merchant can repair
- **THEN** it is stored as repair-capable

#### Scenario: Items not loaded yet
- **WHEN** the player opens a known ammo vendor before the game has loaded its items
- **THEN** the vendor still counts as selling ammo, and the record is updated once the items load

### Requirement: Vendors this character cannot trade with are skipped
Each character SHALL remember whether each known vendor, profession trainer and auctioneer trades with it: yes at Neutral or better or when its merchant, trainer or auction window opens, no at Unfriendly or Hostile, as seen on target, mouseover or nameplate. The search SHALL skip vendors, trainers and auctioneers seen as no. A learned vendor of no side that is not shipped or external SHALL be used only after this character has seen it trade.

#### Scenario: Taught by another character
- **WHEN** a clan quartermaster of no side was learned by another character and this character has never seen it
- **THEN** it is not offered

#### Scenario: Seen as Unfriendly
- **WHEN** this character targets or mouses over a known vendor and the game reports Unfriendly
- **THEN** that vendor is never offered to this character until it is seen at Neutral or better

#### Scenario: Seen as Friendly
- **WHEN** this character sees a learned vendor of no side at Friendly
- **THEN** it can be offered

#### Scenario: Not a vendor
- **WHEN** this character targets a creature that is not a known vendor
- **THEN** nothing is stored

#### Scenario: No reaction
- **WHEN** the game reports no reaction for a seen vendor
- **THEN** nothing changes

#### Scenario: Goblin auction house while Unfriendly
- **WHEN** this character, Unfriendly with the Steamwheedle Cartel, targets the Booty Bay auctioneer
- **THEN** a row click never routes to that auctioneer until it is seen at Neutral or better
