# Proposal

## Why

A profession skill stops rising at the current tier cap (75, 150, 225, 300) until a trainer raises it. Players who gather or craft often hit the cap without noticing and keep working with no progress. The addon already points players at vendors; pointing them at the right trainer just before they hit a cap is the same kind of help.

## What Changes

- New trigger: when a profession is within a threshold of its current tier cap (default 10 points) and a higher tier exists, ask (Yes/No) to navigate to the closest known trainer for that profession.
- Checked on every skill change (gathering and crafting) and on every completed craft, so it re-asks each time rather than once per condition.
- Trainers are learned only by discovery in v1: opening a profession trainer window records the trainer. No trainer data is shipped (pfQuest and wago have none; Questie and the CMaNGOS databases are GPL).
- When no trainer is known for the profession, say so in chat (once per profession per session) instead of asking.
- Priority becomes repair, ammo, sell, trainer.
- New setting: `/cvn trade <points>|on|off` and a checkbox plus slider on the options page.
- Out of scope for v1: shipped trainer data, player-level requirement checks, a `/cvn test` command for trainers.

## Capabilities

### New Capabilities
- `profession-trainer`: when a profession nears its tier cap, the check events, the threshold setting, the final-tier rule, and the "no known trainer" notice.

### Modified Capabilities
- `vendor-trigger`: priority order gains trainer; trainer questions re-ask on every event instead of latching; the waypoint for a trainer ends differently from a vendor waypoint; the settings panel and thresholds gain the profession setting.
- `vendor-navigation`: nearest eligible target gains trainer selection by profession.
- `vendor-discovery`: opening a profession trainer window records the trainer.

## Impact

- New and changed code: `Triggers.lua` (or a sibling module) for the profession check, `Search.lua` (trainer lookup), `Discovery.lua` (trainer records), `Controller.lua` (trainer kind and profession in the request), `Commands.lua`, `Options.lua`, `Core.lua` (events), `Adapter.lua` (skill lines, trainer window, craft events), `Locales/enUS.lua`, both TOCs only if a file is added.
- Saved variables gain a learned-trainers table; existing saved data is untouched.
- Docs: README, `docs/listing.md`, `docs/test-plan.md`, CHANGELOG, version bump at archive.
- Unverified in game: which events fire for crafting on Forever, how to tell profession skill lines from other skills without relying on language, and whether Forever has tiers above 300.
