## MODIFIED Requirements

### Requirement: What is recorded
While the log is on, the addon SHALL record the game events it reacts to (except worn-gear events, which are folded into one line per check), failures of guarded game calls, trigger decisions, the vendor found or why none was, and whether the question was shown, accepted or dismissed.

#### Scenario: Bag event
- **WHEN** the log is on and a bag event arrives
- **THEN** the event name is recorded

#### Scenario: Gear events
- **WHEN** the log is on and durability or inventory events arrive in a burst
- **THEN** no line is recorded per event, and one line gives how many were folded into one check

#### Scenario: Adapter failure
- **WHEN** a guarded game call fails
- **THEN** the failing call and its error text are recorded, once per kind of failure

