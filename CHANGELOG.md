# Changelog

## 1.7.0

### New

- The AddOns list shows the Closest Vendor icon and its settings pages.
- With NorgannonDB, trainer questions show only trainers who teach your next tier, Artisan included.

### Changed

- When you answer No, the addon asks about your next need.
- When you change zone, the addon closes the open question and asks again.
- The addon learns your hearthstone point at the inn.
- Without NorgannonDB, the addon does not route you to Artisan trainers.

### Fixed

- The addon does not ask questions while you are dead.
- When you close a merchant, the addon closes the purchase question.
- The addon skips trainers and auction houses that will not trade with you.
- Pet diets and reagent names show in your game language.

## 1.6.0

### New

- `/cvn demo` shows real routes, questions and notifications. Then it sets your waypoint again.
- You can select one sound for all notifications.
- Move has Done and Cancel buttons. Previews do not change your settings.

### Changed

- Route messages and reminders show as one type of notification: Toast (default) or Warning.
- Home holds the main settings. Ammo, Reagents and Supplies are under Restock.

### Fixed

- Low rows in the status window are red.
- The addon does not show vendors that are Unfriendly or Hostile to you.

## 1.5.0

### New

- With NorgannonDB, the addon also uses its vendors in the new WoW Forever zones.

## 1.4.0

### New

- `/cvn reagents on|off` turns reagent warnings on or off.
- One Supplies setting turns food, water, pet food and the healthstone reminder on or off.

### Changed

- Ammo and Reagents each have their own setting.
- Settings pages are in alphabetical order. The status window page is last.
- In groups, the addon ignores pets of other players.

### Fixed

- Ammo and reagent purchases wait for item data from the game.

## 1.3.0

### New

- You can select the waypoint method: Automatic, TomTom, WaypointUI or the game waypoint (`/cvn nav`).

## 1.2.1

### Fixed

- The addon does not ask about a trainer when your level is too low for the next tier.

## 1.2.0

### Changed

- Each character has its own settings. All characters on the account share learned vendors, trainers and auctioneers.
- A new character starts with the earlier account settings or the default settings.

## 1.1.0

### New

- Food, water and pet food warnings show the closest vendor. Pet food follows the diet of your pet.
- The addon reminds mages to conjure food and water. It reminds warlocks to make a healthstone.
- The status window and settings have a Supplies section.
- New commands: `/cvn food`, `/cvn water`, `/cvn petfood`, `/cvn sound` and `/cvn test food|water|petfood|remind`.

## 1.0.0

### New

- A status window shows ammo, reagents, bag space, durability and professions. You can move it. Click a row to go to a vendor.
- The window is black by default for OLED screens. You can change its appearance.
- The addon buys reagents at merchants.
- The addon can route you to the closest auction house.

### Changed

- The addon does not ask questions in dungeons, raids and battlegrounds.

## 0.5.0

### New

- Class reagent warnings show the closest vendor for Mages, Rogues, Priests, Paladins, Shamans and Druids.
- You can set a reagent threshold and select each reagent.
- The chat message tells you why the addon selected a target.

## 0.4.1

### Changed

- The on-screen message shows for approximately five seconds.

## 0.4.0

### New

- When the addon selects a target without a question, chat shows its name, zone and distance.
- The same text shows on the screen. `/cvn notice off` hides it.

## 0.3.0

### New

- The addon warns you when a profession is near its skill limit. It shows the closest trainer you used.
- When the closest target is on a different map, the question shows two targets.

## 0.2.0

### New

- The addon buys ammo at merchants. It spends only the money you have.
- You can select the ammo type: same as equipped, best or cheapest.
- `/cvn buy ask` asks first. `/cvn buy off` stops purchases.

## 0.1.0

### New

- First release for WoW Forever and Classic Era.
- The addon asks to route you to the closest vendor when your bags are almost full, your gear is damaged or your ammo is low.
- It shows the vendor with TomTom, WaypointUI, the game waypoint or a chat message.
- It has approximately 900 vendors. It learns more vendors when you open them.
