## Why

The game's AddOns list shows a blank square next to Closest Vendor. KeepThat already ships its badge there, and the two addons should look alike.

## What Changes

- Ship the Closest Vendor badge as `ClosestVendor/Media/icon.tga` (64x64, 32-bit TGA with alpha).
- Both TOC files name it with `## IconTexture:`.
- A test checks both TOCs name the same icon and the file is a square, power-of-two TGA with alpha.

## Capabilities

### New Capabilities

### Modified Capabilities

- `settings-interaction`: adds the AddOns list icon requirement.

## Impact

Both TOC files, a new `Media` folder, `tests/test_icon.lua`, the test plan. No settings or saved data change.
