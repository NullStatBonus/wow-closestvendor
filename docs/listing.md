# Store listing

Copy-ready text and field values for the CurseForge and Wago projects. Create the projects first, then add their IDs to both TOC files (see [publishing.md](publishing.md)). Category names and field limits below are from memory of the site forms: confirm them while you fill the forms in, and pick the closest match if a name differs.

## Fields

| Field | Value |
|---|---|
| Project name | Closest Vendor |
| Slug / URL name | closest-vendor (use whatever is free) |
| Summary (one line, keep under 250 characters) | Designed for WoW Forever and Classic Era, this World of Warcraft addon directs you to the closest relevant vendor whenever your gear needs repair or your bags are nearly full. |
| Main category | Map & Minimap |
| Additional categories | Bags & Inventory, Miscellaneous |
| Game versions | Classic Era (1.15.x) and WoW Forever (1.60.x). The packager reads `## Interface` from each TOC: 11509 for `ClosestVendor_Vanilla.toc`, 16001 for `ClosestVendor_Camelot.toc`. |
| License | MIT |
| Source code URL | `https://github.com/NullStatBonus/wow-closestvendor` |
| Issues URL | `https://github.com/NullStatBonus/wow-closestvendor/issues` |
| Relations | Optional dependencies: TomTom (`tomtom` on CurseForge) and WaypointUI (`waypointui` on CurseForge). The addon works without either. |
| Tags | vendor, repair, ammo, reagent, profession, trainer, navigation, waypoint, quality of life, classic, forever |
| Release type | Release (use Beta for pre-release tags) |
| Changelog | Taken from `CHANGELOG.md` by the packager; nothing to type. |
| Donations | none |

## Description

Paste this into the description box (CurseForge and Wago both take Markdown or HTML; use the Markdown editor if offered).

---

Designed for WoW Forever and Classic Era, this World of Warcraft addon directs you to the closest relevant vendor whenever your gear needs repair or your bags are nearly full.

The addon watches five things. It always asks before it sends you anywhere.

- **Bags nearly full:** at 2 free slots or fewer (you choose the number), it offers the closest vendor you can sell to.
- **Worn gear:** when an equipped item is below 20% durability (you choose), it offers the closest repair vendor.
- **Low ammo:** with a bow, crossbow or gun equipped, at 200 or fewer arrows or bullets (you choose), it offers the closest vendor that sells that ammo.
- **Class reagents:** at 5 or fewer of a reagent (you choose), it offers the closest vendor that sells it.
- **Professions:** when a profession is 10 points or fewer from its current skill limit (you choose), it offers the closest trainer you opened before. It asks on every skill-up and every craft.

Reagents the addon watches:

- Mage: Arcane Powder, Rune of Teleportation, Rune of Portals.
- Rogue: Flash Powder.
- Priest: Holy Candle, Sacred Candle.
- Paladin: Symbol of Kings, Symbol of Divinity.
- Shaman: Ankh.
- Druid: Rebirth seeds, Wild Berries, Wild Thornroot.

The addon watches a reagent only when you know a spell that uses it. You can turn off each reagent on its own.

**Buys your ammo.** At any merchant, with a bow, crossbow or gun equipped, the addon fills your quiver or ammo pouch. It needs no clicks. You can make it ask first. Arrows and bullets each have a grade setting: the same ammo you have equipped (default), the best your level allows, or the cheapest. The addon buys only what you can afford. It tells you in chat.

**Buys your class reagents.** This setting is off by default. When you turn it on, the addon stocks you up at any merchant that sells your reagents. The default is 20 of each reagent (you choose, 0 to 100). It counts the reagents already in your bags. By default it asks first and shows the reagents, the counts and the price. You can make it buy at once. It buys only what you can afford and what fits in your bags. It tells you in chat.

**The question.** A small Yes / No question shows the vendor name and zone. Answer Yes. The addon then shows the way with the first of these that you have:

1. TomTom
2. WaypointUI (WoW Forever)
3. The game's own map waypoint (WoW Forever)
4. A chat message with the vendor, zone and coordinates (Classic Era without TomTom: install TomTom to get an arrow)

If the closest vendor is on another map and a vendor on your own map is farther away, the question shows both with zone and distance. You choose one. You can also set the addon to choose for you without a question. It then tells you its choice in chat and with a silent message on screen for about five seconds. You can turn off the message.

If several things are low, the addon asks one question at a time. The order is repair, ammo, reagents, selling, trainers. A repair or ammo trip also covers selling.

**Status window.** A small window you can move shows ammo, class reagents, bag space, durability and professions near their limit. It shows one line for each item. A line turns red when the item is low.

- Each group of lines can show only when low (default), always or never.
- The window hides when no line qualifies.
- Click a line to set a waypoint to the closest vendor for that item. The addon asks no question. This works in combat.
- Drag the title to move the window. Shift-drag anywhere also moves it.
- A lock setting stops all dragging.
- The cog button opens the settings page.
- Turn reagents to always to show Soul Shards, Blinding Powder and conjured food and water. These lines only display; a click does nothing.
- The background is pure black by default. You can pick any color.
- Background opacity goes down to 0, so only the text and icons show. You can also dim the text and icons.
- The window has no border and no bright fixed fills. This is kind to OLED screens.

**Instances and battlegrounds.** Inside an instance, the addon waits and asks nothing. A full-bags question in a battleground is not lost. The addon asks again when you leave. A click on a status window line in an instance searches from your hearthstone point (default) or from your last position outside. You choose. You can also turn on auction house routing (off by default). When an auctioneer is closer than a vendor, a click goes to the auctioneer. The addon ships 28 auctioneers and learns more as you open auction houses.

