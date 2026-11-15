## Why

A player was routed to Gorhak, the Magram Clan quartermaster in Desolace, while Unfriendly with the Magram. Another character on the account had learned him. The game reports such NPCs as having no side, so the addon treated him as usable by everyone. The game offers no call that names the reputation an NPC needs.

## What Changes

- Each character remembers, per NPC id, whether a known vendor trades with it: true when its merchant window opens or it is seen (target, mouseover, nameplate) at Neutral or better, false when seen as Unfriendly or Hostile.
- The search never uses a vendor this character has seen as Unfriendly or Hostile.
- A learned-only vendor of no side (not in the shipped or external lists) is used only once this character has seen it trade.
- The debug report counts what this character has seen.

## Capabilities

### Modified Capabilities
- `vendor-discovery`: per-character trade standing filters the search pool.

## Impact

`Discovery.Tradable` (plain Lua), `Adapter.canTrade` and `A.npc(unit)`, Core event wiring and report line, new per-character `standing` table. Existing learned vendors of no side stay out of the search for each character until that character sees them.
