# In-game test plan

These checks cover what the automated tests cannot check: the real game.

Run them on WoW Forever. Run them on Classic Era when you can.

Run them before a release. Run them after a change to `Adapter.lua`, `Core.lua`, `Report.lua` or `Options.lua`. Run them when a new game build comes out.

Tick each item. Write down the client build.

Each check has one player action, a `Check:` line with the result a player sees, and a `Log:` line the reviewer reads in the debug log or `ClosestVendorCharDB`. A line that starts with "Note" asks you to record what the game does. Those items are unknown: verify them in game.

## 0. Setup

Every item is pass/fail. The tester verifies the `Check:` line. The reviewer verifies the `Log:` line.

Do this once, before the first section: type `/cvn debug on`, then `/reload`. After the last check, type `/reload` again so the game saves the log. The reviewer reads `ClosestVendorCharDB` and `ClosestVendorDB` in `WTF/Account/<account>/<realm>/<character>/SavedVariables/ClosestVendor.lua`.

A section that says "Setup" lists what only that section needs, such as a class, a profession or an addon.

- [ ] Copy `ClosestVendor/` into the AddOns folder. Start the game. Type `/console scriptErrors 1`, then `/reload`.
  Check: no Lua error popup appears on login, and the addon is in the list (Esc, AddOns).
  Log: none; on screen only.
- [ ] Optional: install TomTom, and WaypointUI (WoW Forever only). Sections 3 and 17 use them.
  Check: both show in the AddOns list.
  Log: none; on screen only.
- [ ] Ammo sections only: use a hunter, warrior or rogue with a bow, crossbow or gun equipped and some ammo in the ammo slot.
  Check: the ammo shows in the ammo slot.
  Log: none; on screen only.

## 1. Settings page and commands

- [ ] Open Esc, Options, AddOns, **Closest Vendor** and look at Home.
  Check: Home lists the Warnings in order: Bag space, Durability and Professions (each a checkbox and a slider), then Ammo, Reagents and Supplies (a checkbox only).
  Log: none; on screen only.
- [ ] Look at the pages below Home.
  Check: the pages are Ammo, Reagents, Supplies, then Status window last.
  Log: none; on screen only.
- [ ] Open the Ammo page as a Hunter.
  Check: below the ammo slider are Buy ammo, Ask before buying and the arrow and bullet dropdowns.
  Log: none; on screen only.
- [ ] Open the Reagents page as a class that uses reagents (for example a Mage).
  Check: under the slider is one checkbox for each reagent of your class.
  Log: none; on screen only.
- [ ] Move a slider, then enter `/cvn`.
  Check: `/cvn` shows the new slider number.
  Log: none; on screen only.
- [ ] Enter `/cvn ammo 500` and reopen the page.
  Check: the ammo slider is at 500.
  Log: none; on screen only.
- [ ] Clear a checkbox.
  Check: its slider is greyed out and that trigger stops asking.
  Log: none; on screen only.
- [ ] Enter `/cvn config`.
  Check: the settings page opens.
  Log: none; on screen only.
- [ ] Enter `/cvn`.
  Check: it prints readable lines with no stray symbols or missing text.
  Log: none; on screen only.
- [ ] Enter `/cvn help`.
  Check: it prints readable lines with no stray symbols or missing text.
  Log: none; on screen only.
- [ ] Change settings with `/cvn` and on the page. Enter `/reload`.
  Check: the settings stay.
  Log: none; on screen only.
- [ ] Change settings again and restart the game.
  Check: the settings stay.
  Log: none; on screen only.

## 2. The question

- [ ] Enter `/cvn test sell`.
  Check: a question shows a vendor name and a zone.
  Log: "test command: sell" and "reminder: test".
- [ ] Enter `/cvn test repair`.
  Check: a question shows a vendor name and a zone.
  Log: "test command: repair".
- [ ] As a Hunter, enter `/cvn test arrows`, then `/cvn test bullets`.
  Check: each shows a question with a vendor name and a zone.
  Log: "test command: arrows" and "test command: bullets".
- [ ] Enter `/cvn test sell` and click **Yes**.
  Check: a waypoint to the vendor is set (see section 3).
  Log: "accepted: <vendor> via <provider>".
- [ ] Enter `/cvn test sell` and click **No**, then enter it again and press Esc.
  Check: nothing happens after either answer.
  Log: "question declined: sell".
- [ ] Fill your bags to the threshold (default 2 free slots or fewer), then change your bags again.
  Check: the sell question appears once and does not repeat.
  Log: one "question shown: sell" line.
- [ ] Wear one item below the durability threshold (default 20%).
  Check: the repair question appears once.
  Log: "question shown: repair".
- [ ] Click **Yes** on the repair question.
  Check: navigation starts to the vendor named in the question.
  Log: "accepted: <vendor> via <provider>".
- [ ] Click **No** on a real question, then sell or repair.
  Check: the addon does not ask again until the condition clears, then the question comes back.
  Log: "question declined: sell".
- [ ] Open a question, then sell or repair while it is open.
  Check: the question closes by itself.
  Log: "request released:" line.
- [ ] Make the repair and the sell condition true together.
  Check: the repair question comes first.
  Log: "question shown: repair" comes before any sell question.
- [ ] Meet a condition during combat.
  Check: no question appears in combat.
  Log: "trigger" line with `combat=true`.
- [ ] End combat with the condition still true.
  Check: the question appears after combat ends.
  Log: "trigger" line with `combat=false`.

## 3. Navigation

- [ ] With TomTom, trigger a question and click **Yes**.
  Check: the arrow points at the vendor.
  Log: "accepted: <vendor> via <provider>".
- [ ] On WoW Forever with WaypointUI, trigger a question and click **Yes**.
  Check: the destination shows.
  Log: "accepted: <vendor> via <provider>".
- [ ] On WoW Forever with neither addon, trigger a question and click **Yes**.
  Check: the map waypoint shows and is tracked.
  Log: "accepted: <vendor> via <provider>".
- [ ] On Classic Era with neither addon, trigger a question and click **Yes**.
  Check: a chat line shows the vendor, the zone and the coordinates.
  Log: "accepted: <vendor> via <provider>".
- [ ] With TomTom, set a waypoint and open any vendor window.
  Check: the arrow goes away.
  Log: "merchant window opened".
- [ ] With WaypointUI, set a waypoint and arrive at the vendor.
  Check: the destination goes away.
  Log: "merchant window opened".
- [ ] Enter `/cvn log`.
  Check: the report names the navigation method used.
  Log: the report line "navigation: <provider> (preference <choice>)".

## 4. Vendors and learning

- [ ] Open a repair vendor the addon does not know (a new WoW Forever zone, for example Mount Hyjal or Zephras Isle). Then enter `/cvn test repair`.
  Check: the question names that vendor.
  Log: "merchant window opened" and "question shown:" naming that vendor.
- [ ] Open an ammo vendor the addon does not know, as a Hunter. Then enter `/cvn test arrows`.
  Check: the question names that vendor.
  Log: "merchant window opened" and "question shown:" naming that vendor.
- [ ] Open a general vendor the addon does not know. Then enter `/cvn test sell`.
  Check: the question names that vendor.
  Log: "merchant window opened" and "question shown:" naming that vendor.
- [ ] Open a vendor that will not trade with you (Unfriendly or Hostile). Then enter `/cvn test sell`.
  Check: the question does not name that vendor.
  Log: "standing: npc <id> will not trade (Unfriendly or Hostile)".

## 5. Ammo

- [ ] As a Hunter, equip a bow with fewer arrows than the threshold.
  Check: the arrows question appears.
  Log: "question shown: arrows".
- [ ] As a Hunter, equip a gun with fewer bullets than the threshold.
  Check: the bullets question appears.
  Log: "question shown: bullets".
- [ ] As a Hunter, shoot ammo down to the threshold.
  Check: the question appears when you cross the threshold.
  Log: "event BAG_UPDATE_DELAYED", "event UNIT_INVENTORY_CHANGED" and "event PLAYER_EQUIPMENT_CHANGED" lines show which events fired as the count dropped.
- [ ] As a Hunter, equip a bow with only bullets in the ammo slot.
  Check: the addon counts it as no ammo and asks.
  Log: "trigger" line with the ammo value.
- [ ] As a Rogue or Warrior, equip a thrown weapon.
  Check: the addon never asks about ammo.
  Log: no "question shown:" line for ammo.
- [ ] As a Mage, Priest or Warlock, equip a wand.
  Check: the addon never asks about ammo.
  Log: no "question shown:" line for ammo.

## 6. Professions

- [ ] Open a profession trainer, then enter `/cvn log`.
  Check: the report lists the profession trainer (`trainers: 1 learned` and the profession).
  Log: "trainer window opened" and "trainer services:" line.
- [ ] Open a class trainer, then enter `/cvn log`.
  Check: the report records nothing for the class trainer.
  Log: "trainer window opened" with no "trainer services:" line.
- [ ] Reach the threshold (default 10 points from the limit, for example 65/75 Mining) and gather.
  Check: the trainer question appears on the skill-up. It names the profession, the points left and the trainer.
  Log: "question shown: trainer for <profession>".
- [ ] Click **Yes** on the trainer question.
  Check: a waypoint to the trainer is set.
  Log: "accepted: <trainer> via <provider>".
- [ ] Craft near the limit with a tradeskill window open, with no skill-up.
  Check: the trainer question still appears after the craft.
  Log: "a craft finished".
- [ ] Answer **No** to the trainer question, then craft again.
  Check: the question appears again.
  Log: "question declined: trainer".
- [ ] Leave the trainer question open, then craft again.
  Check: the question does not show a second time.
  Log: one "question shown: trainer" line.
- [ ] Reach the tier limit (for example 75/75).
  Check: the addon still asks.
  Log: "question shown: trainer" at the tier limit.
- [ ] Reach the final tier (300/300).
  Check: the addon never asks.
  Log: no "question shown: trainer" line.
- [ ] With a trainer waypoint set, open a vendor window.
  Check: the waypoint stays.
  Log: no "trainer waypoint cleared:" line.
- [ ] With a trainer waypoint set, open that profession's trainer window.
  Check: the waypoint goes away.
  Log: "trainer waypoint cleared:".
- [ ] Use a profession whose trainer or crafting window you never opened.
  Check: the addon stays silent.
  Log: no "question shown:" line.
- [ ] Use a weapon skill near its limit.
  Check: the addon stays silent.
  Log: no "question shown:" line.
- [ ] Use a known profession that has no trainer on this continent.
  Check: one chat line appears, once.
  Log: "no known trainer for <profession>" once.