**Learns as you play.** The addon ships with about 900 vendors. It remembers every vendor window you open. It also remembers which vendors repair and which sell arrows or bullets. This covers the new WoW Forever zones: Mount Hyjal, Riverglades, Zephras Isle, Darkspear Islands and Shen'dralas.

**Settings.** Open Options, AddOns, **Closest Vendor**. The main page has these settings:

- A checkbox and a slider for each warning.
- Two dropdowns for when the closest target is on another map: ask or navigate without asking, and prefer your map or the closest.
- A dropdown for the instance search point.
- A switch for auction house routing.

The ammo checkbox turns ammo and reagents on or off together. Three subpages sit under the main page:

- **Reagents:** a slider and a checkbox for each reagent of your class. It also has a reagent-buying switch, an ask-first switch and the number of each reagent to carry.
- **Ammo buying:** an ammo-buying switch, an ask-first switch and a grade dropdown for arrows and for bullets.
- **Status window:** lock, scale, background and text opacity, background color (a swatch that opens the color picker) and a show dropdown for each group.

Each setting also has a command:

- `/cvn` shows your settings. `/cvn config` opens the settings page.
- `/cvn bags 4`, `/cvn dur 30`, `/cvn ammo 300`, `/cvn reagent 8` and `/cvn trade 25` change the thresholds. Add `on` or `off` to turn a warning on or off. `/cvn ammo off` also turns off reagents.
- `/cvn reagents` lists the reagents of your class.
- `/cvn reagent off arcane powder` and `/cvn reagent on arcane powder` turn one reagent off or on.
- `/cvn buy on`, `/cvn buy off`, `/cvn buy ask` and `/cvn buy auto` control ammo buying.
- `/cvn arrows best` and `/cvn bullets cheapest` set the grade. The grades are `equipped`, `best` and `cheapest`.
- `/cvn reagentbuy on`, `/cvn reagentbuy off`, `/cvn reagentbuy ask` and `/cvn reagentbuy auto` control reagent buying.
- `/cvn reagentbuy 40` sets the number of each reagent to carry. 0 buys none.
- `/cvn choice ask` and `/cvn choice auto` set what happens when the closest vendor or trainer is on another map.
- `/cvn prefer map` and `/cvn prefer distance` set which one the addon prefers in that case.
- `/cvn notice off` hides the on-screen message that goes with automatic waypoints.
- `/cvn hud lock`, `/cvn hud unlock` and `/cvn hud reset` lock, unlock and reset the status window.
- `/cvn hud scale 150` sets the scale.
- `/cvn hud opacity 0` removes the background.
- `/cvn hud textopacity 60` dims the text and icons.
- `/cvn hud color` opens the color picker. `/cvn hud color #101820` or `/cvn hud color black` sets the background color.
- `/cvn hud row bags always` sets when a group shows. The groups are `ammo`, `reagents`, `professions`, `bags` and `durability`. The values are `low`, `always` and `never`.
- `/cvn anchor hearth` and `/cvn anchor last` set where a click inside an instance searches from.
- `/cvn ah on` and `/cvn ah off` turn auction house routing on or off.
- `/cvn test sell`, `/cvn test repair`, `/cvn test arrows`, `/cvn test bullets` and `/cvn test reagent` show each question now.

**Good to know**

- Distance is a straight line, not a walking route.
- The addon considers only vendors on your current continent.
- "Your map" is the exact map you stand in. A city is its own map, separate from the zone around it.
- The addon skips vendors of the other faction.
- The shipped vendor list is Vanilla data. Vendors that exist only in WoW Forever stay unknown until you open them once.
- The addon counts ammo for the ammo you have equipped (bags included).
- The addon counts reagents in your bags, not the bank.
- Reagent buying is off until you turn it on. It buys only the reagents the warning watches. It buys into ordinary bags. It never buys above the amount you set.
- For ranked spells (Rebirth, Prayer of Fortitude, Gift of the Wild), the addon watches only the reagent of your highest known rank.
- Warlocks, hunters and warriors have no reagent questions.
- Ammo buying fills only quivers and ammo pouches that match your weapon. It never fills ordinary bags.
- "Best" ammo goes by the level an item requires, because the game does not report ammo damage.
- The addon learns trainers; it does not ship them. Open a profession trainer once. The addon then remembers it for all your characters.
- The addon does not check the trainer's level requirement.
- In instances and battlegrounds, the addon asks nothing until you leave.
- A status window click in an instance searches from your hearthstone point or last position. The vendor can be far from you.
- TomTom can refuse a waypoint that you set from inside an instance.
- The status window can lag a moment behind bag and ammo changes.
- If the status window is off screen, type `/cvn hud reset`.

**Problems?** Type `/cvn debug on`. Repeat what went wrong. Type `/cvn log`. Copy the report that opens. Send it with your client (Classic Era or WoW Forever).

Free and open source (MIT). The vendor data comes from the pfQuest database (MIT) and wago.tools map data. The addon text is English. It can be translated; see the source repository.

---

## Screenshots to capture

1. The question with a vendor name and zone (`/cvn test sell`).
2. The repair question (`/cvn test repair`).
3. The settings page under Options, AddOns.
4. A TomTom arrow or the map waypoint after answering Yes.
5. The ammo question for a hunter (`/cvn test arrows`).
6. The chat line after an ammo purchase.
7. The status window with a few lines, one of them red.
8. The Status window settings page.

Use 1920x1080 or larger, UI scale unchanged, with the chat frame showing nothing private.

## After creating the projects

Both IDs are in both TOC files (`## X-Curse-Project-ID`, `## X-Wago-ID`). With the repository secrets `CF_API_TOKEN` and `WAGO_API_TOKEN` set, every `vX.Y.Z` tag publishes to both sites (see publishing.md). Update the pasted description and summary on each site whenever this file changes; the sites do not read it.
