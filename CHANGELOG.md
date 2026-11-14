# Changelog

## 1.4.0

- Buying ammo and reagents now waits for item data the game has not loaded yet, instead of skipping the purchase.
- Ammo and Reagents have separate switches. Each has its checkbox and slider on its own page (Ammo, Reagents). `/cvn ammo on|off` affects ammo only, and `/cvn reagents on|off` is new. A saved ammo-off setting carries over to reagents.
- Settings pages are in alphabetical order with the status window last, and the Warnings list is Bag space, Durability, Professions, Supplies.
- A Supplies checkbox in Warnings (and `/cvn supplies on|off`) turns food, water, pet food and the healthstone reminder on or off together. Turning off "Ammo and reagents" no longer turns them off.
- Less work in groups: other players' pet changes are ignored, and bags are not read for supplies while every supply warning is off.

## 1.3.0

- Choose the waypoint method (Automatic, TomTom, WaypointUI or the game's own) with `/cvn nav` or the settings page.

## 1.2.1

- No trainer question while your level is too low for the next skill tier.

## 1.2.0

- Settings are now saved per character. Learned vendors, trainers and auctioneers are still shared by the account.
- A new character starts from the settings the account had before, or the defaults.

## 1.1.0

- Food, water and pet food warnings with the closest vendor. Pet food follows the pet's diet in every game language.
- Mages are reminded to conjure food and water, and warlocks to create a healthstone, with a sound you can choose (`/cvn sound`).
- A Supplies group in the status window and a Supplies settings page.
- New commands: `/cvn food`, `/cvn water`, `/cvn petfood`, `/cvn sound` and `/cvn test food|water|petfood|remind`.

## 1.0.0

This is a major version bump made by request; nothing saved by earlier versions breaks.

- A movable status window for ammo, reagents, bag space, durability and professions. Click a row to navigate.
- Window appearance settings, black by default for OLED screens.
- Reagent buying at merchants, like ammo buying.
- No questions inside dungeons, raids and battlegrounds. Pins there search from your hearthstone point or last outside position.
- Optional routing to the closest auction house.
- Settings split into Main, Reagents, Ammo and Status window pages.

## 0.5.0

- Class reagent warnings for Mages, Rogues, Priests, Paladins, Shamans and Druids, with the closest vendor that sells them.
- The Ammo setting is now "Ammo and reagents". New reagent threshold and one checkbox per reagent.
- The chat line says why a target was chosen.
- New commands: `/cvn reagent`, `/cvn reagents` and `/cvn test reagent`.

## 0.4.1

- The on-screen message stays for about five seconds.

## 0.4.0

- When a target is chosen without asking, chat names it with its zone and distance.
- The same text shows on screen. `/cvn notice off` hides it.

## 0.3.0

- Warns when a profession is near its skill cap and offers the closest trainer you have used.
- When the closest target is on another map, the question lists both targets (`/cvn choice`, `/cvn prefer`).

## 0.2.0

- Buys ammo for you at any merchant. It spends only what you can afford and says what it bought.
- Choose the ammo for arrows and bullets: same as equipped, best, or cheapest.
- `/cvn buy ask` asks first; `/cvn buy off` turns it off.

## 0.1.0

- First release for WoW Forever and Classic Era.
- Asks to navigate to the closest vendor when bags are nearly full, gear is worn or ammo is low.
- Shows the vendor with TomTom, WaypointUI, the game's waypoint or a chat message.
- Ships about 900 vendors and learns more as you open them.
- Settings page, `/cvn` commands and a debug report.
