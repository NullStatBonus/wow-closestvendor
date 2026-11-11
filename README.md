# Closest Vendor

Designed for WoW Forever and Classic Era, this World of Warcraft addon directs you to the nearest relevant vendor whenever your gear needs repair or your bags are nearly full.

- Free bag slots at or below a threshold (default **2**): nearest vendor you can sell to.
- Any equipped item below a durability threshold (default **20%**): nearest vendor that can repair.
- Equipped ammo at or below a threshold (default **200**), with a bow, crossbow or gun: nearest vendor that sells that ammo (arrows or bullets).
- A class reagent at or below a threshold (default **5**): nearest vendor that sells it. Mage (Arcane Powder, Rune of Teleportation, Rune of Portals), Rogue (Flash Powder), Priest (Holy Candle, Sacred Candle), Paladin (Symbol of Kings, Symbol of Divinity), Shaman (Ankh) and Druid (Rebirth seeds, Wild Berries, Wild Thornroot). A reagent is watched only once you know a spell that uses it, and each one can be switched off on its own.
- A profession within a threshold (default **10**) points of its current skill limit: nearest trainer for that profession that you have opened before. It asks on every skill-up and every craft.
- At any merchant, with a bow, crossbow or gun equipped, it buys ammo to fill your quiver or ammo pouch (no clicks by default). Grade for arrows and bullets is set separately: the same as your equipped ammo, the best your level allows, or the cheapest. It buys only what you can afford and tells you in chat.
- At any merchant that sells your class reagents, it can stock you up to a set amount of each (default **20**), counting what is already in your bags. Off by default; it asks first, showing the reagents, counts and price, unless you switch that off. It buys only what you can afford and what fits in your bags, and tells you in chat.
- Several at once: one question at a time, in the order repair, ammo, reagent, sell, trainer. A repair or ammo trip also covers selling.

When that happens it **asks first** (Yes / No). Yes shows the vendor through the first of these that is available:

1. **TomTom** (Forever and Era)
2. **WaypointUI** (Forever)
3. The built-in map waypoint (Forever)
4. A chat message with the vendor name, zone and coordinates (Era without TomTom)

Era has no built-in waypoint API, so on Era you need TomTom to get an arrow.

**When the closest vendor is on another map,** and a vendor on your own map is farther away, the question lists both with their zone and distance and has three buttons: the one on your map, the closest, and Cancel. Your preference (default: the one on your map) is the first button. If you would rather not be asked, `/cvn choice auto` sets the waypoint straight away using the same preference, prints one chat line and shows the same text on screen for about five seconds (silently, since the map pin already makes a sound). The line names the target with its zone and distance, and the other choice when there was one. `/cvn notice off` turns the on-screen text off. The same applies to trainers.

## Status window

A small movable window lists what the addon tracks, one line per item: ammo (arrows or bullets, with a ranged weapon), each class reagent, bag space, durability and each profession close to its limit. A line turns red when that item is low, using the same threshold as its question. The window only shows when at least one line qualifies, and never shows empty. A value the game cannot read hides its line instead of showing 0.

- **Visibility per group:** the lines come in five groups (Ammo, Reagents, Bag space, Durability, Professions), and each group is **Only when low** (the default), **Always** or **Never**. One setting covers the whole group: every profession line follows Professions, every reagent line follows Reagents. Set it on the Status window settings page or with `/cvn hud row <group> low/always/never`.
- **Click a line** to pin the closest vendor for that item at once, with no question and whatever your choice mode (ask or auto) is. It works in combat. The usual "Navigating to ... to buy ..." chat line and on-screen notice say why. A profession line works only while the profession is within its threshold, and a trainer must already be known.
- **Move it** by dragging the title, or hold Shift and drag anywhere on the window. **Lock window position** (first control on the Status window page, or `/cvn hud lock`) stops all dragging, Shift-drag included. The position is saved; `/cvn hud reset` puts it back.
- **Cog button** on the window opens the Closest Vendor settings page.
- **Display-only lines** are part of the Reagents group but are never low, so they show only while Reagents is Always. They cannot be routed to, so clicking them does nothing: Soul Shards (Warlock), Blinding Powder (Rogue), Conjured Food and Conjured Water (Mage).
- **Size and opacity:** window scale (50 to 200 percent, also `/cvn hud scale`), background opacity (0-100 percent, default 80, also `/cvn hud opacity`) and text and icon opacity (20-100 percent, default 100, also `/cvn hud textopacity`) are on the Status window page. At background opacity 0 no background is drawn at all, only the text and icons.
- **Background color:** pure black by default. Where the game has its color picker, the Status window page shows a swatch of the current color; click it to pick any color. `/cvn hud color` with no color opens the color picker directly, wherever the game has one, even if the swatch is not on the page; `/cvn hud color #rrggbb` works everywhere (and is the only way where there is no picker), and `/cvn hud color black` (or `reset`) goes back to black.
- **OLED-friendly:** the window has no border and no bright fixed fills, a low line is marked by its text color only, and the text and icons can be dimmed, so nothing static needs to stay bright on screen.

