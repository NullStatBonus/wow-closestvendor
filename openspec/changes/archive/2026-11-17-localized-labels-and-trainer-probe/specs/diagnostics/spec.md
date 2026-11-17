## ADDED Requirements

### Requirement: Trainer service probe
With debugging on, opening a profession trainer window SHALL log the number of listed services and the trainer filter states, then one line per service with its skill line, name, rank text, type, level requirement and skill requirement. Values the client does not provide SHALL be logged as nil. The addon SHALL NOT change the trainer filters. With debugging off, nothing SHALL be logged.

#### Scenario: Capture a trainer
- **WHEN** debugging is on and the player opens a Mining trainer
- **THEN** the log lists each service the window shows, with its requirements, and the filters are unchanged
