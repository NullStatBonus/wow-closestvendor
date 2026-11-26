## ADDED Requirements

### Requirement: Vendor and navigation entries
The addon SHALL register the entries `learned(kind[, npcId])` (a count of learned vendors, trainers or auctioneers, or `true` when that npc is learned; nothing for an unknown kind or npc), `standing(npcId)` (`true`, `false` or nothing), `nav()` (the waypoint method in use now: `tomtom`, `waypointui`, `native` or `chat`, from a value kept current without reading the game in the entry) and `external()` (the NorgannonDB state the report shows). They SHALL follow the same rules as the other entries.

#### Scenario: Learned count
- **WHEN** CheckThat calls `learned` with `vendors` before any vendor is learned
- **THEN** it returns 0

#### Scenario: Waypoint method after a settings change
- **WHEN** the player picks the game waypoint on the settings page and CheckThat calls `nav`
- **THEN** it returns `native`
