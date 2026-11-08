# Store listing

Copy-ready text and field values for the CurseForge and Wago projects. Create the projects first, then add their IDs to both TOC files (see [publishing.md](publishing.md)). Category names and field limits below are from memory of the site forms: confirm them while you fill the forms in, and pick the closest match if a name differs.

## Fields

| Field | Value |
|---|---|
| Project name | Closest Vendor |
| Slug / URL name | closest-vendor (use whatever is free) |
| Summary (one line, keep under 250 characters) | Designed for WoW Forever and Classic Era, this World of Warcraft addon directs you to the nearest relevant vendor whenever your gear needs repair or your bags are nearly full. |
| Main category | Map & Minimap |
| Additional categories | Bags & Inventory, Miscellaneous |
| Game versions | Classic Era (1.15.x) and WoW Forever (1.60.x). The packager reads `## Interface` from each TOC: 11509 for `ClosestVendor_Vanilla.toc`, 16001 for `ClosestVendor_Camelot.toc`. |
| License | MIT |
| Source code URL | `https://github.com/NullStatBonus/wow-closestvendor` |
| Issues URL | `https://github.com/NullStatBonus/wow-closestvendor/issues` |
| Relations | Optional dependencies: TomTom (`tomtom` on CurseForge) and WaypointUI (`waypointui` on CurseForge). The addon works without either. |
| Tags | vendor, repair, ammo, profession, trainer, navigation, waypoint, quality of life, classic, forever |
| Release type | Release (use Beta for pre-release tags) |
| Changelog | Taken from `CHANGELOG.md` by the packager; nothing to type. |
| Donations | none |

## Description

Paste this into the description box (CurseForge and Wago both take Markdown or HTML; use the Markdown editor if offered).

---

Designed for WoW Forever and Classic Era, this World of Warcraft addon directs you to the nearest relevant vendor whenever your gear needs repair or your bags are nearly full.

It watches four things and asks before it sends you anywhere:

- **Bags nearly full:** 2 free slots or fewer (you choose the number) and it offers the nearest vendor you can sell to.
- **Gear worn:** any equipped item below 20% durability (you choose) and it offers the nearest repair vendor.
- **Ammo low:** a bow, crossbow or gun equipped and your arrows or bullets at 200 or fewer (you choose) and it offers the nearest vendor that sells that ammo. Once there, it buys the ammo for you (see below).
- **Professions:** a profession 10 points or fewer from its current skill limit (you choose) and it offers the nearest trainer you have opened before. It asks on every skill-up and every craft.

**Buys your ammo.** At any merchant, with a bow, crossbow or gun equipped, it fills your quiver or ammo pouch for you, no clicks. You can have it ask first instead. Arrows and bullets each have a setting: the same ammo you have equipped (default), the best your level allows, or the cheapest. It only buys what you can afford and says so in chat.

A small Yes / No question shows the vendor's name and zone. If the closest vendor is on another map and one on your own map is farther, you get both to choose from, with zone and distance, or you can set it to pick for you without asking, in which case it tells you what it picked in chat and with a silent message on screen (which can be switched off). Answer Yes (or pick one) and it shows the way with the first of these you have:

1. **TomTom**
2. **WaypointUI** (WoW Forever)
3. The game's own map waypoint (WoW Forever)
4. A chat message with the vendor, zone and coordinates (Classic Era without TomTom: install TomTom for an arrow)

If several things are low at once it asks one question at a time: repair first, then ammo, then selling, then trainers. A repair or ammo trip also covers selling.

**Learns as you play.** It ships with about 900 vendors and remembers every vendor window you open, including which ones repair and which sell arrows or bullets. That is how WoW Forever's new zones (Mount Hyjal, Riverglades, Zephras Isle, Darkspear Islands, Shen'dralas) get covered.

**Settings.** Options, AddOns, **Closest Vendor** has a checkbox and a slider for each trigger, plus an ammo-buying switch, an ask-first switch and a grade dropdown for arrows and for bullets, and two dropdowns for when the closest target is on another map (ask or navigate without asking; prefer your map or the closest). The same things are available as commands:

- `/cvn` shows your settings, `/cvn config` opens the settings page
- `/cvn bags 4`, `/cvn dur 30`, `/cvn ammo 300`, `/cvn trade 25` change the thresholds; add `on` or `off` to switch a trigger
- `/cvn buy on`, `/cvn buy off`, `/cvn buy ask`, `/cvn buy auto` control ammo buying; `/cvn arrows best` and `/cvn bullets cheapest` pick the grade (`equipped`, `best` or `cheapest`)
- `/cvn choice ask` or `/cvn choice auto`, and `/cvn prefer map` or `/cvn prefer distance`, decide what happens when the closest vendor or trainer is on another map; `/cvn notice off` hides the on-screen message that goes with automatic pins
- `/cvn test sell`, `/cvn test repair`, `/cvn test arrows`, `/cvn test bullets` show each question right now so you can see what it does

**Good to know**

- Distance is a straight line, not a walking route, and only vendors on your current continent are considered.
- "Your map" is the exact map you stand in. A city is its own map, separate from the zone around it.
- Vendors of the other faction are skipped.
- The shipped vendor list is Vanilla data. Vendors that exist only in WoW Forever are unknown until you open them once.
- Ammo is counted for the ammo you have equipped (bags included).
- Ammo buying fills only quivers and ammo pouches that match your weapon, never ordinary bags. "Best" goes by the level an item requires, because the game does not report ammo damage.
- Trainers are learned, not shipped: open a profession trainer once and the addon remembers it for all your characters. The trainer's level requirement is not checked.
- Nothing is shown in dungeons, where the game gives no map position.

**Problems?** Type `/cvn debug on`, repeat what went wrong, then `/cvn log`. Copy the report that opens and send it with your client (Classic Era or Forever).

Free and open source (MIT). Vendor data generated from the pfQuest database (MIT) and wago.tools map data. The addon's text is English and can be translated; see the source repository.

---

## Screenshots to capture

1. The question with a vendor name and zone (`/cvn test sell`).
2. The repair question (`/cvn test repair`).
3. The settings page under Options, AddOns.
4. A TomTom arrow or the map waypoint after answering Yes.
5. The ammo question for a hunter (`/cvn test arrows`).
6. The chat line after an ammo purchase.

Use 1920x1080 or larger, UI scale unchanged, with the chat frame showing nothing private.

## After creating the projects

Both IDs are in both TOC files (`## X-Curse-Project-ID`, `## X-Wago-ID`). With the repository secrets `CF_API_TOKEN` and `WAGO_API_TOKEN` set, every `vX.Y.Z` tag publishes to both sites (see publishing.md). Update the pasted description and summary on each site whenever this file changes; the sites do not read it.