### Dungeons, raids and battlegrounds

Inside an instance the addon waits instead of asking, so a full-bags question in a battleground is no longer lost: it comes back when you leave. It remembers your last position outside and learns your hearthstone point from your bind location. Clicking a line inside an instance searches near an anchor: battlegrounds use your last position outside; dungeons and raids use `/cvn anchor hearth` (the default, falling back to the last position when the hearthstone point is not known yet) or `/cvn anchor last`. A pin made this way says so in chat.

### Auction house

Off by default (`/cvn ah on`). When on, clicking a line for an item that can be traded goes to the closest auctioneer instead of a vendor when the auctioneer is closer. It is ignored inside instances. The addon ships 28 auctioneers and learns more each time you open an auction house.

## Install

Copy the `ClosestVendor` folder into your AddOns folder:

- Forever: `World of Warcraft/<forever folder>/Interface/AddOns/`
- Classic Era: `World of Warcraft/_classic_era_/Interface/AddOns/`

The addon ships one TOC per game (`ClosestVendor_Vanilla.toc` for Era, `ClosestVendor_Camelot.toc` for Forever).

## Settings page

Options, AddOns, **Closest Vendor** is the main page, with three subcategories under it (on a client without subcategories everything is on the one page under section headings).

- **Closest Vendor** (main page): *Warnings* has a checkbox and a slider for each trigger (bags, durability, ammo and reagents, professions) and a checkbox for the on-screen notice. The ammo checkbox is the one switch for both ammo and reagents. *Navigation* has the dropdowns for when the closest target is on another map (ask which one or navigate without asking; prefer the target on your map or the closest), the search anchor inside instances, and the auction house checkbox.
- **Reagents:** a slider for the reagent threshold and a checkbox for each reagent of your class, all on. Below them, reagent buying: **Buy reagents** (off by default), **Ask before buying reagents** (on by default) and a slider for how many of each reagent to carry (0-100, default 20; 0 buys none). For a class without vendor reagents these three are greyed out, with a tooltip saying why.
- **Ammo:** two checkboxes (buy ammo, ask before buying) and a dropdown for arrows and one for bullets.
- **Status window:** Lock window position (first), sliders for scale, background opacity and text and icon opacity, the background color (a swatch that opens the game's color picker, where the game has one), and an Only when low / Always / Never dropdown for each group of lines, in window order: Ammo, Reagents, Bag space, Durability, Professions. A group that does not apply to your class (Ammo, or Reagents for a class with no reagents) is still listed, greyed out, with a tooltip saying why.

It changes the same settings as the commands below, and `/cvn config` opens the main page.

## Commands

```
/cvn
/cvn config
/cvn bags 4
/cvn bags off
/cvn bags on
/cvn dur 30
/cvn dur off
/cvn dur on
/cvn ammo 300
/cvn ammo off
/cvn ammo on
/cvn reagent 8
/cvn reagents
/cvn reagent off arcane powder
/cvn reagent on arcane powder
/cvn trade 25
/cvn trade off
/cvn trade on
/cvn test sell
/cvn test repair
/cvn test arrows
/cvn test bullets
/cvn test reagent
/cvn debug on
/cvn debug off
/cvn log
/cvn log clear
/cvn choice auto
/cvn choice ask
/cvn prefer distance
/cvn prefer map
/cvn notice off
/cvn notice on
/cvn buy off
/cvn buy ask
/cvn reagentbuy on
/cvn reagentbuy auto
/cvn reagentbuy 40
/cvn arrows best
/cvn bullets cheapest
/cvn hud lock
/cvn hud unlock
/cvn hud reset
/cvn hud scale 150
/cvn hud opacity 0
/cvn hud textopacity 60
/cvn hud color #101820
/cvn hud color black
/cvn hud row bags always
/cvn anchor hearth
/cvn anchor last
/cvn ah on
/cvn ah off
```

- `/cvn` shows the current settings. `/cvn config` opens the settings page.
- `/cvn bags <slots>` sets the free-slot threshold (0 to 200). `on` / `off` turns the bag trigger on or off.
- `/cvn dur <percent>` sets the durability threshold (1 to 100). `on` / `off` turns the durability trigger on or off.
- `/cvn ammo <count>` sets the ammo threshold (0 to 2000). `on` / `off` turns the ammo and reagent triggers on or off.
- `/cvn trade <points>` sets the profession threshold (0 to 300). `on` / `off` turns the profession trigger on or off.
- `/cvn reagent <count>` sets the threshold for all class reagents (1 to 40). `/cvn reagents` lists your class's reagents and whether each is on. `/cvn reagent off <name>` and `/cvn reagent on <name>` switch one reagent (case does not matter).
- `/cvn choice ask` (the default) lists both targets when the closest is on another map and waits for your pick; `/cvn choice auto` sets the waypoint at once, with no question.
- `/cvn prefer map` (the default) prefers the nearest target on your current map; `/cvn prefer distance` prefers the nearest by distance. It decides the first button, and what `auto` picks.
- `/cvn notice on` (the default) / `/cvn notice off` show or hide the on-screen text when a target is chosen without asking. The chat line is always printed.
- `/cvn buy on` / `/cvn buy off` switch ammo buying on or off. `/cvn buy ask` shows the count and price and waits for a Yes; `/cvn buy auto` (the default) buys at once.
- `/cvn reagentbuy on` / `/cvn reagentbuy off` switch reagent buying on or off (off by default). `/cvn reagentbuy ask` (the default) shows the reagents, counts and price and waits for a Yes; `/cvn reagentbuy auto` buys at once. `/cvn reagentbuy <count>` sets how many of each class reagent to carry (0-100, default 20; 0 buys none). A class without vendor reagents is told so.
- `/cvn arrows <mode>` and `/cvn bullets <mode>` choose which ammo to buy: `equipped` (the default), `best` or `cheapest`.
- `/cvn hud lock` / `/cvn hud unlock` block or allow moving the status window; `/cvn hud reset` puts it back at its default position; `/cvn hud scale <percent>` sets its size (50-200); `/cvn hud opacity <percent>` sets how solid its background is (0-100, 0 draws no background); `/cvn hud textopacity <percent>` sets how solid its text and icons are (20-100); `/cvn hud color` opens the color picker, `/cvn hud color <#rrggbb>` sets the background color, and `black` or `reset` goes back to black; `/cvn hud row <group> low/always/never` sets when a group of lines shows. The group is `ammo`, `reagents`, `professions`, `bags` or `durability`, for example `/cvn hud row professions always`. `/cvn` lists the groups you changed.
- `/cvn anchor hearth` (the default) or `/cvn anchor last` sets where a line click searches from inside a dungeon or raid: near your hearthstone point or your last position outside.
- `/cvn ah on` / `/cvn ah off` let a line click go to the auction house when it is closer than a vendor (off by default).
- `/cvn test sell`, `/cvn test repair`, `/cvn test arrows`, `/cvn test bullets` and `/cvn test reagent` ask the same question right now for that kind of vendor, whatever your bags, gear and ammo look like. Yes sets the pin. Opening any vendor window clears it.
- `/cvn debug on` and `/cvn debug off` switch the debug log on and off. `/cvn log` shows a report you can copy, `/cvn log clear` empties the log.
- `/closestvendor` works the same as `/cvn`.

Settings are saved per account.

## How it finds vendors

The addon ships a list of about 900 vendors, and it learns more as you play. Every time you open a vendor window it records that vendor (position, whether it repairs, and which ammo and reagents it sells). Learned vendors replace shipped ones with the same NPC id and are saved between sessions.

Trainers work the same way but nothing is shipped: opening a profession trainer's window records where it is and which professions it teaches. Trainers (and the professions you have seen at a trainer or in a crafting window) are shared by all your characters.

Vendors you open in WoW Forever's new zones (Mount Hyjal, Riverglades, Zephras Isle, Darkspear Islands, Shen'dralas) are the way those zones get covered.

