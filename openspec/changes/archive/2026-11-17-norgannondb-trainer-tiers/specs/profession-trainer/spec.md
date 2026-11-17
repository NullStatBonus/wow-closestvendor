## MODIFIED Requirements

### Requirement: Profession trainer trigger
The addon SHALL ask the player to navigate to the closest known trainer for a profession when the points remaining to that profession's current tier cap are at or below the configured threshold (default 10) and a higher tier exists to learn. The cap SHALL come from the game, not from a built-in table. When the next tier is Artisan (cap 225) and no trainer tiers are known, the addon SHALL NOT ask, mark the row low or route, because few trainers teach it; a click on that profession's row SHALL say so in chat. When trainer tiers are known (NorgannonDB), Artisan SHALL be asked and routed like the other tiers. The trainer chosen SHALL be the closest one that teaches the tier needed: a trainer known to teach less SHALL be skipped, and one whose tier is not known SHALL be used for Journeyman and Expert but never for Artisan.

#### Scenario: Near the cap
- **WHEN** a profession is at 145 of 150 with the default threshold and a higher tier exists
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

#### Scenario: Artisan next
- **WHEN** a profession is at 220 of 225 and the player is level 35
- **THEN** no question is asked, and clicking its status window row sets no waypoint and says in chat that Artisan is taught by only a few trainers

#### Scenario: Artisan with trainer tiers
- **WHEN** NorgannonDB is installed, a profession is at 220 of 225 at level 35, and a Master trainer for it is known
- **THEN** the question names that Master trainer, even if other trainers for the profession are closer

#### Scenario: Skip a trainer that teaches less
- **WHEN** a profession is at 145 of 150 and the closest trainer is a Journeyman trainer for it
- **THEN** the question names the closest trainer that teaches Journeyman or higher, or one whose tier is not known
