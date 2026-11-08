# profession-trainer Specification

## Purpose
Tell the player when a profession is close to its current tier cap and offer to navigate to the closest known trainer for that profession.

## Requirements

### Requirement: Profession trainer trigger
The addon SHALL ask the player to navigate to the closest known trainer for a profession when the points remaining to that profession's current tier cap are at or below the configured threshold (default 10) and a higher tier exists to learn. The cap SHALL come from the game, not from a built-in table.

#### Scenario: Near the cap
- **WHEN** a profession is at 295 of 300 with the default threshold and a higher tier exists
- **THEN** the player is asked whether to navigate to the closest known trainer for that profession

#### Scenario: Far from the cap
- **WHEN** a profession is at 200 of 300 with the default threshold
- **THEN** no question is asked

#### Scenario: Already at the cap
- **WHEN** a profession is at 75 of 75 and a higher tier exists
- **THEN** the player is asked

#### Scenario: Final tier
- **WHEN** a profession is at 300 of 300 and no higher tier exists
- **THEN** no question is asked

#### Scenario: Unreadable skills
- **WHEN** the game gives no readable skill data
- **THEN** no question is asked and no error is raised

### Requirement: Check on every skill change and craft
The addon SHALL check all professions whenever a skill value changes and whenever the player completes a craft, and SHALL ask again on each such event while the condition holds, unless a question for that profession is already open or its waypoint is active.

#### Scenario: Gathering skill-up
- **WHEN** a gathering skill rises and the profession is within the threshold
- **THEN** the question is asked

#### Scenario: Craft without a skill-up
- **WHEN** the player completes a craft that raises no skill and the profession is within the threshold
- **THEN** the question is asked

#### Scenario: Declined, then another event
- **WHEN** the player declined the question and then makes another craft within the threshold
- **THEN** the question is asked again

#### Scenario: Question already open
- **WHEN** a question for the same profession is open and another craft completes
- **THEN** the open question stays and no second one is shown

#### Scenario: Language independent
- **WHEN** the game runs in a language other than English
- **THEN** skill changes are detected by comparing values, not by reading chat text

### Requirement: Profession threshold setting
The addon SHALL persist a per-account profession threshold (default 10 points, 0 to 300) and an on/off switch, settable with `/cvn trade <points>`, `/cvn trade on` and `/cvn trade off`, and SHALL ask nothing while the switch is off.

#### Scenario: Custom threshold
- **WHEN** the player runs `/cvn trade 25` and a profession is 20 points from its cap
- **THEN** the question is asked

#### Scenario: Switched off
- **WHEN** the player runs `/cvn trade off`
- **THEN** no profession question is asked

#### Scenario: Out of range
- **WHEN** the player runs `/cvn trade 301`
- **THEN** the setting is unchanged and the addon says so

### Requirement: Known professions only
The addon SHALL only consider a skill line a profession after it has seen that profession's name at a profession trainer window or an open tradeskill or craft window, and SHALL otherwise ignore the skill line.

#### Scenario: Weapon skill
- **WHEN** a weapon skill is near its cap
- **THEN** no question is asked

#### Scenario: Profession learned at a trainer
- **WHEN** the player has opened a Herbalism trainer and Herbalism nears its cap
- **THEN** the question is asked

#### Scenario: Never seen
- **WHEN** a skill line has not been seen at a trainer or a crafting window
- **THEN** it is ignored

### Requirement: No known trainer
When no trainer is known for the profession on the player's continent, the addon SHALL NOT show a question and SHALL say so in chat once per profession per session.

#### Scenario: Nothing learned yet
- **WHEN** a known profession is within the threshold and no trainer for it has been recorded
- **THEN** a chat message names the profession and says how trainers are learned, and no question is shown

#### Scenario: Message not repeated
- **WHEN** the same situation recurs in the same session
- **THEN** the chat message is not shown again

### Requirement: Question text
The question SHALL name the profession, the points remaining and the trainer, and all player-facing text SHALL be localizable.

#### Scenario: Dialog contents
- **WHEN** the question is shown for Mining at 295 of 300 with a trainer named Gelman in Ironforge
- **THEN** the text names Mining, 5 points remaining, and the trainer's name and zone