## Limitations

- **Forever-only vendors are unknown until you open them.** The shipped list is Vanilla data. Forever's new zones have no shipped vendors, and vendors in zones Forever reshaped may be slightly off.
- **Ammo buying fills only quivers and ammo pouches** that match your weapon, never ordinary bags, and ignores the stack in your ammo slot. "Best" ranks by the level an item requires, since the game does not report ammo damage.
- **Ammo is counted for the ammo you have equipped** (bags included). If the equipped ammo is the wrong kind for your weapon, or none is equipped, the count is 0. Thrown weapons and wands are not monitored.
- **Reagents are counted in your bags** (not the bank), and only for the spells you know. For ranked spells the reagent of your highest known rank is the one watched (for example the seed for your best Rebirth). Warlocks, hunters and warriors have none, and rogue poisons are not covered. Soul Shards, Blinding Powder and conjured food and water appear only as display-only status window lines, shown while the Reagents group is Always: they are counted, never routed to (no vendor sells them). The addon asks and shows the way, and buys reagents only when you switch reagent buying on.
- **Reagent buying covers the reagents the warning watches:** those of your class whose spell you know and that are switched on (so a reagent switched off on the Reagents page is not bought either), counted the same way, bags only. It tops each up to the amount and never above it; an item a merchant sells in batches is bought only in whole batches that stay within the amount. Reagents go in ordinary bags only (not quivers, soul bags or profession bags). When gold or bag room runs out it buys what it can, in reagent table order, and says so. The money left after an ammo purchase at the same merchant is taken into account.
- **Trainers are learned, not shipped.** Until you have opened a trainer for a profession, the addon cannot send you to one; it says so once per profession per session in chat. It only watches professions it has seen at a trainer or in a crafting window.
- **The last skill tier is taken to end at 300.** A profession whose limit is already 300 is never asked about. Whether WoW Forever has tiers above 300 is not verified. The trainer's level requirement is not checked, so a character that is too low may be sent to a trainer who cannot teach the next tier yet.
- **Distance is a straight line**, not a walking route, and only vendors on your current continent are considered.
- **"Your map" means the exact map you are standing in.** A city is its own map, separate from the zone around it, so in a city "your map" is that city.
- **Vendors of the other faction are skipped.** Neutral vendors count for everyone.
- Nothing is asked in dungeons, raids and battlegrounds; the addon waits until you leave. A status window click there searches from an anchor (see above), so the vendor shown may be far from where you stand, and TomTom may refuse a waypoint set from inside an instance (chat then says so). Where the game gives no map position at all, the addon waits and retries.
- The status window can lag a moment behind bag, ammo and skill changes. A saved window position that ends up off screen after a UI scale change is recovered with `/cvn hud reset`.
- Auction house routing goes by straight-line distance to an auctioneer, as with vendors, and uses auctioneers shipped or learned; it does not check prices or whether an item can be sold there.
- Professions are matched by the name the game shows, so after changing the game language, trainers are learned again.
- The addon's own text is English. Other languages can be added; see [docs/localization.md](docs/localization.md).
- Written and tested against fake game APIs. See the status of in-game checks in `docs/test-plan.md`.

## Problems?

Type `/cvn debug on`, do the thing that went wrong, then type `/cvn log`. A window opens with a report: select all (Ctrl+A), copy (Ctrl+C), and send it with a short description and your client (Classic Era or Forever). `/cvn debug off` stops recording. The report holds the game build, your settings (including whether the game's color picker and settings button exist, and why the background color swatch is missing if it is) and what the addon saw and decided; it holds no character name.

## For developers

See [CONTRIBUTING.md](CONTRIBUTING.md). In short:

```
make test     # Lua tests (luajit tests/run.lua [pattern]) and Python tests
make check    # TOC, version and changelog checks, the same ones the release workflow runs
```

The vendor list is generated, not edited by hand (`python3 tools/fetch_data.py`, then `python3 tools/build_vendors.py`); see [docs/publishing.md](docs/publishing.md). To use a different data source, add a function that returns normalized records (see `pfquest_records` in `tools/build_vendors.py`) and pass them to `render`.

## License and data

MIT, see [LICENSE](LICENSE). The vendor list is generated from the [pfQuest](https://github.com/shagu/pfQuest) database (MIT) and wago.tools map data. See [THIRD_PARTY.md](THIRD_PARTY.md).
