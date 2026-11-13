# Design

- Two saved variables: `ClosestVendorDB` (account) holds `learned`, `trainers`, `auctioneers`; `ClosestVendorCharDB` (character) holds `cfg`, `hud`, `professions`, `hearth`, `lastOutside`, `log`. `Core.lua` reads them through two locals, `DB` and `CHAR`.
- Migration happens once per character, when `ClosestVendorCharDB` does not exist yet: deep-copy `DB.cfg` and `DB.hud` into it. The copy is deep because `cfg` holds nested tables (`reagentOff`, `hudRow`). The old tables are left in place: the next character needs them, and removing them would lose settings if the player downgrades.
- Professions, hearth and the log are not copied: the old tables mixed every character, and the game re-teaches them (any crafting or trainer window, the next login).
- Rejected: making the whole `ClosestVendorDB` per character. It would make every alt re-learn vendors.
