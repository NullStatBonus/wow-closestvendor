## ADDED Requirements

### Requirement: Automatic pin says why
The automatic-pin notice (chat line and on-screen message) SHALL state why the addon is navigating, as a reason after the target: "to buy ammo", "to buy <reagent>", "to repair your gear", "to sell items and free bag space" or "to train <profession>".

#### Scenario: Reason after the target
- **WHEN** a target is pinned in `auto` mode for any trigger
- **THEN** the notice reads "Navigating to <vendor> (<zone>, N yards) <reason>." and, with two candidates, adds "The other choice was ..."
