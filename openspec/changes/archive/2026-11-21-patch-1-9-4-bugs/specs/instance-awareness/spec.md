## ADDED Requirements

### Requirement: A bind is kept on logout
When the player answered an innkeeper's question and the bind name matches, the addon SHALL also apply the position on logout or reload, for clients that do not announce the bind.

#### Scenario: Bind then log out
- **WHEN** the player binds at an inn and logs out before any zone change
- **THEN** the hearthstone point keeps the inn's position
