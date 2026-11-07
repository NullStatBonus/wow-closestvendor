# In-game test plan

What the automated tests cannot check: the real game. Run it on WoW Forever (and on Classic Era when convenient) before a release, after a change to `Adapter.lua`, `Core.lua`, `Report.lua` or `Options.lua`, and when a new game build comes out. Tick items off and note the client build.

## 0. Setup

1. Copy `ClosestVendor/` into the AddOns folder; start the game. `/console scriptErrors 1`, then `/reload`.
2. No Lua error popup appears on login. The addon is listed (Esc, AddOns).
3. Optional extras to test with: TomTom, WaypointUI (Forever).
4. For ammo: a hunter (or warrior or rogue) with a bow, crossbow or gun equipped and some ammo in the ammo slot.

## 1. Settings page and commands

- [ ] Esc, Options, AddOns, **Closest Vendor** exists, with a checkbox and a slider for Bag space, Durability and Ammo, plus Buy ammo and Ask before buying ammo checkboxes and Arrows to buy / Bullets to buy dropdowns.
- [ ] Moving a slider changes the number shown by `/cvn`; `/cvn ammo 500` moves the ammo slider to 500 when the page is reopened.
- [ ] Clearing a checkbox greys out its slider and stops that trigger asking.
- [ ] `/cvn config` opens the page.
- [ ] `/cvn` and `/cvn help` print readable lines: no stray symbols, no missing text.
- [ ] Settings changed with `/cvn` and on the page survive `/reload` and a full restart.

## 2. The question

- [ ] `/cvn test sell`, `/cvn test repair`, `/cvn test arrows`, `/cvn test bullets` each show the question with a vendor name and zone. **Yes** sets the pin (see section 3); **No** or Esc does nothing.
- [ ] Fill your bags to the threshold (default: 2 free slots or fewer): the sell question appears once and does not repeat on later bag changes.
- [ ] Wear one item below the durability threshold (default 20%): the repair question appears once.
- [ ] Answer **Yes** to a real question (not a test): navigation starts at the vendor named in it.
- [ ] Answer **No**: it does not ask again until the condition clears (sell something / repair) and then comes back.
- [ ] Sell or repair while the question is open: the question closes by itself.
- [ ] With both repair and sell conditions true: repair is asked first.
- [ ] The question never appears in combat; it appears after combat ends.

## 3. Navigation

- [ ] With TomTom: the arrow points at the vendor and is removed when you open any vendor window.
- [ ] With WaypointUI (Forever): the destination shows; it is removed on arrival or when you open a vendor.
- [ ] With neither (Forever): the map waypoint shows and is super-tracked.
- [ ] With neither (Era): a chat line with the vendor, zone and coordinates.
- [ ] `/cvn log` (section 5) reports the navigation method it used.

## 4. Vendors and learning

- [ ] Open a vendor the addon did not know (a new Forever zone, e.g. Mount Hyjal or Zephras Isle): afterwards `/cvn test sell` can pick it.
- [ ] Open a repair vendor: `/cvn test repair` can pick it. Open an ammo vendor: `/cvn test arrows` / `bullets` can pick it.
- [ ] Spot-check about 10 known vendors against their real positions (cities, remote camps, faction-specific). Note any that are off, and whether a "vendor" refuses to buy some items.

## 5. Ammo

- [ ] With a bow and fewer arrows than the threshold: the arrows question appears. With a gun and bullets: the bullets question.
- [ ] Use ammo down to the threshold by shooting: the question appears when you cross it. Turn `/cvn debug on` first and note **which events fired** as the count dropped (`BAG_UPDATE_DELAYED`, `UNIT_INVENTORY_CHANGED`, `PLAYER_EQUIPMENT_CHANGED`) in the report.
- [ ] Equip the wrong kind of ammo for the weapon: it counts as no ammo and asks. Equip a thrown weapon or a wand: it never asks.

## 6. Professions

