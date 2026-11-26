## MODIFIED Requirements

### Requirement: Plan of record
The repository SHALL hold the in-game test plans as `plans/closestvendor.yaml` (core), `plans/closestvendor.ui.yaml` and `plans/closestvendor.addons.yaml`, each under 25 steps with its own section range. Each plan SHALL start with a version check and end with a Lua error check. Step ids `cv.s<N>.<M>` SHALL be unique across the plans, in order, and never renumbered or reused; every "test plan" reference SHALL name a step or section a plan has.

#### Scenario: Reference check
- **WHEN** a doc cites "test plan 3.2" and the plans have no `cv.s3.2`
- **THEN** the automated tests fail

#### Scenario: Plan too long
- **WHEN** one of the three plans has 25 steps or more
- **THEN** the automated tests fail

#### Scenario: Plan set
- **WHEN** one of the three plans is missing, or a plan does not start with its version step
- **THEN** the automated tests fail
