# Tasks

## 1. Item matching (pure)

- [x] 1.1 Add the matcher (text or link -> candidate item ids, bound of 8) beside `Search.lua`/`Supplies.lua`, with item-to-need mapping; verify with a new `tests/test_search.lua` or `tests/test_supplies.lua` case for link, partial name, case, accented name, no match, 9+ matches, diet-only and food/drink items.
- [x] 1.2 Temporarily break the id-vs-name logic, verify the new tests fail, restore, verify they pass.

## 2. Adapter reads

- [x] 2.1 Add guarded item icon and cursor-anchored menu helpers to `Adapter.lua` returning nil when missing; verify in `tests/test_adapter.lua` with present and absent globals.

## 3. Controller lookup

- [x] 3.1 Add `Find(text)` to `Controller.lua`: outcome lines, item menu for 2-8 matches, seller list through the existing choice list, category note, pick through `pinTarget`, chat fallback without a menu; verify in `tests/test_controller.lua` for each outcome, faction filtering, instance anchor, browse-without-pin and pick-pins.
- [x] 3.2 Every new sentence is `L["..."]` and added to the locale files; verify `tests/test_locale.lua` passes.

## 4. Entry points

- [x] 4.1 Add `/cvn find` and its help line in `Commands.lua`; verify in `tests/test_commands.lua` (with text, without text) and `tests/test_readme.lua`.
- [x] 4.2 Add the Find supplies input section to Home in `Options.lua`; verify in `tests/test_options.lua` that it is last, stores no setting and calls the lookup.

## 5. Docs and check

- [x] 5.1 Update `README.md` (command, Home section, "Good to know": category-level answers), `docs/listing.md`, and `docs/test-plan.md` with short checks (`/cvn find` for a drink and a reagent; Home input; Escape leaves the waypoint), each with `Check:` and `Log:` lines and a debug log line per behavior; verify `make test` and `make check` pass.

## Workflow follow-up

- Archive with a minor version bump in both TOC files and a `CHANGELOG.md` section, then commit, PR (naming test files and copying the in-game checks), merge, tag and push the tag.
