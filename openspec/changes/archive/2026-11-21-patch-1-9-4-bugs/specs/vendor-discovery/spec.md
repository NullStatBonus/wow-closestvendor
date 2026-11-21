## ADDED Requirements

### Requirement: Standing of an external trainer
The addon SHALL record the standing (trades or not) of a profession trainer known only from NorgannonDB, as it does for a learned trainer.

#### Scenario: Unfriendly external trainer
- **WHEN** this character targets a NorgannonDB trainer the addon has not learned and the game reports Unfriendly
- **THEN** the standing is saved as not trading and the trainer is not used

