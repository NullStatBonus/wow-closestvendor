## 1. Search

- [x] 1.1 `Search.Nearest` and `Search.NearestTrainer`: optional `mapId`, return `best, bestOnMap` (second nil without `mapId`)
- [x] 1.2 `tests/test_search.lua`: on-map winner differs from overall; same vendor; none on map; no `mapId` unchanged; hostile faction and need filters still apply to both

## 2. Adapter and Controller

- [x] 2.1 `Adapter.playerWorldPos`: return the map id as a fourth value; update `tests/test_adapter.lua`
- [x] 2.2 `Controller`: derive one or two candidates (overall, on-map) for vendor and trainer questions
- [x] 2.3 `Controller`: `ask` / `askTrainer` pass `accept` and `alt` callbacks when two candidates exist; both guarded by `promptId`
- [x] 2.4 `Controller`: `auto` mode pins without `env.confirm` (map pref -> on-map, distance pref -> overall), `say`s one line, keeps all gates; one candidate pins directly
- [x] 2.5 `PromptText`: two-target text per kind with name, zone and distance; new `L[...]` sentences and button captions; `Controller.Test` uses the same path
- [x] 2.6 `tests/test_controller.lua`: two-way question, each button, Cancel/late answer ignored, collapse cases, auto with each preference, auto gated by combat/open question/trainer trip, trainers

## 3. Settings and UI

- [x] 3.1 `Core.lua`: add `vendorMode = "ask"` and `vendorPrefer = "map"` to `DEFAULTS`; popup `button3` / `OnAlt`; preferred target on `button1`; `confirm` passes both callbacks and distances
- [x] 3.2 `Commands.lua`: `/cvn choice ask|auto`, `/cvn prefer map|distance`, status line, help text; `tests/test_commands.lua`, `tests/test_readme.lua`
- [x] 3.3 `Options.lua`: two dropdowns; `tests/test_options.lua`
- [x] 3.4 `reportText` lists both settings; `tests/test_core.lua`
- [x] 3.5 `Locales`: add keys to every locale file; `tests/test_locale.lua` passes

## 4. Docs

- [x] 4.1 README: feature, settings, commands, "Good to know" (map means the exact map, cities are their own maps)
- [x] 4.2 `docs/listing.md`: text and, if needed, the summary line
- [x] 4.3 `docs/test-plan.md`: in-game checks for the two-target question, each button, auto with each preference, no-map case, trainers (unique, ordered section number)

## 5. Verify and release

- [x] 5.1 `make test` and `make check` pass; temporarily break the candidate rule and confirm a test fails
- [x] 5.2 At archive: keep `## Version:` at 0.3.0 (already bumped for the trainer change, nothing is released yet); add the map-choice bullets to the existing `## 0.3.0` section of `CHANGELOG.md`; name 0.3.0 in the commit
