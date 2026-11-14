# Closest Vendor

Closest Vendor is a World of Warcraft addon for WoW Forever and Classic Era.
It shows you the closest vendor, trainer or auctioneer when you need one.
It reacts when your gear needs repair, your bags are nearly full, or your ammo, reagents, food, water or skills are low.

## Quick start

1. Copy the `ClosestVendor` folder into your AddOns folder (see [Install](#install)).
2. Type `/cvn` in chat to see your current settings.
3. Type `/cvn config` to open the settings page.

## What it does

The addon has a warning for each of these conditions.
When a warning fires, the addon shows the closest vendor that fits.

- **Bags:** free bag slots are at or below the threshold (default **2**). The addon shows the closest vendor you can sell to.
- **Durability:** an equipped item is below the threshold (default **20%**). The addon shows the closest vendor that can repair.
- **Ammo:** equipped ammo is at or below the threshold (default **200**), and you use a bow, crossbow or gun. The addon shows the closest vendor that sells that ammo (arrows or bullets).
- **Reagents:** a class reagent is at or below the threshold (default **5**). The addon shows the closest vendor that sells it.
  - Mage: Arcane Powder, Rune of Teleportation, Rune of Portals.
  - Rogue: Flash Powder.
  - Priest: Holy Candle, Sacred Candle.
  - Paladin: Symbol of Kings, Symbol of Divinity.
  - Shaman: Ankh.
  - Druid: Rebirth seeds, Wild Berries, Wild Thornroot.
  - The addon watches a reagent only after you know a spell that uses it.
  - You can turn off each reagent on its own.
- **Food:** the food in your bags is at or below the threshold (default **5**). All classes. The addon counts every food item: bought, cooked, looted or conjured. The addon shows the closest vendor that sells food.
- **Water:** the drinks in your bags are at or below the threshold (default **5**). Only classes that use mana: Mage, Priest, Paladin, Shaman, Druid, Warlock and Hunter. Warriors and rogues never see it. The addon shows the closest vendor that sells drink.
- **Pet food:** the food your pet eats is at or below the threshold (default **5**). Hunters only, and only while a pet is out.
  - The addon reads the pet's diet from the game: Meat, Fish, Bread, Cheese, Fruit or Fungus.
  - It counts the items that the pet eats.
  - With no pet out, the addon watches nothing.
- **Reminders:** some classes can make their own supplies.
  - A mage who knows Conjure Food or Conjure Water gets a reminder in chat. The addon does not send that mage to a vendor. A mage who does not know the spell goes to a vendor like other classes.
  - A warlock who knows Create Healthstone and has no healthstone gets a reminder to make one.
  - The reminder shows once, until the cause is gone. It also shows on screen if the on-screen notice is on.
  - The reminder waits while you are in combat or in an instance.
  - A reminder plays a sound. The default is the whisper ping. You can pick another sound or none (see Supplies settings).
- **Professions:** a profession is within the threshold (default **10**) points of its current skill limit. The addon shows the closest trainer for that profession that you opened before. It asks on every skill-up and every craft.

If more than one warning is active, the addon asks one question at a time.
The order is: repair, ammo, reagent, food, water, pet food, sell, trainer.
A repair trip or an ammo trip also covers selling.
A food, water or pet food trip does not cover selling.
If no known vendor sells what you need, the addon prints one chat line and shows no question.

### Buying

- **Ammo buying:** at any merchant, with a bow, crossbow or gun equipped, the addon buys ammo to fill your quiver or ammo pouch.
  - It does not ask by default.
  - You set the grade for arrows and bullets separately: the same as your equipped ammo, the best your level allows, or the cheapest.
  - It buys only what you can afford.
  - It tells you in chat what it bought.
- **Reagent buying:** at any merchant that sells your class reagents, the addon can stock you up to a set amount of each (default **20**).
  - It counts what is already in your bags.
  - It is off by default.
  - It asks first and shows the reagents, the counts and the price. You can turn the question off.
  - It buys only what you can afford and what fits in your bags.
  - It tells you in chat what it bought.

### The question and the waypoint

When a warning fires, the addon **asks first** (Yes / No).
If you choose Yes, the addon shows the vendor with the first of these methods that is available:

1. **TomTom** (WoW Forever and Classic Era)
2. **WaypointUI** (WoW Forever)
3. The built-in map waypoint (WoW Forever)
4. A chat message with the vendor name, zone and coordinates (Classic Era without TomTom)

Classic Era has no built-in waypoint API.
On Classic Era, you need TomTom to get an arrow.

### When the closest vendor is on another map

This applies when a vendor on your own map is farther away than the closest vendor.
The question then lists both vendors with their zone and distance.
The question has three buttons: the vendor on your map, the closest vendor, and Cancel.

- Your preference decides the first button. The default is the vendor on your map.
- To skip the question, type `/cvn choice auto`. The addon then sets the waypoint at once with the same preference.
- In auto mode, the addon prints one chat line. The line names the target with its zone and distance. It also names the other choice, if there was one.
- In auto mode, the addon also shows the same text on screen for about five seconds. This text is silent, because the map pin already makes a sound. A reminder sets no pin, so it plays its own sound.
- To turn off the on-screen text, type `/cvn notice off`.
- The same rules apply to trainers.

## Status window

The status window is a small window that you can move.
It lists what the addon tracks, one row for each item.

- The rows are: ammo (arrows or bullets, with a ranged weapon), each class reagent, food, water (mana classes), pet food (a hunter with a pet out), bag space, durability, and each profession close to its limit.
- A row turns red when that item is low. It uses the same threshold as its warning.
- The window shows only when at least one row qualifies.
- The window never shows empty.
- If the game cannot read a value, the addon hides that row. It does not show 0.

### Visibility per group

- The rows come in six groups: Ammo, Reagents, Supplies, Bag space, Durability and Professions.
- Each group is set to **Only when low** (the default), **Always** or **Never**.
- One setting covers the whole group. Every profession row follows Professions. Every reagent row follows Reagents. The food, water and pet food rows follow Supplies.
- Set it on the Status window settings page.
- Or type `/cvn hud row <group> low/always/never`.

### Click a row

- Click a row to pin the closest vendor for that item at once.
- The addon does not ask a question. It ignores your choice mode (ask or auto).
- It works in combat.
- A chat line ("Navigating to ... to buy ...") and an on-screen notice say why.
- A profession row works only while the profession is within its threshold.
- For a profession row, the addon must already know a trainer.

### Move and lock

- Drag the title to move the window.
- Or hold Shift and drag anywhere on the window.
- **Lock window position** stops all dragging, Shift-drag included. It is the first control on the Status window page. Or type `/cvn hud lock`.
- The addon saves the position.
- Type `/cvn hud reset` to put the window back at its default position.
- The cog button on the window opens the Closest Vendor settings page.

### Display-only rows

- These rows are part of the Reagents group.
- They are never low. They show only while Reagents is set to Always.
- You cannot route to them. A click does nothing.
- The rows are: Soul Shards (Warlock), Blinding Powder (Rogue), Conjured Food and Conjured Water (Mage).

### Size and opacity

- Window scale is 50 to 200 percent. Or type `/cvn hud scale`.
- Background opacity is 0-100 percent. The default is 80. Or type `/cvn hud opacity`.
- Text and icon opacity is 20-100 percent. The default is 100. Or type `/cvn hud textopacity`.
- All three are on the Status window page.
- At background opacity 0, the addon draws no background. You see only the text and icons.

### Background color

- The default color is pure black.
- If the game has its color picker, the Status window page shows a swatch of the current color. Click the swatch to pick any color.
- Type `/cvn hud color` with no color to open the color picker directly. This works wherever the game has a picker, even if the swatch is not on the page.
- Type `/cvn hud color #rrggbb` to set a color. This works everywhere. It is the only way where there is no picker.
- Type `/cvn hud color black` (or `reset`) to go back to black.

### OLED-friendly

- The window has no border.
- The window has no bright fixed fills.
- Only the text color marks a low row.
- You can dim the text and icons.
- Nothing static needs to stay bright on screen.

## Dungeons, raids and battlegrounds

Inside an instance, the addon waits and does not ask.
When you leave, the question comes back.
This way, a full-bags question in a battleground is not lost.

- The addon remembers your last position outside.
- The addon learns your hearthstone point from your bind location.
- If you click a row inside an instance, the addon searches near an anchor.
- In a battleground, the anchor is your last position outside.
- In a dungeon or raid, you choose the anchor:
  - `/cvn anchor hearth` is the default. If the hearthstone point is not known yet, the addon uses the last position.
  - `/cvn anchor last` uses your last position outside.
- A pin made this way says so in chat.

## Auction house

- This feature is off by default. Type `/cvn ah on` to turn it on.
- When it is on, click a row for an item that you can trade.
- If an auctioneer is closer than a vendor, the addon goes to the auctioneer.
- The addon ignores this feature inside instances.
- The addon ships 28 auctioneers.
- The addon learns more each time you open an auction house.

## Install

Copy the `ClosestVendor` folder into your AddOns folder:

- WoW Forever: `World of Warcraft/<forever folder>/Interface/AddOns/`
- Classic Era: `World of Warcraft/_classic_era_/Interface/AddOns/`

The addon has one TOC file for each game:

- `ClosestVendor_Vanilla.toc` for Classic Era.
- `ClosestVendor_Camelot.toc` for WoW Forever.

## Settings page

To open it, go to Options, AddOns, **Closest Vendor**.
This is the main page. It has four subcategories.
On a client without subcategories, everything is on the one page under section headings.

The settings page changes the same settings as the commands below.
Type `/cvn config` to open the main page.

### Closest Vendor (main page)

- **Warnings:** a checkbox and a slider for each warning (bags, durability, ammo and reagents, professions).
- **Warnings:** a checkbox for the on-screen notice.
- The ammo checkbox is the one switch for ammo, reagents, food, water and pet food. The label stays "Ammo and reagents". When it is off, the addon does not watch any of them.
- **Navigation:** a dropdown for when the closest target is on another map. You choose to ask which one, or to navigate without asking.
- **Navigation:** a dropdown to prefer the target on your map or the closest target.
- **Navigation:** a dropdown for the search anchor inside instances.
- **Navigation:** a checkbox for the auction house.

### Reagents

- A slider for the reagent threshold.
- A checkbox for each reagent of your class. All are on.
- Below them are three controls for reagent buying:
  - **Buy reagents** (off by default).
  - **Ask before buying reagents** (on by default).
  - A slider for how many of each reagent to carry (0-100, default 20). The value 0 buys none.
- For a class without vendor reagents, these three controls are greyed out. A tooltip says why.

### Supplies

- A checkbox and a slider (1-40, default 5) for each of food, water and pet food.
- A row shows only if your class can use it. A warrior sees no water. Only a hunter sees pet food.
- A warlock also gets a **Healthstone reminder** checkbox.
- Every class gets a **Reminder sound** dropdown (only mages and warlocks are reminded): Whisper ping (default), Minimap ping, Group invite, Ready check or None. Choosing one plays it.
- All are on by default.
- The main switch "Ammo and reagents" also turns these off.

### Ammo

- A checkbox to buy ammo.
- A checkbox to ask before buying.
- A dropdown for arrows.
- A dropdown for bullets.

### Status window

- **Lock window position** is the first control.
- Sliders for scale, background opacity, and text and icon opacity.
- The background color. It is a swatch that opens the game's color picker, where the game has one.
- An Only when low / Always / Never dropdown for each group, in window order: Ammo, Reagents, Supplies, Bag space, Durability, Professions.
- A group that does not apply to your class is still listed. This is Ammo, or Reagents for a class with no reagents.
- The addon greys out that group. A tooltip says why.

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
/cvn food 8
/cvn food off
/cvn food on
/cvn water 8
/cvn water off
/cvn water on
/cvn petfood 8
/cvn petfood off
/cvn petfood on
/cvn test sell
/cvn test repair
/cvn test arrows
/cvn test bullets
/cvn test reagent
/cvn test food
/cvn test water
/cvn test petfood
/cvn test remind
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

### General

- `/cvn` shows the current settings.
- `/cvn config` opens the settings page.
- `/closestvendor` works the same as `/cvn`.
- Settings are saved per character. The vendors, trainers and auctioneers the addon learns are shared by the account. A character you have not used with the addon before starts from the settings you had before this was per character.

### Thresholds

- `/cvn bags <slots>` sets the free-slot threshold (0 to 200).
- `/cvn bags on` and `/cvn bags off` turn the bag warning on or off.
- `/cvn dur <percent>` sets the durability threshold (1 to 100).
- `/cvn dur on` and `/cvn dur off` turn the durability warning on or off.
- `/cvn ammo <count>` sets the ammo threshold (0 to 2000).
- `/cvn ammo on` and `/cvn ammo off` turn the ammo and reagent warnings on or off.
- `/cvn trade <points>` sets the profession threshold (0 to 300).
- `/cvn trade on` and `/cvn trade off` turn the profession warning on or off.
- `/cvn reagent <count>` sets the threshold for all class reagents (1 to 40).
- `/cvn reagents` lists the reagents of your class and shows if each is on.
- `/cvn reagent off <name>` turns off one reagent. Case does not matter.
- `/cvn reagent on <name>` turns on one reagent. Case does not matter.
- `/cvn food <count>` sets the food threshold (1 to 40).
- `/cvn water <count>` sets the water threshold (1 to 40).
- `/cvn petfood <count>` sets the pet food threshold (1 to 40).
- `/cvn food on`, `/cvn water on` and `/cvn petfood on` turn that warning on. Use `off` to turn it off.
- The healthstone reminder has a switch on the Supplies page only.
- `/cvn sound` shows the reminder sound. `/cvn sound <name>` picks whisper, ping, invite, ready or none, and plays it.

### Navigation

- `/cvn choice ask` is the default. When the closest target is on another map, it lists both targets and waits for your pick.
- `/cvn choice auto` sets the waypoint at once, with no question.
- `/cvn prefer map` is the default. It prefers the closest target on your current map.
- `/cvn prefer distance` prefers the closest target by distance.
- The `prefer` setting decides the first button. It also decides what `auto` picks.
- `/cvn notice on` is the default. It shows the on-screen text when the addon chooses a target without asking.
- `/cvn notice off` hides the on-screen text.
- The chat line is always printed.
- `/cvn anchor hearth` is the default. In a dungeon or raid, a row click searches near your hearthstone point.
- `/cvn anchor last` makes a row click search near your last position outside.
- `/cvn ah on` lets a row click go to the auction house when it is closer than a vendor.
- `/cvn ah off` turns this off. It is off by default.

### Buying

- `/cvn buy on` and `/cvn buy off` turn ammo buying on or off.
- `/cvn buy ask` shows the count and price, and waits for a Yes.
- `/cvn buy auto` is the default. It buys at once.
- `/cvn reagentbuy on` and `/cvn reagentbuy off` turn reagent buying on or off. It is off by default.
- `/cvn reagentbuy ask` is the default. It shows the reagents, counts and price, and waits for a Yes.
- `/cvn reagentbuy auto` buys at once.
- `/cvn reagentbuy <count>` sets how many of each class reagent to carry (0-100, default 20). The value 0 buys none.
- If your class has no vendor reagents, the addon tells you.
- `/cvn arrows <mode>` and `/cvn bullets <mode>` choose which ammo to buy.
- The modes are `equipped` (the default), `best` and `cheapest`.

### Status window

- `/cvn hud lock` blocks moving the status window.
- `/cvn hud unlock` allows moving it.
- `/cvn hud reset` puts it back at its default position.
- `/cvn hud scale <percent>` sets its size (50-200).
- `/cvn hud opacity <percent>` sets how solid its background is (0-100). The value 0 draws no background.
- `/cvn hud textopacity <percent>` sets how solid its text and icons are (20-100).
- `/cvn hud color` opens the color picker.
- `/cvn hud color <#rrggbb>` sets the background color.
- `/cvn hud color black` or `/cvn hud color reset` goes back to black.
- `/cvn hud row <group> low/always/never` sets when a group of rows shows.
- The group is `ammo`, `reagents`, `professions`, `bags` or `durability`.
- Example: `/cvn hud row professions always`.
- `/cvn` lists the groups you changed.

### Test and debug

- `/cvn test sell`, `/cvn test repair`, `/cvn test arrows`, `/cvn test bullets` and `/cvn test reagent` ask the question now for that kind of vendor.
- `/cvn test food`, `/cvn test water` and `/cvn test petfood` do the same for food, water and pet food.
  - A rogue or warrior who tests water gets "Your class does not use water."
  - Without a pet, the pet food test says "There is no pet to feed."
- `/cvn test remind` shows the conjure reminder for a mage, or the healthstone reminder for a warlock, and plays the reminder sound. It always works: any other class gets a plain test line and the sound.
- They ignore the state of your bags, gear and ammo.
- Yes sets the pin.
- Opening any vendor window clears the pin.
- `/cvn debug on` turns on the debug log.
- `/cvn debug off` turns it off.
- `/cvn log` shows a report that you can copy.
- `/cvn log clear` empties the log.

## How it finds vendors

The addon ships a list of about 900 vendors.
It learns more as you play.

- Each time you open a vendor window, the addon records that vendor.
- It records the position, whether the vendor repairs, and which ammo, reagents, food and drink the vendor sells.
- A learned vendor replaces a shipped vendor with the same NPC id.
- The addon saves learned vendors between sessions.

Trainers work the same way, but the addon ships no trainers.

- When you open a profession trainer window, the addon records where the trainer is.
- It also records which professions the trainer teaches.
- All your characters share the trainers.
- All your characters also share the professions you saw at a trainer or in a crafting window.

The vendors that you open in the new zones of WoW Forever cover those zones.
The new zones are Mount Hyjal, Riverglades, Zephras Isle, Darkspear Islands and Shen'dralas.

## Limitations

### Vendors and trainers

- Vendors that exist only in WoW Forever are unknown until you open them.
- The shipped list is Vanilla data.
- The new zones of WoW Forever have no shipped vendors.
- Vendors in zones that WoW Forever reshaped can be slightly wrong.
- The addon ships no trainers.
- Until you open a trainer for a profession, the addon cannot send you to one.
- The addon says this once for each profession in each session, in chat.
- The addon watches only professions that it saw at a trainer or in a crafting window.
- Professions are matched by the name that the game shows.
- After you change the game language, the addon learns trainers again.
- The addon skips vendors of the other faction.
- Neutral vendors count for everyone.

### Ammo

- The addon counts the ammo that you have equipped. This includes ammo in your bags.
- If the equipped ammo is the wrong kind for your weapon, the count is 0.
- If no ammo is equipped, the count is 0.
- The addon does not monitor thrown weapons or wands.
- Ammo buying fills only quivers and ammo pouches that match your weapon.
- Ammo buying never fills ordinary bags.
- Ammo buying ignores the stack in your ammo slot.
- "Best" ranks ammo by the level that an item requires. The game does not report ammo damage.

### Reagents

- The addon counts reagents in your bags, not in the bank.
- The addon counts a reagent only for spells that you know.
- For ranked spells, the addon watches the reagent of your highest known rank. Example: the seed for your best Rebirth.
- Warlocks, hunters and warriors have no reagents.
- The addon does not cover rogue poisons.
- Soul Shards, Blinding Powder, and conjured food and water are display-only rows.
  - They show only while the Reagents group is set to Always.
  - The addon counts them.
  - The addon never routes to them, because no vendor sells them.
- The addon asks and shows the way. It buys reagents only when you turn on reagent buying.

### Reagent buying

- Reagent buying covers the reagents that the warning watches.
- These are reagents of your class, for a spell that you know, and that are turned on.
- If you turn off a reagent on the Reagents page, the addon does not buy it.
- The addon counts them the same way, in bags only.
- The addon tops up each reagent to the set amount. It never goes above the amount.
- If a merchant sells an item in batches, the addon buys only whole batches that stay within the amount.
- Reagents go in ordinary bags only. They do not go in quivers, soul bags or profession bags.
- If gold or bag room runs out, the addon buys what it can. It follows the reagent table order. It says so in chat.
- The addon takes into account the money left after an ammo purchase at the same merchant.

### Food, water and pet food

- The addon ships vendor data for food, water and pet diets. It learns more when you open a vendor window.
- Some pets eat only meat or fish. Few vendors sell those. If no known vendor sells it, the addon prints one chat line and shows no question.
- The addon finds your pet's diet from its family, not from text. It works in every language. A pet family the addon does not know is not watched.
- The addon counts items in your bags, not in the bank.
- The addon does not buy food, water or pet food for you.
- The status window shows Food, Water and Pet food rows in its Supplies group. They are separate from the Conjured Food and Conjured Water rows.

### Skill levels

- The addon takes the last skill tier to end at 300.
- The addon never asks about a profession whose limit is already 300.
- The addon does not ask about a profession while you are too low a level to learn its next tier from a trainer (level 10 for 75, 20 for 150, 35 for 225).
- It is not verified if WoW Forever has tiers above 300.
- The addon does not check the level requirement of the trainer.
- A character that is too low can be sent to a trainer who cannot teach the next tier yet.

### Distance and maps

- Distance is a straight line, not a walking route.
- The addon considers only vendors on your current continent.
- "Your map" means the exact map that you stand in.
- A city is its own map, separate from the zone around it. In a city, "your map" is that city.
- Auction house routing also uses straight-line distance to an auctioneer.
- It uses auctioneers that are shipped or learned.
- It does not check prices.
- It does not check if you can sell an item there.

### Instances

- The addon asks nothing in dungeons, raids and battlegrounds. It waits until you leave.
- A status window click in an instance searches from an anchor (see above).
- The vendor that the addon shows can be far from where you stand.
- TomTom can refuse a waypoint that you set from inside an instance. Chat then says so.
- If the game gives no map position at all, the addon waits and tries again.

### Other

- The status window can lag a moment behind changes to bags, ammo and skills.
- A saved window position can end up off screen after a UI scale change. Type `/cvn hud reset` to recover it.
- The text of the addon is English only. You can add other languages. See [docs/localization.md](docs/localization.md).
- The addon was written and tested against fake game APIs. See the status of in-game checks in `docs/test-plan.md`.

## Problems?

1. Type `/cvn debug on`.
2. Do the thing that went wrong.
3. Type `/cvn log`. A window opens with a report.
4. Select all (Ctrl+A) and copy (Ctrl+C).
5. Send the report with a short description and your client (Classic Era or WoW Forever).
6. Type `/cvn debug off` to stop recording.

The report holds:

- The game build.
- Your settings. This includes whether the game's color picker and settings button exist, and why the background color swatch is missing if it is.
- What the addon saw and decided.

The report holds no character name.

## For developers

See [CONTRIBUTING.md](CONTRIBUTING.md). In short:

```
make test     # Lua tests (luajit tests/run.lua [pattern]) and Python tests
make check    # TOC, version and changelog checks, the same ones the release workflow runs
```

The vendor list is generated. Do not edit it by hand.
Run `python3 tools/fetch_data.py`, then `python3 tools/build_vendors.py`.
See [docs/publishing.md](docs/publishing.md).

To use a different data source, add a function that returns normalized records.
See `pfquest_records` in `tools/build_vendors.py`.
Pass the records to `render`.

## License and data

MIT, see [LICENSE](LICENSE).
The vendor list comes from the [pfQuest](https://github.com/shagu/pfQuest) database (MIT) and wago.tools map data.
See [THIRD_PARTY.md](THIRD_PARTY.md).
