## ADDED Requirements

### Requirement: Question lines name the source and the distance
While the log is on, each `question shown:` line SHALL add, after the target's npc id, where the target came from (`learned` when this account learned it, `NorgannonDB` when only that addon gave it, `shipped` otherwise) and its distance from the search start in whole yards, as `, <source>, <n> yd`. The rest of the line SHALL stay as before.

#### Scenario: Learned vendor nearby
- **WHEN** the sell question names a vendor this account learned 8 yards away
- **THEN** the line reads `question shown: sell, <vendor> (npc <id>), learned, 8 yd`

#### Scenario: Trainer question
- **WHEN** a trainer question names a shipped trainer 40 yards away
- **THEN** the line reads `question shown: trainer for <profession>, <trainer> (npc <id>), shipped, 40 yd` followed by the points left when the question came from a skill check