- [ ] Open a tradeskill window. Enter `/cvn log`.
  Check: the report lists the profession under the professions seen.
  Log: "trainers: N learned, professions seen: <list>" in the report.
- [ ] Enter `/cvn trade 25` and open the settings page.
  Check: the Professions slider shows 25.
  Log: none; on screen only.
- [ ] Enter `/cvn trade off` and open the settings page.
  Check: the Professions checkbox is cleared.
  Log: none; on screen only.

## 7. Report and debug log

- [ ] With the log off, enter `/cvn log`.
  Check: a window opens with the version, game build, locale, navigation method, vendor counts and settings, and it says how to turn the log on.
  Log: none; on screen only.
- [ ] Enter `/cvn debug on`. Trigger a question. Enter `/cvn log`.
  Check: the log lists the events, the decision with the bag, durability and ammo values behind it, the vendor found, and whether the question was shown and accepted.
  Log: "debug log turned on", "trigger", "question shown:" and "accepted:" lines.
- [ ] With the log window open, press Ctrl+C.
  Check: the text is selected and Ctrl+C copies all of it.
  Log: none; on screen only.
- [ ] With the log window open, press Esc.
  Check: the window closes.
  Log: none; on screen only.
- [ ] Enter `/cvn log clear` and cancel.
  Check: the entries stay.
  Log: none; on screen only.
- [ ] Enter `/cvn log clear` and confirm.
  Check: the entries are gone.
  Log: none; on screen only.
- [ ] Enter `/cvn debug off`.
  Check: the log stops recording.
  Log: "debug log turned off" is the last line.

## 8. Safety

- [ ] Enter a dungeon, then leave it.
  Check: inside, no error, no question and no waypoint. After leaving, normal behavior returns.
  Log: "instance: <old> -> <new>" lines and, inside, "profession check skipped: in an instance".
- [ ] Enter a battleground, then leave it.
  Check: inside, no error, no question and no waypoint. After leaving, normal behavior returns.
  Log: "instance: <old> -> <new>" lines.
- [ ] Optional. Enable TomTom after a login without it, then enter `/reload`.
  Check: no error.
  Log: none; on screen only.
- [ ] Optional. Enable WaypointUI after a login without it, then enter `/reload`.
  Check: no error.
  Log: none; on screen only.
- [ ] Optional, on a client where a game function is missing.
  Check: the addon keeps working.
  Log: "game call failed: <name>" once.

## 9. Languages

- [ ] Use a non-English client.
  Check: the addon sentences are in English. Spell and zone names are the game's.
  Log: none; on screen only.
- [ ] Install a translation file (see docs/localization.md). Enter `/cvn`.
  Check: the output shows the translation.
  Log: none; on screen only.
- [ ] With the translation file installed, trigger a question.
  Check: the question shows the translation.
  Log: none; on screen only.
- [ ] With the translation file installed, open the settings page.
  Check: the page shows the translation.
  Log: none; on screen only.

## 10. Buying ammo

Use a Hunter with a bow (or a gun) and a quiver (or ammo pouch).

- [ ] With `/cvn buy auto` (the default) and a partly filled quiver, open an ammo vendor.
  Check: the addon buys until the quiver is full with no dialog. One chat line gives the count and the cost, and the count matches the room left.
  Log: "ammo buy:" lines with the item, price, space and money.
- [ ] Open an ammo vendor with a full quiver.
  Check: the addon buys nothing.
  Log: "ammo buy: less than one purchase of room".
- [ ] Open an ammo vendor with no quiver or ammo pouch.
  Check: the addon buys nothing.
  Log: "ammo buy: less than one purchase of room".
- [ ] Open an ammo vendor with a thrown weapon equipped.
  Check: the addon buys nothing.
  Log: "ammo buy: no bow, crossbow or gun equipped, or its ammo cannot be read".
- [ ] Open a vendor that sells no ammo.
  Check: the addon buys nothing and stays silent.
  Log: "ammo buy: merchant sells no".
- [ ] Enter `/cvn buy ask`. Open an ammo vendor and do not click.
  Check: a dialog shows the count and the price. Nothing is bought.
  Log: "ammo buy:" plan line.
- [ ] With the dialog open, click **No**.
  Check: nothing is bought.
  Log: "ammo buy:" plan line.
- [ ] With the dialog open, click **Yes**.
  Check: the addon buys the ammo.
  Log: "ammo buy:" plan line.
- [ ] Enter `/cvn buy off`. Open an ammo vendor.
  Check: the addon buys nothing.
  Log: "ammo buy: off".
- [ ] At a vendor that sells several arrow grades, enter `/cvn arrows best` and open the vendor.
  Check: it buys the highest grade your level allows.
  Log: "ammo buy: best item".
- [ ] Enter `/cvn arrows cheapest` and open the same vendor.
  Check: it buys the cheapest grade.
  Log: "ammo buy: cheapest item".
- [ ] Enter `/cvn arrows equipped` and open the same vendor.
  Check: it buys the ammo in your ammo slot.
  Log: "ammo buy: equipped item".
- [ ] Set the arrow and the bullet setting to different values. Open an ammo vendor with a bow equipped.
  Check: the addon follows the arrow setting.
  Log: "ammo buy:" line naming the arrow item.
- [ ] With the same settings, open an ammo vendor with a gun equipped.
  Check: the addon follows the bullet setting.
  Log: "ammo buy:" line naming the bullet item.
- [ ] Use `equipped` with ammo this vendor does not sell.
  Check: the addon buys nothing and a chat line says so.
  Log: "ammo buy: no <kind> offer for mode equipped".
- [ ] Have too little gold for a full purchase.
  Check: the addon buys only what you can afford and the chat line says so.
  Log: "ammo buy: cannot afford one purchase".
- [ ] Have almost no gold.
  Check: chat says "You cannot afford any ammo here."
  Log: "ammo buy: cannot afford one purchase".
- [ ] Use a quiver that holds a different grade of ammo.
  Check: the addon does not overbuy.
  Log: "ammo buy:" line showing the space.
- [ ] Open the settings page.
  Check: the Arrows and Bullets dropdowns match `/cvn`.
  Log: none; on screen only.

## 11. Targets on another map

Stand near a zone edge, where the closest vendor is across the border. Type `/cvn test sell` (or `/cvn test repair`) to repeat the question.

- [ ] Trigger the question where a vendor on another map is closer than the vendor on your map.
  Check: the question lists both vendors, each with zone and distance in yards. It has three buttons.
  Log: "question shown: ".
- [ ] Check the order of the buttons with `/cvn prefer map` (the default).
  Check: the first button is the vendor on your map.
  Log: "question shown: ".
- [ ] Click the first button.
  Check: the waypoint goes to the vendor on your map.
  Log: "accepted: <vendor> via <provider>".
- [ ] Repeat the question, then click the second button.
  Check: the waypoint goes to the closer vendor on the other map.
  Log: "accepted: <vendor> via <provider>".
- [ ] Repeat the question, then click Cancel.
  Check: no waypoint is set.
  Log: "question declined: ".
- [ ] Repeat the question, then press Esc.
  Check: no waypoint is set.
  Log: "question declined: ".
- [ ] Type `/cvn prefer distance` and trigger the question.
  Check: the closer vendor is now the first button.
  Log: "question shown: ".
- [ ] Stand where the closest vendor is on your own map and trigger the question.
  Check: you get the plain Yes / No question, naming that vendor.
  Log: "question shown: ".
- [ ] Stand on a map with no known vendor and trigger the question.
  Check: you get the plain Yes / No question, naming the closest vendor on another map.
  Log: "question shown: ".
- [ ] Type `/cvn choice auto` and trigger the question with `prefer map`.
  Check: no question opens. The waypoint goes at once to the vendor on your map.
  Log: "auto: <vendor> (npc <id>) chosen from two candidates".
- [ ] With `/cvn choice auto`, type `/cvn prefer distance` and trigger the question.
  Check: no question opens. The waypoint goes at once to the closer vendor.
  Log: "auto: <vendor> (npc <id>) chosen from two candidates".
- [ ] Trigger an automatic waypoint with two candidates.
  Check: one chat line and the same on-screen text name the target with zone and distance in yards, and the other choice.
  Log: "auto: <vendor> (npc <id>) chosen from two candidates".
- [ ] Trigger an automatic waypoint.
  Check: the notification sound plays once.
  Log: none; on screen only.
- [ ] Trigger an automatic waypoint and watch the on-screen text.
  Check: the text stays about five seconds, high and centered, then goes.
  Log: none; on screen only.
- [ ] Set a second waypoint while the on-screen text shows.
  Check: the new text replaces the old one and the time restarts.
  Log: none; on screen only.
- [ ] Cause a game error, for example try an action that fails.
  Check: the error text looks the same and lasts as long as usual.
  Log: none; on screen only.
- [ ] Type `/cvn notice off` and trigger an automatic waypoint.
  Check: the on-screen text does not show. The chat line stays.
  Log: none; on screen only.
- [ ] Type `/cvn notice on` and trigger an automatic waypoint.
  Check: the on-screen text comes back.
  Log: none; on screen only.
- [ ] Type `/cvn notice off`, then open the settings page.
  Check: the notice checkbox is cleared.
  Log: none; on screen only.
- [ ] With `/cvn choice auto`, trigger with only one candidate.
  Check: the single candidate gets a waypoint at once.
  Log: "auto: ".
- [ ] With `/cvn choice auto`, trigger while in combat.
  Check: no waypoint is set.
  Log: "trigger" shows combat=true.
- [ ] With a profession near its cap, trigger the trainer question under `/cvn choice ask`.
  Check: the trainer question opens, as it does for vendors.
  Log: "question shown: trainer for <profession>".
- [ ] With a profession near its cap, trigger the trainer question under `/cvn choice auto`.
  Check: no question opens. The waypoint goes at once to the trainer.
  Log: "auto: ".
- [ ] Stand in a city and trigger the question.
  Check: the vendor on "your map" is a vendor inside the city.
  Log: "question shown: ".
- [ ] Open the settings page.
  Check: the two target dropdowns show the same values as `/cvn choice` and `/cvn prefer`.
  Log: none; on screen only.
- [ ] Type `/cvn`.
  Check: it shows both target settings.
  Log: none; on screen only.
- [ ] Type `/cvn log`.
  Check: the report lists the target choice settings and which target the addon showed or set.
  Log: "accepted: " or "auto: ".

## 12. Reagents

Use a character whose class has reagents: mage, rogue, priest, paladin, shaman or druid. This section checks the spell and item IDs in the real client.

