## Why

In the game's Options > AddOns list, Don't Do That and KeepThat show their pages under their name, but Closest Vendor shows one entry with the whole tree inside it. The three addons should look alike there.

## What Changes

- The Closest Vendor entry in the AddOns list opens Home, as KeepThat's does.
- Restock, Navigation, Appearance, Advanced and About are listed under it, in tree order, each opening its own page.
- `/cvn settings` and the HUD cog still open the standalone window with the full tree.

## Capabilities

### New Capabilities

### Modified Capabilities

- `settings-interaction`: adds the AddOns list pages requirement.

## Impact

`Options.lua` registration, `tests/fake_ace.lua`, options and core tests, README, test plan. No settings or saved data change.
