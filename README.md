# Closest Vendor

Closest Vendor is a World of Warcraft addon for WoW Forever and Classic Era.
It shows you the closest vendor, trainer or auctioneer when you need one.
It reacts when your gear needs repair, your bags are nearly full, or your ammo, reagents, food, water or skills are low.

## Quick start

1. Copy the `ClosestVendor` folder into your AddOns folder (see [Install](#install)).
2. Type `/cvn` in chat to open settings; `/cvn help` displays addon info and commands.
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
  - The reminder shows once, until the cause is gone. It is a notification: it shows as a Toast or Warning, with the notification sound, if the on-screen notice is on.
  - The reminder waits while you are in combat or in an instance.
- **Professions:** a profession is within the threshold (default **10**) points of its current skill limit. The addon shows the closest trainer for that profession that you opened before. It asks on every skill-up and every craft. At 225, Artisan comes next, and only a few trainers teach it. With the optional NorgannonDB addon installed, the addon knows which trainers teach which tier and routes every tier, Artisan included, only to a trainer who teaches it. Without NorgannonDB, it uses the closest trainer for Journeyman and Expert and does not route for Artisan (a click on that row near the limit says so in chat).

If more than one warning is active, the addon asks one question at a time.
The order is: repair, ammo, reagent, food, water, pet food, sell, trainer.
A repair trip or an ammo trip also covers selling.
A food, water or pet food trip does not cover selling.
If you answer No, that warning is not asked again until it clears, and the next warning is asked. A No to repair or ammo can still be followed by the sell question.
If no known vendor sells what you need, the addon prints one chat line and shows no question, and moves on to the next warning.
Questions wait while you are dead or a ghost, as in combat, and come once you are alive.
A question still open when you change zone or enter an instance is withdrawn, because its vendor was chosen from where you were. It is asked again from your new place, or once you leave the instance. Combat leaves an open question alone: you can still answer and route.

### Buying

A purchase question closes when you close the merchant window. Nothing is bought if the merchant changed before you answered.

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

To use another method first, for example the built-in waypoint while TomTom is installed, choose it with `/cvn nav` or on the settings page.
If your choice is not available, the addon uses the order above.

### When the closest vendor is on another map

This applies when a vendor on your own map is farther away than the closest vendor.
The question then lists both vendors with their zone and distance.
The question has three buttons: the vendor on your map, the closest vendor, and Cancel.

- Your preference decides the first button. The default is the vendor on your map.
- To skip the question, type `/cvn choice auto`. The addon then sets the waypoint at once with the same preference.
- In auto mode, the addon prints one chat line. The line names the target with its zone and distance. It also names the other choice, if there was one.
- In auto mode, the addon also shows the same text as a notification (see Appearance).
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
- Set it on the Appearance > Status window section.
- Or type `/cvn hud row <group> low/always/never`.

### Click a row

- Click a row to pin the closest vendor for that item at once.
- The addon does not ask a question. It ignores your choice mode (ask or auto).
- It works in combat.
- A chat line ("Navigating to ... to buy ...") and an on-screen notice say why.
- A profession row works only while the profession is within its threshold.
- For a profession row, the addon must already know a trainer.
- A trainer waypoint ends when the profession is no longer within its threshold, or when you unlearn it.

### Other sellers

- A row with more than one known seller has a small arrow at its right end.
- Hover the arrow to see what it does, for example "Other repair vendors".
- Click the arrow to see a list: the seller a row click would choose (marked), then up to three others, nearest first.
- Each entry shows the name, the zone and the distance. Pick one to set the waypoint there.
- Press Escape or click elsewhere to close the list without a change.
- With auction house routing on, the list can include the closest auctioneer.
- If the seller no longer fits when you pick it (for example, you equipped a gun after opening the arrow list), no waypoint is set. Chat says "The seller list changed. Open it again to choose."

### Move and lock

- Drag the title to move the window.
- Or hold Shift and drag anywhere on the window.
- **Lock position** stops all dragging, Shift-drag included. It is the first control on the Appearance > Status window section. Or type `/cvn hud lock`.
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
- All three are on the Appearance > Status window section.
- At background opacity 0, the addon draws no background. You see only the text and icons.

### Background color

- The default color is pure black.
- If the game has its color picker, the Appearance > Status window section offers Background color, which opens the guarded game color picker. Cancelling restores the original color.
- Type `/cvn hud color` with no color to open the color picker directly. This works wherever the game has a picker, even if settings cannot open.
- Type `/cvn hud color #rrggbb` to set a color. This works everywhere. It is the only way where there is no picker.
- Type `/cvn hud color black` (or `reset`) to go back to black.

### OLED-friendly

- The window has no border.
- The window has no bright fixed fills.
- Low rows use red text, a red warning symbol and a visible Low label.
- You can dim the text and icons.
- Nothing static needs to stay bright on screen.

## Find a supply

Plan a trip before anything runs low. Type `/cvn find` with an item link or part of an item name, for example `/cvn find Moonberry Juice`. The same search is the **Find supplies** box at the end of Home.

- It finds food, drink, pet food and your class reagents. Typed names match the game's own item names, in any letter case. A pasted item link always works.
- No item matches: chat says so. More than 8 items match: chat asks you to type more of the name. Two to eight items open a menu of icon and name at the mouse pointer; one item goes straight to its sellers.
- The seller list is the same as the status window's: the closest eligible seller (marked), then up to three others, each with name, zone and distance. It follows the same faction, reputation, instance and auction house rules as a row click.
- A known item with no known seller gets its own chat line, different from "no match".
- Pick a seller to set the waypoint there. Looking at a list changes nothing. Press Escape to close it.
- The addon knows vendors by category for food, drink and pet food, not item by item. For those items chat says the sellers sell that category in general and may not stock the item. Class reagents are exact.

## Dungeons, raids and battlegrounds

Inside an instance, the addon waits and does not ask.
When you leave, the question comes back.
This way, a full-bags question in a battleground is not lost.

- The addon remembers your last position outside.
- The addon learns your hearthstone point when you set it at an innkeeper. If you set it before installing the addon, or the addon misses it, the point is known by name only until you set it again; meanwhile the addon uses your last position outside.
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

Type `/cvn settings` (also `/cvn config` or `/cvn options`) or click the HUD cog to open Home. Settings use the bundled AceConfig tree; no other addon is needed. Where supported, Options > AddOns also lists Closest Vendor: the entry opens Home, with Restock, Navigation, Appearance, Advanced and About under it. The standalone tree remains available without native Settings registration.

Pages appear in this order: **Home, Restock (Ammo, Reagents, Supplies), Navigation, Appearance (Notifications, Status window, Sound), Advanced, About**. The window title is **Closest Vendor**; Advanced explains where settings are saved. The settings window starts at 600×460, matching KeepThat, and can be resized. Pages use readable rows, section headings and spacing, with compact dropdowns, sliders and buttons. Each page and Appearance tab explains its purpose; section notes explain the decisions and their consequences before the controls, including warning counts versus buying targets and purchases without confirmation. Commands and controls edit the same saved settings immediately. Existing settings and learned places retain their scopes.

### Home

Home has every switch that decides whether the addon acts:

- **What to watch:** bag, durability and profession warning switches and thresholds, plus the Ammo, Reagents and Supplies switches.
- **How to act:** **Destination on another map** (Ask which one / Navigate without asking) and **Preferred target**.
- **Where to show it:** **On-screen notice**.
- **Find supplies:** a box at the end of Home. Type part of an item name or paste an item link, then press Okay. It runs the same search as `/cvn find` and saves nothing.

Disabled controls retain their values; their descriptions explain which switch enables them.

### Restock

Restock holds **Ammo**, **Reagents** and **Supplies**: the counts that warn you, which items to watch, and merchant buying. Each warning is turned on or off on Home.

### Navigation

Choose the waypoint provider, instance anchor and auction routing here.

### Appearance

Appearance has three tabs: **Notifications**, **Status window** and **Sound**.

Every route message, class reminder and test message is a notification. Notifications all look and sound the same:

- **On-screen notice** (on Home) turns notifications on or off. Off keeps only the chat line, with no sound.
- **Style** is **Toast** (default for fresh installs) or **Warning** (the game's large centered text). Existing users without a saved style keep Warning.
- **Preview** shows a sample in your style, with your sound, without changing anything.
- With Toast: **Background opacity, Text and icon opacity, Scale, Move, Reset position**. A new toast replaces the old one and lasts five seconds. Warning has no appearance or position settings, so these are hidden.

The Status window tab has **Lock position, Background opacity, Text and icon opacity, Scale, Preview, Move, Reset position, Background color** and the row visibility choices.

Only one notification is on screen at a time: the newest replaces the old one, live or sample, Toast or Warning. A status window click, a new `/cvn demo` or a `/cvn preview` also ends any demo or preview that is running; a stopped demo puts your previous waypoint back first. A click on a demo row routes for real.

Move shows a placeholder with **Done** and **Cancel**: only Done saves; Cancel or Escape restores the starting position. Unlock the status window before moving it. Only the status window has **Lock position**. Reset position changes only the anchor. Normal unlocked HUD title/Shift-drag still saves immediately, and row clicks retain their navigation behavior.


### Sound

The Sound tab has one choice, **Notification sound**. It plays with every notification: Whisper ping (default), Minimap ping, Group invite, Ready check or None. If another addon shares sounds through LibSharedMedia (a SharedMedia pack, DBM, BigWigs or WeakAuras), they follow, marked "(sound pack)". Closest Vendor does not ship that library. Choosing one plays it. `/cvn sound <name>` sets the same choice. No sound plays while On-screen notice is off, and questions play no notification sound.

### Advanced and About

Advanced explains character settings and account-wide learned places (at load, the addon removes old account-level copies of the hearthstone point, last outside position, professions and log that settings per character replaced), with Record debug information, Show debug report and confirmed diagnostic clearing. The report uses the same standard AceGUI window and scrollable, read-only text box as KeepThat, with copy instructions and a normal close button. About shows the addon name, the installed version and a one-sentence purpose. `/cvn help` lists the commands.

### Ammo

- A slider for the ammo threshold. The Ammo checkbox is in Warnings on the main page.
- A checkbox to buy ammo.
- A checkbox to ask before buying.
- A dropdown for arrows.
- A dropdown for bullets.

### Reagents

- A slider for the reagent threshold. The Reagents checkbox is in Warnings on the main page.
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
- All are on by default.
- Each item has its own switch, and the **Supplies** checkbox on the main page turns all of them off. The Ammo and Reagents switches do not.

### Status window in Appearance

- **Lock position** is the first control.
- Sliders for scale, background opacity, and text and icon opacity.
- The background color. It is a button that opens the game's color picker, where the game has one.
- An Only when low / Always / Never dropdown for each group, in window order: Ammo, Reagents, Supplies, Bag space, Durability, Professions.
- A group that does not apply to your class is still listed. This is Ammo, or Reagents for a class with no reagents.
- The addon greys out that group. A tooltip says why.

## Commands

```
/cvn settings appearance
/cvn status
/cvn help appearance
/cvn get bags.threshold
/cvn set appearance.notification-style toast
/cvn demo
/cvn preview hud
/cvn find Moonberry Juice
/cvn
/cvn config
/cvn bags 4
/cvn bags off
/cvn bags on
/cvn dur 30
/cvn dur off
/cvn dur on
/cvn supplies off
/cvn supplies on
/cvn ammo 300
/cvn ammo off
/cvn ammo on
/cvn reagents off
/cvn reagents on
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
/cvn nav native
/cvn anchor hearth
/cvn anchor last
/cvn ah on
/cvn ah off
```

### Presentation commands

- `/cvn settings [page]` accepts home, restock, ammo, reagents, supplies, navigation, appearance, sound, advanced, about, notifications and status-window; the last two open that tab of Appearance. Page names are case insensitive.
- `/cvn status` reports effective settings, scope and availability guidance; bare `/cvn` opens Home.
- `/cvn help appearance` lists public keys and previews; `help diagnostics` explains reports. Domain topics: bags, ammo, reagents, supplies, navigation, hud.
- `/cvn get <key>` is read-only. `/cvn set <key> <value>` validates the whole input and gives one acknowledgement. Missing, unknown, fractional, out-of-range and surplus input never changes a setting.
- `/cvn demo` runs a tour of real outcomes, one every five seconds: a route set without asking (notification), a question (confirmation), food, water or pet food for your class, arrows, a status-window row click (your class reagent, which can route to an auction house, or repair) and a reminder. Each uses your real vendor data, waypoint and notification style, with your sound, even with On-screen notice off. The status window shows made-up rows meanwhile. At the end your game waypoint comes back: the one you had before, or the one you set during the tour. Settings are never changed, and no warning is marked as handled. Repeating restarts it.
- `/cvn preview notice`, `hud` or `prompt` shows one safe sample for ten seconds. Samples cannot buy or set waypoints. Timers and supported drawing APIs are required.

| Public key | Values | Default | Stored character key |
| --- | --- | --- | --- |
| bags.threshold | whole number 0–200 | 2 | bagThreshold |
| appearance.notification-style | warning / toast | toast | notificationStyle |
| appearance.hud.background-opacity | whole percent 0–100 | 80 | hudAlpha |
| appearance.hud.text-opacity | whole percent 20–100 | 100 | hudTextAlpha |
| appearance.hud.scale | whole percent 50–200 | 100 | hudScale |
| appearance.hud.locked | on / off | off | hudLocked |
| appearance.toast.background-opacity | whole percent 0–100 | 100 | toastAlpha |
| appearance.toast.text-opacity | whole percent 0–100 | 100 | toastTextAlpha |
| appearance.toast.scale | whole percent 50–200 | 100 | toastScale |

These values are per character. Prior saved values override defaults. Commands and UI use the same typed registry and refresh hooks; positions are saved separately in the character's `hud` and `toast` tables. No profile switching is offered.

### General

- `/cvn` opens settings on Home; `/cvn status` shows current values.
- `/cvn config` opens the settings page.
- `/cvn find <item link or name>` shows the nearest known sellers of a food, drink, pet food or class reagent item. Pick one to set the waypoint. With no text it prints how to use it.
- `/closestvendor` works the same as `/cvn`.
- Settings are saved per character. The vendors, trainers and auctioneers the addon learns are shared by the account. A character you have not used with the addon before starts from the settings you had before this was per character.

### Thresholds

- `/cvn bags <slots>` sets the free-slot threshold (0 to 200).
- `/cvn bags on` and `/cvn bags off` turn the bag warning on or off.
- `/cvn dur <percent>` sets the durability threshold (1 to 100).
- `/cvn dur on` and `/cvn dur off` turn the durability warning on or off.
- `/cvn supplies on` and `/cvn supplies off` turn the food, water, pet food and healthstone warnings on or off together.
- `/cvn ammo <count>` sets the ammo threshold (0 to 2000).
- `/cvn ammo on` and `/cvn ammo off` turn the ammo warning on or off.
- `/cvn reagents on` and `/cvn reagents off` turn the reagent warnings on or off.
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
- `/cvn sound` shows the notification sound. `/cvn sound <name>` picks whisper, ping, invite, ready, none or a sound-pack sound by its name (any letter case), and plays it.

### Navigation

- `/cvn nav` shows the waypoint method. `/cvn nav <name>` picks auto, tomtom, waypointui or native. Auto is the default and uses the order in "The question and the waypoint". A method you pick is tried first. If it is not available, the addon uses the usual order.
- `/cvn choice ask` is the default. When the closest target is on another map, it lists both targets and waits for your pick.
- `/cvn choice auto` sets the waypoint at once, with no question.
- `/cvn prefer map` is the default. It prefers the closest target on your current map.
- `/cvn prefer distance` prefers the closest target by distance.
- The `prefer` setting decides the first button. It also decides what `auto` picks.
- `/cvn notice on` is the default. It shows every notification on screen, with the notification sound.
- `/cvn notice off` hides notifications and their sound. Chat lines still print.
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
- `/cvn status` lists the groups you changed.

### Test and debug

The legacy `test` commands are live integration tests: accepting a question can set a real waypoint. Use `preview` for safe visual inspection; `demo` sets real waypoints and puts yours back at the end.

- `/cvn test sell`, `/cvn test repair`, `/cvn test arrows`, `/cvn test bullets` and `/cvn test reagent` ask the question now for that kind of vendor.
- `/cvn test food`, `/cvn test water` and `/cvn test petfood` do the same for food, water and pet food.
  - A rogue or warrior who tests water gets "Your class does not use water."
  - Without a pet, the pet food test says "There is no pet to feed."
- `/cvn test remind` shows the conjure reminder for a mage, or the healthstone reminder for a warlock, as a notification with the notification sound. It always works: any other class gets a plain test notification.
- They ignore the state of your bags, gear and ammo.
- Yes sets the pin.
- Opening any vendor window clears the pin.
- `/cvn reagent on|off <name>` accepts the English name or the name your game shows. `/cvn reagents` prints the game's name once the game has loaded the item. Matching ignores case for A-Z, Latin accented letters and Cyrillic.
- `/cvn debug on` turns on the debug log. It records decisions and failures. Durability and inventory events are not logged one by one: one line, "gear events: N folded into one check", gives the count.
  - A warning that waits names its reason once, for example "trigger held in combat: repair", "trigger held while dead: repair" or "trigger held in an instance: sell". Inside an instance the reason stays "in an instance", also during a fight there. Dead during a fight is "while dead".
  - Each change of the ammo the addon watches is logged once: "ammo watched: arrow", or "ammo not watched: ..." for a thrown weapon, a wand, no ranged weapon or the ammo warning turned off.
  - Each vendor or trainer window logs what the addon learned from it, for example "vendor learned: Name (npc 1234), new" (or "updated", "unchanged"); a class trainer logs "trainer window: nothing learned: not a profession trainer". Targeting an NPC that will not trade with you logs its standing. At login the addon logs what it found of NorgannonDB.
  - A merchant window logs whether it cleared your waypoint or kept a trainer waypoint. Each profession check names the skills near their limit that it does not ask about, and why ("level 20 needed", "the last tier", ...), and why it asked nothing ("a question is open"). A question with two targets logs both, with the preference that put one first.
  - The status window logs what it shows when that changes, for example "status window: shown, rows: bags low, durability" or "status window: hidden". A count change alone logs nothing, and a demo, preview or Move logs nothing.
  - Each setting you change, by command or on the settings page, logs one line, for example "setting changed: bagThreshold 2 -> 5". The settings page logs a moved slider once, a second after you stop.
  - A purchase question logs "ammo buy: asked" (or "reagent buy: asked") once it shows, and "ammo buy: declined" when you click No or press Escape. An ammo purchase cut short by your gold ends with "(all you could afford)". A test command that asks nothing logs why, for example "test command: nothing asked: the class does not use water".
  - Closing a merchant with a purchase question open logs "purchase question closed with the merchant: ammo" (or "reagents"). Each purchase logs what it bought: only the purchases the game took, with a "FAILED:" line for any that did not go through. A merchant window that closes an open vendor question logs "question closed: merchant opened (sell)" (or the question's kind).
- `/cvn debug off` turns it off.
- `/cvn log` shows a report that you can copy.
- `/cvn log clear` asks for confirmation before clearing diagnostic entries only. Cancel keeps everything.

## How it finds vendors

The addon ships a list of about 900 vendors.
It learns more as you play.

- Each time you open a vendor window, the addon records that vendor.
- It records the position, whether the vendor repairs, and which ammo, reagents, food and drink the vendor sells.
- If the game has not loaded every item in the vendor's list yet, the addon keeps what it already knew about that vendor and reads the list again when the items arrive.
- A learned vendor replaces a shipped vendor with the same NPC id.
- The addon saves learned vendors between sessions.

Trainers work the same way, but the addon ships no trainers.

- When you open a profession trainer window, the addon records where the trainer is.
- It also records which professions the trainer teaches.
- All your characters share the trainers.
- Each character keeps its own list of the professions it saw at a trainer or in a crafting window.

The vendors that you open in the new zones of WoW Forever cover those zones.
The new zones are Mount Hyjal, Riverglades, Zephras Isle, Darkspear Islands and Shen'dralas.

### NorgannonDB (optional)

If the NorgannonDB addon is installed, the addon also reads its vendors in the new zones of WoW Forever, and its profession trainers everywhere.

- It is read when you log in, and again if NorgannonDB finishes loading later.
- It adds vendors, with their position, faction, repair and what they sell. It adds nothing in other zones.
- Nothing from NorgannonDB is copied into this addon or saved by it.
- All vendors are one list, and the closest one wins.
- For the same vendor, NorgannonDB's data comes before the shipped list. What you see when you open a vendor comes before both.
- If you open a vendor that is more than 3% of the map away from NorgannonDB's position, your position is used.
- It adds profession trainers whose title tells which tier they teach, with their position and the professions of the recipes they teach, named in your game's language. A trainer you opened keeps its position, and gains the tier.
- `/cvn log` says whether NorgannonDB was found, how many vendors it added and how many trainers with a tier.

## Limitations

### Vendors and trainers

- Vendors that exist only in WoW Forever are unknown until you open them.
- The shipped list is Vanilla data.
- The new zones of WoW Forever have no shipped vendors. The optional NorgannonDB addon fills them in. The Darkspear Islands have no vendors there.
- Vendors in zones that WoW Forever reshaped can be slightly wrong.
- The addon ships no trainers.
- Until you open a trainer for a profession, the addon cannot send you to one.
- The addon says this once for each profession in each session, in chat.
- The addon watches only professions that it saw at a trainer or in a crafting window.
- Professions are matched by the name that the game shows.
- After you change the game language, the addon learns trainers again.
- The addon skips vendors of the other faction.
- Reputation: each character remembers vendors, profession trainers and auctioneers it has seen as Unfriendly or Hostile (target, mouseover, nameplate) and never routes to them. This covers the goblin auction houses in Booty Bay, Gadgetzan and Everlook when you are Unfriendly with their cartel. A vendor of no side that another character taught you, such as a clan quartermaster, is used only after this character has seen it at Neutral or better or opened its window. The game does not say which reputation a vendor needs, so a shipped vendor you cannot trade with is skipped only after you have seen it.
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
- `/cvn find` searches these items by category: the addon does not know which items a vendor stocks, so a seller may not have the exact item you typed. It lists only items the game has named for you; an item link always works.
- The status window shows Food, Water and Pet food rows in its Supplies group. They are separate from the Conjured Food and Conjured Water rows.

### Skill levels

- The addon takes the last skill tier to end at 300.
- The addon never asks about a profession whose limit is already 300.
- The addon does not ask about a profession while you are too low a level to learn its next tier from a trainer (level 10 for 75, 20 for 150).
- Without NorgannonDB, Artisan (after 225) is never routed: few trainers teach it and the addon cannot tell which. Journeyman and Expert trainers usually stand side by side, so the closest trainer is used for those.
- With NorgannonDB, a trainer's tier comes from its title: before patch 2.3 a trainer teaches the tiers below its title (a Journeyman Blacksmith teaches Apprentice, an Expert Journeyman, an Artisan Expert, a Master Artisan). Trainers with other titles, such as specialization masters or "Mining Trainer", have no known tier: they are used for Journeyman and Expert, never for Artisan.
- It is not verified if WoW Forever has tiers above 300.
- The addon does not check the level requirement of the trainer.
- The closest trainer is not checked for which tier it teaches; see issue #27.

### Distance and maps

- Distance is a straight line, not a walking route.
- The addon considers only vendors on your current continent.
- "Your map" means the exact map that you stand in.
- A city is its own map, separate from the zone around it. In a city, "your map" is that city.
- Auction house routing also uses straight-line distance to an auctioneer.
- The list of other sellers is ordered by straight-line distance and shows only sellers the addon knows.
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
- A sound-pack sound needs the addon that shares it. While that addon is off, the whisper ping plays instead, and your choice stays saved.
- The text of the addon is English only. You can add other languages. See [docs/localization.md](docs/localization.md).
- The addon was written and tested against fake game APIs. The in-game checks are a CheckThat test plan, `plans/closestvendor.yaml`.
- With the CheckThat test runner installed, the addon gives it read-only values for automatic checks: its version, a setting, the open warning, what the account learned, an NPC's standing, the waypoint method, what NorgannonDB gave, what the status window shows, a saved setting by its saved name and the reagents the warning watches. Without CheckThat, nothing changes.

## Problems?

1. Type `/cvn debug on`.
2. Do the thing that went wrong.
3. Type `/cvn log`. A window opens with a report.
4. Select all (Ctrl+A) and copy (Ctrl+C).
5. Send the report with a short description and your client (Classic Era or WoW Forever).
6. Type `/cvn debug off` to stop recording.

The report holds:

- The game build.
- Your settings. This includes picker and AceConfig availability, effective notice style and HUD/toast appearance, toast position, character scope and sample/Move state.
- Whether the CheckThat test runner is `working`, `not detected`, `too old` or `failed` (with the reason).
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
