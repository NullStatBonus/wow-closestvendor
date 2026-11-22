# In-game test plan

These checks cover what the automated tests cannot check: the real game.

Run them on WoW Forever. Run them on Classic Era when you can.

Run them before a release. Run them after a change to `Adapter.lua`, `Core.lua`, `Report.lua` or `Options.lua`. Run them when a new game build comes out.

Tick each item. Write down the client build.

Each check has one player action, a `Check:` line with the result a player sees, and a `Log:` line the reviewer reads in the debug log or `ClosestVendorCharDB`. A line that starts with "Note" asks you to record what the game does. Those items are unknown: verify them in game.

## 0. Setup

1. Copy `ClosestVendor/` into the AddOns folder. Start the game. Enter `/console scriptErrors 1`. Then enter `/reload`.
2. Check: no Lua error popup appears on login, and the addon is in the list (Esc, AddOns).
3. Optional: install TomTom. Optional: install WaypointUI (WoW Forever).
4. For ammo tests, use a hunter, warrior or rogue. Equip a bow, crossbow or gun. Put some ammo in the ammo slot.

## 1. Settings page and commands

- [ ] Open Esc, Options, AddOns, **Closest Vendor**. Look at Home, then at the pages below it.
  Check: Home Warnings list, in order, Bag space, Durability and Professions (each a checkbox and a slider), then Ammo, Reagents and Supplies (a checkbox only). The pages are Ammo, Reagents, Supplies, then Status window last. The Ammo page has the Buy ammo, Ask before buying and arrow and bullet dropdowns below the ammo slider. The Reagents page has one checkbox for each reagent of your class under the slider.
  Log: none; on screen only.
- [ ] Move a slider, then enter `/cvn ammo 500` and reopen the page.
  Check: `/cvn` shows the new slider number, and the ammo slider is at 500.
  Log: none; on screen only.
- [ ] Clear a checkbox.
  Check: its slider is greyed out and that trigger stops asking.
  Log: none; on screen only.
- [ ] Enter `/cvn config`, then `/cvn`, then `/cvn help`.
  Check: the settings page opens, and the other two print readable lines with no stray symbols or missing text.
  Log: none; on screen only.
- [ ] Change settings with `/cvn` and on the page. Enter `/reload`. Change them again and restart the game.
  Check: the settings stay after both.
  Log: none; on screen only.

## 2. The question

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Enter `/cvn test sell`, `/cvn test repair`, `/cvn test arrows` and `/cvn test bullets`. Click **Yes** in one, and **No** or Esc in another.
  Check: each shows a question with a vendor name and a zone. Yes sets a waypoint (see section 3). No does nothing.
  Log: "test command: sell" and "reminder: test".
- [ ] Fill your bags to the threshold (default 2 free slots or fewer), then change your bags again.
  Check: the sell question appears once and does not repeat.
  Log: one "question shown: sell" line.
- [ ] Wear one item below the durability threshold (default 20%). Click **Yes**.
  Check: the repair question appears once. Yes starts navigation to the vendor named in the question.
  Log: "question shown: repair" and "accepted: <vendor> via <provider>".
- [ ] Click **No** on a real question, then sell or repair.
  Check: the addon does not ask again until the condition clears, then the question comes back.
  Log: "question declined: sell".
- [ ] Open a question, then sell or repair while it is open.
  Check: the question closes by itself.
  Log: "request released:" line.
- [ ] Make the repair and the sell condition true together.
  Check: the repair question comes first.
  Log: "question shown: repair" comes before any sell question.
- [ ] Meet a condition during combat, then end combat.
  Check: no question appears in combat. It appears after combat ends.
  Log: "trigger" line with `combat=true`, then one with `combat=false`.

## 3. Navigation

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Trigger a question and click **Yes**, once for each setup you have. TomTom: the arrow points at the vendor. WaypointUI (WoW Forever): the destination shows. Neither addon, WoW Forever: the map waypoint shows and is super-tracked. Neither addon, Classic Era: a chat line shows the vendor, the zone and the coordinates.
  Check: the result in that setup is as listed.
  Log: "accepted: <vendor> via <provider>".
- [ ] With TomTom or WaypointUI, open any vendor window (or arrive, for WaypointUI).
  Check: the arrow or destination goes away.
  Log: "merchant window opened".
- [ ] Enter `/cvn log`.
  Check: the report names the navigation method used.
  Log: the report line "navigation: <provider> (preference <choice>)".

## 4. Vendors and learning

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Open a vendor the addon does not know, a repair vendor and an ammo vendor (a new WoW Forever zone, for example Mount Hyjal or Zephras Isle). Then enter `/cvn test sell`, `/cvn test repair` and `/cvn test arrows` or `/cvn test bullets`.
  Check: each test can pick the vendor you opened.
  Log: "merchant window opened" and "question shown:" naming that vendor.
- [ ] Note: compare about 10 known vendors (cities, remote camps, faction-specific) with their real positions. Note each vendor in the wrong place and each "vendor" that refuses to buy some items.
  Check: you list the wrong vendors for the report. This is a data survey with no pass or fail.
  Log: "standing: npc <id> will not trade (Unfriendly or Hostile)" for a refusing vendor.

## 5. Ammo

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Equip a bow with fewer arrows than the threshold, then equip a gun with fewer bullets than the threshold.
  Check: the arrows question appears, then the bullets question.
  Log: "question shown: arrows" and "question shown: bullets".
- [ ] Shoot ammo down to the threshold.
  Check: the question appears when you cross the threshold.
  Log: "event BAG_UPDATE_DELAYED", "event UNIT_INVENTORY_CHANGED" and "event PLAYER_EQUIPMENT_CHANGED" lines show which events fired as the count dropped.
- [ ] Equip the wrong kind of ammo for the weapon.
  Check: the addon counts it as no ammo and asks.
  Log: "trigger" line with the ammo value.
- [ ] Equip a thrown weapon, then a wand.
  Check: the addon never asks.
  Log: no "question shown:" line for ammo.

## 6. Professions

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Open a profession trainer, then a class trainer. Enter `/cvn log`.
  Check: the report lists the profession trainer (`trainers: 1 learned` and the profession). The class trainer records nothing. Note whether the trainer shows its services at `TRAINER_SHOW` or only after `TRAINER_UPDATE`.
  Log: "trainer window opened"; "event TRAINER_SHOW" or "event TRAINER_UPDATE"; "trainer services:" line.
- [ ] Reach the threshold (default 10 points from the limit, for example 65/75 Mining) and gather. Click **Yes**.
  Check: the trainer question appears on the skill-up. It names the profession, the points left and the trainer. Yes sets the waypoint.
  Log: "question shown: trainer for <profession>" and "accepted: <trainer> via <provider>".
- [ ] Craft near the limit with a tradeskill window open. Answer **No**, then craft again. Leave the question open, then craft again.
  Check: the question appears after every craft, even with no skill-up. After No it asks again. While it is open it does not show a second time.
  Log: "a craft finished", "question declined: trainer" and one "question shown: trainer" line.
- [ ] Note which events fired for one craft, and for a Craft All (WoW Forever). Check whether `UNIT_SPELLCAST_SUCCEEDED` fires once for each item.
  Check: this is a probe with no pass or fail.
  Log: "event UNIT_SPELLCAST_SUCCEEDED" lines.
- [ ] Reach the tier limit (for example 75/75), then 300/300 (or the final tier).
  Check: at the tier limit it still asks. At the final tier it never asks.
  Log: "question shown: trainer" at the tier limit and none at the final tier.
- [ ] WoW Forever. Note whether any profession goes above 300 and the `maxRank` the skill list shows.
  Check: you note the value. This is a probe with no pass or fail.
  Log: none; on screen only.
- [ ] With a trainer waypoint set, open a vendor window, then open that profession's trainer window.
  Check: the vendor window keeps the waypoint. The trainer window removes it.
  Log: "trainer waypoint cleared:" appears only after the trainer window.
- [ ] Use a profession whose trainer or crafting window you never opened, a weapon skill, and a known profession with no trainer on this continent.
  Check: the first two stay silent. The third prints one chat line, once.
  Log: "no known trainer for <profession>" once.
- [ ] Open a tradeskill window. Enter `/cvn log`.
  Check: you note whether the report line `professions seen` lists the profession.
  Log: "trainers: N learned, professions seen: <list>" in the report.
