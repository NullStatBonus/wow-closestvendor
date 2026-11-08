# Proposal

## Why

The closest target is chosen by straight-line distance across the whole continent, so a player near a zone border is often sent to a vendor or trainer on another map, even though one on their own map would be a more natural trip (or the reverse: the in-map one is far). The player can judge which is better, so the addon should offer both when they differ instead of silently picking one.

## What Changes

- Find two candidates for every vendor and trainer question: **A**, the nearest eligible target on the player's current map (`uiMapID`, exact match), and **B**, the nearest eligible target on any other map of the continent.
- When B exists and is strictly closer than A, the question offers both: three buttons, **this map** / **closest** / **Cancel**. Otherwise (no B, no A, or B not closer) behavior is unchanged: one target, plain Yes/No.
- The dialog names each target with its zone and distance.
- New setting `vendorMode`: `ask` (default) shows the question; `auto` skips it and sets the waypoint at once.
- New setting `vendorPrefer`: `map` (default) or `distance`. It orders the buttons in `ask`, and picks the target in `auto` (`map` pins A, `distance` pins B).
- Slash command and a settings-page control for both settings; the report header lists them.
- Applies to sell, repair, ammo and profession-trainer triggers alike.
- Not changed: the ammo purchase confirmation, the trigger thresholds, the learned/shipped data.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `vendor-navigation`: adds the map-aware choice of target (A/B candidates, when both are offered, the auto pin and its fallbacks). Added as new requirements so they layer on the trainer-aware "Nearest eligible vendor".
- `vendor-trigger`: adds the three-button question and the `vendorMode` / `vendorPrefer` settings (page and command).

## Impact

- `Adapter.lua`: expose the player's current map id alongside the world position.
- `Search.lua`: nearest-on-map and nearest-off-map variants for vendors and trainers.
- `Controller.lua`: choose A/B, ask with two accept callbacks or pin directly in `auto`; `PromptText` names both targets.
- `Core.lua`: popup gains a third button; defaults, report header.
- `Commands.lua`, `Options.lua`: the two settings.
- `Locales`: new full-sentence keys.
- Tests: `test_search`, `test_controller`, `test_commands`, `test_options`, `test_core`, `test_locale`.
- Docs: README, `docs/listing.md`, `docs/test-plan.md`; CHANGELOG and ships in 0.3.0 with the trainer change (no further bump).
- Ordering: builds on the archived `add-profession-trainer-nav`; both ship in 0.3.0.
