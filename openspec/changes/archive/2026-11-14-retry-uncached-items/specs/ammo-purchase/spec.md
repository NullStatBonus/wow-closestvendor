# Spec Delta

## ADDED Requirements

### Requirement: Item data not loaded yet
When buying ammo or reagents at a merchant stops because the game has not loaded an item's data, and nothing was asked or bought, the addon SHALL try again when the game reports that item data arrived, up to three times for that visit. A purchase that was already asked or made SHALL NOT be repeated, and closing the merchant window SHALL end any retry.

#### Scenario: Data arrives after the merchant opens
- **WHEN** a merchant opens, a reagent's stack size is unknown, and the data arrives a moment later
- **THEN** the purchase question is asked once

#### Scenario: Data never arrives
- **WHEN** the data is still missing after three tries
- **THEN** the addon stops trying for that visit
