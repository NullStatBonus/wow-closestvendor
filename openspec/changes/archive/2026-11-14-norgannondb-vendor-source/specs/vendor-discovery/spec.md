# Spec Delta

## MODIFIED Requirements

### Requirement: Learned data wins
A learned vendor SHALL replace a shipped vendor with the same NPC id when building the search data. When an external source also lists that NPC id, the rules in `external-vendor-source` decide which position and flags are used.

#### Scenario: Moved or mispositioned vendor
- **WHEN** a learned record and a shipped record share an NPC id
- **THEN** only the learned position is used
