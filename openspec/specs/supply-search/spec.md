# supply-search Specification

## Purpose
Lets the player look up, on demand, the nearest known seller of a supply or class reagent by item link or name, and route to one.

## Requirements

### Requirement: Item matching
The addon SHALL match a query to items by id. An item link SHALL give its id. Typed text SHALL match the game's own item names, ignoring case, as a substring. The candidates SHALL be the shipped food, drink and pet-food items and the player's class reagents. An item the client has no name for yet SHALL NOT match by text.

#### Scenario: Item link
- **WHEN** the player pastes the link of a known drink
- **THEN** that item is the only match, whatever the client language

#### Scenario: Partial name
- **WHEN** the player types part of a drink's name in any letter case
- **THEN** every candidate whose name contains the text matches

### Requirement: Outcomes are told apart
The addon SHALL give a different chat line for each outcome: no item matches the query; more than 8 items match, so the player is asked to type more of the name; the item is recognized but no eligible seller is known; or sellers are listed. It SHALL show no list for the first three.

#### Scenario: Unmatched name
- **WHEN** the query matches no candidate
- **THEN** chat says no supply item matches that text and nothing opens

#### Scenario: Too many matches
- **WHEN** 9 or more items match
- **THEN** chat asks for more of the name and no menu opens

#### Scenario: Recognized, no seller
- **WHEN** the item is recognized and no known seller of its category is eligible for the player's faction and reputation
- **THEN** chat says the item is known but no seller is known yet

### Requirement: Several items choose first
When 2 to 8 items match, the addon SHALL open the game's menu at the cursor listing each item with its icon and name. Choosing one SHALL continue as for a single match. When exactly one item matches, the addon SHALL go straight to the seller list.

#### Scenario: Two matches
- **WHEN** two drinks match the typed text
- **THEN** a menu lists both with icons and choosing one opens its seller list

#### Scenario: One match
- **WHEN** exactly one item matches
- **THEN** its seller list opens with no item menu

### Requirement: Seller list for an item
The seller list SHALL be the choice list of seller-choice: the nearest eligible seller marked, up to three others by straight-line distance, each with name, zone and distance. It SHALL use the faction, reputation, instance-anchor and auctioneer rules a status-row click uses for the same need.

#### Scenario: Eligibility matches a row click
- **WHEN** a nearer seller is for the other faction
- **THEN** it is not listed, as for a row click

#### Scenario: In an instance
- **WHEN** the player is in an instance
- **THEN** the list is searched and measured from the same anchor a row click uses

### Requirement: Category answer is labeled
Sellers of food, drink and pet food SHALL be found by category, because vendor data does not list items. For such an item the answer SHALL say which category it searched, so the player knows the seller may not stock that exact item. A class reagent answer SHALL name the item and need no such note.

#### Scenario: Drink item
- **WHEN** the player looks up a drink
- **THEN** chat says the sellers are of drink in general, not of that item

#### Scenario: Reagent
- **WHEN** the player looks up a class reagent
- **THEN** the sellers listed sell that reagent and no category note appears

### Requirement: Browsing leaves the route alone
Looking up an item and opening lists SHALL NOT change the waypoint, the warnings or any saved setting. Choosing a seller SHALL pin it as a status-row choice does: waypoint, chat notice and notification. Escape or a click elsewhere SHALL close a menu with no change.

#### Scenario: Browse only
- **WHEN** the player opens a seller list and dismisses it
- **THEN** the current waypoint is unchanged

#### Scenario: Pick a seller
- **WHEN** the player chooses a seller from the list
- **THEN** the waypoint is set to it and chat names it

### Requirement: No menu control
When the client has no menu control the addon can use, the lookup SHALL print the nearest seller in chat and SHALL pin nothing.

#### Scenario: No menu
- **WHEN** the client has neither menu control and one item matches
- **THEN** chat names the nearest eligible seller, zone and distance, and no waypoint is set