- [ ] Enter `/cvn trade 25`, then `/cvn trade off`.
  Check: the commands and the settings page slider agree.
  Log: none; on screen only.

## 7. Report and debug log

- [ ] With the log off, enter `/cvn log`.
  Check: a window opens with the version, game build, locale, navigation method, vendor counts and settings, and it says how to turn the log on.
  Log: none; on screen only.
- [ ] Enter `/cvn debug on`. Trigger a question. Enter `/cvn log`.
  Check: the log lists the events, the decision with the bag, durability and ammo values behind it, the vendor found, and whether the question was shown and accepted.
  Log: "debug log turned on", "trigger", "question shown:" and "accepted:" lines.
- [ ] Look at the open log window. Press Ctrl+C, then Esc.
  Check: the text is selected, Ctrl+C copies all of it and Esc closes the window.
  Log: none; on screen only.
- [ ] Enter `/cvn log clear` and cancel, then enter it again and confirm.
  Check: cancel keeps the entries. Confirm empties them.
  Log: none; on screen only.
- [ ] Enter `/cvn debug off`.
  Check: the log stops recording.
  Log: "debug log turned off" is the last line.

## 8. Safety

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Enter a dungeon or a battleground, then leave it.
  Check: inside, no error, no question and no waypoint. After leaving, normal behavior returns.
  Log: "instance: <old> -> <new>" lines and, in the instance, "profession check skipped: in an instance".
- [ ] Optional. Enable TomTom or WaypointUI after a login without it, then enter `/reload`.
  Check: no error either way.
  Log: none; on screen only.
- [ ] Optional, on a client where a game function is missing.
  Check: the addon keeps working.
  Log: "game call failed: <name>" once.

## 9. Languages

- [ ] Use a non-English client.
  Check: the addon sentences are in English. Spell and zone names are the game's.
  Log: none; on screen only.
- [ ] Install a translation file (see docs/localization.md). Enter `/cvn`, trigger a question, then open the settings page.
  Check: all three show the translation.
  Log: none; on screen only.

## 10. Buying ammo

Before the first check: type `/cvn debug on`, then `/reload`. Use a hunter with a bow (or a gun) and a quiver (or ammo pouch). After the last check: `/reload` again.

- [ ] With `/cvn buy auto` (the default) and a partly filled quiver, open an ammo vendor.
  Check: the addon buys until the quiver is full with no dialog. One chat line gives the count and the cost, and the count matches the room left.
  Log: "ammo buy:" lines with the item, price, space and money.
- [ ] Note how many `BuyMerchantItem` calls the addon needed and the vendor's batch size (the report shows it).
  Check: this confirms the one-call-per-batch assumption. It is a probe with no pass or fail.
  Log: "ammo buy:" plan line.
- [ ] Open an ammo vendor with a full quiver. Then do it with no quiver or ammo pouch, with a wand or thrown weapon equipped, and at a vendor that sells no ammo.
  Check: the addon buys nothing each time, and stays silent at the vendor with no ammo.
  Log: "ammo buy: less than one purchase of room", "ammo buy: no bow, crossbow or gun equipped, or its ammo cannot be read" and "ammo buy: merchant sells no".
- [ ] Enter `/cvn buy ask`. Open an ammo vendor. Do not click, then click **No**, then repeat and click **Yes**.
  Check: a dialog shows the count and the price. Nothing is bought until Yes. No buys nothing.
  Log: "ammo buy:" plan line.
- [ ] Enter `/cvn buy off`. Open an ammo vendor.
  Check: the addon buys nothing.
  Log: "ammo buy: off".
- [ ] At a vendor that sells several arrow grades, enter `/cvn arrows best`, then `cheapest`, then `equipped`.
  Check: it buys the highest grade your level allows, the cheapest grade, and the ammo in your ammo slot.
  Log: "ammo buy: best item", "ammo buy: cheapest item" and "ammo buy: equipped item".
- [ ] Set the arrow and the bullet setting to different values. Use `equipped` with ammo this vendor does not sell.
  Check: a bow follows the arrow setting and a gun the bullet setting. With unsold ammo the addon buys nothing and a chat line says so.
  Log: "ammo buy: no <kind> offer for mode equipped".
- [ ] Have too little gold for a full purchase, then almost no gold.
  Check: the addon buys only what you can afford and the chat line says so. With almost none, chat says "You cannot afford any ammo here."
  Log: "ammo buy: cannot afford one purchase".
- [ ] Use a quiver that holds a different grade of ammo.
  Check: the addon does not overbuy.
  Log: "ammo buy:" line showing the space.
- [ ] Open the settings page.
  Check: the Arrows and Bullets dropdowns match `/cvn`.
  Log: none; on screen only.

## 11. Targets on another map

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again. Stand near a zone edge, where the closest vendor is across the border. Type `/cvn test sell` (or `/cvn test repair`) to repeat the question.

- [ ] Trigger the question where a vendor on another map is closer than the vendor on your map.
  Check: the question lists both vendors, each with zone and distance in yards. It has three buttons; the first is the vendor on your map (`/cvn prefer map`, the default).
  Log: "question shown: ".
- [ ] Click the first button. Repeat, click the second button.
  Check: the waypoint goes to the vendor on your map, then to the closer vendor.
  Log: "accepted: <vendor> via <provider>".
- [ ] Repeat, then click Cancel. Repeat, then press Esc.
  Check: no waypoint is set either time.
  Log: "question declined: ".
- [ ] Type `/cvn prefer distance` and trigger the question.
  Check: the closer vendor is now the first button.
  Log: "question shown: ".
- [ ] Stand where the closest vendor is on your own map, trigger the question. Then stand on a map with no known vendor and trigger it again.
  Check: both times you get the plain Yes / No question, naming that vendor, then the closest vendor on another map.
  Log: "question shown: ".
- [ ] Type `/cvn choice auto` and trigger the question with `prefer map`, then with `prefer distance`.
  Check: no question opens. The waypoint goes at once to the vendor on your map, then to the closer vendor. One chat line and the same on-screen text name the target with zone and distance in yards, and the other choice when there were two. The notification sound plays once. The text stays about five seconds, high and centered, then goes.
  Log: "auto: <vendor> (npc <id>) chosen from two candidates".
- [ ] Set a second waypoint while the on-screen text shows.
  Check: the new text replaces the old one and the time restarts.
  Log: none; on screen only.
- [ ] Cause a game error, for example try an action that fails.
  Check: the error text looks the same and lasts as long as usual.
  Log: none; on screen only.
- [ ] Type `/cvn notice off`, trigger an automatic waypoint, then type `/cvn notice on` and trigger it again. Open the settings page.
  Check: with notice off, the on-screen text stops and the chat line stays. With it on, the text comes back. The settings checkbox matches `/cvn notice`.
  Log: none; on screen only.
- [ ] With `/cvn choice auto`, trigger with only one candidate, then in combat.
  Check: the single candidate gets a waypoint at once. In combat no waypoint is set.
  Log: "auto: " for the first; "trigger" shows combat=true for the second.
- [ ] With a profession near its cap, trigger the trainer question under `/cvn choice ask` and `/cvn choice auto`.
  Check: it behaves the same as for vendors.
  Log: "question shown: trainer for <profession>".
- [ ] Stand in a city.
  Check: "your map" is the city. Note which vendors the addon offers.
  Log: "question shown: ".
- [ ] Open the settings page and type `/cvn`.
  Check: the dropdowns match `/cvn choice` and `/cvn prefer`, and `/cvn` shows both settings.
  Log: none; on screen only.
- [ ] Type `/cvn log`.
  Check: the report lists the target choice settings and which target the addon showed or set.
  Log: "accepted: " or "auto: ".

## 12. Reagents

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again. Use a character whose class has reagents: mage, rogue, priest, paladin, shaman or druid. This section checks the spell and item IDs in the real client.

- [ ] Type `/cvn` and `/cvn log`.
  Check: `/cvn` shows "Reagents: on, trigger at 5 or fewer". The report lists the reagents you expect for the spells you know.
  Log: `reagents: on, class <class>, threshold 5, watching: ..., switched off: none`.
- [ ] Optional, a low-level mage. Check the report, then learn a spell with a reagent, such as Portals.
  Check: a reagent for a spell you do not know (no Rune of Portals) is not watched. After you learn it, the addon watches it without a reload. Note whether `SPELLS_CHANGED` fired.
  Log: `reagents: ... watching:` before and after.
