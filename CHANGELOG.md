# Changelog

## 1.13.1

- **Fixed: A known vendor or trainer keeps its saved place when you stand a few steps away.** Before, each visit saved a new place.

## 1.13.0

- **New: `/cvn test trainer` asks about the nearest profession trainer the addon knows.** You do not need a profession.
- Changed: The debug log tells where each vendor or trainer in a question comes from. It also gives the distance in yards.

## 1.12.0

- **New: `/cvn testsettings on` puts your settings aside while you run a test plan.** `/cvn testsettings off` brings them back.
- New: The CheckThat test plans turn test settings on at the start and off at the end. Your own settings stay as they are.

## 1.11.3

- **Changed: The debug log shows more of what the addon decides about buying, supplies and the status window.** CheckThat can check more of them without you.
- Changed: The debug log keeps the last 1000 lines. Before, it kept 300.

## 1.11.2

- **Changed: The debug log shows more of what the addon decides about vendors, trainers and waypoints.** CheckThat can check more of them without you.
- Changed: A click on an Artisan profession row says that trainer tiers are unknown only when the skill is near its limit.

## 1.11.1

- **Changed: The debug log shows more of what the addon decides about warnings.** CheckThat can check more warnings without you.

## 1.11.0

- **New: The addon works with the CheckThat test runner.** CheckThat can read the addon version and your settings. Without CheckThat, nothing changes.
- Fixed: The debug log records when you turn it off. Before, that line was missing.

## 1.10.0

- **New: `/cvn find` shows the nearest known sellers of a food, drink, pet food or class reagent item.** Type an item name or paste an item link. Pick a seller to set a waypoint.
- New: A **Find supplies** box at the end of the Home page runs the same search.
- New: When many items match, chat asks you to type more of the name.
- New: For food, drink and pet food, chat says the seller may not stock that exact item.

## 1.9.5

- **Fixed: A repair question no longer opens after you reach a merchant.** Before, a gear check could ask just after the merchant window opened.
- Fixed: After `/cvn demo`, your own map waypoint stays when the game cannot say what is there. Before, the addon could replace it.
- Fixed: When you stop `/cvn demo`, a waypoint you set very near a demo pin stays. Before, the addon could replace it.
- Fixed: `/cvn reagent` matches a reagent name in any case for accented Latin and Cyrillic letters. Before, only A to Z ignored case.
- Fixed: `/cvn settings` with a wrong page name lists `notifications` and `status-window`. Before, it left them out.

## 1.9.4

- **Fixed: The debug log keeps decisions and failures longer.** Before, durability and inventory events filled it in about 20 minutes.
- Fixed: `/cvn settings status-window` opens the Status window tab, and `/cvn settings notifications` works. Before, the first opened Appearance only and the second failed.
- Fixed: The addon remembers an Unfriendly trainer that only NorgannonDB lists. Before, it offered that trainer again.
- Fixed: When an auction house and a vendor are about the same distance, the closer one wins. Before, whole-yard rounding could choose the farther one.
- Fixed: The addon keeps your own map waypoint when it is near the addon waypoint. Before, it could remove yours.
- Fixed: After `/cvn demo`, the status window shows real rows when a timer fails. Before, the made-up rows stayed.
- Fixed: After `/cvn demo`, the addon does not set your old waypoint when the game cannot say what is there. Before, it could replace a newer waypoint.
- Fixed: A bind at the same inn is kept when you log out or reload at once. Before, the addon could lose the inn's position.
- Fixed: `/cvn reagent` accepts the reagent name in your game language. Before, only English names worked.
- Changed: Durability and inventory events start one check each burst. The addon removes old saved keys at login.

## 1.9.3

- **Fixed: When you bind again at the inn you are bound to, the addon learns where it is.** Before, a row click in a dungeon searched near your last position outside.
- Fixed: When you pick a seller from an old list, the addon checks it again. Before, it could route you to a vendor without your ammo.
- Fixed: When you unlearn a profession, its trainer waypoint goes away. Before, the waypoint stayed.
- Fixed: After `/cvn demo`, your own map waypoint comes back. Before, the demo removed it.
- Fixed: The status window updates when a timer does not start. Before, the window could stop updating.

## 1.9.2

- **Fixed: When you click a row, the open warning comes back after that trip.** Before, the warning was lost or blocked the other warnings.
- Fixed: After you answer No, the next warning waits for a map position. Before, it could stop and never show.
- Fixed: A trainer question closes when you change zone. Before, Yes could route you from the old place.
- Fixed: The bag space warning shows after you decline repair and ammo. Before, the addon did not ask about it.
- Fixed: When you change to a gun or to a pet that eats other food, the addon asks again. Before, it kept the old vendor.

## 1.9.1

- **Fixed: When you click Yes later, the addon buys only the ammo or reagents you still need.** Before, it bought the full amount, also after you bought some by hand.
- Fixed: Ammo and reagent buying works with items that you can use. Before, the addon could skip them on some clients.
- Fixed: A vendor keeps its arrows and bullets when its items load slowly. Before, the addon could forget that the vendor sells ammo.
- Fixed: "Best usable" ammo waits for the item data, then buys. Before, it said the merchant did not sell your ammo.

