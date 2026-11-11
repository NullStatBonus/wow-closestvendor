# In-game test plan

What the automated tests cannot check: the real game. Run it on WoW Forever (and on Classic Era when convenient) before a release, after a change to `Adapter.lua`, `Core.lua`, `Report.lua` or `Options.lua`, and when a new game build comes out. Tick items off and note the client build.

## 0. Setup

1. Copy `ClosestVendor/` into the AddOns folder; start the game. `/console scriptErrors 1`, then `/reload`.
2. No Lua error popup appears on login. The addon is listed (Esc, AddOns).
3. Optional extras to test with: TomTom, WaypointUI (Forever).
4. For ammo: a hunter (or warrior or rogue) with a bow, crossbow or gun equipped and some ammo in the ammo slot.

## 1. Settings page and commands

- [ ] Esc, Options, AddOns, **Closest Vendor** exists, with a checkbox and a slider for Bag space, Durability and Ammo and reagents (with the reagent slider and one checkbox per reagent of your class under it), plus Buy ammo and Ask before buying ammo checkboxes and Arrows to buy / Bullets to buy dropdowns.
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

## 11. Targets on another map

Stand near a zone edge, or in a zone where the nearest vendor is across the border. Use `/cvn test sell` (and `/cvn test repair`) so you can repeat it. Turn `/cvn debug on` first.

- [ ] With a vendor on your map that is farther than one on another map: the question lists both, each with its zone and a distance in yards, and has three buttons. The first is the one on your map (`/cvn prefer map`, the default).
- [ ] The first button sets the pin at the vendor on your map; the second at the closer one; Cancel and Esc set nothing.
- [ ] `/cvn prefer distance`: the closer vendor is now the first button.
- [ ] Stand where the nearest vendor is on your own map: the plain Yes / No question appears, with that vendor.
- [ ] Stand on a map with no known vendor: the plain question names the nearest vendor on another map.
- [ ] `/cvn choice auto`: no question. The pin is set at once, at the vendor on your map with `prefer map`, at the closer one with `prefer distance`, and one chat line names it.
- [ ] `/cvn choice auto`: one chat line and the same text on screen, naming the pinned target with zone and distance in yards and, when there were two, the other choice. No sound beyond the map pin's own. The text stays about five seconds (count it), sits high and centered, and disappears. A second pin while it shows replaces the text and restarts the time. A game error (for example, try an action that fails) still looks and lasts as usual.
- [ ] `/cvn notice off`: the on-screen text stops, the chat line stays. `/cvn notice on` brings it back. The settings page checkbox matches.
- [ ] `/cvn choice auto` with only one candidate: pinned at once too. In combat, nothing is pinned.
- [ ] Repeat with a profession near its cap: the trainer question and `auto` behave the same.
- [ ] In a city, "your map" is the city. Note which vendors are offered.
- [ ] The settings page dropdowns match `/cvn choice` and `/cvn prefer`, and `/cvn` shows both.
- [ ] `/cvn log` lists the settings (target choice) and, with debug on, which target was shown or pinned.

## 12. Reagents

Use a character whose class has reagents (mage, rogue, priest, paladin, shaman, druid), with `/cvn debug on`. Spell and item IDs were checked against the Era and Forever data tables; this section checks them in the real client.

- [ ] `/cvn` shows a "Reagents: on, trigger at 5 or fewer" line. `/cvn log` shows `reagents: class ..., threshold 5, watching: ..., switched off: none` with the reagents you expect for the spells you know.
- [ ] Spell gating: a reagent for a spell you do not know is not in `watching` (a low-level mage: no Rune of Portals); learning the spell adds it without a reload (note whether `SPELLS_CHANGED` fired in the log).
- [ ] Rank gating: a druid knowing Rebirth rank 3 watches Ashwood Seed only, not the rank 1 and 2 seeds; a priest knowing Prayer of Fortitude rank 2 watches Sacred Candle, not Holy Candle. Check each class's list against its spellbook, and whether lower ranks still report as known (`/dump IsPlayerSpell(<id>)`).
- [ ] Use reagents down to 5 (cast the spell): the question appears once, names the reagent and the count, says "sells <reagent>" so it is clear what to buy, and the vendor is one that sells it. Yes sets the pin.
- [ ] Counts: Rune of Teleportation 1 vs 5 vs 6 in bags and the threshold boundary (5 asks, 6 does not). Reagents in the bank are not counted.
- [ ] Open a vendor that sells the reagent: the question and the pin go away. Open any other vendor with a reagent question open: same.
- [ ] Two reagents low (for example Arcane Powder and Rune of Teleportation): one question, the second only after the first is answered or the merchant opened.
- [ ] Order: with a reagent low and gear worn below the threshold, the repair question comes first and the reagent question after it resolves; with a reagent low and full bags, the reagent question comes before the sell question. (No class has both ammo and reagents, so ammo versus reagents is covered by the automated tests.)
- [ ] `/cvn reagent 10`, the settings slider and `/cvn` agree; 0 and 41 are refused with a message about 1 to 40.
- [ ] `/cvn reagents` lists your class's reagents, all on. `/cvn reagent off arcane powder` turns one off (no more questions for it); `/cvn reagent on arcane powder` brings it back. An unknown or another class's reagent name gets a message.
- [ ] The settings page lists only your class's reagents, all on by default, each with a checkbox that matches `/cvn reagents`; clearing "Ammo and reagents" greys the ammo slider, the reagent slider and the reagent checkboxes and silences both ammo and reagents.
- [ ] Hunter, warrior and warlock: no reagent checkboxes, `/cvn reagents` says there are none, no reagent question ever.
- [ ] `/cvn test reagent` asks about the first watched reagent whatever the count; with nothing watched it says so in chat.
- [ ] Vendor data: open a reagent vendor you have not opened before (a druid or priest supplier): afterwards `/cvn log` or `/cvn test reagent` can pick it. Open a shipped reagent vendor: it is still picked (the learned record keeps its reagents).
- [ ] `/cvn choice auto`: a low reagent pins at once, one chat line and the on-screen text read "Navigating to <vendor> (<zone>, N yards) to buy <reagent>."; the other-map choice works as for ammo. Every automatic pin says why: "... to buy ammo.", "... to repair your gear.", "... to sell items and free bag space.", "... to train <profession>."
- [ ] Check the shipped data: 5 to 10 reagent vendors in cities and camps are where the pin says, and sell the item (`GetMerchantItemInfo`).

## Not covered yet

- Walking distance (vendors are chosen by straight-line distance).
- Buying reagents for you, and warlock shards and rogue poisons.