- [ ] Type `/cvn`.
  Check: it shows "Reagents: on, trigger at 5 or fewer".
  Log: none; on screen only.
- [ ] Type `/cvn log`.
  Check: the report lists the reagents you expect for the spells you know.
  Log: `reagents: on, class <class>, threshold 5, watching: ..., switched off: none`.
- [ ] Optional, a low-level mage who does not know Portals. Type `/cvn log`.
  Check: the report does not list a reagent for a spell you do not know (no Rune of Portals).
  Log: `reagents: ... watching:`.
- [ ] Optional, the same mage. Learn Portals, then type `/cvn log` without a reload.
  Check: the report now lists Rune of Portals.
  Log: `reagents: ... watching:`.
- [ ] Use a druid who knows Rebirth rank 3. Type `/cvn log`.
  Check: the report lists Ashwood Seed only, not the rank 1 and 2 seeds.
  Log: `reagents: ... watching:`.
- [ ] Use a priest who knows Prayer of Fortitude rank 2. Type `/cvn log`.
  Check: the report lists Sacred Candle, not Holy Candle.
  Log: `reagents: ... watching:`.
- [ ] Carry 6 Runes of Teleportation.
  Check: no question opens.
  Log: no "question shown: reagent" line.
- [ ] Cast Teleport until 5 Runes of Teleportation are left.
  Check: one question opens. It names the reagent, the count and "sells <reagent>" for a vendor that sells it.
  Log: "question shown: reagent Rune of Teleportation".
- [ ] Click **Yes** on that question.
  Check: the waypoint is set to that vendor.
  Log: "accepted: <vendor> via <provider>".
- [ ] Put reagents in the bank, then type `/cvn log`.
  Check: the report does not count the banked reagents.
  Log: `reagents: ... watching:` shows the count without them.
- [ ] Open a reagent question, then open a vendor that sells the reagent.
  Check: the question and the waypoint go away.
  Log: "merchant window opened" and "request released: reagent".
- [ ] Open a reagent question, then open any other merchant.
  Check: the question and the waypoint go away.
  Log: "merchant window opened" and "request released: reagent".
- [ ] Get two reagents low, for example Arcane Powder and Rune of Teleportation.
  Check: one question shows. The second appears only after you answer it.
  Log: one "question shown: reagent" line, the second after the answer.
- [ ] Have a reagent low and gear worn below the repair threshold.
  Check: the repair question comes first, then the reagent question.
  Log: "question shown: " lines in that order.
- [ ] Have a reagent low and full bags.
  Check: the reagent question comes before the sell question.
  Log: "question shown: " lines in that order.
- [ ] Type `/cvn reagent 10`, then `/cvn`.
  Check: `/cvn` shows the trigger at 10 or fewer.
  Log: `reagents: ... threshold 10`.
- [ ] Type `/cvn reagent 10`, then open the settings page.
  Check: the reagent slider shows 10.
  Log: `reagents: ... threshold 10`.
- [ ] Type `/cvn reagents`.
  Check: the list shows your class reagents, all on.
  Log: none; on screen only.
- [ ] Type `/cvn reagent off arcane powder` and get Arcane Powder low.
  Check: no question opens for that reagent.
  Log: `reagents: ... switched off: Arcane Powder`.
- [ ] Type `/cvn reagent on arcane powder` and get Arcane Powder low.
  Check: the question comes back.
  Log: "question shown: reagent ".
- [ ] Open the settings page.
  Check: it lists only your class reagents, with checkboxes that match `/cvn reagents`.
  Log: none; on screen only.
- [ ] Clear "Reagents" in Warnings and get a reagent low.
  Check: no reagent question opens.
  Log: no "question shown: reagent" line.
- [ ] Use a hunter, a warrior or a warlock (any one). Type `/cvn reagents`.
  Check: the settings page shows no reagent checkboxes, and the command says there are none.
  Log: `reagents: ... watching: none`.
- [ ] Use a hunter, a warrior or a warlock (any one) and play normally.
  Check: no reagent question ever appears.
  Log: `reagents: ... watching: none`.
- [ ] Type `/cvn test reagent`.
  Check: it asks about the first watched reagent, whatever the count.
  Log: "test command: reagent".
- [ ] Type `/cvn test reagent` with nothing watched.
  Check: chat says nothing is watched.
  Log: "test command: reagent".
- [ ] Open a reagent vendor you have not opened before (a druid or priest supplier), then get that reagent low.
  Check: the question can name the new vendor.
  Log: "question shown: reagent " names that vendor.
- [ ] Open a shipped reagent vendor, then get that reagent low.
  Check: the question can still name the shipped vendor.
  Log: "question shown: reagent " names that vendor.
- [ ] Type `/cvn choice auto` and get a reagent low.
  Check: the waypoint is set at once. Chat and screen read "Navigating to <vendor> (<zone>, N yards) to buy <reagent>."
  Log: "auto: ".
- [ ] Trigger an automatic waypoint for ammo.
  Check: the text says "... to buy ammo."
  Log: "auto: ".
- [ ] Trigger an automatic waypoint for repair.
  Check: the text says "... to repair your gear."
  Log: "auto: ".
- [ ] Trigger an automatic waypoint for selling.
  Check: the text says "... to sell items and free bag space."
  Log: "auto: ".
- [ ] Trigger an automatic waypoint for a trainer.
  Check: the text says "... to train <profession>."
  Log: "auto: ".
- [ ] Pick 5 to 10 shipped reagent vendors in cities and camps. Set the waypoint, go there and open each.
  Check: each vendor stands where the waypoint says and sells the reagent.
  Log: "merchant window opened".

No in-game check, unit tests only: no class has both ammo and reagents (ammo versus reagents priority).

## 13. Status window, instances and auction house

The addon decides these from game calls the fake-API tests cannot reach. Write down the client build.

### 13.1 Settings layout

- [ ] Open settings with a slash command.
  Check: the settings tree opens (standalone fallback in section 20).
  Log: none; on screen only.
- [ ] Open settings with the cog.
  Check: it opens the same ordered tree.
  Log: none; on screen only.
- [ ] Open settings from Options > AddOns.
  Check: it opens the same ordered tree.
  Log: none; on screen only.
- [ ] Open the Home page.
  Check: it keeps all warning switches and the bag, durability and profession thresholds.
  Log: none; on screen only.
- [ ] Open the Appearance page.
  Check: it has a Status window section. Lock position comes first, then independent scale, background and text controls, a color picker action and six group visibility selectors (Ammo, Reagents, Supplies, Bags, Durability, Professions).
  Log: none; on screen only.
- [ ] Use a class without ammo or reagents.
  Check: those groups are disabled with an explanation, and their item controls do not act.
  Log: none; on screen only.

No in-game check, unit tests only: saved values survive the reorganization and disabled controls keep their values.

### 13.2 The window

- [ ] Set every row to the default and have nothing low.
  Check: the status window is not shown.
  Log: none; on screen only.
- [ ] Bring your bags to the threshold.
  Check: the status window appears with Bag space in red.
  Log: none; on screen only.
- [ ] Free your bags after that.
  Check: the window hides and never shows empty.
  Log: none; on screen only.
- [ ] Type `/cvn hud row bags always`.
  Check: Bag space shows, and is not red above the threshold.
  Log: `status window: ... rows: bags: always` in `/cvn log`.
- [ ] Type `/cvn hud row bags never` and get bags low.
  Check: Bag space stays hidden.
  Log: `status window: ... rows: bags: never` in `/cvn log`.
- [ ] Type `/cvn hud row bags low`.
  Check: Bag space follows the default again.
  Log: `status window: ... rows: ` in `/cvn log`.
- [ ] Type `/cvn hud row Professions always` (any case).
  Check: every profession line shows.
  Log: `status window: ... rows: `.
- [ ] Type `/cvn hud row reagents never`, then `/cvn`.
  Check: every reagent line hides, and `/cvn` lists the changed groups.
  Log: `status window: ... rows: `.
- [ ] Use a character with two professions. Change the Professions dropdown on the settings page.
  Check: both profession lines move together.
  Log: `status window: ... rows: professions: ...`.
- [ ] Optional, a hunter with a ranged weapon. Look at the ammo row.
  Check: it shows Arrows or Bullets, and the count matches your bags.
  Log: none; on screen only.
- [ ] Look at a reagent row.
  Check: it shows a count that matches your bags.
  Log: none; on screen only.
- [ ] Look at a profession row near its cap.
  Check: it shows skill/max.
  Log: none; on screen only.
- [ ] Look at the Bag space and Durability rows.
  Check: the numbers match your bags and gear.
  Log: none; on screen only.
- [ ] Use a warlock. Set Reagents to Always.
  Check: the Soul Shards row shows, and the count matches your bags.
  Log: none; on screen only.
- [ ] Use a rogue. Set Reagents to Always.
  Check: the Blinding Powder row shows, and the count matches your bags.
  Log: none; on screen only.
- [ ] Use a mage. Set Reagents to Always.
  Check: the Conjured Food and Water rows show, and each count sums all ranks.
  Log: none; on screen only.
- [ ] Use a warlock. Set Reagents to Only when low.
  Check: the Soul Shards row is hidden and never red.
  Log: none; on screen only.
- [ ] Buy or use ammo.
  Check: the ammo row updates.
  Log: none; on screen only.
- [ ] Use a reagent.
  Check: the reagent row updates.
  Log: none; on screen only.
- [ ] Sell items.
  Check: the Bag space row updates.
  Log: none; on screen only.
- [ ] Repair your gear.
  Check: the Durability row updates.
  Log: none; on screen only.
- [ ] Get a skill-up.
  Check: the profession row updates.
  Log: none; on screen only.
- [ ] Drag the title.
  Check: the window moves.
  Log: `ClosestVendorCharDB.hud` holds the position.
- [ ] Drag the title, then type `/reload`.
  Check: the window stays where you put it.
  Log: `ClosestVendorCharDB.hud` holds the position.
- [ ] Drag the title, then restart the game.
  Check: the window stays where you put it.
  Log: `ClosestVendorCharDB.hud` holds the position.
- [ ] Shift-drag anywhere on the window.
  Check: the window moves.
  Log: none; on screen only.
- [ ] Drag a row without Shift.
  Check: the window does not move.
  Log: none; on screen only.
- [ ] Release a drag over a row.
  Check: the release does not click the row.
  Log: none; on screen only.
- [ ] Type `/cvn hud lock`, then drag the title and Shift-drag.
  Check: neither drag moves the window.
  Log: none; on screen only.
- [ ] Type `/cvn hud unlock`, then drag the title and Shift-drag.
  Check: both drags move the window again.
  Log: none; on screen only.