- [ ] Open a profession trainer (any): `/cvn log` after `/cvn debug on` shows the trainer window event and the report lists `trainers: 1 learned` and the profession. Open a class trainer: nothing is recorded.
- [ ] Reach the threshold (default 10 points from the limit, e.g. 65/75 Mining) and gather: the trainer question appears on the skill-up, names the profession, the points left and the trainer, and **Yes** sets the pin.
- [ ] Craft with a tradeskill window open near the limit: the question appears after every craft, also when no skill-up happened. Note which events fired for a single craft and for a Craft All (Forever): `UNIT_SPELLCAST_SUCCEEDED` once per item?
- [ ] Answer **No**: the next skill-up or craft asks again. Leave the question open and craft again: it is not shown a second time.
- [ ] At the tier limit (e.g. 75/75) it still asks; at 300/300 (or the final tier) it never asks. On Forever, check whether any profession can go above 300 and what `maxRank` the skill list shows.
- [ ] Open the trainer window for that profession: the pin disappears. Open a vendor window on the way: the trainer pin stays.
- [ ] A profession you never opened a trainer or crafting window for stays silent; weapon skills never ask. A known profession with no trainer on this continent prints one chat line, once.
- [ ] Does opening a tradeskill window teach the addon the profession (report line `professions seen`)? Does the trainer window have its services loaded at `TRAINER_SHOW`, or only after `TRAINER_UPDATE` (the log shows which event recorded it)?
- [ ] `/cvn trade 25`, `/cvn trade off`, the settings page slider agree.

## 7. Report and debug log

- [ ] `/cvn log` with the log off opens a window with the version, game build, locale, navigation method, vendor counts and settings, and says how to turn the log on.
- [ ] `/cvn debug on`, then trigger a question: `/cvn log` lists the events, the decision with the bag/durability/ammo values behind it, the vendor found, and whether it was shown and accepted.
- [ ] The text is selected; Ctrl+C copies it all; Esc closes the window.
- [ ] `/cvn log clear` empties it; `/cvn debug off` stops recording.

## 8. Safety

- [ ] Inside a dungeon or battleground: no error, no question, no pin. After leaving, normal behavior returns.
- [ ] Loading with TomTom or WaypointUI disabled, then enabling and `/reload`: no error either way.
- [ ] On a client where a function is missing, a line like `game call failed: <name>` appears once in the log, and the addon keeps working.

## 9. Languages

- [ ] On a non-English client the addon's sentences are English and spell/zone names are the game's.
- [ ] With a translation file installed (docs/localization.md): `/cvn`, the question and the settings page show it.

## 10. Buying ammo

Use a hunter with a bow (or a gun) and a quiver (or ammo pouch). Turn `/cvn debug on` first.

- [ ] With the quiver partly full and `/cvn buy auto` (default): opening an ammo vendor buys until the quiver is full, with no dialog. One chat line gives the count and cost.
- [ ] Check the count bought matches the room left. Note how many `BuyMerchantItem` calls were needed and the vendor's batch size (the report shows it). This confirms the one-call-per-batch assumption.
- [ ] Opening the vendor with a full quiver buys nothing.
- [ ] No quiver or pouch: nothing is bought. Wand or thrown weapon: nothing is bought.
- [ ] `/cvn buy ask`: a dialog shows the count and price; nothing is bought until **Yes**; **No** buys nothing.
- [ ] `/cvn buy off`: nothing is bought.
- [ ] `/cvn arrows best` at a vendor selling several grades buys the highest grade your level allows; `/cvn arrows cheapest` buys the cheapest; `/cvn arrows equipped` buys what is in your ammo slot.
- [ ] Setting arrows and bullets differently: a bow follows the arrow setting, a gun the bullet setting.
- [ ] Equipped ammo that this vendor does not sell, with `equipped`: nothing is bought and a chat line says so. A vendor that sells no ammo at all stays silent.
- [ ] Short on gold: only what you can afford is bought, and the chat line says so. With almost no gold, "You cannot afford any ammo here."
- [ ] A quiver holding a different grade does not make it overbuy.
- [ ] The Arrows and Bullets dropdowns on the settings page match `/cvn`.

## Not covered yet

- Walking distance (vendors are chosen by straight-line distance).
- Classes' own reagents (mage powders, rogue poisons and so on).
