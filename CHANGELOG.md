# Changelog

## 1.2.1

- Professions: the addon no longer asks about a trainer, or marks the profession low in the status window, while your level is too low for the next tier (level 10 for 75, 20 for 150, 35 for 225).

## 1.2.0

- Settings are now saved per character: thresholds, switches, the reminder sound, the status window options and position, known professions, the hearthstone point and the debug log. The vendors, trainers and auctioneers the addon learns are still shared by the account.
- A character that has not used the addon before starts from the settings the account had, or from the defaults. Known professions are learned again when you open a trade window or trainer.

## 1.1.0

- Food, water and pet food: the addon counts the food, drink and pet food in your bags (bought, cooked, looted or conjured) and, at 5 or fewer by default, asks about the closest vendor that sells it. Water is for classes that use mana. Pet food is for a hunter with a pet out, and it follows the pet's diet (Meat, Fish, Bread, Cheese, Fruit, Fungus), found from the pet's creature family, so it works in every game language.
- Reminders instead of trips: a mage who knows Conjure Food or Conjure Water is reminded to conjure it. A warlock who knows Create Healthstone and carries none is reminded to create one. A reminder is a notice with no question and no pin.
- Reminder sound: a reminder plays a sound. The default is the whisper ping. Choose another (minimap ping, group invite, ready check) or none on the Supplies page or with `/cvn sound <name>`.
- Status window: a new Supplies group with Food, Water and Pet food rows. It follows the same Only when low, Always or Never modes. Click a row to pin the closest seller.
- Settings: a new Supplies page with a switch and a threshold (1 to 40) for each of food, water and pet food, a healthstone reminder switch for warlocks, and the reminder sound. The "Ammo and reagents" switch also turns these off.
- Commands: `/cvn food`, `/cvn water`, `/cvn petfood` (count, on or off), `/cvn sound`, `/cvn test food|water|petfood|remind` and `/cvn hud row supplies`. `/cvn test remind` always works and plays the sound. The unlisted `/cvn demo` now shows supplies and reminders too.
- Priority order is now repair, ammo, reagent, food, water, pet food, sell, then profession trainer.
- Vendor data records which vendors sell food, water and each pet diet. Vendors you open are learned with their supplies. The item lists come from the game's client data.
- The debug report lists the new settings.

## 1.0.0

This is a major version bump made by request; nothing saved by earlier versions breaks.

- Status window: a small movable window showing ammo, class reagents, bag space, durability and professions. Each group (Ammo, Reagents, Bags, Durability, Professions) is set to Only when low, Always or Never; display-only items (Soul Shards, Blinding Powder, Conjured Food and Water) show when Reagents is Always. Click a row to navigate to the closest vendor with no question, even in combat. Drag the title to move it (Shift-drag when unlocked), lock it, and reset it.
- Window appearance: background opacity 0 to 100% (at 0 only text and icons are drawn), text and icon opacity 20 to 100%, scale 50 to 200%, and a background color chosen with the game's color picker. Black by default, so it is kind to OLED screens.
- Reagent buying: stock up to a set amount (0 to 100) of each reagent your class uses when a merchant window opens, with an ask-first option, like ammo buying.
- Instances: no questions or pins inside dungeons, raids and battlegrounds, and a pin made there searches from your hearthstone point or your last position outside (`/cvn anchor hearth|last`).
- Auction house: optional routing to the closest auctioneer when it is nearer than a vendor (`/cvn ah on|off`); auctioneers are shipped and learned.
- Settings are split into the main page (Warnings, Navigation) and Reagents, Ammo and Status window pages.
- Commands: `/cvn hud lock|unlock|reset|scale|opacity|textopacity|color|row`, `/cvn anchor`, `/cvn ah`, `/cvn reagentbuy`.
- The debug report lists the new settings and says whether the color picker and settings button exist.

## 0.5.0