- [ ] Move the window, then type `/cvn hud reset`.
  Check: the window returns to its default position.
  Log: "status window position reset".
- [ ] Type `/cvn hud scale 150`.
  Check: the window is 1.5 times larger.
  Log: `status window: ... scale 150%` in `/cvn log`.
- [ ] Type `/cvn hud scale 150`, then open the settings page.
  Check: the scale slider shows 150.
  Log: `status window: ... scale 150%` in `/cvn log`.
- [ ] Move the window far to a corner, then change the UI scale in Video settings.
  Check: the window stays on screen, or `/cvn hud reset` brings it back.
  Log: none; on screen only.
- [ ] Click the cog button.
  Check: the Closest Vendor Home page opens.
  Log: none; on screen only.
- [ ] Look at the cog button.
  Check: it shows a cog. The fallback is an asterisk, never a blank or a missing-texture square. The window background shows with no error message.
  Log: none; on screen only.
- [ ] Under `/cvn choice ask`, click a low Bag space row.
  Check: the waypoint goes to the closest vendor at once with no question. Chat and screen say "Navigating to ... to sell ...".
  Log: "direct pin: <kind>".
- [ ] Under `/cvn choice auto`, click a low Bag space row.
  Check: the waypoint goes to the closest vendor at once, the same as in ask mode.
  Log: "direct pin: <kind>".
- [ ] In combat, click a low Bag space row.
  Check: the waypoint goes to the closest vendor at once.
  Log: "direct pin: <kind>".
- [ ] Optional, a hunter. Click a low ammo row.
  Check: the waypoint goes at once to the closest vendor. Chat and screen say "Navigating to ... to buy ammo."
  Log: "direct pin: <kind>".
- [ ] Click a low reagent row.
  Check: the waypoint goes at once to the closest vendor. Chat and screen say "Navigating to ... to buy ...".
  Log: "direct pin: <kind>".
- [ ] Click a low Durability row.
  Check: the waypoint goes at once to the closest vendor. Chat and screen say "Navigating to ... to repair ...".
  Log: "direct pin: <kind>".
- [ ] Click a profession row within its threshold.
  Check: the waypoint goes at once to the closest trainer. Chat and screen say "Navigating to ... to train ...".
  Log: "direct pin: <kind>".
- [ ] Open a question, then click a row.
  Check: the question closes and the waypoint is set. The addon does not ask again.
  Log: "direct pin: ". The line "request put back: <kind> (a click replaced it)" does not appear.
- [ ] After a row click, trigger an unrelated trigger.
  Check: the waypoint stays.
  Log: none; on screen only.
- [ ] After a row click, open a merchant window.
  Check: the waypoint clears.
  Log: "merchant window opened".
- [ ] Click a display-only row.
  Check: nothing happens.
  Log: none; on screen only.
- [ ] Click a profession row with no known trainer.
  Check: chat says no trainer is known.
  Log: "no known trainer for <profession>".

### 13.3 Opacity and color

- [ ] Fresh install: type `/cvn`.
  Check: it says "background 80% of color #000000, text and icons 100%". The window background is pure black at 80 percent.
  Log: report header "status window: ..., opacity 80%, color #000000, text opacity 100%".
- [ ] Type `/cvn hud opacity 0`, then `/cvn hud color #ffffff`.
  Check: only the title, the cog and the line text show. There is no fill, border or faint rectangle, even with white selected.
  Log: none; on screen only.
- [ ] With opacity 0, drag the window by its title and click a line.
  Check: drag and click still work.
  Log: none; on screen only.
- [ ] Open the settings page and move the text opacity slider to its lowest.
  Check: the slider stops at 20.
  Log: none; on screen only.
- [ ] Type `/cvn hud textopacity 40`, then cause a line that was not shown before.
  Check: the title, the cog and every line are dim, including the new line. The background keeps its own opacity.
  Log: none; on screen only.
- [ ] Open Appearance > Status window > Background color, change the wheel and confirm.
  Check: the background updates live and keeps the color.
  Log: none; on screen only.
- [ ] Open the same color wheel, change it and cancel.
  Check: the background returns to the original color.
  Log: none; on screen only.
- [ ] Type `/cvn hud color`, change the wheel and cancel.
  Check: the background returns to the original color.
  Log: none; on screen only.
- [ ] Optional, on a client where the game color picker is missing. Open the Background color page.
  Check: the page explains that the picker is missing and shows no dead control.
  Log: none; on screen only. The report names AceConfig availability and the game picker; include it in client bug reports.
- [ ] Optional, on the same client. Type `/cvn hud color #101820`, then `/cvn hud color black`.
  Check: the color changes, then black restores black.
  Log: none; on screen only.
- [ ] OLED check: set opacity 0 and text opacity 40, then leave the window over a dark area for a minute.
  Check: nothing static is bright. There is no border and no fixed fill.
  Log: none; on screen only.
- [ ] Show one low line in the window.
  Check: the low line has red text, a red warning symbol and a visible Low label. Lines that are not low use neutral text.
  Log: none; on screen only.
- [ ] Set opacity, color and text opacity, type `/reload`, then `/cvn log`.
  Check: the opacity, color and text opacity values survive.
  Log: report header "status window: ..., opacity N%, color #rrggbb, text opacity N%".

### 13.4 Instances

- [ ] Zone into a dungeon.
  Check: nothing changes on screen.
  Log: "instance: none -> party".
- [ ] Zone into a raid.
  Check: nothing changes on screen.
  Log: "instance: none -> raid".
- [ ] Zone into a battleground (Warsong Gulch, Arathi Basin or Alterac Valley).
  Check: nothing changes on screen.
  Log: "instance: none -> pvp".
- [ ] Leave the instance and go outdoors.
  Check: nothing changes on screen.
  Log: "instance: ... -> none".
- [ ] Fill your bags to the threshold inside a battleground.
  Check: no sell question shows.
  Log: no "question shown: " line while inside.
- [ ] Leave the battleground with full bags.
  Check: the sell question shows once.
  Log: "trigger ..." line for bags after the "instance: pvp -> none" line.
- [ ] Wear gear below the repair threshold in a dungeon, then leave the dungeon.
  Check: the repair question shows once after you leave.
  Log: "trigger repair ..." line after the "instance: party -> none" line.
- [ ] Walk outside, enter a dungeon and click a row.
  Check: chat says the waypoint search starts from your last position outside.
  Log: "row click: ..." line.
- [ ] Type `/cvn anchor last` and click a row inside a dungeon.
  Check: chat says the search starts from your last position outside.
  Log: "row click: ..." line.
- [ ] Type `/cvn anchor hearth` and click a row inside a dungeon.
  Check: chat says the search starts from your hearthstone point.
  Log: "row click: ..." line.
- [ ] Click a row inside a battleground with either anchor setting.
  Check: the search starts from your last outdoor position.
  Log: "row click: ..." line.
- [ ] Optional, with TomTom installed, click a row inside an instance.
  Check: if TomTom refuses the waypoint, chat says so.
  Log: none; on screen only.

### 13.5 Anchors and the hearthstone point

- [ ] On WoW Forever, type `/dump GetBindLocation()`.
  Check: chat prints a place name.
  Log: none; on screen only.
- [ ] On Classic Era, type `/dump GetBindLocation()`.
  Check: chat prints a place name.
  Log: none; on screen only.
- [ ] Bind your hearthstone at a new inn, then relog or change zone.
  Check: nothing changes on screen. The reviewer confirms the new hearthstone point from the log, written only when the name changed.
  Log: "hearthstone point learned: <inn>".
- [ ] On a new character with no known hearthstone point, type `/cvn anchor hearth` and enter a dungeon.
  Check: the addon searches from your last position outside.
  Log: none; on screen only.
- [ ] Type `/cvn anchor hearth`, then `/cvn anchor last`.
  Check: the "Search from, inside an instance" dropdown shows the same choice after each command.
  Log: report line "instance anchor: ...".

### 13.6 Auction house

- [ ] Fresh install: type `/cvn ah on`, then `/cvn ah off`.
  Check: the "Route to the auction house" checkbox follows each command.
  Log: report line "auction house routing: off".
- [ ] Turn routing on, stand near a major city auction house and click a tradeable row (a reagent or Bag space).
  Check: the waypoint goes to the auctioneer.
  Log: "direct pin: auctioneer <name> (npc N) is closer".
- [ ] With routing on, click a tradeable row from a spot where a vendor is closer than the auction house.
  Check: the waypoint goes to the vendor.
  Log: no "direct pin: auctioneer" line.
- [ ] With routing on, click a row inside an instance.
  Check: the waypoint goes to a vendor, not the auction house.
  Log: no "direct pin: auctioneer" line.
- [ ] WoW Forever only. Open an auction house you have never opened, then type `/cvn log`.
  Check: the auction house window opens. The reviewer confirms the addon learned it.
  Log: report line "auctioneers: N shipped, N learned" with learned one higher; `ClosestVendorDB.auctioneers` has the auctioneer.
- [ ] Type `/reload`, then `/cvn log`.
  Check: nothing changes on screen. The reviewer confirms the learned auctioneer survives.
  Log: report line "auctioneers: ... learned" keeps the same count.
- [ ] Walk to a shipped auctioneer (any of the 28 with coordinates) and click a tradeable row with routing on.
  Check: the waypoint points at where the auctioneer stands.
  Log: "direct pin: auctioneer <name> (npc N) is closer".

### 13.7 Buying reagents

Use a mage who knows Arcane Brilliance and Teleport, and a reagent vendor.

- [ ] Fresh install: type `/cvn`, then open a reagent vendor.
  Check: chat says "Reagent buying: off, asks first, up to 20 of each". The addon buys nothing.
  Log: report line "reagent buying: off, asks first, up to 20 of each"; "reagent buy: off".
- [ ] Open the settings page, Reagents.
  Check: below the reagent checkboxes are Buy reagents, Ask before buying reagents and an amount slider (0 to 100, default 20).
  Log: none; on screen only.
- [ ] On the Reagents page, turn Buy reagents off.
  Check: the other two controls are greyed out. Turning it on makes them usable again.
  Log: none; on screen only.
- [ ] Type `/cvn reagentbuy on`, then `/cvn reagentbuy ask`, then `/cvn reagentbuy 35`.
  Check: the checkbox, the Ask checkbox and the slider follow each command.
  Log: report line "reagent buying: ...".
- [ ] As a Hunter, Warrior or Warlock, open the settings page, Reagents.
  Check: all three controls are greyed out with "Your class does not use reagents."
  Log: none; on screen only.
