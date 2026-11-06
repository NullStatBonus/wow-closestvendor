# Tasks

## 1. Client facts and scaffold

- [x] 1.1 Take the Era and Forever interface numbers and TOC suffixes from the shipping sibling addon `wow-dontdothat` (Era 11509 `_Vanilla`, Forever 16001 `_Camelot`) instead of testing Era; verify they are recorded in design.md Context
- [ ] 1.2 Create the addon folder with `ClosestVendor_Vanilla.toc` (11509) and `ClosestVendor_Camelot.toc` (16001), same `## Version:` in both, and empty `Core.lua` (no embedded libraries); verify the addon appears and loads without errors (`/console scriptErrors 1`) on Forever (Era load check deferred by the user)
- [x] 1.3 Add the test setup: `tests/stubs.lua` (fake WoW API), a `luajit` runner, a stdlib `unittest` setup for `tools/`, and a `make test` target; verify `make test` runs a trivial passing test in each language and fails when one test is made to fail

## 2. Vendor data pipeline

- [x] 2.1 Use the pfQuest database (MIT) as the vendor source, add the MIT `LICENSE` and a `THIRD_PARTY.md` carrying pfQuest's notice; verify both files exist and `THIRD_PARTY.md` contains pfQuest's copyright line and license text
- [x] 2.2 Download the pinned pfQuest files and the wago `UiMapAssignment` CSV (Era and Forever builds) into git-ignored `tools/data/` with `tools/fetch_data.py`; verify row counts are non-zero and record the table choice in design.md Open Questions
- [x] 2.3 Write `tools/build_vendors.py`: read pfQuest `meta.vendor`/`meta.repair`, units coordinates and enUS names, map zone to `uiMapID`, emit the generated data file with a source/version header; verify with a unit test that non-vendors and vendors without coordinates are dropped, the repair flag is set, coordinates are divided to 0-1, and re-runs are byte-identical
- [x] 2.4 Add a sanity check over the generated data file: it parses as valid Lua, record count is non-zero, coordinates are in 0-1, every record has a name and faction; verify it runs under `make test` and fails on a deliberately corrupted file
- [ ] 2.5 Spot-check 10 known vendors (cities, remote camps, faction-specific) against in-game positions on Forever; verify results in `tools/README.md`, including whether specialty vendors buy all items

## 3. Triggers

- [x] 3.1 Implement bag free-slot counter and bag trigger with latch and hysteresis in a module with no WoW globals (WoW calls via a thin wrapper); verify with a pure-Lua test using stubbed `C_Container`, run by `make test`
- [x] 3.2 Implement lowest-durability computation (ignore items without durability) and durability trigger; verify with a stubbed-API test including a mixed-items case
- [x] 3.3 Add combat deferral, clear on `MERCHANT_SHOW`/condition resolution, and repair-over-sell priority; verify with event-sequence tests

## 4. Navigation

- [x] 4.1 Implement nearest-vendor search (no WoW globals) over the instance bucket using squared world distance, faction and repair filters; verify with a test on `tests/fixtures/vendors.lua`, including the hostile-faction case, run by `make test`
- [x] 4.2 Implement the TomTom adapter (`IsAddOnLoaded` detection, 0-1 coordinates, remove via returned uid); verified by stub tests of the call arguments, the fake-global case and removal (in-game check in 9.1)
- [x] 4.3 Implement the WaypointUI adapter (`WaypointUIAPI.Navigation`, 0-100 coordinates, per-method feature detection, clear only its own destination); verified by stub tests including missing-method, failure and thrown-error fallbacks (in-game check in 9.1)
- [x] 4.4 Implement the Blizzard native waypoint adapter, the chat fallback and the adapter selection order; verified by stub tests of the order, `CanSetUserWaypointOnMap`, and not clearing a waypoint the user replaced (in-game check in 9.1)
- [x] 4.5 Handle no-position (instance) and no-vendor cases silently with retry in `Controller.lua`; verified by stub tests of retry, combat, dropped requests and replacing an active target (dungeon check in 9.1)
- [x] 4.6 Wire it together in `Core.lua`: events, WoW wrappers, saved-variable defaults, a retry timer that runs only while a request is pending, and both TOCs listing every module; verified by `tests/test_core.lua` against a fake game (38 checks; load check on Forever in 9.1)
- [x] 4.7 Ask before navigating: `Controller` calls `env.confirm` (kind, vendor, accept) and `env.cancelConfirm`; `Core.lua` shows a `StaticPopup` whose Yes navigates; decline keeps the trigger latched; the dialog closes when the condition clears or a merchant opens; verified by controller and core stub tests and a pure test of the dialog text (in-game dialog check in 9.1)