- [ ] Rank gating. Use a druid who knows Rebirth rank 3, or a priest who knows Prayer of Fortitude rank 2.
  Check: the druid watches Ashwood Seed only, not the rank 1 and 2 seeds. The priest watches Sacred Candle, not Holy Candle. Each class list matches its spellbook.
  Log: `reagents: ... watching:`.
- [ ] Note: `/dump IsPlayerSpell(<id>)` for a lower rank.
  Check: note whether lower ranks still report as known.
  Log: none; on screen only.
- [ ] Carry 6, then 5, then 1 Runes of Teleportation (cast the spell to use them down).
  Check: 6 does not ask. 5 asks once, naming the reagent, the count and "sells <reagent>" for a vendor that sells it. Click **Yes** and the waypoint is set.
  Log: "question shown: reagent Rune of Teleportation".
- [ ] Put reagents in the bank.
  Check: the addon does not count them.
  Log: `reagents: ... watching:` shows the count without them.
- [ ] Open a reagent question, then open a merchant (a vendor that sells the reagent, then any other).
  Check: each time the question and the waypoint go away.
  Log: "merchant window opened" and "request released: reagent".
- [ ] Get two reagents low, for example Arcane Powder and Rune of Teleportation.
  Check: one question shows. The second appears only after you answer or open the merchant.
  Log: one "question shown: reagent" line, the second after the answer.
- [ ] Have a reagent low and gear worn below the threshold; then a reagent low and full bags.
  Check: the repair question comes first, then the reagent question. The reagent question comes before the sell question.
  Log: "question shown: " lines in that order.
- [ ] Type `/cvn reagent 10`, then `/cvn reagent 0` and `/cvn reagent 41`.
  Check: 10 is accepted, and the command, settings slider and `/cvn` agree. 0 and 41 are refused with a message about the range 1 to 40.
  Log: `reagents: ... threshold 10`.
- [ ] Type `/cvn reagents`, `/cvn reagent off arcane powder`, then `/cvn reagent on arcane powder`, then `/cvn reagent` with an unknown reagent or one of another class.
  Check: the list shows your class reagents, all on. Off stops questions for that reagent; on brings it back. The unknown name gives a message. The settings page lists only your class reagents with checkboxes that match.
  Log: `reagents: ... switched off: Arcane Powder` after off.
- [ ] Clear "Reagents" in Warnings, then clear "Ammo" instead. Trigger an ammo question and a reagent question each time.
  Check: with Reagents cleared, reagent questions stop. With Ammo cleared and Reagents on, only the reagent question appears. With `/cvn ammo on` and `/cvn reagents off`, only the ammo question appears.
  Log: "question shown: " only for the active kind.
- [ ] Use a hunter, a warrior or a warlock. Type `/cvn reagents` and play normally.
  Check: no reagent checkboxes, the command says there are none, and no reagent question ever appears.
  Log: `reagents: ... watching: none`.
- [ ] Type `/cvn test reagent`, then again with nothing watched.
  Check: it asks about the first watched reagent whatever the count. With nothing watched, chat says so.
  Log: "test command: reagent".
- [ ] Open a reagent vendor you have not opened before (a druid or priest supplier), then a shipped reagent vendor.
  Check: the addon can pick the new vendor. The shipped vendor is still picked and keeps its reagents.
  Log: "question shown: reagent " names that vendor.
- [ ] Type `/cvn choice auto` and get a reagent low. Repeat with the other-map choice.
  Check: the waypoint is set at once. Chat and screen read "Navigating to <vendor> (<zone>, N yards) to buy <reagent>." It works as for ammo.
  Log: "auto: ".
- [ ] Trigger each automatic waypoint (ammo, repair, sell, train).
  Check: each says why: "... to buy ammo.", "... to repair your gear.", "... to sell items and free bag space.", "... to train <profession>."
  Log: "auto: ".
- [ ] Pick 5 to 10 shipped reagent vendors in cities and camps. Set the waypoint, go there and open each.
  Check: each is where the waypoint says and sells the item (`GetMerchantItemInfo`).
  Log: "merchant window opened".

No in-game check, unit tests only: no class has both ammo and reagents (ammo versus reagents priority).

## 13. Status window, instances and auction house

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again. The addon decides these from game calls the fake-API tests cannot reach. Write down the client build.

### 13.1 Settings layout

- [ ] Open settings through slash commands, the cog and Options > AddOns.
  Check: all three open the same ordered tree (standalone fallback in section 20). Home keeps all warning switches and the bag, durability and profession thresholds. Appearance has a Status window section with Lock position first, independent scale, background and text controls, a color picker action and six group visibility selectors (Ammo, Reagents, Supplies, Bags, Durability, Professions).
  Log: none; on screen only.
- [ ] Use a class without ammo or reagents.
  Check: those groups are disabled with an explanation, and its item controls do not act.
  Log: none; on screen only.

No in-game check, unit tests only: saved values survive the reorganization and disabled controls keep their values.

### 13.2 The window

- [ ] Set every row to the default and have nothing low. Bring your bags to the threshold, then free them.
  Check: with nothing low the status window is not shown. At the threshold it appears with Bag space in red. After freeing bags it hides and never shows empty.
  Log: none; on screen only.
- [ ] Type `/cvn hud row bags always`, `never`, then `low`.
  Check: always shows Bag space (not red above the threshold). Never hides it even when low. Low returns the default.
  Log: `status window: ... rows: bags: always` in `/cvn log`.
- [ ] Type `/cvn hud row Professions always` (any case), then `/cvn hud row reagents never`.
  Check: every profession line shows, then every reagent line hides. `/cvn` lists the changed groups.
  Log: `status window: ... rows: `.
- [ ] Type `/cvn hud row arcane powder always`, then `/cvn hud row mining always`.
  Check: each time a message names the groups you can use.
  Log: none; on screen only.
- [ ] Use a character with two professions. Change the Professions dropdown on the settings page.
  Check: both profession lines move together.
  Log: `status window: ... rows: professions: ...`.
- [ ] Look at each row: ammo (hunter, warrior or rogue with a ranged weapon), reagents, Bag space, Durability, and a profession near its cap.
  Check: ammo shows Arrows or Bullets; reagents show counts; the profession shows `skill/max`. Counts match your bags. A row the game cannot read is hidden, never 0.
  Log: none; on screen only.
- [ ] Display-only rows. Use a warlock (Soul Shards), a rogue (Blinding Powder) or a mage (Conjured Food and Water). Set Reagents to Only when low, then Always.
  Check: with Only when low those rows are hidden and never red. With Always they show, and the counts match your bags. Food and water sum all ranks. Check each item ID in game.
  Log: none; on screen only.
- [ ] Buy or use ammo, use a reagent, sell, repair, and get a skill-up.
  Check: the window refreshes after each. Note any lag; ammo use may lag by one event.
  Log: none; on screen only.
- [ ] Drag the title, then `/reload`, then restart the game.
  Check: the window moves, and the position survives both.
  Log: `ClosestVendorCharDB.hud` holds the position.
- [ ] Shift-drag anywhere on the window; drag a row without Shift; release a drag over a row.
  Check: Shift-drag moves the window. A drag without Shift does not. The release does not click the row.
  Log: none; on screen only.
- [ ] Type `/cvn hud lock`, drag the title and Shift-drag; then `/cvn hud unlock`, then `/cvn hud reset`.
  Check: locked, neither drag moves it. Unlocked, both work again. Reset returns the window to its default position.
  Log: "status window position reset".
- [ ] Type `/cvn hud scale 150`, then `49` and `201`. Open the settings page.
  Check: 150 makes the window 1.5 times larger. 49 and 201 are refused. The slider matches.
  Log: `status window: ... scale 150%` in `/cvn log`.
- [ ] Move the window far to a corner, then change the UI scale in Video settings.
  Check: the window stays on screen, or `/cvn hud reset` recovers it.
  Log: none; on screen only.
- [ ] Click the cog button.
  Check: the Closest Vendor Home page opens. The cog shows (the fallback is an asterisk, never a blank or a missing-texture square). The window background draws with no `BackdropTemplate` error.
  Log: none; on screen only.
