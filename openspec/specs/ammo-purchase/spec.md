# ammo-purchase Specification

## Purpose
Buy ammo at a merchant to fill the quiver or ammo pouch matching the equipped ranged weapon, choosing the item by a per-kind grade mode and limiting the purchase to what the player can afford.

## Requirements

### Requirement: Fill ammo storage at a merchant
When a merchant window opens and a bow, crossbow or gun is equipped, the addon SHALL buy ammo of that weapon's kind (arrows for bows and crossbows, bullets for guns) until the player's quivers or ammo pouches of that kind are full, counting ammo already carried. It SHALL buy nothing for thrown weapons, wands, no ranged weapon, or when the player has no matching quiver or pouch, and SHALL NOT fill general-purpose bags.

#### Scenario: Partly full quiver
- **WHEN** a bow is equipped, the quiver holds 600 of 1000 slots' worth of arrows, and the merchant sells the chosen arrows
- **THEN** the addon buys 400 arrows

#### Scenario: Already full
- **WHEN** the matching quiver is already full
- **THEN** nothing is bought

#### Scenario: No quiver or pouch
- **WHEN** a gun is equipped and no ammo pouch is carried
- **THEN** nothing is bought

#### Scenario: Unmonitored weapon
- **WHEN** a wand or thrown weapon is equipped
- **THEN** nothing is bought

### Requirement: Buy without prompting by default
The addon SHALL buy at once, without a dialog, by default. When the "ask first" setting is on, it SHALL instead show a dialog naming the item, the count and the total price, and SHALL buy only if the player accepts. When buying is switched off, it SHALL buy nothing.

#### Scenario: Default
- **WHEN** a merchant opens with ammo to buy and default settings
- **THEN** the purchase happens with no dialog

#### Scenario: Ask first
- **WHEN** a merchant opens with ammo to buy and "ask first" is on
- **THEN** a dialog shows the count and price, and nothing is bought until the player accepts

### Requirement: Ammo grade selection
The addon SHALL choose which item to buy by a grade mode set separately for arrows and for bullets: "same as equipped" (the default) buys the item in the ammo slot; "best usable" buys the merchant's ammo of the right kind with the highest required level the character meets; "cheapest" buys the lowest price per unit. If the mode finds no item, or the equipped ammo is unknown, the addon SHALL fall back to the equipped item, and if the merchant does not sell that either, SHALL buy nothing and say so in chat.

#### Scenario: Same as equipped
- **WHEN** Jagged Arrows are equipped, the mode is "same as equipped", and the merchant sells them
- **THEN** Jagged Arrows are bought

#### Scenario: Best usable
- **WHEN** the mode is "best usable", the character is level 30, and the merchant sells arrows requiring levels 1, 10, 25 and 40
- **THEN** the level 25 arrows are bought

#### Scenario: Separate modes
- **WHEN** arrows are set to "cheapest" and bullets to "same as equipped"
- **THEN** a bow buys the cheapest arrows and a gun buys the equipped bullets

#### Scenario: Item not sold
- **WHEN** the chosen item is not sold at this merchant
- **THEN** nothing is bought and a chat line says so

### Requirement: Afford and report
The addon SHALL limit the purchase to what the player can afford and to the quantities the merchant allows, and SHALL print one chat line stating what was bought and its cost, or why nothing was bought. Unreadable game data SHALL be treated as unknown and cause no purchase, never a guessed amount.

#### Scenario: Short of gold
- **WHEN** the full top-up costs more than the player holds
- **THEN** only the affordable amount is bought and the chat line says it was partial

#### Scenario: Unreadable data
- **WHEN** the quiver size or merchant price cannot be read
- **THEN** nothing is bought

### Requirement: Item data not loaded yet
When buying ammo or reagents at a merchant stops because the game has not loaded an item's data, and nothing was asked or bought, the addon SHALL try again when the game reports that item data arrived, up to three times for that visit. A purchase that was already asked or made SHALL NOT be repeated, and closing the merchant window SHALL end any retry.

#### Scenario: Data arrives after the merchant opens
- **WHEN** a merchant opens, a reagent's stack size is unknown, and the data arrives a moment later
- **THEN** the purchase question is asked once

#### Scenario: Data never arrives
- **WHEN** the data is still missing after three tries
- **THEN** the addon stops trying for that visit