## 5. Discovery

- [x] 5.1 Implement the learned-vendor store (no WoW globals): record by npc id, update without duplicating, overwrite shipped records with the same id, ignore records without an id; verify with a test of each case, run by `make test`
- [x] 5.2 Capture merchants on `MERCHANT_SHOW` (npc id from the GUID, name, `CanMerchantRepair()`, faction, map position) into `ClosestVendorDB.learned`, and convert shipped plus learned records to world coordinates bucketed by continent at login; verified by `tests/test_core.lua` (in-game check in 9.1)

## 6. Config and docs

- [x] 6.1 Add SavedVariables defaults, `/cvn bags <n>|on|off`, `/cvn dur <pct>|on|off` (pure parser in `Commands.lua`, wired in `Core.lua`); verified by `tests/test_commands.lua` (37 checks) and `tests/test_core.lua` (settings land in the saved-variables table and apply at once; survival across `/reload` is checked in 9.1)
- [x] 6.2 Write README (install, commands, discovery, data attribution, license, limitations); verified by `tests/test_readme.lua`, which runs every documented command through the real parser and checks the documented limits
- [x] 6.3 Add `/cvn test sell` and `/cvn test repair` (`Commands.lua` returns an action, `Controller.Test` asks the usual question, nothing shown with a message when there is no position or vendor); verified by command, controller and core stub tests and the README test (in-game check in 9.1)

## 7. Ammo

- [x] 7.1 Add the ammo seller flag to the data: `tools/fetch_data.py` fetches pfQuest `items.lua`, `tools/build_vendors.py` reads the sold-by lists for the standard arrows and bullets and writes the eighth record field; verify with unit tests (arrow, bullet, both, none, unlisted vendor) and `tests/test_data.lua` checking the field and that both kinds have many vendors
- [x] 7.2 Move the record shape to eight fields on disk (ammo code) and world coordinates to positions 9 and 10 at runtime in `Search`, `Discovery`, `Core` and the tests; `Search.Nearest` takes a need (nil, repair, arrow, bullet); verify the existing suites pass and a new search test per need
- [x] 7.3 Add the ammo condition to `Triggers` with priority repair > ammo > sell (lower priority never replaces an open or active higher one; ammo and repair cover selling) and the pure helpers for weapon kind and ammo count; verify with tests for threshold, no ammo, wrong ammo, unmonitored weapons, priority and replacement
- [x] 7.4 Wire ammo into `Controller` (env.ammo, the dialog kinds arrow and bullet with the count in the text, pending/retry, test kinds) and `Core` (API calls, events, learning the ammo code from merchant items); verify with controller and core stub tests
- [x] 7.5 Add `/cvn ammo <n>|on|off` and `/cvn test arrows|bullets` and update the README; verify with command tests and the README test

## 8. Settings panel

- [x] 8.1 Add `ns.Commands.LIMITS` as the single source of the threshold limits, and `Options.lua` registering a "Closest Vendor" page (checkbox plus slider per trigger, bound to the saved settings, applying changes at once, sliders disabled when the trigger is off) inside `pcall`; verify with stub tests of every registration call, the limits, the callbacks and an absent settings API
- [x] 8.2 Add `/cvn config` to open the page, load `Options.lua` from both TOCs, and document the panel in the README; verify with command, core and README tests (in-game check in 9.1)

## 9. Integration

- [ ] 9.1 Play-test on Forever (full checklist: `docs/test-plan.md`) with `/console scriptErrors 1`: the addon loads without errors (also closes 1.2); TomTom arrow points at the vendor and is removed on arrival; WaypointUI shows the destination; the native waypoint shows when neither is installed; filling bags to the threshold and wearing gear below 20% each show the dialog once and do not spam; Yes starts navigation, No does not and does not ask again until the condition clears and recurs; opening a vendor learns it and a later trip picks it; settings changed with `/cvn` survive `/reload`; `/cvn test sell`, `/cvn test repair`, `/cvn test arrows` and `/cvn test bullets` each show the dialog and Yes sets the pin; with a hunter and a bow or gun, using ammo down to the threshold shows the ammo dialog (note which inventory events fire); opening an ammo vendor teaches the addon that it sells ammo; the "Closest Vendor" page exists under Options, AddOns, its controls change the settings (compare with `/cvn`) and `/cvn config` opens it; no error inside a dungeon. Era: chat fallback, if you test Era later