- [ ] As a Hunter, Warrior or Warlock, type `/cvn reagentbuy on`.
  Check: chat says "Your class does not use reagents."
  Log: none; on screen only.
- [ ] Type `/cvn reagentbuy on` and `/cvn reagentbuy auto`. Carry 7 Arcane Powder and 0 Runes of Teleportation. Open the vendor on WoW Forever.
  Check: you end with exactly 20 of each. One chat line names both reagents with counts and the cost, and the bag counts and money spent match it.
  Log: "reagent buy: target 20, money ..., plan: ..., cost ..., short: ..." once.
- [ ] Repeat the same purchase on Classic Era.
  Check: you end with exactly 20 of each, the same as on WoW Forever.
  Log: "reagent buy: target 20, money ..., plan: ..., cost ..., short: ..." once.
- [ ] After that purchase, close the vendor and open it again.
  Check: the addon buys nothing and shows no chat line.
  Log: no new "reagent buy: ... plan:" line.
- [ ] Type `/cvn reagentbuy ask`. Open the vendor and do not click.
  Check: a dialog lists the reagents, the counts and the total price. Nothing is bought.
  Log: "reagent buy: target ..., plan: ..." line once.
- [ ] With the dialog showing, click **No** or press Esc.
  Check: the addon buys nothing.
  Log: no purchase line follows.
- [ ] Open the vendor again and click **Yes**.
  Check: the addon buys the listed reagents.
  Log: "reagent buy: target ..., plan: ..." line.
- [ ] As a Rogue with a bow, type `/cvn buy ask`. Open a vendor that sells arrows and Flash Powder.
  Check: both dialogs show. Neither replaces the other.
  Log: "ammo buy: ..." and "reagent buy: ..." lines.
- [ ] Type `/cvn reagentbuy 0`, then open the vendor.
  Check: the addon buys nothing and shows no dialog.
  Log: "reagent buy: amount is 0".
- [ ] Have less gold than one reagent costs, then open the vendor.
  Check: chat says "You cannot afford any reagents here."
  Log: "reagent buy: target ..., short: ..." line.
- [ ] Have gold for only part of the list, then open the vendor.
  Check: the addon buys that part in table order, and the chat line ends with "(all you could afford)".
  Log: "reagent buy: target ..., plan: ..." line.
- [ ] Fill ordinary bags with no free slot and no partial stack of the reagent (quivers, soul bags and profession bags do not count). Open the vendor.
  Check: chat says "Your bags have no room for reagents."
  Log: "reagent buy: target ..., plan: ..." line.
- [ ] Free one bag slot, then open the vendor.
  Check: the addon buys what fits and the chat line ends with "(all that fits in your bags)".
  Log: "reagent buy: target ..., plan: ..." line.
- [ ] Keep a partial stack of the reagent in a full bag, then open the vendor.
  Check: the addon tops up that stack.
  Log: "reagent buy: target ..., plan: ..." line.
- [ ] Turn off one reagent on the Reagents page, then open the vendor.
  Check: the addon does not buy that reagent.
  Log: "reagent buy: target ..., plan: ..." line without that item.
- [ ] As a low-level mage, open a vendor that sells Rune of Portals, a reagent for a spell you do not know.
  Check: the addon does not buy it. It never buys Soul Shards, Blinding Powder or conjured items.
  Log: "reagent buy: target ..., plan: ..." line without those items.
- [ ] As a Rogue, type `/cvn buy auto` and `/cvn reagentbuy auto`. Have gold for the ammo only, then open a vendor that sells both.
  Check: the addon buys the ammo and no Flash Powder.
  Log: "ammo buy: ..." then "reagent buy: ... short: ..." line.
- [ ] Optional. Open a vendor with the reagent dialog showing, then close the vendor window before you answer.
  Check: the dialog stays, and **Yes** buys nothing.
  Log: "reagent buy: purchase dropped: the merchant window changed" or "reagent buy: bags or money unknown at Yes".

## 14. Food, water and pet food

Use `/cvn` to check the line "Supplies: food on (5), water on (5), pet food on (5), healthstone reminder on".

### 14.1 Food and water

- [ ] As a Warrior, carry 5 or fewer food items (cooked, looted or conjured all count). Type `/cvn test food`.
  Check: the addon asks about the closest vendor that sells food.
  Log: "question shown: supply ..., <vendor> (npc N), N left".
- [ ] As a Warrior, type `/cvn test water`.
  Check: chat says "Your class does not use water." No question shows.
  Log: "test command: ...".
- [ ] As a Rogue, type `/cvn test water`.
  Check: chat says "Your class does not use water." No question shows.
  Log: "test command: ...".
- [ ] As a Priest, carry 5 or fewer drinks.
  Check: the addon asks about the closest vendor that sells drink.
  Log: "question shown: supply ..., <vendor> (npc N), N left".
- [ ] Answer Yes to the drink question.
  Check: the closest drink vendor gets pinned. No sell question follows.
  Log: "accepted: <vendor> via <provider>".
- [ ] Type `/cvn choice auto` and lower food again.
  Check: one chat line and the on-screen notice show, like other triggers. No question shows.
  Log: "accepted: <vendor> via <provider>" with no "question shown" line.

### 14.2 Pet food

- [ ] As a Hunter with no pet out, type `/cvn test petfood`.
  Check: chat says "There is no pet to feed." No question shows.
  Log: "test command: ...".
- [ ] As a Hunter, call a pet and let its food run low.
  Check: the addon asks about the closest vendor that sells food your pet eats.
  Log: "question shown: supply ..., <vendor> (npc N), N left".
- [ ] Dismiss the pet, then call a pet with a different diet.
  Check: with the pet dismissed there is no pet food warning. With the new pet, the warning counts what that pet eats.
  Log: none; on screen only.
- [ ] Use a pet that eats only meat or fish in a place where no known vendor sells it.
  Check: one chat line shows and no dialog.
  Log: none; on screen only.
- [ ] As a Hunter, trigger the pet food question for a pet.
  Check: the question names the diets that the pet family eats.
  Log: "question shown: supply ...".

### 14.3 Reminders

- [ ] As a Mage who knows Conjure Food, type `/cvn notice on`, then carry 5 or fewer food items.
  Check: chat says "You are low on food (2 left). Cast Conjure Food to make more." and the same text shows on screen. The addon asks about no vendor.
  Log: "reminder: food (N)".
- [ ] As a Mage who knows Conjure Water, carry 5 or fewer drinks.
  Check: chat says the same kind of line for water, also on screen. The addon asks about no vendor.
  Log: "reminder: water (N)".
- [ ] As that Mage, let food and drink both run low at once.
  Check: two chat lines show and one sound plays.
  Log: "reminder: food (N)" and "reminder: water (N)".
- [ ] Stay low on food, then raise the count above the threshold and lower it again.
  Check: the reminder shows once while you stay low, and shows again after the second drop.
  Log: "reminder: food (N)" once per drop.
- [ ] As a Mage without the spell, carry 5 or fewer food items.
  Check: the addon asks about a vendor like other classes.
  Log: "question shown: supply ...".
- [ ] As a Warlock who knows Create Healthstone, carry no healthstone.
  Check: chat says "You have no healthstone. Cast Create Healthstone to make one."
  Log: "reminder: healthstone (0)".
- [ ] As that Warlock, carry a healthstone of any rank.
  Check: no reminder shows.
  Log: no "reminder: healthstone" line.
- [ ] As a Mage, type `/cvn test remind`.
  Check: a test reminder shows and a sound plays.
  Log: "reminder: test".
- [ ] As a Warlock, type `/cvn test remind`.
  Check: a test reminder shows and a sound plays.
  Log: "reminder: test".
- [ ] As a Warrior, type `/cvn test remind`.
  Check: chat says "This is a test reminder. Only mages and warlocks get real ones." and a sound plays.
  Log: "reminder: test".
- [ ] In combat, type `/cvn test remind`.
  Check: the sound plays in combat.
  Log: "reminder: test".
- [ ] Start a reminder condition in combat or in an instance.
  Check: the reminder waits, then shows when combat or the instance ends. The sound plays then, once, and not again while the reminder stays shown.
  Log: "reminder: food (N)" after the combat or instance ends.
- [ ] Type `/cvn sound`.
  Check: chat lists the current sound and the choices whisper, ping, invite, ready and none.
  Log: report line "supplies: ..., notification sound <name>".
- [ ] Type `/cvn sound ping`, `/cvn sound invite` and `/cvn sound ready`, one at a time.
  Check: each sound plays at once, and `/cvn` shows the chosen name.
  Log: report line "supplies: ..., notification sound <name>".
- [ ] Type `/cvn sound none`, then `/cvn test remind`.
  Check: nothing plays, and the reminder still shows in chat.
  Log: "reminder: test".
- [ ] As a Warrior, let a vendor question show for food, then say Yes.
  Check: no notification sound when the question shows. The map pin makes its own sound when you say Yes.
  Log: "question shown: supply ..." then "accepted: ...".

### 14.4 Settings and commands

- [ ] As a Warlock, open the settings page, Supplies.
  Check: Supplies sits after Reagents. It shows **Healthstone reminder** and the rows your class can use. It has no sound control.
  Log: none; on screen only.
- [ ] As a Warrior, open the settings page, Supplies.
  Check: it shows only rows a Warrior can use, and no **Healthstone reminder**.
  Log: none; on screen only.
- [ ] Open Appearance, Sound tab, and pick each choice in the **Notification sound** dropdown.
  Check: the dropdown offers Whisper ping, Minimap ping, Group invite, Ready check and None. Each choice plays at once.
  Log: none; on screen only.
- [ ] Type `/cvn ammo off`, then lower food.
  Check: food questions and reminders still work, and the Supplies controls stay enabled.
  Log: "question shown: supply ...".
- [ ] Clear the **Supplies** checkbox in Warnings (or type `/cvn supplies off`).
  Check: no food, water or pet food question, reminder or low row shows. The checkbox is cleared and `/cvn` shows "Supply warnings: off".
  Log: report line "supplies: ...".
- [ ] Type `/cvn supplies on`.
  Check: the warnings work again with the thresholds you had.
  Log: report line "supplies: ...".
- [ ] Type `/cvn food off`, then lower food and water.
  Check: no food question shows. The water question still shows.
  Log: report line "supplies: ...; food off (5)".
- [ ] Type `/cvn water off`, then lower food and water.
  Check: no water question shows. The food question still shows.
  Log: report line "supplies: ..., water off (5)".
- [ ] As a Hunter, type `/cvn petfood off`, then lower pet food and food.
  Check: no pet food question shows. The food question still shows.
  Log: report line "supplies: ..., pet food off (5)".
