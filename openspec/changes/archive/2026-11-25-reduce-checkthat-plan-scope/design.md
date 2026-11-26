# Design

## Context

Follow-up to #61 (Phases 1 to 4, 1.11.0 to 1.11.3). The build plan and its binding revisions were reviewed by Opus and Codex. No plan has been run and nothing is merged, so the steps are renumbered once now.

## Decisions

**D1. The game proves only what fakes cannot.** A plan step exists for real API data, real events, end-to-end wiring, drawing, sound, other addons and saved variables across `/reload`. Logic a unit test proves gets no step.

**D2. Three plans, all run every release.** The user rule is one plan under 25 steps; more steps split. Core keeps the warnings to the vendor; ui keeps what is drawn; addons keeps what needs another addon. Running all three keeps requirement coverage above 90%.

**D3. Section ranges.** Core s0 to s9, ui s10 to s19, addons s20 to s29 (used now: s0 to s6, s10 to s13, s20 to s21). A "test plan check N.M" names one step across the set, and `tests/test_plan.lua` resolves references against all three.

**D4. Each plan stands alone.** Its own setup section: the version step (`entry.version`, `op: ge`, 11103), then Lua errors and debug logging with one `/reload`, proved by the login line after the reload. Its last step reads CheckThat's error list (scope session). CheckThat 0.21.0 has no scope for one run (`scope` is `attempt` or `session`), and a new run keeps the list, so a ClosestVendor error from an earlier run, also of another ClosestVendor plan, fails this step too; the step's notes say to compare the error time with the run start. A run-level scope is a CheckThat issue.

**D5. Rules from the #61 reviews.** Run sends all commands at once, so a step whose player acts between two commands types them from their boxes. A setup command never satisfies the step's assertions. Each step carries its own setup and Skip condition (section intros are not on the card, and a skipped class step must not leave a threshold changed: the next step every class runs types the defaults back). Restores are visible steps. Existing unit tests are not removed or weakened.

**D6. Purchase paths and evidence the count rose.** Ammo is checked on its default path: with `/cvn buy auto` a Hunter buys as the merchant opens, with no question (check 4.2). The purchase question and its close with the merchant are checked on the reagent path, which asks by default (checks 4.1 and 4.2). A `bought` line only counts the calls the game took. After the purchase, reopening the vendor proves the count: `ammo buy: less than one purchase of room` for ammo (with room for a full purchase before), and `reagent buy: target <n>, money <n>, plan: nothing, cost 0, short: nil` for reagents.

**D7. Both outcomes of low food.** A Mage who knows Conjure Food gets a reminder, any other character a vendor question. The step's required pattern `[y:] food[, ]` matches only the two outcomes the player sees, `question shown: supply food, ` and `reminder: food (` (not the request alone, `trigger go food (`), and two diagnostic lines say which happened.

**D8. Clients.** Core and ui run on WoW Forever and Classic Era. The core route step is tagged per client: Forever picks the game waypoint with `/cvn nav native`; Classic Era without TomTom shows the chat coordinates. WaypointUI and NorgannonDB steps are Forever only.

**D9. No version bump.** Every changed file but one is left out of the package (`.pkgmeta` `ignore:`). `DESIGN.md` ships, but its change only names the plan to follow for visual review (`plans/closestvendor.ui.yaml`) and the checks left to a hand review; it changes no addon behavior. The release-only-on-addon-change rule overrides the AGENTS.md bump-at-sync rule, and AGENTS.md now states that exception. No CHANGELOG section and no tag; the change ships with the next addon release.

## Coverage

Covered = a unit test proves the requirement (pure logic), or a plan step exercises it in the game (the requirements whose unit tests use fakes for game data). The row-by-row table is the scope review's requirement coverage, remapped to the new step ids.