- [ ] Click a low row: ammo, a reagent, Bag space, Durability and a profession within its threshold. Repeat with `/cvn choice ask`, then `/cvn choice auto`, and once in combat.
  Check: the waypoint goes to the closest vendor at once with no question, the same in both modes and in combat. Chat and screen say "Navigating to ... to buy/repair/sell/train ...".
  Log: "direct pin: <kind>".
- [ ] Open a question, then click a row.
  Check: the question closes and the waypoint is set. The addon does not ask again.
  Log: "direct pin: " and "request put back: <kind> (a click replaced it)" does not appear.
- [ ] After a row click, trigger an unrelated trigger, then open a merchant window.
  Check: the unrelated trigger does not clear the waypoint. The merchant window clears it.
  Log: "merchant window opened".
- [ ] Click a display-only row, then a profession row with no known trainer.
  Check: the display-only row does nothing. The profession row says in chat that no trainer is known.
  Log: "no known trainer for <profession>".

### 13.3 Opacity and color

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Fresh install: type `/cvn`, then `/cvn log`.
  Check: the status window background is pure black at 80 percent, text and icons at 100 percent, and `/cvn` says "background 80% of color #000000, text and icons 100%".
  Log: report header "status window: ..., opacity 80%, color #000000, text opacity 100%".
- [ ] Type `/cvn hud opacity 0`, then `/cvn hud color #ffffff`. Drag the window by its title and click a line.
  Check: only the title, the cog and the line text show, with no fill, no border and no faint rectangle, even with white selected. Drag and click still work. The screen behind the window is untouched.
  Log: none; on screen only.
- [ ] Type `/cvn hud opacity 101`, `/cvn hud opacity -1`, `/cvn hud textopacity 19` and `/cvn hud textopacity 101`.
  Check: the addon refuses each with a message. The text opacity slider stops at 20 at its lowest.
  Log: none; on screen only.
- [ ] Type `/cvn hud textopacity 40`, then cause a line that was not shown before.
  Check: the title, the cog and every line are dim, including the new line. The background keeps its own opacity.
  Log: none; on screen only.
- [ ] Open Appearance > Status window > Background color and change the wheel. Confirm once, then change again and cancel. Repeat from `/cvn hud color`.
  Check: the background updates live. Confirm keeps the color. Cancel restores the original color.
  Log: none; on screen only.
- [ ] On a client where the game color picker is missing, open the same page and type `/cvn hud color #101820`, then `/cvn hud color black`.
  Check: the page explains that the picker is missing and shows no dead control. The color command works, an invalid color is refused, and black restores black.
  Log: none; on screen only. The report names AceConfig availability and the game picker; include it in client bug reports.
- [ ] OLED check: set opacity 0 and text opacity 40, then leave the window over a dark area for a minute with one low line showing.
  Check: nothing static is bright. There is no border and no fixed fill. The low line has red text, a red warning symbol and a visible Low label. Lines that are not low use neutral text.
  Log: none; on screen only.
- [ ] Type `/reload`, then `/cvn log`.
  Check: the opacity, color and text opacity values survive.
  Log: report header "status window: ..., opacity N%, color #rrggbb, text opacity N%".

### 13.4 Instances

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Zone into a dungeon, a raid, each battleground (Warsong Gulch, Arathi Basin, Alterac Valley) and then outdoors.
  Check: nothing to see in game. The reviewer confirms the instance type from the log.
  Log: "instance: none -> party", "instance: none -> raid", "instance: none -> pvp", then "instance: ... -> none".
- [ ] WoW Forever only. In an instance, type `/dump IsInInstance()`. In a battleground, type `/dump C_Map.GetBestMapForUnit("player")` and `/dump C_Map.GetPlayerMapPosition`.
  Note: record what the game returns for each. Unknown until tested.
  Log: none; on screen only.
- [ ] Fill your bags to the threshold inside a battleground, then leave it.
  Check: no sell question shows inside. The sell question shows once after you leave.
  Log: "trigger ..." line for bags after the "instance: pvp -> none" line.
- [ ] Wear gear below the repair threshold in a dungeon, then leave the dungeon.
  Check: the repair question shows once after you leave.
  Log: "trigger repair ..." line after the "instance: party -> none" line.
- [ ] Walk outside, enter a dungeon and click a row. Then type `/cvn anchor last` and click a row, and `/cvn anchor hearth` and click a row.
  Check: chat says the waypoint search starts from your last position outside, then from your last position outside again, then from your hearthstone point.
  Log: "row click: ..." lines.
- [ ] Click a row inside a battleground with either anchor setting.
  Check: the search starts from your last outdoor position.
  Log: "row click: ..." line.
- [ ] If TomTom is installed, click a row inside an instance.
  Check: if TomTom refuses the waypoint, chat says so.
  Log: none; on screen only.
- [ ] WoW Forever only. Click a row inside an instance and look at the map.
  Note: record what the map waypoint does. Unknown until tested.
  Log: none; on screen only.

### 13.5 Anchors and the hearthstone point

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Type `/dump GetBindLocation()` on WoW Forever and on Classic Era.
  Check: each client prints a place name.
  Log: none; on screen only.
- [ ] Bind your hearthstone at a new inn, then relog or change zone.
  Check: nothing changes on screen. The reviewer confirms the new hearthstone point from the log, written only when the name changed.
  Log: "hearthstone point learned: <inn>".
- [ ] Before the hearthstone point is known (new character), type `/cvn anchor hearth` and enter a dungeon.
  Check: the addon falls back to your last position outside.
  Log: none; on screen only.
- [ ] Type `/cvn anchor hearth`, then `/cvn anchor last`, then `/cvn anchor x`.
  Check: the first two match the "Search from, inside an instance" dropdown. The last shows a message.
  Log: report line "instance anchor: ...".

### 13.6 Auction house

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Fresh install: type `/cvn ah on`, then `/cvn ah off`.
  Check: the default is off, and the commands match the "Route to the auction house" checkbox. With it off, a row click always picks a vendor.
  Log: report line "auction house routing: off".
- [ ] Turn it on and stand near a major city auction house. Click a tradeable row (a reagent or Bag space), then repeat from a spot where a vendor is closer.
  Check: the waypoint goes to the auctioneer when it is closer, and to the vendor when the vendor is closer.
  Log: "direct pin: auctioneer <name> (npc N) is closer" for the first click only.
- [ ] With it on, click a row inside an instance.
  Check: the addon ignores the auction house.
  Log: no "direct pin: auctioneer" line.
- [ ] WoW Forever only. Open an auction house you have never opened, then type `/cvn log`.
  Check: the auction house window opens. The reviewer confirms the addon learned it. Note the event name that fires on WoW Forever.
  Log: report line "auctioneers: N shipped, N learned" with learned one higher; `ClosestVendorDB.auctioneers` has the auctioneer.
- [ ] Type `/reload`, then `/cvn log`.
  Check: the learned auctioneer survives.
  Log: report line "auctioneers: ... learned" keeps the same count.
- [ ] Walk to a shipped auctioneer (any of the 28 with coordinates) and click a tradeable row with routing on.
  Check: the waypoint points at where the auctioneer stands.
  Log: "direct pin: auctioneer <name> (npc N) is closer".
- [ ] Note the item binding of the rows shown on 1.60.
  Check: all current rows are tradeable. Unknown for soulbound items.
  Log: none; on screen only.

### 13.7 Buying reagents

Use a mage who knows Arcane Brilliance and Teleport, and a reagent vendor. Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Fresh install: type `/cvn` and `/cvn log`, then open a reagent vendor.
  Check: `/cvn` says "Reagent buying: off, asks first, up to 20 of each". The addon buys nothing.
  Log: report line "reagent buying: off, asks first, up to 20 of each"; "reagent buy: off".
- [ ] Open the settings page, Reagents. Turn Buy reagents off and on.
  Check: below the reagent checkboxes are Buy reagents, Ask before buying reagents and an amount slider (0 to 100, default 20). With Buy reagents off, the other two are greyed out.
  Log: none; on screen only.
- [ ] Type `/cvn reagentbuy on`, `off`, `ask`, `auto` and `35`. Then type `101`, `-1` and `2.5`.
  Check: the first five match the checkbox, the Ask checkbox and the slider. The last three are each refused with a message.
  Log: report line "reagent buying: ...".
- [ ] Hunter, Warrior or Warlock only. Open the settings page, then type `/cvn reagentbuy on`.
  Check: all three controls are greyed out with "Your class does not use reagents." The command says the same.
  Log: none; on screen only.
