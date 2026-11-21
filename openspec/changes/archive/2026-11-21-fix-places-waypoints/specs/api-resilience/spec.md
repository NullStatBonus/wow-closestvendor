## ADDED Requirements

### Requirement: Failed timer is not scheduled
When the game's timer call fails, the addon SHALL treat the timer as not scheduled, so work that waits on it (a status window redraw, a re-check while a map position is missing) can be scheduled again later instead of waiting forever.

#### Scenario: Timer call throws
- **WHEN** the timer function raises an error
- **THEN** the call reports not scheduled, the error is logged once, and a later redraw request tries again
