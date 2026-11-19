## Purpose
Lets the player see the other known sellers or trainers for a status-window need and pick one to route to, instead of only the one a row click chooses.

## ADDED Requirements

### Requirement: Choice list
For a routable row, the addon SHALL list the target a row click would pin, marked as the default, then up to three other eligible targets ordered by straight-line distance from the same search start the row click uses. Each entry SHALL show name, zone and distance in yards. Eligibility SHALL be the same as for the row click, including faction and reputation.

#### Scenario: Default first
- **WHEN** the map preference makes a row click pick a vendor on the player's map that is not the nearest overall
- **THEN** that vendor is first and marked, and the nearest overall follows as an alternative

#### Scenario: At most three alternatives
- **WHEN** six eligible repair vendors are known on the continent
- **THEN** the list shows the default and the three nearest others

#### Scenario: Faction filtered
- **WHEN** a nearer vendor is for the other faction
- **THEN** it is not listed

#### Scenario: Started from an anchor in an instance
- **WHEN** the player is in an instance and the row click would search from the hearthstone point
- **THEN** the list is searched from the hearthstone point and its distances are measured from there

### Requirement: Every routable row takes part
The choice list SHALL be available for every row a click can route: repair, ammo, food, water, pet food, class reagents a vendor sells, profession trainers and sell. Trainer entries SHALL use the same tier rule as the trainer row click. Display-only rows SHALL have no choice list.

#### Scenario: Trainer row
- **WHEN** a profession near its cap has three known trainers that teach the next tier
- **THEN** the list shows those trainers and no trainer that cannot teach that tier

#### Scenario: Display-only row
- **WHEN** a Soul Shard row is shown
- **THEN** it has no choice list

### Requirement: One entry per NPC
An NPC known at more than one place SHALL appear once in the list, at its nearest known place.

#### Scenario: Duplicate records
- **WHEN** the same vendor NPC is recorded at two places on the continent
- **THEN** the list shows it once, at the nearer place

### Requirement: Auctioneer entry
When the auction house setting is on and the player is outside an instance, the list for ammo or a reagent that is not soulbound SHALL include the nearest known auctioneer as one entry, placed by its distance, and SHALL include no other auctioneer. Otherwise the list SHALL hold no auctioneer.

#### Scenario: Auction house on
- **WHEN** the setting is on, the player is outside, and an auctioneer is known for an ammo row
- **THEN** exactly one auctioneer appears in the list, in distance order

#### Scenario: Soulbound reagent
- **WHEN** the reagent is soulbound
- **THEN** no auctioneer is listed

### Requirement: Chevron on the row
A routable row with at least one alternative SHALL show a chevron at its right edge with its own click area, and a tooltip naming the action for that row, for example "Other repair vendors". A row with no alternative SHALL show no chevron. The chevron SHALL dim with the text and icon opacity and SHALL draw no fill or border.

#### Scenario: Alternatives exist
- **WHEN** two eligible repair vendors are known
- **THEN** the durability row shows a chevron with the tooltip "Other repair vendors"

#### Scenario: Only one seller
- **WHEN** only one eligible seller is known for a row
- **THEN** that row shows no chevron

#### Scenario: Dimmed text
- **WHEN** text and icon opacity is 40 percent
- **THEN** the chevron is drawn at 40 percent too

### Requirement: Chevron click opens the list
Clicking the chevron SHALL open the list in the game's menu, anchored to the chevron. It SHALL NOT also route the row, open settings or start a drag. While the window is being moved, or when Shift is held on an unlocked window, the chevron SHALL do nothing.

#### Scenario: Click opens the menu
- **WHEN** the player clicks a row's chevron
- **THEN** the menu opens at the chevron and no waypoint changes

#### Scenario: Rest of the row unchanged
- **WHEN** the player clicks the row outside the chevron
- **THEN** the row routes to its default target as before

#### Scenario: Move mode
- **WHEN** the window is in its move mode
- **THEN** clicking the chevron opens nothing

### Requirement: Picking an entry
Choosing an entry SHALL pin that target as a row click pins its default: set the waypoint, print the notice in chat, show the notification, and treat the row's warning as handled. Closing the menu with Escape or a click elsewhere SHALL change nothing.

#### Scenario: Pick an alternative
- **WHEN** the player chooses the second vendor in the list
- **THEN** the waypoint is set to that vendor and the chat notice names it

#### Scenario: Pick the auctioneer
- **WHEN** the player chooses the auctioneer entry
- **THEN** the notice says to buy at the auction house

#### Scenario: Dismiss
- **WHEN** the player presses Escape with the menu open
- **THEN** the menu closes and the current waypoint stays

### Requirement: Menu control
The list SHALL use the game's own menu control: the newer context menu where the client has it, otherwise the classic drop-down menu. When neither is available the chevron SHALL not be shown and row clicks SHALL keep working.

#### Scenario: No menu control
- **WHEN** the client has no menu control the addon can use
- **THEN** no chevron is shown and the row click still routes