- [ ] Type `/cvn reagentbuy on` and `/cvn reagentbuy auto`. Carry 7 Arcane Powder and 0 Runes of Teleportation. Open the vendor, then open it again.
  Check: you end with exactly 20 of each. One chat line names both reagents with counts and the cost, and the bag counts and money spent match it. The second visit buys nothing and shows no chat line.
  Log: "reagent buy: target 20, money ..., plan: ..., cost ..., short: ..." once.
- [ ] Note how many items one `BuyMerchantItem(index, quantity)` call buys and whether `GetMerchantItemMaxStack` exists, on WoW Forever and on Classic Era.
  Note: if one call buys only one item, the count falls short. Copy the log into a bug report.
  Log: "reagent buy: ..." line shows the plan; the bag counts show the result.
- [ ] Type `/cvn reagentbuy ask`. Open the vendor and do not click. Then click **No** or press Esc, then open it again and click **Yes**.
  Check: a dialog lists the reagents, the counts and the total price. Nothing is bought until **Yes**. **No** or Esc buys nothing.
  Log: "reagent buy: target ..., plan: ..." line once; no purchase follows a No.
- [ ] Rogue with a bow, `/cvn buy ask`. Open a vendor that sells arrows and Flash Powder.
  Check: both dialogs show. Neither replaces the other.
  Log: "ammo buy: ..." and "reagent buy: ..." lines.
- [ ] Type `/cvn reagentbuy 0`, then open the vendor.
  Check: the addon buys nothing and shows no dialog.
  Log: "reagent buy: amount is 0".
- [ ] Have less gold than one reagent costs, then open the vendor.
  Check: chat says "You cannot afford any reagents here."
  Log: "reagent buy: target ..., short: ..." line.
- [ ] Have gold for only part of the list.
  Check: the addon buys that part in table order, and the chat line ends with "(all you could afford)".
  Log: "reagent buy: target ..., plan: ..." line.
- [ ] Fill ordinary bags with no free slot and no partial stack of the reagent (quivers, soul bags and profession bags do not count). Then free one slot. Then keep a partial stack.
  Check: first chat says "Your bags have no room for reagents." With one slot, the addon buys what fits and the line ends with "(all that fits in your bags)". With a partial stack, the addon tops it up.
  Log: "reagent buy: target ..., plan: ..." line each time.
- [ ] Turn off a reagent on the Reagents page. Separately, as a low-level mage, use a reagent for a spell you do not know (Rune of Portals).
  Check: the addon buys neither. It never buys Soul Shards, Blinding Powder or conjured items.
  Log: "reagent buy: target ..., plan: ..." line without those items.
- [ ] Rogue with `/cvn buy auto` and `/cvn reagentbuy auto`. Have gold for the ammo only, then open a vendor that sells both.
  Check: the addon buys no Flash Powder. The ammo cost is taken off first.
  Log: "ammo buy: ..." then "reagent buy: ... short: ..." line.
- [ ] Optional. Open a vendor with a dialog showing, then close the merchant before you answer Yes.
  Note: record what the game does with the purchase. The dialog stays. The ammo dialog behaves the same.
  Log: "reagent buy: purchase dropped: the merchant window changed" or "reagent buy: bags or money unknown at Yes".

## 14. Food, water and pet food

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again. Use `/cvn` to check the line "Supplies: food on (5), water on (5), pet food on (5), healthstone reminder on".

### 14.1 Food and water

- [ ] Warrior: carry 5 or fewer food items (cooked, looted or conjured all count), then type `/cvn test water`.
  Check: the addon asks about the closest vendor that sells food. For water, chat says "Your class does not use water." with no question. A rogue never gets a water question.
  Log: "question shown: supply ..., <vendor> (npc N), N left".
- [ ] Priest: carry 5 or fewer drinks, then answer Yes.
  Check: the addon asks about the closest vendor that sells drink. Yes pins that vendor, and a food or water trip does not also ask about selling.
  Log: "accepted: <vendor> via <provider>".
- [ ] Type `/cvn choice auto` and lower food again.
  Check: one chat line and the on-screen notice, like other triggers.
  Log: "accepted: <vendor> via <provider>" with no "question shown" line.

### 14.2 Pet food

- [ ] Hunter with no pet out: type `/cvn test petfood`.
  Check: chat says "There is no pet to feed." No question shows.
  Log: "test command: ...".
- [ ] Call a pet and let its food run low. Dismiss it. Then call a pet with a different diet.
  Check: the addon asks about the closest vendor that sells food your pet eats. With the pet dismissed it watches nothing. With the new pet it counts what that pet eats.
  Log: "question shown: supply ..., <vendor> (npc N), N left".
- [ ] Use a pet that eats only meat or fish in a place where no known vendor sells it.
  Check: one chat line and no dialog.
  Log: none; on screen only.
- [ ] Type `/dump UnitCreatureFamily("pet")`; repeat on a non-English client if you have one.
  Check: it prints a name and a number. The pet food question names the diets that this family eats.
  Log: none; on screen only.

### 14.3 Reminders

- [ ] Mage who knows Conjure Food and Conjure Water: carry 5 or fewer food items, then 5 or fewer drinks. Type `/cvn notice on` first.
  Check: chat says "You are low on food (2 left). Cast Conjure Food to make more." and the same kind of line for water, also on screen. The addon asks about no vendor. Two reminders at once give two chat lines and one sound.
  Log: "reminder: food (N)" and "reminder: water (N)".
- [ ] Stay low, then raise the count above the threshold and lower it again.
  Check: the reminder shows once while you stay low, and shows again after the second drop.
  Log: "reminder: food (N)" once per drop.
- [ ] Mage without the spell: carry 5 or fewer food items.
  Check: the addon asks about a vendor like other classes.
  Log: "question shown: supply ...".
- [ ] Warlock who knows Create Healthstone: carry no healthstone, then carry one of any rank.
  Check: chat says "You have no healthstone. Cast Create Healthstone to make one." With a healthstone there is no reminder.
  Log: "reminder: healthstone (0)".
- [ ] Type `/cvn test remind` as a mage, as a warlock and as another class, once in combat.
  Check: the mage and warlock reminders show. Any other class gets "This is a test reminder. Only mages and warlocks get real ones." Every class hears the sound, also in combat.
  Log: "reminder: test".
- [ ] Start a reminder condition in combat or in an instance.
  Check: the reminder waits, then shows when combat or the instance ends. The sound plays then, once, and not again while the reminder stays shown.
  Log: "reminder: food (N)" after the combat or instance ends.
- [ ] Type `/cvn sound`, then `/cvn sound ping`, `invite`, `ready`, `none` and `banana`. After each valid name, type `/cvn test remind`.
  Check: `/cvn sound` lists the current sound and whisper, ping, invite, ready and none. Each name plays at once, `/cvn` shows it, and a reminder plays it. With none, nothing plays and the reminder still shows in chat. `banana` lists the choices and changes nothing.
  Log: report line "supplies: ..., notification sound <name>".
- [ ] Warrior, or a mage without the spell: let a vendor question show for food, then say Yes.
  Check: no notification sound when the question shows. The map pin makes its own sound when you say Yes.
  Log: "question shown: supply ..." then "accepted: ...".

### 14.4 Settings and commands

- [ ] Open the settings page, Supplies, as a warlock and as another class. Then open Appearance, Sound tab.
  Check: Supplies sits after Reagents and shows only rows your class can use. A warlock also sees **Healthstone reminder**. Supplies has no sound control. Sound has a **Notification sound** dropdown (Whisper ping, Minimap ping, Group invite, Ready check, None), and a choice plays at once.
  Log: none; on screen only.
- [ ] Type `/cvn ammo off`, then lower food.
  Check: food, water, pet food and reminders still work, and the Supplies controls stay enabled. Ammo and reagent questions stop.
  Log: "question shown: supply ...".
- [ ] Clear the **Supplies** checkbox in Warnings (or type `/cvn supplies off`), then type `/cvn supplies on`.
  Check: with it off there is no food, water or pet food question, reminder or low row, the checkbox is cleared and `/cvn` shows "Supply warnings: off". With it on they work again with the thresholds you had.
  Log: report line "supplies: ...".
