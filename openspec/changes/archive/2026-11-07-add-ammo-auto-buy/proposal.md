# Proposal

## Why

The ammo trigger walks the player to a vendor but then leaves them to count quiver space and buy by hand. Topping up to a full quiver or pouch is the whole point of the trip, so the addon should finish it.

## What Changes

- On opening a merchant with a bow, crossbow or gun equipped, buy ammo until the matching quiver or ammo pouch is full. Zero clicks by default.
- Buy only for the weapon's ammo kind, and only into quivers/pouches of that kind (no filling general bags).
- Settings: buying on/off, "ask first" (a confirm popup instead of buying at once), and a separate grade mode for arrows and for bullets: same as equipped (default), best usable, cheapest.
- Buy what the player can afford; report the purchase, or why nothing was bought, in chat.
- First time the addon acts on the game rather than only reading it.

## Capabilities

### New Capabilities
- `ammo-purchase`: topping up ammo to quiver/pouch capacity at a merchant, grade selection, and its settings.

### Modified Capabilities

## Impact

- `Adapter.lua`: purchase call, merchant item reads, quiver/pouch slot counts, stack size, required level.
- New pure-Lua module `Ammo.lua` (both TOCs) with capacity and grade-selection logic and `tests/test_ammo.lua`.
- `Controller.lua` / `Core.lua`: call on merchant open. `Options.lua`, `Commands.lua`, `Core.lua` DEFAULTS: new settings.
- `Locales/enUS.lua`: new strings. Minor version bump and CHANGELOG on archive.