- [ ] Type `/cvn food 10` and carry 10 food items, then 11.
  Check: the addon asks at 10 and not at 11.
  Log: "question shown: supply ..." at 10 only.
- [ ] Move a slider on the Supplies page.
  Check: `/cvn` shows the new value.
  Log: report line "supplies: ...".
- [ ] Carry plenty of food, then type `/cvn test food`.
  Check: the question shows now, whatever the count.
  Log: "test command: ...".

### 14.5 Learning and order

- [ ] Open a baker or a water vendor that the addon does not ship.
  Check: nothing changes on screen. The reviewer confirms the addon learned it, and that it is now a target for food or water.
  Log: `ClosestVendorDB.learned` has the vendor with supplies.
- [ ] With reagents and food both low, answer the questions.
  Check: the questions come in the order repair, ammo, reagent, food, water, pet food, sell, trainer. Reagent comes before food.
  Log: "question shown: ..." lines in that order.
- [ ] Open a merchant while food is low.
  Check: the addon buys nothing. It does not buy food, water or pet food in this version.
  Log: "merchant window opened" with no purchase line.
- [ ] Open the status window settings and type `/cvn hud row supplies always`.
  Check: a **Show: Supplies** dropdown sits between Reagents and Bag space and shows Always.
  Log: none; on screen only.
- [ ] As a Warrior, look at the status window with Supplies set to Always.
  Check: a Food row shows and no Water row.
  Log: none; on screen only.
- [ ] As a Priest, look at the status window with Supplies set to Always.
  Check: a Food row and a Water row show.
  Log: none; on screen only.
- [ ] As a Hunter with a pet out, look at the status window with Supplies set to Always.
  Check: a Pet food row shows.
  Log: none; on screen only.
- [ ] Set Supplies to Only when low and carry plenty of food.
  Check: no supply row shows.
  Log: none; on screen only.
- [ ] Drop food to 5 or fewer.
  Check: the Food row shows in red at the same time as the warning.
  Log: "trigger ..." line for food.
- [ ] Type `/cvn food off`, then keep food at 5 or fewer.
  Check: the Food row is not red.
  Log: none; on screen only.
- [ ] Type `/cvn ammo off` instead, then keep food at 5 or fewer.
  Check: the Food row is still red.
  Log: none; on screen only.
- [ ] As a Hunter, call a pet, then dismiss it, then call a different pet.
  Check: the Pet food row appears and goes away, and the count changes to the new pet's food.
  Log: none; on screen only.
- [ ] Click the Food row.
  Check: the closest food seller is pinned at once with no question.
  Log: "row click: ..." then "accepted: <vendor> via <provider>".
- [ ] Click the Food row in combat.
  Check: the closest food seller is pinned at once with no question.
  Log: "row click: ..." then "accepted: <vendor> via <provider>".
- [ ] As a Mage, set Reagents to Always and look at the window.
  Check: the Conjured Food and Conjured Water rows and the Food and Water rows are separate and do not conflict.
  Log: none; on screen only.
- [ ] Set Supplies to Never.
  Check: no supply rows show.
  Log: none; on screen only.

## 15. Settings per character

- [ ] On character A, type `/cvn bags 30` and `/cvn sound ping`, then move the status window. Log in character B on the same account.
  Check: B shows its own values and window position, not 30, ping or A's position.
  Log: none; on screen only.
- [ ] On A, open a merchant the addon does not know. Log in B and trigger a sell warning near it.
  Check: B can be directed to that merchant.
  Log: none; on screen only.
- [ ] Log in a character that never used the addon, on an account with earlier settings.
  Check: it starts with those earlier settings.
  Log: none; on screen only.

## 16. Profession level gate

- [ ] Below level 20 with a profession at 150/150, change a skill or craft.
  Check: no trainer question shows.
  Log: no "question shown: trainer for <profession>" line.
- [ ] Below level 20, set Professions to Always in the status window.
  Check: the profession row shows but is not red.
  Log: none; on screen only.
- [ ] Reach level 20 and change a skill or craft.
  Check: the trainer question appears.
  Log: "question shown: trainer for <profession>".

## 17. Waypoint choice

- [ ] Type `/cvn nav`.
  Check: chat shows Waypoint: Automatic and the choices.
  Log: none; on screen only.
- [ ] With TomTom loaded, type `/cvn nav native`, then `/cvn test sell` and answer Yes.
  Check: the game's own waypoint shows, with no TomTom arrow.
  Log: "accepted: <seller> via <provider>" names the native provider.
- [ ] With TomTom loaded, type `/cvn nav tomtom`, then `/cvn test sell` and answer Yes.
  Check: a TomTom arrow shows.
  Log: "accepted: <seller> via <provider>" names TomTom.
- [ ] Without WaypointUI installed, type `/cvn nav waypointui`, then `/cvn test sell` and answer Yes.
  Check: a waypoint still appears, using the usual order.
  Log: "accepted: <seller> via <provider>" names a provider that is installed.
- [ ] Open the settings page.
  Check: a Waypoint dropdown under Navigation has the same four choices.
  Log: none; on screen only.

## 18. Fewer reads and late item data

- [ ] In a group with another hunter or warlock, have them dismiss and summon their pet several times. Then dismiss and summon your own pet. Type `/cvn log`.
  Check: the report is not filled with lines for their pet.
  Log: no `event UNIT_PET party1` lines; `event UNIT_PET player` lines for your own pet.
- [ ] Turn off food, water, pet food and the healthstone reminder, then change your bags.
  Check: nothing is asked, and other warnings still work.
  Log: no "reminder:" lines for the four switched-off kinds.
- [ ] Optional (hard to cause). With reagent buying on, open a merchant that sells your reagent right after a fresh login.
  Check: the purchase question appears once, possibly a moment after the window opens.
  Log: "merchant window opened", then one "question shown" line for the reagent.

## 19. NorgannonDB

- [ ] Without NorgannonDB, type `/cvn log`.
  Check: vendors work as before.
  Log: "NorgannonDB: not found".
- [ ] WoW Forever with NorgannonDB installed. Log in and type `/cvn log`.
  Check: nothing to see in game.
  Log: "NorgannonDB: found, schema 1.5" with a number of vendors added.
- [ ] WoW Forever. Stand in Riverglades, with bags nearly full, and type `/cvn test sell`. Repeat in Zephras Isle.
  Check: a vendor in that zone is named and the pin points to a real vendor.
  Log: "question shown: ..." names the vendor.
- [ ] Open the vendor you were sent to.
  Check: the next pin uses where the vendor stood when you opened it, if that differs.
  Log: "merchant window opened".
- [ ] Disable NorgannonDB and type `/reload`.
  Check: no errors show.
  Log: "NorgannonDB: not found".

## 20. Settings and appearance acceptance

Setup: Classic Era and WoW Forever, with only Closest Vendor installed, at matching UI scale. Write down the client build and addon version from `/cvn log`.

- [ ] Type `/cvn`, then `/cvn help`, then `/cvn status`.
  Check: the first opens Home, the second prints the purpose and commands in chat, the third prints the current values.
  Log: none; on screen only.
- [ ] Open settings with `/cvn settings`, `/cvn config`, `/cvn options`, the cog and game Options, one after another.
  Check: one settings tree opens each time, Home first, with pages Home, Ammo, Reagents, Supplies, Navigation, Appearance, Advanced and About. No duplicate category and no error.
  Log: none; on screen only.
- [ ] Change a value on a settings page, then with `/cvn set`.
  Check: the open control and the live window both show the new value.
  Log: none; on screen only.
- [ ] Type `/cvn set` with a missing, a fractional, an unknown and an out-of-range value.
  Check: chat explains each, and no setting changes.
  Log: none; on screen only.
- [ ] Turn off a feature switch and a buying switch.
  Check: the dependent controls keep their values and say what they need.
  Log: none; on screen only.
- [ ] Warrior and mage (or hunter or warlock): open Supplies and Reagents.
  Check: each class sees only the controls that apply to it.
  Log: none; on screen only.
- [ ] Open Background color, pick a color, then cancel.
  Check: the original color comes back. Without a color picker, the page says so and points to `/cvn hud color`.
  Log: none; on screen only.
- [ ] On a fresh install, open Appearance. Then reload a character with a saved Warning style and notice off.
  Check: Toast is the default on the fresh install. The saved character keeps Warning and notice off.
  Log: `/cvn log` shows the effective style and the notice state.
- [ ] Select Warning, then Toast, and trigger a notice each time (`/cvn test sell`).
  Check: exactly one style shows the target, zone, yards and reason. A newer notice replaces the old one.
  Log: `/cvn log` shows the effective style.
- [ ] Turn On-screen notice off, change the style, then trigger a notice.
  Check: chat still shows the notice, and changing the style does not turn notices on.
  Log: `/cvn log` shows notice enabled false.
- [ ] Optional, in a disposable copy: remove the Ace libraries.
  Check: the standalone settings still open, or the addon says settings are unavailable. Commands and play continue.
  Log: none; on screen only.
- [ ] Load a character saved by the previous version, with custom thresholds, buying choices, colors and window position.
  Check: every value is kept, and learned vendors are still there.
  Log: `ClosestVendorCharDB` holds the values; `ClosestVendorDB` holds the learned vendors.
- [ ] Open each settings page without reading the README.
  Check: you can say what each page does, and the text explaining a choice comes before the choice.
  Log: none; on screen only.
- [ ] Show the status window and a warning. Use a very long vendor, zone or item name.
  Check: no essential text and no button label is cut off.
  Log: none; on screen only.
- [ ] Hover an item in the window, then a tooltip from another addon.
  Check: item-quality titles stay readable and the other tooltip keeps its content and frame.
  Log: none; on screen only.
- [ ] Set a real waypoint (`/cvn test sell`, click Yes), turn On-screen notice off, then type `/cvn demo` and wait for the tour to end.
  Check: the tour steps through route, question, food or water, arrows, a row click, reminder, each with your style and sound. At the end your earlier waypoint is back and no setting changed.
  Log: "demo: ..." lines for each step, "demo: over", "demo: previous waypoint restored".
- [ ] Type `/cvn demo` twice quickly.
  Check: only the newer tour runs, and its first notification replaces the old one.
  Log: "demo: stopped".
- [ ] During a tour, click a status window row.
  Check: the tour stops, your previous waypoint comes back, and the row routes with its own notification.
  Log: "demo: stopped".
- [ ] Type `/cvn preview notice`, then click a status window row.
  Check: the live notification replaces the sample.
  Log: none; on screen only.