- [ ] Type `/cvn food off`, `/cvn water off` and `/cvn petfood off`, one at a time.
  Check: each turns off only its own question. The other two still work.
  Log: report line "supplies: ...; food off (5)".
- [ ] Type `/cvn food 10` and carry 10 food items, then 11. Then type `/cvn food 0` and `/cvn food 41`.
  Check: the addon asks at 10 and not at 11. It rejects 0 and 41. The same holds for water and petfood.
  Log: "question shown: supply ..." at 10 only.
- [ ] Move a slider on the Supplies page. Type `/cvn test food`, `/cvn test water` and `/cvn test petfood`.
  Check: `/cvn` shows the new value. Each test asks now, whatever the count.
  Log: "test command: ..." and report line "supplies: ...".

### 14.5 Learning and order

- [ ] Open a baker or a water vendor that the addon does not ship.
  Check: nothing changes on screen. The reviewer confirms the addon learned it, and that it is now a target for food or water.
  Log: `ClosestVendorDB.learned` has the vendor with supplies.
- [ ] With reagents and food both low, answer the questions.
  Check: the order is repair, ammo, reagent, food, water, pet food, sell, trainer. Reagent comes before food.
  Log: "question shown: ..." lines in that order.
- [ ] Open a merchant while food is low.
  Check: the addon buys nothing. It does not buy food, water or pet food in this version.
  Log: "merchant window opened" with no purchase line.
- [ ] Open the status window settings and type `/cvn hud row supplies always`.
  Check: a **Show: Supplies** dropdown sits between Reagents and Bag space and matches the command. The window shows a Food row for every class, a Water row for mana classes and a Pet food row for a hunter with a pet out. A warrior has no Water row.
  Log: none; on screen only.
- [ ] Set Supplies to Only when low. Carry plenty of food, then drop to 5 or fewer.
  Check: with plenty, no supply row. At 5 or fewer, the Food row shows in red at the same time as the warning. With `/cvn food off` it is not red. With `/cvn ammo off` instead it is still red.
  Log: "trigger ..." line for food.
- [ ] Hunter: call a pet, then dismiss it, then call a different pet.
  Check: the Pet food row appears and goes away, and the count changes to the new pet's food.
  Log: none; on screen only.
- [ ] Click the Food row, also in combat.
  Check: the closest food seller is pinned at once with no question.
  Log: "row click: ..." then "accepted: <vendor> via <provider>".
- [ ] Mage with Reagents set to Always: look at the window.
  Check: the Conjured Food and Conjured Water rows and the Food and Water rows are separate and do not conflict.
  Log: none; on screen only.
- [ ] Set Supplies to Never.
  Check: no supply rows show.
  Log: none; on screen only.

## 15. Settings per character

- [ ] On character A, type `/cvn bags 30` and `/cvn sound ping`, move the status window, then log in character B on the same account.
  Check: B shows its own values and window position, not 30, ping or A's position.
  Log: none; on screen only.
- [ ] On A, open a merchant the addon does not know. Log in B and trigger a sell warning near it.
  Check: B can be directed to that merchant.
  Log: none; on screen only.
- [ ] Log in a character that never used the addon, on an account with earlier settings.
  Check: it starts with those earlier settings.
  Log: none; on screen only.

## 16. Profession level gate

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Below level 20 with a profession at 150/150, change a skill or craft. Then set Professions to Always in the status window.
  Check: no trainer question, and the profession row shows but is not red.
  Log: no "question shown: trainer for <profession>" line.
- [ ] Reach level 20 and change a skill or craft.
  Check: the trainer question appears.
  Log: "question shown: trainer for <profession>".

## 17. Waypoint choice

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Type `/cvn nav`.
  Check: chat shows Waypoint: Automatic and the choices.
  Log: none; on screen only.
- [ ] With TomTom loaded, type `/cvn nav native`, then `/cvn test sell` and answer Yes. Repeat with `/cvn nav tomtom`.
  Check: native gives the game's own waypoint with no TomTom arrow; tomtom gives a TomTom arrow.
  Log: "accepted: <seller> via <provider>" names the chosen provider.
- [ ] Type `/cvn nav waypointui` without WaypointUI installed, then `/cvn test sell` and answer Yes.
  Check: a waypoint still appears, using the usual order.
  Log: "accepted: <seller> via <provider>" names a provider that is installed.
- [ ] Open the settings page.
  Check: a Waypoint dropdown under Navigation has the same four choices.
  Log: none; on screen only.
- [ ] Type `/cvn nav banana`.
  Check: chat lists the choices and nothing changes.
  Log: none; on screen only.

## 18. Fewer reads and late item data

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

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

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Without NorgannonDB, type `/cvn log`.
  Check: vendors work as before.
  Log: "NorgannonDB: not found".
- [ ] WoW Forever with NorgannonDB installed. Log in and type `/cvn log`.
  Check: nothing to see in game.
  Log: "NorgannonDB: found, schema 1.5" with a number of vendors added.
- [ ] WoW Forever. Stand in Riverglades, then Zephras Isle, with bags nearly full (`/cvn test sell`). Then open the vendor you were sent to.
  Check: a vendor in that zone is named and the pin points to a real vendor. If the vendor stood elsewhere, the next pin uses where you opened it.
  Log: "question shown: ..." names the vendor; "merchant window opened".
- [ ] Disable NorgannonDB and `/reload`.
  Check: no errors.
  Log: "NorgannonDB: not found".

## 20. Cohesive presentation acceptance (both supported clients)

Run on Classic Era and WoW Forever with only Closest Vendor installed, at matching UI scale. Record client build and addon version from `/cvn log`.

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Type `/cvn`, `/cvn help`, then `/cvn status`.
  Check: Home opens; help shows purpose, scope and commands in chat; status shows current values.
  Log: none; on screen only.
- [ ] On a fresh install, open Appearance. Then use an account or character with saved Warning and Toast styles and with notice off, and `/reload`.
  Check: Toast is the default on a fresh install; an existing character without a saved style keeps Warning; saved choices and notice off are kept.
  Log: `/cvn log` shows the effective style and notice enabled state.
- [ ] Upgrade existing SavedVariables with custom thresholds, buying choices, row modes, colors, opacity and HUD position. Compare a second character.
  Check: all values are kept; each character keeps its own values; learned vendors stay account-wide.
  Log: `ClosestVendorCharDB` holds the values; `ClosestVendorDB` holds the learned vendors.
- [ ] Open settings with `/cvn settings`, `/cvn config`, `/cvn options`, the cog and game Options, several times.
  Check: one tree, Home first, pages Home/Ammo/Reagents/Supplies/Navigation/Appearance/Advanced/About, no duplicate categories, no errors.
  Log: none; on screen only.
- [ ] Optional, in a disposable copy: remove the Ace libraries, or make native registration fail.
  Check: standalone settings still open, or the addon explains that settings are unavailable; commands and gameplay continue.
  Log: none; on screen only.
- [ ] Change values in the UI and with `/cvn set`. Try missing, fractional, unknown, out-of-range and trailing values.
  Check: open controls and live visuals agree; bad values change nothing; old mixed-case reagent names still work.
  Log: none; on screen only.
- [ ] Turn off feature and buying switches; check a warrior and a mage, hunter or warlock.
  Check: dependent controls keep their values and explain the prerequisite; only the controls that apply to the class show.
  Log: none; on screen only.
- [ ] Open Background color, change it, then cancel. Repeat with settings reopened. Without a color picker, read the Background control.
  Check: cancel brings the original color back; without a picker the page explains it and points to `/cvn hud color`.
  Log: none; on screen only.
- [ ] Select Warning, then Toast; cause automatic and row-click notices with one and two candidates. Then turn notice off and change style. Check two characters.
  Check: exactly one style shows target, zone, yards, reason and alternative, silent for five seconds; a newer notice replaces and restarts it; with notice off chat remains and changing style does not turn notices on; each character keeps its own choice.
  Log: `/cvn log` shows the effective style and notice enabled state.
- [ ] Show the status window, a warning, a toast, a tooltip and a confirmation at the same scale. Use very long vendor, zone, item or action text and uncached icons. Hover native and third-party tooltips.
  Check: no essential text or full button label clips; item-quality titles stay readable; other tooltips keep their content and frame.
  Log: none; on screen only.
