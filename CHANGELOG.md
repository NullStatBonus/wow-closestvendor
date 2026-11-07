# Changelog

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