- [ ] Type `/cvn preview toast` while Warning is selected.
  Check: the toast shows, and the saved style stays Warning.
  Log: none; on screen only.
- [ ] Type `/cvn preview nothing`, then (not a mage or warlock) `/cvn preview reminder`.
  Check: chat lists the valid kinds, then says the reminder is unavailable for your class.
  Log: none; on screen only.
- [ ] Click Move with settings open, drag a surface past the screen edge, and click Done. Then `/reload`.
  Check: Done keeps the position inside the screen, and it stays after `/reload`. The placeholder and Done/Cancel sit above settings.
  Log: none; on screen only.
- [ ] Click Move, drag the surface, and press Escape.
  Check: the old position comes back.
  Log: none; on screen only.
- [ ] Lock the status window, then try the title and Shift-drag.
  Check: both do nothing. Row clicks still work.
  Log: none; on screen only.
- [ ] Reset a position, then start Move again.
  Check: only the position changes, and no old placeholder hides the Move buttons.
  Log: none; on screen only.
- [ ] Set background opacity to 0, then 80, then 100.
  Check: at 0 no fill, border or accent shows. Text and icons still dim on their own.
  Log: none; on screen only.
- [ ] Set addon scale to 150 for the window and the toast.
  Check: both scale, with no clipped text.
  Log: none; on screen only.
- [ ] In combat, open settings, a preview and Move.
  Check: no error, and anything unavailable says why.
  Log: none; on screen only.
- [ ] With TomTom or WaypointUI disabled, type `/cvn preview notice`.
  Check: no error, and the notice still shows.
  Log: none; on screen only.
- [ ] Type `/cvn log`, then `/cvn log clear` and cancel, then `/cvn log clear` and confirm.
  Check: the report is copyable. Cancel keeps the log. Confirm empties only the log.
  Log: the report header shows style, notice state, appearance, toast position and character scope.
- [ ] Appearance, Notifications tab: look at the Toast controls, then set Style to Warning.
  Check: Toast Move shows, with no lock. With Warning the Toast controls hide and a note says why.
  Log: none; on screen only.
- [ ] Change the notification Sound, then type `/cvn sound`.
  Check: chat reports the sound. With None, every notification is silent.
  Log: none; on screen only.
- [ ] Open all pages and Appearance tabs at normal and 150% UI scale, in standalone and game Options. Resize the window, then close and reopen.
  Check: controls fill full rows, headings have space, long labels stay readable, every action is reachable by scrolling, and the size stays for the session. Each page starts at 600×460 with its introduction above its first section.
  Log: none; on screen only.
- [ ] Open About beside KeepThat at matching scale.
  Check: the addon name is large and the version small and grey, with a one-sentence purpose and one command per row with grey explanations.
  Log: none; on screen only.
- [ ] Open `/cvn log` beside `/kt log`.
  Check: both have the standard frame, a title, a copy hint, scrollable selectable read-only text, and reopen with current data.
  Log: none; on screen only.

## 21. Reputation standing

- [ ] On a character that opened a clan quartermaster's window (Gorhak in Magram Village or Molkar in Gelkis Village), then on another character that never saw it, trigger a sell warning nearby.
  Check: the second character is not sent to the quartermaster.
  Log: "question shown: ..." names a vendor other than the quartermaster.
- [ ] Unfriendly with that clan, target or mouse over the quartermaster, then trigger a warning that would route there.
  Check: no route goes to the quartermaster.
  Log: "standing: npc <id> will not trade (Unfriendly or Hostile)"
- [ ] Unfriendly with that clan, type `/cvn log`.
  Check: nothing to see in game.
  Log: "standing (this character): N vendors trade, N will not"
- [ ] Raise reputation to Neutral and target the quartermaster again.
  Check: it can be offered again.
  Log: "standing: npc <id> will trade".

## 22. AddOns list icon and pages

- [ ] Open the game's AddOns list (Menu > AddOns) on Classic Era and WoW Forever and select Closest Vendor.
  Check: the badge icon shows by the name; Restock, Navigation, Appearance, Advanced and About are listed under it; selecting it shows Home.
  Log: none; on screen only.
- [ ] In that list, change a value on Restock > Ammo, then type `/cvn settings`.
  Check: the changed value shows in the settings window.
  Log: none; on screen only.

## 23. Safe questions

Use `/cvn choice ask` so questions show.

- [ ] Hunter, with ammo "ask first" on: open an ammo merchant, leave the question open and close the merchant.
  Check: the question closes and nothing is bought.
  Log: "purchase dropped: the merchant window changed"
- [ ] Mage, with reagent "ask first" on: open a reagent merchant, leave the question open and close the merchant.
  Check: the question closes and nothing is bought.
  Log: "purchase dropped: the merchant window changed"
- [ ] With the ammo question open, cause a route question.
  Check: the route question does not replace the ammo question.
  Log: none; on screen only.
- [ ] With gear below the threshold and bags full, answer No to the repair question, or press Escape on it.
  Check: the sell question appears within a moment.
  Log: "question declined: repair".
- [ ] After that, wait a few minutes without repairing.
  Check: the repair question is not asked again until you repair.
  Log: no new "question shown" line for repair.
- [ ] With bags full and repair needed, where no repairer is known on the continent.
  Check: the sell question is asked.
  Log: "no known vendor for repair on this continent".
- [ ] Die with gear just above the threshold so death drops it below. Resurrect at the corpse or a spirit healer.
  Check: no question while dead or a ghost; the repair question appears once alive.
  Log: "trigger repair" appears only after the resurrection.
- [ ] Repeat, but accept a resurrection from another player before releasing.
  Check: the repair question appears once alive.
  Log: "trigger repair" appears after the resurrection.
- [ ] With the sell question showing, let gear drop below the threshold and answer No to repair.
  Check: the sell question is asked again.
  Log: "question declined: repair", then "question shown" for the sell.

## 24. Zone changes, hearth, partial merchants and standing

- [ ] With the sell question open, enter a dungeon.
  Check: the question closes and nothing is asked inside.
  Log: "question withdrawn: the player changed zone".
- [ ] Leave that dungeon.
  Check: the sell question is asked again.
  Log: "question shown: ..." for the sell.
- [ ] With the repair question open, ride into the next zone.
  Check: the question is asked again, naming the closest repairer of the new zone.
  Log: "question withdrawn: the player changed zone", then "question shown: ..." for repair.
- [ ] With a question open, start combat, then click Yes.
  Check: the question stays and Yes still sets the waypoint.
  Log: "accepted: <seller> via <provider>".
- [ ] Set your hearthstone at an innkeeper, then walk into a dungeon. Type `/cvn anchor hearth` and click a row.
  Check: the row searches near the inn.
  Log: "hearthstone point learned: <inn>"; `/cvn log` names the inn as the hearthstone point.
- [ ] Optional. Talk to an innkeeper and decline the bind, then bind elsewhere without the addon seeing it (or `/reload` between). Enter a dungeon and click a row.
  Check: dungeon searches use your last position outside.
  Log: `/cvn log` shows the new hearthstone point by name only.
- [ ] After a fresh login, open a known ammo vendor straight away.
  Check: the vendor still counts as an ammo vendor.
  Log: "merchant window opened"; a "not fully loaded" line may show, with what was known kept.
- [ ] Unfriendly with the Steamwheedle Cartel, target the Booty Bay auctioneer, turn on `/cvn ah on`, and click a reagent row nearby.
  Check: it does not route to that auctioneer.
  Log: "standing: npc <id> will not trade (Unfriendly or Hostile)".

## 25. Translated labels and the trainer probe

- [ ] Non-English client: as a hunter with a pet, trigger the pet food question.
  Check: the question names the diets in that language.
  Log: none; on screen only.
- [ ] Non-English client: open the Reagents page.
  Check: the reagent checkboxes show the game's item names.
  Log: none; on screen only.
- [ ] Open a profession trainer, then type `/cvn log`.
  Check: the trainer window shows its usual list, unchanged by the addon.
  Log: "trainer services: N listed; filters ..." and one "  service:" line per entry with level and skill requirements.

## 26. Artisan without NorgannonDB

- [ ] Without NorgannonDB, with a profession at 215-225 of 225 (level 35 or more), change a skill or craft.
  Check: no trainer question comes.
  Log: no "question shown: trainer for <profession>" line.
- [ ] Then click the profession row.
  Check: the row is not red; chat says Artisan is taught by only a few trainers and no waypoint is set.
  Log: no "question shown: trainer for <profession>" line.
- [ ] With a profession at 145 of 150 (level 20 or more), change a skill or craft.
  Check: the trainer question still comes.
  Log: "question shown: trainer for <profession>".

## 27. Trainer tiers with NorgannonDB

WoW Forever with NorgannonDB installed.

- [ ] Type `/cvn log`.
  Check: nothing to see in game.
  Log: the NorgannonDB line counts "trainers with a tier".
- [ ] At 145 of 150 (level 20+), near a Journeyman Blacksmith and further from an Expert or Artisan Blacksmith, change a skill.
  Check: the question names the Expert or Artisan Blacksmith, not the Journeyman.
  Log: "question shown: trainer for <profession>, <trainer> ...".
- [ ] At 220 of 225 (level 35+), change a skill.
  Check: the question names a Master trainer (for example Brikk Keencraft in Booty Bay for Blacksmithing).
  Log: "question shown: trainer for <profession>, <trainer> ...".
- [ ] Then click the profession row.
  Check: the row is red and the click routes to that Master trainer.
  Log: "direct pin: ..."
- [ ] Non-English client: trigger the trainer question.
  Check: it uses the game's profession name and the trainer's localized name.
  Log: none; on screen only.
- [ ] Disable NorgannonDB and `/reload`.
  Check: section 26 behavior returns.
  Log: "NorgannonDB: not found".

## 28. Sound-pack sounds

Needs any addon that shares sounds, for example a SharedMedia pack.

- [ ] Without such an addon, open Appearance > Sound.
  Check: only Whisper ping, Minimap ping, Group invite, Ready check and None are listed.
  Log: none; on screen only.
- [ ] With the pack, open Appearance > Sound and choose a pack sound.
  Check: pack sounds follow the built-in ones, each marked "(sound pack)"; choosing one plays it.
  Log: none; on screen only.
- [ ] Type `/cvn sound <name>` with a pack sound name in lower case.
  Check: the pack sound is chosen.
  Log: none; on screen only.
- [ ] Type `/cvn sound banana`.
  Check: chat lists the choices with a count of pack sounds.
  Log: none; on screen only.
- [ ] Type `/cvn test remind`.
  Check: the chosen sound plays.
  Log: "test command: remind".
