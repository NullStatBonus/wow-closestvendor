# Design

## Context

Phase 3 of #61, stacked on Phase 2 (1.11.1). The build plan had an evidence inventory for each step (108 steps) and was reviewed by Opus and Codex. The build was then reviewed against the CheckThat card by Opus and code-reviewed by Opus and Codex, in three rounds, with every finding fixed.

## Decisions

**D1.** Rules as in Phase 2 (auto when a line or entry proves the decision; player steps keep required assertions and a `notes` reason; Run-safe commands; visible restores; Skip for class-, profession- or addon-specific steps).

**D2. Header lines are not evidence.** The `/cvn log` header (navigation, learned counts, NorgannonDB, standing) never reaches the debug log, so entries replace it.

**D3. `nav()` reads a cache** that Core refreshes at login, world entry, each slash command, each settings-page change and when another addon loads; the entry call reads nothing from the game.

**D4. Confirmed clears.** `Nav.Clear` returns true only when the method confirms the removal, false on an error, nil when it cannot tell (WaypointUI without `GetUserNavigation`). The lines say which.

**D5. Dedupe.** Left-out, skip and repeated standing lines are written when their text without ranks changes, after a state change, or after 30 s, so skill-ups and retargeting do not fill the 300-line log.

**D6. No hard-coded unverified npc ids.** Steps match names or `npc %d+` patterns; Gorhak's steps are optional because he is not in the shipped data.

**D7. One player-visible change:** a click on an Artisan row says trainer tiers are unknown only near the skill's limit; elsewhere the log gives the real reason.

## Risks

- HEARTHSTONE_BOUND is unverified on every client; cv.s33.1 reloads so the hearth is learned at logout anyway.
- `ct lines` false misses for concatenated or formatted lines: NullStatBonus/wow-checkthat#144.
