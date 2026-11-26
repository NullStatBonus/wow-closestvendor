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

## ADDED Requirements

### Requirement: Warning decisions are recorded
While the log is on, the addon SHALL record each warning decision a test plan checks, once per change so bursts do not fill the log: a request held back (in an instance, while dead, in combat, in that order), a vendor question closed because the merchant window opened, a purchase question closed with the merchant, the ammo it watches (or why none), and what a purchase bought. A failed purchase call, or a question still shown after the addon tried to close it, is recorded with `FAILED:`.

#### Scenario: Held in combat
- **WHEN** bags are nearly full while the player is in combat
- **THEN** one line `trigger held in combat: sell` is recorded, not one per bag event

#### Scenario: Dead and in combat
- **WHEN** a request is held while the player is dead and in combat
- **THEN** the line names death: `trigger held while dead: <kind>`

#### Scenario: Question closed by the merchant
- **WHEN** a sell question is open and the player opens a merchant
- **THEN** `question closed: merchant opened (sell)` is recorded once the question is gone; an open trainer question stays and writes nothing

#### Scenario: Purchase
- **WHEN** an ammo purchase goes through for some batches and a game call fails for another
- **THEN** the bought line counts only the batches the game took, and the failure is recorded with `FAILED:`
