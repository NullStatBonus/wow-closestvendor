# Proposal

## Why

Players forget to vend and repair until bags are full or gear breaks, then hunt for the nearest merchant. An addon can detect both conditions and point at the right vendor automatically, for WoW Forever and Classic Era.

## What Changes

- New addon (Forever + Classic Era) that watches free bag slots and equipped-item durability.
- When free slots <= threshold (default 2), navigate to the nearest vendor that buys items.
- When durability < threshold (default 20%), navigate to the nearest vendor that repairs.
- Navigation goes through an adapter, first available wins: TomTom, then WaypointUI's navigation API, then the Blizzard user waypoint (Forever only; Classic Era lacks it), then a chat message.
- Ship a generated static vendor table (only vendors that sell/buy or repair), built offline from the MIT-licensed pfQuest database plus wago DB2 map data. GPL sources (Questie, vmangos, cmangos) are not used.
- Learn vendors at runtime: when a merchant window opens, record that vendor (id, name, position, repair capability) so vendors missing from the shipped data, such as Forever-only ones, are discovered by play.
- Release the addon under the MIT license, with the pfQuest notice kept in `THIRD_PARTY.md`.
- Watch ranged ammo: with a bow, crossbow or gun equipped, when the equipped ammo drops to a threshold (default 200), ask to navigate to the nearest vendor that sells that kind of ammo (arrows or bullets).
- Settings for the thresholds and enable/disable of each trigger.

Out of scope for v1: class reagents other than ammo (the trigger is built so they can be added), walking-path distance, cross-continent routing, a settings UI beyond slash commands.

## Capabilities

### New Capabilities
- `vendor-trigger`: Detect low bag space / low durability and decide when to start and stop navigation, with configurable thresholds.
- `vendor-data`: Static dataset of sell and repair vendors with coordinates, plus the offline build that generates it.
- `vendor-discovery`: Learn vendors from merchant windows at runtime, persist them, and merge them into the search.
- `vendor-navigation`: Pick the nearest eligible vendor and hand it to a waypoint adapter (TomTom, WaypointUI, Blizzard waypoint, chat).

### Modified Capabilities

None (greenfield).

## Impact

- New addon folder with per-flavor TOCs (`_Vanilla` = Era 11509, `_Camelot` = Forever 16001, the same pattern as the sibling `wow-dontdothat` addon), Lua, generated vendor data, saved variables.
- `LICENSE` (MIT) and `THIRD_PARTY.md` (pfQuest, MIT).
- Optional dependencies: TomTom, WaypointUI. No embedded libraries (native `C_Map` provides world positions).
- Test tooling: `luajit` tests with WoW API stubs, stdlib `unittest` for the build script, a `make test` entry point.
- Build tooling: script consuming the pfQuest database and wago map CSVs (to map pfQuest zone ids to UI maps).