- Class reagents: reminds Mages, Rogues, Priests, Paladins, Shamans and Druids when a reagent they use is low (5 or fewer by default) and offers to navigate to the closest vendor that sells it. Only reagents for spells you know are watched, and rank-based reagents (druid seeds, priest candles) follow your highest rank.
- Settings page: the Ammo row is now "Ammo and reagents", one switch for both. A new reagent threshold slider (1 to 40) applies to all reagents, and each of your class reagents has its own checkbox. All on by default.
- Commands: `/cvn reagent <count>`, `/cvn reagents` (list), `/cvn reagent on <name>`, `/cvn reagent off <name>`, `/cvn test reagent`. `/cvn ammo on` and `/cvn ammo off` switch ammo and reagent questions together.
- Priority order is now repair, ammo, reagent, sell, then profession trainer.
- Vendor data records which vendors sell each reagent; vendors you open are learned with their reagents.
- When a target is chosen without asking, the chat line and on-screen message now say why: "to buy ammo", "to buy <reagent>", "to repair your gear", "to sell items and free bag space" or "to train <profession>". The reagent question also names what to buy.
- The `/cvn` help text is shorter.
- The debug report lists the reagent settings.

## 0.4.1

- The on-screen message shown when a target is chosen without asking now stays for about five seconds instead of fading after about three. It uses its own frame, so the game's own error messages are unchanged. A newer message replaces the one showing.

## 0.4.0

- When the closest target is chosen without asking (`/cvn choice auto`), the chat line now names it with its zone and distance, and names the other choice when there was one.
- The same text is also shown on screen, silently (the map pin already makes a sound). `/cvn notice off` turns the on-screen text off; a settings page checkbox matches. On by default.
- The debug report lists the on-screen notice setting.

## 0.3.0

- Tells you when a profession is close to its current skill cap (10 points by default, or already at it) and offers to navigate to the closest trainer you have used for it. It checks on every skill-up and every craft.
- Trainers are learned as you open profession trainer windows; none are shipped yet. If none is known for the profession, it says so once per session.
- `/cvn trade <points>`, `/cvn trade on` and `/cvn trade off` change it, with matching settings page controls.
- When the closest vendor or trainer is on another map and one on your own map is farther, the question now lists both, with zone and distance, and has three buttons: the one on your map, the closest, and Cancel. Otherwise nothing changes.
- `/cvn choice ask` (default) asks; `/cvn choice auto` sets the waypoint without asking. `/cvn prefer map` (default) or `/cvn prefer distance` sets which target comes first, and what `auto` picks. Matching settings page dropdowns.
- The debug report lists the profession and target-choice settings.

## 0.2.0

- Buys ammo for you. At any merchant, with a bow, crossbow or gun equipped, it fills your quiver or ammo pouch, with no clicks. It spends only what you can afford and tells you in chat what it bought.
- Choose which ammo to buy, separately for arrows and bullets: the same as your equipped ammo (default), the best your level allows, or the cheapest.
- `/cvn buy ask` shows the count and price and waits for a Yes; `/cvn buy off` turns buying off. New settings page controls match.
- The debug report lists the ammo-buying settings and what happened at each merchant.

## 0.1.0

- First release for WoW Forever and Classic Era.
- Asks whether to navigate to the nearest vendor when your free bag slots drop to 2 or fewer, any equipped item falls below 20% durability, or your equipped ranged ammo (arrows or bullets) drops to 200 or fewer. All three thresholds can be changed or switched off.
- Shows the vendor with TomTom, WaypointUI, the built-in map waypoint (Forever) or a chat message with the coordinates.
- Ships about 900 vendors and learns more as you open vendor windows, including which ones repair and which sell arrows or bullets.
- Settings page under Options, AddOns, plus `/cvn` commands, including `/cvn test sell|repair|arrows|bullets` to preview each question.
- `/cvn debug on` and `/cvn log` record and show a copyable report for bug reports.
- The addon's text can be translated; see `docs/localization.md`.
