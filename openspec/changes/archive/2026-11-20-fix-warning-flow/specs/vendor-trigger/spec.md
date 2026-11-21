## ADDED Requirements

### Requirement: The next need after No waits for a position
When the player answers No and the next need finds no map position, that request SHALL wait and be retried every few seconds, as any request waiting for a position does, and SHALL be asked once a position comes back.

#### Scenario: No position after No
- **WHEN** the player answers No to the repair question, bags are full, and the game gives no map position at that moment
- **THEN** the sell question is asked once a map position is available again, without another bag or gear change

### Requirement: Selling stays covered across a replaced trip
When a higher request replaces a repair or ammo request that covered selling, selling SHALL NOT be marked handled by the replaced trip. Once the requests resolve without a trip and bags are still low, the sell question SHALL be asked.

#### Scenario: Repair replaces an ammo request
- **WHEN** bags are full and ammo is low, the ammo question is open, durability drops so the repair question replaces it, and the player answers No to repair and then No to ammo
- **THEN** the sell question is asked

### Requirement: An ammo request follows the weapon
When the equipped ranged weapon changes to one that uses the other ammo kind while an ammo request is open or active, the addon SHALL close its question and its waypoint and SHALL ask again for the new kind if it is also low.

#### Scenario: Bow to gun
- **WHEN** the arrow question is open or an arrow vendor is pinned for low arrows, and the player equips a gun with low bullets
- **THEN** the arrow question or waypoint ends and the bullet question is asked