| Capability | Requirements | Unit tests | Plan steps | New unit tests | Not covered | Covered | Steps |
|---|---|---|---|---|---|---|---|
| ammo-purchase | 9 | 4 | 2 | 0 | 3 | 6/9 | 4.2, 4.3 |
| api-resilience | 3 | 3 | 0 | 0 | 0 | 3/3 |  |
| auction-routing | 3 | 3 | 0 | 0 | 0 | 3/3 |  |
| checkthat-integration | 7 | 3 | 4 | 0 | 0 | 7/7 | 0.1, 3.3, 13.5, 21.4 |
| class-reagents | 19 | 13 | 6 | 0 | 0 | 19/19 | 2.3, 4.1, 4.2, 4.4, 13.3 |
| craft-reminders | 6 | 2 | 3 | 0 | 1 | 5/6 | 2.4, 21.8, 21.9 |
| diagnostics | 11 | 0 | 10 | 1 | 0 | 11/11 | 0.2, 1.3, 2.4, 2.5, 3.1, 3.2, 4.1, 5.1, 11.1, 13.4 |
| external-vendor-source | 8 | 2 | 5 | 0 | 1 | 7/8 | 21.4, 21.5, 21.6, 21.7 |
| food-and-water | 7 | 4 | 2 | 1 | 0 | 7/7 | 2.4 |
| instance-awareness | 6 | 2 | 2 | 0 | 2 | 4/6 | 3.3, 3.4 |
| localization | 4 | 3 | 0 | 0 | 1 | 3/4 |  |
| notification-presentation | 5 | 0 | 5 | 0 | 0 | 5/5 | 11.2, 12.3, 13.1, 13.4, 13.6, 21.9 |
| pet-food | 5 | 3 | 0 | 1 | 1 | 4/5 |  |
| profession-trainer | 11 | 5 | 5 | 0 | 1 | 10/11 | 2.5, 2.6, 21.7 |
| saved-settings | 4 | 2 | 2 | 0 | 0 | 4/4 | 6.2, 13.4, 13.5 |
| seller-choice | 9 | 5 | 4 | 0 | 0 | 9/9 | 11.3 |
| settings-interaction | 10 | 3 | 7 | 0 | 0 | 10/10 | 5.1, 13.1, 13.2, 13.4, 13.5 |
| shared-presentation | 3 | 0 | 3 | 0 | 0 | 3/3 | 11.6, 12.5 |
| slash-interface | 5 | 3 | 1 | 0 | 1 | 4/5 | 5.2 |
| status-window | 17 | 7 | 8 | 0 | 2 | 15/17 | 11.1, 11.2, 11.4, 11.5, 11.6, 12.1 |
| supply-search | 7 | 3 | 4 | 0 | 0 | 7/7 | 5.2 |
| vendor-data | 11 | 9 | 1 | 0 | 1 | 10/11 | 1.1, 1.2 |
| vendor-discovery | 12 | 2 | 5 | 0 | 5 | 7/12 | 1.3, 2.5, 4.1, 6.2 |
| vendor-navigation | 13 | 6 | 7 | 0 | 0 | 13/13 | 1.1, 3.3, 11.2, 12.3, 21.1, 21.2, 21.3 |
| vendor-trigger | 27 | 17 | 9 | 0 | 1 | 26/27 | 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.3, 12.4, 13.1 |
| visual-preview | 6 | 2 | 4 | 0 | 0 | 6/6 | 11.4, 12.1, 12.2, 12.5 |
| **Total** | 228 | 106 | 99 | 3 | 20 | **208/228** | |

208 of 228 (91.2%) with the three new unit tests; 205 of 228 (89.9%) without them.

Not covered by a plan step or a pure unit test:

- ammo-purchase: Ammo purchase question ends with its merchant (the reagent question's close is checked in 4.1)
- ammo-purchase: Item data not loaded yet
- ammo-purchase: Required level not loaded yet
- craft-reminders: Warlocks are reminded to create a healthstone
- external-vendor-source: Cheap to read
- instance-awareness: Last outdoor position
- instance-awareness: Hearthstone point
- localization: Labels for game data are translated
- pet-food: Pet food follows the active pet
- profession-trainer: Trainer questions end with the place
- slash-interface: Reagent names in the game language
- status-window: Moving and locking
- status-window: Cog button
- vendor-data: Shared dataset across flavors
- vendor-discovery: Record auctioneers
- vendor-discovery: Record supplies sold
- vendor-discovery: Vendors this character cannot trade with are skipped
- vendor-discovery: An unread item kind makes the list partly read
- vendor-discovery: Standing of an external trainer
- vendor-trigger: Two-target question

## Risks

- `ct lines` cannot find lines built with `format` or concatenation (`trigger go`, `accepted: ... via`, `... buy: asked`, `find: "..."`, the demo lines); each was checked by hand against the source (NullStatBonus/wow-checkthat#144).
- The ui plan's settings step changes the bag threshold on the page; if a tester skips the reload check, the restore step still types the default back.
