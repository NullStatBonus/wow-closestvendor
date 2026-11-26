# In-game test plan

The in-game checks live in [`plans/closestvendor.yaml`](../plans/closestvendor.yaml), a CheckThat test plan. This file only points there, so it cannot drift from the plan.

- **Check and build it:** `make plan` (needs the installed `ct` tools; see AGENTS.md, CheckThat). It writes `build/closestvendor.ct`.
- **Run it** with the CheckThat addon in game: type `/ct import`, paste the contents of `build/closestvendor.ct`, then type `/ct start ClosestVendor`. Steps marked automatic are judged from the debug log, CheckThat facts and ClosestVendor's entries; the others ask the player.
- **Read a run back** with `ct collect --plan plans/closestvendor.yaml --dest evidence` (kept out of Git), or the `/ct-verify` skill.
- **Numbers:** "test plan check 4.1" means step `cv.s4.1`; "test plan section 20" means section `s20`. Step ids are never renumbered or reused. The old subsections 13.1 to 13.7 and 14.1 to 14.5 are numbered straight through their section (`cv.s13.1`, `cv.s13.2`, ...).

## Not covered yet

- Walking distance. The addon chooses vendors by straight-line distance.
- Warlock shards and rogue poisons.
