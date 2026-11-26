## ADDED Requirements

### Requirement: Vendor, trainer and waypoint decisions are recorded
While the log is on, the addon SHALL record each vendor, trainer and waypoint decision a test plan checks, after its effect: vendors and trainers learned or not, waypoints cleared, kept or not confirmed, trainer searches, profession checks skipped or skills left out, the choice between two candidates, and why a direct pin is not routed. A line repeats only when its text without ranks changes or after a quiet time. A clear that raises an error is recorded with `FAILED:`.

#### Scenario: Vendor learned
- **WHEN** the player opens a merchant the addon does not know
- **THEN** one line `vendor learned: <name> (npc <id>), new` is recorded

#### Scenario: Waypoint clear not confirmed
- **WHEN** the addon removes its waypoint but the waypoint method cannot confirm the removal
- **THEN** `waypoint clear not confirmed: ...` is recorded, not `waypoint cleared:`

#### Scenario: Skill-ups do not flood the log
- **WHEN** a weapon skill rises point by point near its cap
- **THEN** its left-out line is recorded once, not once per point