## 1.9.0

- **New: You can choose another seller from the status window.** A row with more than one known seller shows an arrow. Click the arrow to see up to three other sellers and pick one.
- Changed: The About page shows only the name, the version and what the addon does. `/cvn help` lists the commands.

## 1.8.0

- **New: The notification sound can come from a sound pack.** If another addon shares sounds through LibSharedMedia, they show after the built-in sounds. `/cvn sound <name>` accepts their names.
- Changed: When the sound pack is not available, the whisper ping plays. Your choice stays saved.

## 1.7.0

- New: The AddOns list shows the Closest Vendor icon and its settings pages.
- **New: With NorgannonDB, trainer questions show only trainers who teach your next tier.** This includes Artisan. Before, the addon showed the closest trainer, and that trainer could not always teach you.
- Changed: When you answer No, the addon asks about your next need. Before, it asked nothing more until the first need stopped.
- Changed: When you change zone, the addon closes the open question and asks again.
- Changed: The addon learns your hearthstone point at the inn.
- Changed: Without NorgannonDB, the addon does not route you to Artisan trainers.
- Fixed: The addon does not ask questions while you are dead. It asks when you are alive again.
- Fixed: When you close a merchant, the addon closes the purchase question. Before, the question stayed open.
- Fixed: The addon skips trainers and auction houses that will not trade with you.
- Fixed: Pet diets and reagent names show in your game language.

## 1.6.0

- New: `/cvn demo` shows real routes, questions and notifications. Then it sets your waypoint again.
- New: You can select one sound for all notifications.
- New: Move has Done and Cancel buttons. Previews do not change your settings.
- Changed: Route messages and reminders show as one type of notification: Toast (default) or Warning.
- Changed: Home holds the main settings. Ammo, Reagents and Supplies are under Restock.
- Fixed: Low rows in the status window are red.
- Fixed: The addon does not show vendors that are Unfriendly or Hostile to you.

## 1.5.0

- New: With NorgannonDB, the addon also uses its vendors in the new WoW Forever zones.

## 1.4.0

- New: `/cvn reagents on|off` turns reagent warnings on or off.
- New: One Supplies setting turns food, water, pet food and the healthstone reminder on or off.
- Changed: Ammo and Reagents each have their own setting.
- Changed: Settings pages are in alphabetical order. The status window page is last.
- Changed: In groups, the addon ignores pets of other players.
- Fixed: Ammo and reagent purchases wait for item data from the game.

## 1.3.0

- New: You can select the waypoint method: Automatic, TomTom, WaypointUI or the game waypoint (`/cvn nav`).

## 1.2.1

- Fixed: The addon does not ask about a trainer when your level is too low for the next tier.

## 1.2.0

- Changed: Each character has its own settings. All characters on the account share learned vendors, trainers and auctioneers.
- Changed: A new character starts with the earlier account settings or the default settings.

## 1.1.0

- New: Food, water and pet food warnings show the closest vendor. Pet food follows the diet of your pet.
- New: The addon reminds mages to conjure food and water. It reminds warlocks to make a healthstone.
- New: The status window and settings have a Supplies section.
- New commands: `/cvn food`, `/cvn water`, `/cvn petfood`, `/cvn sound` and `/cvn test food|water|petfood|remind`.

## 1.0.0

- New: A status window shows ammo, reagents, bag space, durability and professions. You can move it. Click a row to go to a vendor.
- New: The window is black by default for OLED screens. You can change its appearance.
- New: The addon buys reagents at merchants.
- New: The addon can route you to the closest auction house.
- Changed: The addon does not ask questions in dungeons, raids and battlegrounds.

## 0.5.0

- New: Class reagent warnings show the closest vendor for Mages, Rogues, Priests, Paladins, Shamans and Druids.
- New: You can set a reagent threshold and select each reagent.
- New: The chat message tells you why the addon selected a target.

## 0.4.1

- Changed: The on-screen message shows for approximately five seconds.

## 0.4.0

- New: When the addon selects a target without a question, chat shows its name, zone and distance.
- New: The same text shows on the screen. `/cvn notice off` hides it.

## 0.3.0

- New: The addon warns you when a profession is near its skill limit. It shows the closest trainer you used.
- New: When the closest target is on a different map, the question shows two targets.

## 0.2.0

- New: The addon buys ammo at merchants. It spends only the money you have.
- New: You can select the ammo type: same as equipped, best or cheapest.
- New: `/cvn buy ask` asks first. `/cvn buy off` stops purchases.

## 0.1.0

- First release for WoW Forever and Classic Era.
- The addon asks to route you to the closest vendor when your bags are almost full, your gear is damaged or your ammo is low.
- It shows the vendor with TomTom, WaypointUI, the game waypoint or a chat message.
- It has approximately 900 vendors. It learns more vendors when you open them.
