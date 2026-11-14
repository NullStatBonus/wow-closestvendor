# Design

- `Professions.Within(skills, known, threshold, level)` takes the player level. `P.TIER_LEVEL` maps a cap to the level its next tier needs: 75 to 10, 150 to 20, 225 to 35 (Classic trainer rules; not checked against WoW Forever).
- The level is read through the adapter (`A.level`) at each check: `env.level` for the controller, `src.level` for the status snapshot. A level-up alone does not re-run the check; the next skill change or craft does.
- A missing level (nil) never gates, in line with "unknown is nil".
