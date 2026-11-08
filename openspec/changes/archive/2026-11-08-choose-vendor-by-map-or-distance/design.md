# Design

## Context

See proposal.md for motivation. Today `Search.Nearest` / `Search.NearestTrainer` return one record by squared world distance, `Controller.findVendor` / `checkTrade` call them, `ask` / `askTrainer` pass one `accept` to `env.confirm`, and `Core.lua` shows a two-button `StaticPopup`. `Adapter.mapPosition` already reads the player's map id but `playerWorldPos` returns only continent and world x,y. Vendor and trainer records already hold their `uiMapID` (index 3). Game calls stay in `Adapter.lua`; the rest is plain Lua under `luajit tests/run.lua`.

## Goals / Non-Goals

**Goals:**
- Offer the nearest on-map and the nearest off-map target when the off-map one is closer.
- `auto` mode that pins without asking, with a preference for which target.
- Same behavior for vendors and trainers, one pair of settings.

**Non-Goals:**
- Parent-zone or continent-region matching: "same map" is an exact `uiMapID` match.
- Different preferences per trigger kind.
- Any change to the ammo purchase dialog.

## Decisions

**One search pass returns both winners.** `Search.Nearest` (and the trainer variant) gains an optional `mapId` argument and returns `best, bestOnMap`: while scanning, track the overall winner and the winner with `v[3] == mapId`. With no `mapId` the second value is nil and the first is unchanged, so existing callers and tests keep working. Squared distances only; the only `sqrt` is for the two displayed distances. Alternative: two separate scans, rejected as double the work for no gain.

**Candidate rule in the Controller.** `overall` is the nearest eligible target; `onMap` is the nearest on the player's map. If `onMap` is nil or `onMap == overall` there is one candidate (`overall`); otherwise `overall` is off-map and strictly closer, so there are two. This encodes "offer B only when closer" with no extra comparison, and handles unknown map (`mapId` nil, so `onMap` nil).

**Player map id travels through `env.playerPos`.** `A.playerWorldPos` returns a fourth value, the map id; existing callers that take three values are unaffected. Chosen over a new `env.playerMap()` to avoid reading the position twice (it can differ between calls).

**Popup with a third button.** `StaticPopup` supports `button1` / `button3` / `button2` with `OnAccept` / `OnAlt` / cancel. For a two-target question `Core.lua` shows `button1` = preferred, `button3` = other, `button2` = Cancel, each of the first two labeled by a localized "This map" / "Closest" caption. For a single target the dialog is as today (Yes / No). The popup data carries `{accept, alt}`; `OnAlt` calls `alt`. `hideOnEscape` keeps Esc as cancel. The `promptId` guard applies to both callbacks so a late answer cannot navigate. Alternative considered: two sequential Yes/No dialogs, rejected as worse UX.

**Dialog text.** A new full-sentence `L[...]` per kind (sell, repair, arrow, bullet, trainer) that names both targets as pre-formatted strings `name (zone, N yards)`; no concatenated fragments. Button captions are their own keys. Distances are rounded to whole yards from world units (assumed 1 world unit = 1 yard; the exact scale is not user-visible beyond "about").

**Auto mode.** In `auto` the Controller skips `env.confirm` and calls the same accept path (`clearNav`, `env.nav.Set`, set `pinTrade` for trainers), then `say`s one line naming the target. All existing gates (combat, open question, active trip, trainer lowest priority) run before the choice, so they apply unchanged. Without a map or with a single candidate, `auto` pins that candidate.

**Settings.** `cfg.vendorMode = "ask"|"auto"` and `cfg.vendorPrefer = "map"|"distance"` in `DEFAULTS`. Commands: `/cvn choice ask|auto` and `/cvn prefer map|distance`, validated with the valid values printed on error, as `arrows`/`bullets` do. Settings page: two dropdowns using the existing `Settings.CreateDropdown` pattern (the ammo grade rows), optional like the rest of the page. Both appear in `reportText`.

## Risks / Trade-offs

- [City and zone are separate maps, so a player in a city sees the "this map" vendor as the city's] → accepted by design (exact map match); noted in "Good to know".
- [Map id of a recorded vendor differs in granularity from the player's current map] → both come from the same `GetBestMapForUnit`-style data at record time; a mismatch just yields a single candidate, never an error.
- [`auto` can send the player across a zone without asking] → default is `ask`; `auto` prints the chosen target.
- [Builds on the trainer change, now archived as 0.3.0] → deltas are ADDED requirements only, so they layer on the main specs.

## Migration Plan

New saved keys default on load (`DEFAULTS` fill), so existing saves need nothing. Version stays 0.3.0 (unreleased, shared with the trainer change). Rollback is reverting the commit; unknown keys in saved settings are ignored.
