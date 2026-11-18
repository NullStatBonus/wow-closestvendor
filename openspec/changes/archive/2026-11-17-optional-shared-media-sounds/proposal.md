# Proposal

## Why

The notification sound offers only four game sounds and None. Many players already have sound packs registered with LibSharedMedia-3.0, through DBM, BigWigs, WeakAuras or a SharedMedia pack. Don't Do That already lists those sounds. Closest Vendor should list them too, without shipping the library (GitHub issue #30).

## What Changes

- When another addon provides LibSharedMedia-3.0, the Notification sound dropdown and `/cvn sound <name>` also list its sounds, labelled "<name> (sound pack)". The built-in sounds stay first, and None stays silent.
- The setting saves a sound-pack choice as `lsm:<name>`. The built-in keys do not change, so saved settings are not touched.
- The list is read each time it is shown or used, so a library that loads late still appears.
- If a saved sound-pack sound is missing (pack removed or not loaded yet), the default sound plays. The choice stays saved and works again when the pack is back.
- Sound-pack sounds play as files (`PlaySoundFile`). Built-in sounds still play by id.
- Closest Vendor does not embed LibSharedMedia. Without it, nothing changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `craft-reminders`: "The reminder sound is a choice" adds the sound-pack choices and the missing-sound fallback.

## Impact

- `ClosestVendor/Adapter.lua`: read LibSharedMedia through LibStub (pcall-guarded, nil when missing); list its sound names; fetch a file path; `A.playSound` plays a number by `PlaySound` and a string path by `PlaySoundFile`.
- `ClosestVendor/Supplies.lua`: the sound list joins `S.SOUNDS` with sound-pack names; `SoundId` resolves `lsm:` keys and falls back to the default; `FindSound` matches sound-pack names.
- `ClosestVendor/Commands.lua`, `ClosestVendor/Options.lua`: choices, names and dropdown values come from the joined list (the dropdown values become a function).
- `ClosestVendor/Core.lua`: wires the Adapter's sound-pack reader into Supplies.
- Tests: `test_supplies`, `test_commands`, `test_options`, `test_adapter`, with a fake LibSharedMedia.
- Docs: README, `docs/listing.md`, a new `docs/test-plan.md` section. The debug report already prints `remindSound`.
- Version: minor bump to 1.8.0 at archive.
