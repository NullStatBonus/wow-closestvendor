# Changelog

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