- [ ] Set a real waypoint (`/cvn test sell`), turn On-screen notice off, then type `/cvn demo`.
  Check: one step every five seconds: a route set without asking, a navigation question, food, then water (mana class) or pet food (hunter), arrows, a row click for your first watched reagent (or repair; with auction routing on and a closer auctioneer it routes there), and a reminder. Each notification uses your style and sound. Yes sets a real waypoint and the next step removes it. At the end your earlier waypoint is back, the status window shows real rows and no setting changed.
  Log: "demo: ..." lines for each step, "demo: over", and "demo: previous waypoint restored".
- [ ] Type `/cvn demo` twice quickly. Then, during a tour, click a status window row.
  Check: only the newer tour continues and its first notification replaces the old one; a row click stops the tour, brings back the previous waypoint, then routes to that row with its own notification.
  Log: "demo: stopped".
- [ ] Type `/cvn preview notice`, then click a status window row.
  Check: the sample is replaced by the live notification.
  Log: none; on screen only.
- [ ] Preview hud, warning, toast, prompt and (as a mage or warlock) reminder one at a time. Then try an unknown kind and, as another class, the reminder.
  Check: Toast preview while Warning is selected does not save Toast; unknown kinds list the choices; the reminder preview explains it is unavailable for other classes.
  Log: none; on screen only.
- [ ] Click Move with settings open, then move each surface, drag past the screen edge, and click Done. Repeat with Cancel and with Escape. Try with the window locked, before and during Move.
  Check: the placeholder and Done/Cancel appear above settings, even with no toast; Done clamps and keeps the position after `/reload`; Cancel and Escape restore the old one; lock blocks title and Shift-drag; outside Move the window title, Shift-drag and row clicks work and Escape does not dismiss the status window.
  Log: none; on screen only.
- [ ] Reset each position, then start another Move or preview.
  Check: only the position changes; color, opacity, scale, thresholds, modes and switches stay; no stale placeholder or old timer hides the Move buttons.
  Log: none; on screen only.
- [ ] Set background opacity to 0, 80 and 100 and addon scale to 100 and 150 for the status window and toast. Look at the warning cue and Low label in greyscale.
  Check: at 0 no fill, border or accent shows; text and icon dimming work on their own, including new rows and missing icons; the cue and Low label are still clear.
  Log: none; on screen only.
- [ ] Open settings, preview and Move in combat, inside an instance, and with TomTom, WaypointUI, timers, map data or preferred fonts missing.
  Check: no errors; unavailable actions say why; confirmation and purchase guards and reminder meanings are unchanged.
  Log: none; on screen only.
- [ ] Type `/cvn log`, then `/cvn log clear` and cancel, then again and confirm.
  Check: the report is copyable and shows style, notice state, appearance, toast position, character scope and sample or Move state apart from real decisions; cancel keeps the log; confirm clears only the log.
  Log: the report header carries those values.
- [ ] Capture Home, Appearance, low rows, tooltip, selected warning and toast, sample prompt and both Move placeholders, with long text, opacity 0/80/100 and scale 100/150. Compare with every row in the change's coverage.md.
  Check: each row of coverage.md has a matching capture.
  Log: none; on screen only.

## 21. Reputation standing

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] On a character that opened a clan quartermaster's window (Gorhak in Magram Village or Molkar in Gelkis Village), then on another character that never saw it, trigger a sell warning nearby.
  Check: the second character is not sent to the quartermaster.
  Log: "question shown: ..." names a vendor other than the quartermaster.
- [ ] Unfriendly with that clan, target or mouse over the quartermaster, then trigger a warning that would route there.
  Check: no route goes to the quartermaster.
  Log: "standing: npc <id> will not trade (Unfriendly or Hostile)"; `/cvn log` shows "standing (this character): N vendors trade, N will not".
- [ ] Raise reputation to Neutral and target the quartermaster again.
  Check: it can be offered again.
  Log: "standing: npc <id> will trade".

## 22. AddOns list icon and pages

- [ ] Open the game's AddOns list (Menu > AddOns) on Classic Era and WoW Forever. Select Closest Vendor, change a value on Restock > Ammo, then type `/cvn settings`.
  Check: the badge icon shows by the name; Restock, Navigation, Appearance, Advanced and About are listed under it; selecting it shows Home; the changed value shows in `/cvn settings`.
  Log: none; on screen only.

## 23. Safe questions

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

Use `/cvn choice ask` so questions show.

- [ ] Hunter, with ammo "ask first" on: open an ammo merchant, leave the question open and close the merchant. Repeat with a reagent merchant.
  Check: the question closes and nothing is bought.
  Log: "purchase dropped: the merchant window changed" (ammo, then reagent).
- [ ] With the ammo question open, cause a route question.
  Check: the route question does not replace the ammo question.
  Log: none; on screen only.
- [ ] With gear below the threshold and bags full, answer No to the repair question, or press Escape on it.
  Check: the sell question appears within a moment; repair is not asked again until you repair.
  Log: "question declined: repair".
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

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] With the sell question open, enter a dungeon, then leave.
  Check: the question closes, nothing is asked inside, and the sell question is asked again after leaving.
  Log: "question withdrawn: the player changed zone".
- [ ] With the repair question open, ride into the next zone.
  Check: the question is asked again, naming the closest repairer of the new zone.
  Log: "question withdrawn: the player changed zone", then "question shown: ..." for repair.
- [ ] With a question open, start combat, then click Yes.
  Check: the question stays and Yes still sets the waypoint.
  Log: "accepted: <seller> via <provider>".
- [ ] Set your hearthstone at an innkeeper, then walk into another zone. In a dungeon, type `/cvn anchor hearth` and click a row.
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

- [ ] Non-English client: as a hunter with a pet, trigger the pet food question; open the Reagents page.
  Check: the question names the diets in that language; the reagent checkboxes show the game's item names.
  Log: none; on screen only.

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Open a small-town profession trainer and a capital-city trainer for the same profession, ideally below Expert. Type `/cvn log`.
  Check: the trainer window's filters are unchanged.
  Log: "trainer services: N listed; filters ..." and one "  service:" line per entry with level and skill requirements. Copy the report into the trainer-tier issue.

## 26. Artisan without NorgannonDB

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Without NorgannonDB, with a profession at 215-225 of 225 (level 35 or more), change a skill or craft, then click the profession row.
  Check: no trainer question and the row is not red; chat says Artisan is taught by only a few trainers and no waypoint is set.
  Log: no "question shown: trainer for <profession>" line.
- [ ] With a profession at 145 of 150 (level 20 or more), change a skill or craft.
  Check: the trainer question still comes.
  Log: "question shown: trainer for <profession>".

## 27. Trainer tiers with NorgannonDB

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

WoW Forever with NorgannonDB installed.

- [ ] Type `/cvn log`.
  Check: nothing to see in game.
  Log: the NorgannonDB line counts "trainers with a tier".
- [ ] At 145 of 150 (level 20+), near a Journeyman Blacksmith and further from an Expert or Artisan Blacksmith, change a skill.
  Check: the question names the Expert or Artisan Blacksmith, not the Journeyman.
  Log: "question shown: trainer for <profession>, <trainer> ...".
- [ ] At 220 of 225 (level 35+), change a skill, then click the profession row.
  Check: the question names a Master trainer (for example Brikk Keencraft in Booty Bay for Blacksmithing); the row is red; the click routes there.
  Log: "question shown: trainer for <profession>, <trainer> ...".
- [ ] Non-English client: trigger the trainer question.
  Check: it uses the game's profession name and the trainer's localized name.
  Log: none; on screen only.
- [ ] Disable NorgannonDB and `/reload`.
  Check: section 26 behavior returns.
  Log: "NorgannonDB: not found".

## 28. Sound-pack sounds

Needs any addon that shares sounds, for example a SharedMedia pack.

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

- [ ] Without such an addon, open Appearance > Sound.
  Check: only Whisper ping, Minimap ping, Group invite, Ready check and None are listed.
  Log: none; on screen only.
- [ ] With the pack, open Appearance > Sound and choose a pack sound. Then type `/cvn sound <name>` with a pack name in lower case, `/cvn sound banana`, and `/cvn test remind`.
  Check: pack sounds follow the built-in ones, each marked "(sound pack)"; choosing plays it; the lower-case name picks it; banana lists the choices with a count of pack sounds; the test plays the chosen sound.
  Log: "test command: remind".
