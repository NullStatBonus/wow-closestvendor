## Purpose

Keep the addon working, without errors, when a game function is missing or behaves differently on a client.

## ADDED Requirements

### Requirement: Guarded game calls
The addon SHALL read game state only through a single adapter that guards each call, so that a missing or throwing function yields "no data" instead of an error.

#### Scenario: Function missing
- **WHEN** a game function the addon uses does not exist on the client
- **THEN** no error is raised and the trigger that needs it does not fire

#### Scenario: Function throws
- **WHEN** a game function raises an error
- **THEN** the error does not reach the player and the other triggers keep working

#### Scenario: Slot data missing
- **WHEN** the durability of one equipment slot cannot be read
- **THEN** that slot is ignored and the others are still checked

### Requirement: Unknown is not zero
When no bag reports its free slots, the addon SHALL treat the count as unknown and SHALL NOT request navigation for full bags.

#### Scenario: Bag API unavailable
- **WHEN** every bag query fails
- **THEN** no sell request is made

#### Scenario: Some bags unreadable
- **WHEN** some bags report free slots and others fail
- **THEN** only the readable bags are counted
