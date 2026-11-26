## ADDED Requirements

### Requirement: Trainer test command
The addon SHALL provide `/cvn test trainer`, which asks the trainer question now for the nearest known profession trainer of the player's faction, whatever the profession skill, tier, threshold or combat state, and SHALL set the destination if the player accepts. It SHALL prefer a trainer for a profession the character knows, and otherwise take the nearest trainer of any profession. Questions from it SHALL NOT be withdrawn by a zone change.

#### Scenario: Test trainer accepted
- **WHEN** the player runs `/cvn test trainer` near a known profession trainer and accepts
- **THEN** that trainer becomes the destination

#### Scenario: No profession known
- **WHEN** the character knows no profession and the addon knows a trainer nearby
- **THEN** the question names the nearest trainer and one profession it teaches

#### Scenario: No trainer known
- **WHEN** no map position is available or no profession trainer is known on this continent
- **THEN** the addon says why in chat and shows no dialog
