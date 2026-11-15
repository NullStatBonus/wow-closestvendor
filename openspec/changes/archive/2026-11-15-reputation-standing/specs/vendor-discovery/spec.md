## ADDED Requirements

### Requirement: Vendors this character cannot trade with are skipped
Each character SHALL remember whether each known vendor trades with it: yes at Neutral or better or when its merchant window opens, no at Unfriendly or Hostile, as seen on target, mouseover or nameplate. The search SHALL skip vendors seen as no. A learned vendor of no side that is not shipped or external SHALL be used only after this character has seen it trade.

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