- [ ] Disable the pack and `/reload`, then `/cvn test remind`. Enable the pack and `/reload`, then test again.
  Check: without the pack the whisper ping plays and the Sound tab still shows the chosen name; with the pack the chosen sound plays again.
  Log: "test command: remind".

## 29. About page

- [ ] Open About, then type `/cvn help`.
  Check: About shows the name, version and purpose sentence and no command list; help still lists the commands.
  Log: none; on screen only.

## 30. Other sellers

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again.

Any level; Stormwind or Orgrimmar has several repair vendors. Run on Classic Era and WoW Forever.

- [ ] Type `/cvn hud row durability always`. Hover the arrow at the right end of the durability row, then click it.
  Check: the tooltip says "Other repair vendors"; a menu opens at the arrow with the first entry marked and up to three more with zone and yards; no waypoint changes yet.
  Log: none; on screen only.
- [ ] Pick the second entry.
  Check: the menu closes, the waypoint moves there and chat says "Navigating to ...".
  Log: "chosen pin: <kind>, <seller>".
- [ ] Open the menu again and press Escape, then click the row outside the arrow.
  Check: Escape closes the menu and keeps the waypoint; the row click routes to the marked seller.
  Log: "direct pin: <kind>" for the row click.
- [ ] Shrink the window to its smallest (scale 50%, short rows) with a low row showing.
  Check: the arrow does not cover the text and looks right. If it does, switch to right-click on the row (see the change design).
  Log: none; on screen only.
- [ ] With the window unlocked, Shift-click and drag from the arrow. Then lock the window and click the arrow.
  Check: unlocked, Shift-click does nothing and the drag does not move the window; locked, the arrow still opens the menu.
  Log: none; on screen only.
- [ ] Look at a row with only one known seller.
  Check: it has no arrow.
  Log: none; on screen only.
- [ ] In a contested zone with an Alliance and a Horde camp (for example Stranglethorn Vale), open the menu.
  Check: none of the other faction is listed.
  Log: none; on screen only.
- [ ] Type `/cvn ah on` and open the ammo row menu. Then open the menu of a profession row near its cap.
  Check: the ammo list can show one auctioneer and picking it says "at the auction house"; the profession list shows only trainers that teach the next tier.
  Log: "chosen pin: ..." for the pick.

## 31. Merchant purchases

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again. Needs a hunter with a quiver and a class with reagents (for example a mage). Run on Classic Era and WoW Forever.

- [ ] Ammo buying on, "ask first" on (`/cvn buy ask`). Open an arrow vendor, buy some arrows by hand, then click Yes.
  Check: it buys only the room left, and chat names that amount.
  Log: "ammo buy: ..." plan line, then no "nothing left to buy".
- [ ] Repeat, but fill the quiver by hand before Yes.
  Check: nothing is bought and chat has no "Bought" line.
  Log: "ammo buy: nothing left to buy".
- [ ] Reagent buying on, asking on, amount 20 (`/cvn reagentbuy on`, `/cvn reagentbuy 20`). Open a reagent vendor, buy some by hand, then click Yes.
  Check: it buys only what brings you to 20.
  Log: "reagent buy: target 20, ... plan: ...".
- [ ] With asking off (`/cvn buy auto`, `/cvn reagentbuy auto`), open an arrow vendor and a reagent vendor.
  Check: both purchases happen without a question.
  Log: "ammo buy: ..." and "reagent buy: ..." plan lines.
- [ ] Optional (hard to cause). With `/cvn arrows best`, right after a fresh login, open an arrow vendor you have not visited this session, with nothing in the ammo slot.
  Check: one purchase happens.
  Log: no "ammo buy: merchant sells no" line before it.

## 32. Warning flow

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again. Use `/cvn choice ask` so questions show. Lower a threshold or wear gear down to make a warning fire.

- [ ] With the repair question open, click a low reagent or food row in the status window. Open a vendor's window afterward.
  Check: the repair question closes and the row's vendor is pinned; no repair question comes during that trip; after you open a vendor's window it comes back.
  Log: "direct pin: ..." for the click; later "question shown: repair".
- [ ] With the repair question open, click a row that is not low, then move an item in your bags and answer No when asked.
  Check: that vendor is pinned; the repair question comes back at the next check; after No, the next low warning is asked.
  Log: "direct pin: ...", "question declined: repair".
- [ ] Optional. With a profession near its cap (`/cvn trade 300`, then craft once) and the trainer question open, enter a dungeon.
  Check: the question closes.
  Log: "question withdrawn: the player changed zone".
- [ ] With bags full and ammo low and the ammo question open, wear gear below the durability threshold. Answer No to repair, then No to ammo.
  Check: the repair question replaces the ammo question; then the sell question comes.
  Log: "question declined: repair", "question declined: ammo", then "question shown" for the sell.
- [ ] Hunter with low arrows and low bullets, arrow question open or arrow vendor pinned: equip a gun. With low pet food and a meat vendor pinned, call a pet that does not eat meat.
  Check: the arrow question or pin ends and the bullet question is asked; the meat pin ends and a vendor for the new pet's food is asked.
  Log: "request released: ..." then "question shown: ..." for the new kind.

## 33. Places and waypoints

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again, so the game saves the log. The reviewer reads `ClosestVendorCharDB` in `WTF/Account/<account>/<realm>/<character>/SavedVariables/ClosestVendor.lua`.

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

Before the first check: type `/cvn debug on`, then `/reload`. After the last check: `/reload` again, so the game saves the log. The reviewer reads `ClosestVendorCharDB` and `ClosestVendorDB` in `WTF/Account/<account>/<realm>/<character>/SavedVariables/ClosestVendor.lua`.

- [ ] Type `/cvn settings status-window`, then `/cvn settings notifications`.
  Check: the settings window opens on Appearance, first on the Status window tab, then on the Notifications tab.
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

Before the first check: type `/cvn debug on`, then `/reload`. Use a character that knows a vendor that sells drink (any class) and, for the reagent check, a mage. After the last check: `/reload` again.

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


Toast movement/sound follow-up: verify the Appearance Notifications tab shows Toast Move and no lock, including characters with old toastLocked data. The status window still blocks title/Shift-drag and Move when locked. Set Style to Warning: the Toast controls are hidden and a note explains why. Change Sound and confirm `/cvn sound` reports it; with None, every notification is silent.


Settings layout review: inspect all six pages, the three Restock pages and the Appearance tabs at normal and 150% UI scale in standalone and game Options. Controls occupy full rows, section headings have breathing room, and long dropdown labels/values remain readable. Appearance has Notifications and Status window tabs; all actions and row controls remain reachable by scrolling. The window title is Closest Vendor, with no This character or Shared Settings suffix; scope details are in Advanced. Compare About alongside KeepThat at matching scale: large addon name, small grey version, one-sentence purpose and separate command rows with grey explanations. Check window resizing and long translations.


Settings context walkthrough: without reading README or hovering controls, explain what each page does and how its settings affect play. On Home distinguish warnings from buying; on Ammo/Reagents distinguish warning thresholds from stock targets and identify when money can be spent without confirmation. On Supplies identify applicable class behavior and shared sound usage. On Navigation explain Ask/Auto, fallback providers, instance origin and auction routing. On every Appearance tab distinguish live surfaces, safe samples and positioning; on Advanced follow the record/reproduce/copy workflow and confirm clear scope. About retains KT's readable hierarchy and explains command purposes. Context should appear before its decision, wrap completely and avoid duplicating the character scope on every page.


Report/dropdown consistency: compare `/cvn log` beside `/kt log` at matching scale. Confirm standard frame chrome, title, copy hint, scrollable text, selection, read-only behavior, close/Escape and repeated opens with current data. Without working AceGUI, confirm the existing report/chat fallback. Inspect short dropdowns (styles, row modes, sounds, ammo grades) versus longer navigation labels at normal/150% scale and a resized window: controls should fit useful content without spanning the whole page or clipping essential choices. Section context and readable row spacing remain intact.


Window-size screenshot follow-up: after reload, open CV and KT side by side at the same UI scale. Their settings should both start at 600×460; compact sliders, dropdowns and buttons should fit the content pane without stretching. Each page's introduction must precede its first section (not sit below the controls). Resize CV, close/reopen and confirm the user size is retained during the session. Check scrolling at 600×460 on every page and Appearance tab for complete text and reachable actions.