- [ ] Disable the pack and `/reload`, then type `/cvn test remind`.
  Check: the whisper ping plays and the Sound tab still shows the chosen name.
  Log: "test command: remind".
- [ ] Enable the pack and `/reload`, then type `/cvn test remind`.
  Check: the chosen sound plays again.
  Log: "test command: remind".

## 29. About page

- [ ] Open About.
  Check: About shows the name, version and purpose sentence and no command list.
  Log: none; on screen only.
- [ ] Type `/cvn help`.
  Check: help lists the commands.
  Log: none; on screen only.

## 30. Other sellers

Any level; Stormwind or Orgrimmar has several repair vendors. Run on Classic Era and WoW Forever.

- [ ] Type `/cvn hud row durability always`. Hover the arrow at the right end of the durability row.
  Check: the tooltip says "Other repair vendors".
  Log: none; on screen only.
- [ ] Click that arrow.
  Check: a menu opens at the arrow with the first entry marked and up to three more with zone and yards; the waypoint does not change.
  Log: none; on screen only.
- [ ] Pick the second entry.
  Check: the menu closes, the waypoint moves there and chat says "Navigating to ...".
  Log: "chosen pin: <kind>, <seller>".
- [ ] Open the menu again and press Escape.
  Check: the menu closes and the waypoint stays.
  Log: none; on screen only.
- [ ] Click the row outside the arrow.
  Check: the waypoint goes to the marked seller.
  Log: "direct pin: <kind>".
- [ ] Shrink the window to its smallest (scale 50%, short rows) with a low row showing.
  Check: the arrow does not cover the text and looks right.
  Log: none; on screen only.
- [ ] With the window unlocked, Shift-click and drag from the arrow.
  Check: Shift-click does nothing and the drag does not move the window.
  Log: none; on screen only.
- [ ] Lock the window and click the arrow.
  Check: the arrow still opens the menu.
  Log: none; on screen only.
- [ ] Look at a row with only one known seller.
  Check: it has no arrow.
  Log: none; on screen only.
- [ ] In a contested zone with an Alliance and a Horde camp (for example Stranglethorn Vale), open the menu.
  Check: none of the other faction is listed.
  Log: none; on screen only.
- [ ] Hunter. Type `/cvn ah on`, open the ammo row menu and pick an auctioneer.
  Check: the list can show one auctioneer; picking it says "at the auction house".
  Log: "chosen pin: ..." for the pick.
- [ ] Open the menu of a profession row near its cap.
  Check: the list shows only trainers that teach the next tier.
  Log: none; on screen only.

## 31. Merchant purchases

Needs a hunter with a quiver and a class with reagents (for example a mage). Run on Classic Era and WoW Forever.

- [ ] Hunter, ammo buying on, "ask first" on (`/cvn buy ask`). Open an arrow vendor, buy some arrows by hand, then click Yes.
  Check: it buys only the room left, and chat names that amount.
  Log: "ammo buy: ..." plan line, then no "nothing left to buy".
- [ ] Repeat, but fill the quiver by hand before Yes.
  Check: nothing is bought and chat has no "Bought" line.
  Log: "ammo buy: nothing left to buy".
- [ ] Mage, reagent buying on, asking on, amount 20 (`/cvn reagentbuy on`, `/cvn reagentbuy 20`). Open a reagent vendor, buy some by hand, then click Yes.
  Check: it buys only what brings you to 20.
  Log: "reagent buy: target 20, ... plan: ...".
- [ ] Hunter, asking off (`/cvn buy auto`). Open an arrow vendor.
  Check: arrows are bought without a question.
  Log: "ammo buy: ..." plan line.
- [ ] Mage, asking off (`/cvn reagentbuy auto`). Open a reagent vendor.
  Check: reagents are bought without a question.
  Log: "reagent buy: ..." plan line.
- [ ] Optional (hard to cause). Hunter, `/cvn arrows best`, right after a fresh login, open an arrow vendor you have not visited this session, with nothing in the ammo slot.
  Check: one purchase happens.
  Log: no "ammo buy: merchant sells no" line before it.

## 32. Warning flow

Use `/cvn choice ask` so questions show. Lower a threshold or wear gear down to make a warning fire.

- [ ] With the repair question open, click a low reagent or food row in the status window.
  Check: the repair question closes and the row's vendor is pinned.
  Log: "direct pin: ..."
- [ ] Open a vendor's window afterward.
  Check: the repair question comes back.
  Log: "question shown: repair".
- [ ] With the repair question open, click a row that is not low.
  Check: that vendor is pinned and the repair question comes back at the next check.
  Log: "direct pin: ..."
- [ ] Then move an item in your bags and answer No to the repair question.
  Check: the next low warning is asked.
  Log: "question declined: repair".
- [ ] Optional. With a profession near its cap (`/cvn trade 300`, then craft once) and the trainer question open, enter a dungeon.
  Check: the question closes.
  Log: "question withdrawn: the player changed zone".
- [ ] Hunter with bags full and ammo low and the ammo question open: wear gear below the durability threshold. Answer No to repair, then No to ammo.
  Check: the repair question replaces the ammo question; then the sell question comes.
  Log: "question declined: repair", "question declined: ammo", then "question shown" for the sell.
- [ ] Hunter with low arrows and low bullets, arrow question open or arrow vendor pinned: equip a gun.
  Check: the arrow question or pin ends and the bullet question is asked.
  Log: "request released: ..." then "question shown: ..." for bullets.
- [ ] Hunter with low pet food and a meat vendor pinned: call a pet that does not eat meat.
  Check: the meat pin ends and a vendor for the new pet's food is asked.
  Log: "request released: ..." then "question shown: ..." for the new food.

## 33. Places and waypoints

The reviewer reads `ClosestVendorCharDB` in `WTF/Account/<account>/<realm>/<character>/SavedVariables/ClosestVendor.lua`.

- [ ] Classic Era and WoW Forever. Setup: your hearthstone is already bound to an inn; stand at that inn's innkeeper. Bind your hearthstone there again.
  Check: nothing changes on screen. The reviewer confirms this from the log.
  Log: `hearth` has `continent`, `x` and `y`; `log` has "hearthstone point learned: <inn>".
- [ ] WoW Forever only (Classic Era has no game waypoint). Setup: if TomTom or WaypointUI is installed, type `/cvn nav native` first and `/cvn nav auto` after the check. Put your own waypoint on the map, type `/cvn demo`, and wait about a minute for the tour to end.
  Check: your waypoint is on the map again, where you put it.
  Log: "demo: your game waypoint restored, not tracked".
- [ ] Optional, on an alt only (unlearning loses the skill). Setup: the alt has a profession and the addon knows a trainer for it; the status window shows the profession row (`/cvn hud row professions always`). Click the profession row to set a waypoint to the trainer, then unlearn that profession.
  Check: the trainer waypoint goes away.
  Log: "trainer waypoint cleared: <profession> was unlearned".

No in-game check, unit tests only: the seller list that changes before you pick, a tracked game waypoint after the demo, a game waypoint the game refuses, and the failed timer.

## 34. Patches 1.9.4 and 1.9.5

The reviewer reads `ClosestVendorCharDB` and `ClosestVendorDB` in `WTF/Account/<account>/<realm>/<character>/SavedVariables/ClosestVendor.lua`.

- [ ] Type `/cvn settings status-window`.
  Check: the settings window opens on Appearance, on the Status window tab.
  Log: none; this is on screen only.
- [ ] Type `/cvn settings notifications`.
  Check: the settings window opens on Appearance, on the Notifications tab.
  Log: none; this is on screen only.
- [ ] Play for two minutes with gear that wears (fight or wait for a durability tick), then type `/cvn log`.
  Check: the report is short and readable, with no line for each durability event.
  Log: "gear events: N folded into one check" lines.
- [ ] After the `/reload` at the end.
  Check: nothing to see in game.
  Log: `ClosestVendorDB` has no `hearth`, `lastOutside`, `professions` or `log` key.
- [ ] Classic Era only. Setup: bind your hearthstone at an inn you are not bound to, then type `/reload` at once.
  Check: nothing changes on screen. The reviewer confirms this from the saved file.
  Log: `ClosestVendorCharDB.hearth` has `x` and `y` for that inn.
- [ ] Low durability on gear that wears (or wait for a tick). Open a merchant at the same moment.
  Check: no repair question stays on screen.
  Log: "merchant window opened" comes before any "trigger" line for repair.

No in-game check, unit tests only: the demo with an unreadable waypoint or a waypoint near a demo pin, the reagent names in another game language, the Unfriendly NorgannonDB trainer, the vendor and auctioneer tie in whole yards, the player waypoint next to the addon's, the demo with an unreadable waypoint or a failed timer, and Move (Done, Cancel, lock).

## 35. Find supplies

Use a character that knows a vendor that sells drink (any class) and, for the reagent check, a mage.

- [ ] Type `/cvn find zzzz`.
  Check: chat says no supply item matches zzzz, and no menu opens.
  Log: "find: no item matches".
- [ ] Type `/cvn find` and part of a drink's name, for example `/cvn find juice`. If a menu of items opens, pick one drink.
  Check: chat says the sellers sell drink in general. A list opens at the mouse with the nearest seller marked, each with zone and distance. Your waypoint has not changed.
  Log: "find: <item> looked up as drink" and "find: seller list for <item>".
- [ ] In that list, pick a seller.
  Check: a waypoint is set to that seller and chat names it.
  Log: "accepted: <seller> via <provider>".
- [ ] Repeat the search, then press Escape with the list open.
  Check: the list closes and the waypoint stays where it was.
  Log: no new "accepted:" line.
- [ ] Mage only. Type `/cvn find rune of teleportation`.
  Check: chat says the sellers of that rune are listed, and a list opens with no "sell drink in general" note.
  Log: "find: seller list for Rune of Teleportation".
- [ ] Type `/cvn settings`, type a drink name in **Find supplies** at the end of Home, press Okay.
  Check: the same menu opens as for the command. Closing the settings window changes no setting.
  Log: "find:" lines as for the command; `ClosestVendorCharDB` has no new setting.

No in-game check, unit tests only: more than 8 matching items (chat asks for more of the name; it needs nine cached names), a seller of the wrong pet diet leaving the pet warning open, a pick ending a running demo, a reagent found by its game-language name, no menu control on the client (chat names the nearest seller), the search from the hearthstone point in an instance, an item the client has not named yet found by link, and the other faction's sellers.

## Not covered yet

- Walking distance. The addon chooses vendors by straight-line distance.
- Warlock shards and rogue poisons.

