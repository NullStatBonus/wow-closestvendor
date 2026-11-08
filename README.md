# Closest Vendor

Designed for WoW Forever and Classic Era, this World of Warcraft addon directs you to the nearest relevant vendor whenever your gear needs repair or your bags are nearly full.

- Free bag slots at or below a threshold (default **2**): nearest vendor you can sell to.
- Any equipped item below a durability threshold (default **20%**): nearest vendor that can repair.
- Equipped ammo at or below a threshold (default **200**), with a bow, crossbow or gun: nearest vendor that sells that ammo (arrows or bullets).
- A profession within a threshold (default **10**) points of its current skill limit: nearest trainer for that profession that you have opened before. It asks on every skill-up and every craft.
- At any merchant, with a bow, crossbow or gun equipped, it buys ammo to fill your quiver or ammo pouch (no clicks by default). Grade for arrows and bullets is set separately: the same as your equipped ammo, the best your level allows, or the cheapest. It buys only what you can afford and tells you in chat.
- Several at once: one question at a time, in the order repair, ammo, sell, trainer. A repair or ammo trip also covers selling.

When that happens it **asks first** (Yes / No). Yes shows the vendor through the first of these that is available:

1. **TomTom** (Forever and Era)
2. **WaypointUI** (Forever)
3. The built-in map waypoint (Forever)
4. A chat message with the vendor name, zone and coordinates (Era without TomTom)

Era has no built-in waypoint API, so on Era you need TomTom to get an arrow.

**When the closest vendor is on another map,** and a vendor on your own map is farther away, the question lists both with their zone and distance and has three buttons: the one on your map, the closest, and Cancel. Your preference (default: the one on your map) is the first button. If you would rather not be asked, `/cvn choice auto` sets the waypoint straight away using the same preference. The same applies to trainers.

## Install

Copy the `ClosestVendor` folder into your AddOns folder:

- Forever: `World of Warcraft/<forever folder>/Interface/AddOns/`
- Classic Era: `World of Warcraft/_classic_era_/Interface/AddOns/`

The addon ships one TOC per game (`ClosestVendor_Vanilla.toc` for Era, `ClosestVendor_Camelot.toc` for Forever).

## Settings page

Options, AddOns, **Closest Vendor** has a checkbox and a slider for each trigger (bags, durability, ammo, professions), plus ammo buying: two checkboxes (buy ammo, ask before buying) and a dropdown for arrows and one for bullets. Two more dropdowns choose what happens when the closest target is on another map: ask which one or navigate without asking, and prefer the target on your map or the closest. It changes the same settings as the commands below, and `/cvn config` opens it.

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
/cvn trade 25
/cvn trade off
/cvn trade on
/cvn test sell
/cvn test repair
/cvn test arrows
/cvn test bullets
/cvn debug on
/cvn debug off
/cvn log
/cvn log clear
/cvn choice auto
/cvn choice ask
/cvn prefer distance
/cvn prefer map
/cvn buy off
/cvn buy ask
/cvn arrows best
/cvn bullets cheapest
```

- `/cvn` shows the current settings. `/cvn config` opens the settings page.
- `/cvn bags <slots>` sets the free-slot threshold (0 to 200). `on` / `off` turns the bag trigger on or off.
- `/cvn dur <percent>` sets the durability threshold (1 to 100). `on` / `off` turns the durability trigger on or off.
- `/cvn ammo <count>` sets the ammo threshold (0 to 2000). `on` / `off` turns the ammo trigger on or off.
- `/cvn trade <points>` sets the profession threshold (0 to 300). `on` / `off` turns the profession trigger on or off.
- `/cvn choice ask` (the default) lists both targets when the closest is on another map and waits for your pick; `/cvn choice auto` sets the waypoint at once, with no question.
- `/cvn prefer map` (the default) prefers the nearest target on your current map; `/cvn prefer distance` prefers the nearest by distance. It decides the first button, and what `auto` picks.
- `/cvn buy on` / `/cvn buy off` switch ammo buying on or off. `/cvn buy ask` shows the count and price and waits for a Yes; `/cvn buy auto` (the default) buys at once.
- `/cvn arrows <mode>` and `/cvn bullets <mode>` choose which ammo to buy: `equipped` (the default), `best` or `cheapest`.
- `/cvn test sell`, `/cvn test repair`, `/cvn test arrows` and `/cvn test bullets` ask the same question right now for that kind of vendor, whatever your bags, gear and ammo look like. Yes sets the pin. Opening any vendor window clears it.
- `/cvn debug on` and `/cvn debug off` switch the debug log on and off. `/cvn log` shows a report you can copy, `/cvn log clear` empties the log.
- `/closestvendor` works the same as `/cvn`.

Settings are saved per account.

## How it finds vendors

The addon ships a list of about 900 vendors, and it learns more as you play. Every time you open a vendor window it records that vendor (position, and whether it repairs). Learned vendors replace shipped ones with the same NPC id and are saved between sessions.

Trainers work the same way but nothing is shipped: opening a profession trainer's window records where it is and which professions it teaches. Trainers (and the professions you have seen at a trainer or in a crafting window) are shared by all your characters.

Vendors you open in WoW Forever's new zones (Mount Hyjal, Riverglades, Zephras Isle, Darkspear Islands, Shen'dralas) are the way those zones get covered.

## Limitations

- **Forever-only vendors are unknown until you open them.** The shipped list is Vanilla data. Forever's new zones have no shipped vendors, and vendors in zones Forever reshaped may be slightly off.
- **Ammo buying fills only quivers and ammo pouches** that match your weapon, never ordinary bags, and ignores the stack in your ammo slot. "Best" ranks by the level an item requires, since the game does not report ammo damage.
- **Ammo is counted for the ammo you have equipped** (bags included). If the equipped ammo is the wrong kind for your weapon, or none is equipped, the count is 0. Thrown weapons and wands are not monitored.
- **Trainers are learned, not shipped.** Until you have opened a trainer for a profession, the addon cannot send you to one; it says so once per profession per session in chat. It only watches professions it has seen at a trainer or in a crafting window.
- **The last skill tier is taken to end at 300.** A profession whose limit is already 300 is never asked about. Whether WoW Forever has tiers above 300 is not verified. The trainer's level requirement is not checked, so a character that is too low may be sent to a trainer who cannot teach the next tier yet.
- **Distance is a straight line**, not a walking route, and only vendors on your current continent are considered.
- **"Your map" means the exact map you are standing in.** A city is its own map, separate from the zone around it, so in a city "your map" is that city.
- **Vendors of the other faction are skipped.** Neutral vendors count for everyone.
- Nothing is shown in places the game gives no map position, such as dungeons. The addon waits and retries.
- Professions are matched by the name the game shows, so after changing the game language, trainers are learned again.
- The addon's own text is English. Other languages can be added; see [docs/localization.md](docs/localization.md).
- Written and tested against fake game APIs. See the status of in-game checks in `docs/test-plan.md`.

## Problems?

Type `/cvn debug on`, do the thing that went wrong, then type `/cvn log`. A window opens with a report: select all (Ctrl+A), copy (Ctrl+C), and send it with a short description and your client (Classic Era or Forever). `/cvn debug off` stops recording. The report holds the game build, your settings and what the addon saw and decided; it holds no character name.

## For developers

See [CONTRIBUTING.md](CONTRIBUTING.md). In short:

```
make test     # Lua tests (luajit tests/run.lua [pattern]) and Python tests
make check    # TOC, version and changelog checks, the same ones the release workflow runs
```

The vendor list is generated, not edited by hand (`python3 tools/fetch_data.py`, then `python3 tools/build_vendors.py`); see [docs/publishing.md](docs/publishing.md). To use a different data source, add a function that returns normalized records (see `pfquest_records` in `tools/build_vendors.py`) and pass them to `render`.

## License and data

MIT, see [LICENSE](LICENSE). The vendor list is generated from the [pfQuest](https://github.com/shagu/pfQuest) database (MIT) and wago.tools map data. See [THIRD_PARTY.md](THIRD_PARTY.md).
