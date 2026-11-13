# In-game test plan

These checks cover what the automated tests cannot check: the real game.

Run them on WoW Forever. Run them on Classic Era when you can.

Run them before a release. Run them after a change to `Adapter.lua`, `Core.lua`, `Report.lua` or `Options.lua`. Run them when a new game build comes out.

Tick each item. Write down the client build.

Each check has an action and an expected result. A line that starts with "Note" asks you to record what the game does. Those items are unknown: verify them in game.

## 0. Setup

1. Copy `ClosestVendor/` into the AddOns folder. Start the game. Enter `/console scriptErrors 1`. Then enter `/reload`.
2. Expected: no Lua error popup appears on login. The addon is in the list (Esc, AddOns).
3. Optional: install TomTom. Optional: install WaypointUI (WoW Forever).
4. For ammo tests, use a hunter, warrior or rogue. Equip a bow, crossbow or gun. Put some ammo in the ammo slot.

## 1. Settings page and commands

- [ ] Open Esc, Options, AddOns, **Closest Vendor**. Expected: the page exists.
- [ ] On the settings page, find Bag space, Durability, and Ammo and reagents. Expected: each has one checkbox and one slider.
- [ ] Look under the Ammo and reagents slider. Expected: the reagent slider is there, with one checkbox for each reagent of your class.
- [ ] Look at the rest of the settings page. Expected: the Buy ammo and Ask before buying ammo checkboxes are there. The Arrows to buy and Bullets to buy dropdowns are there.
- [ ] Move a slider. Expected: `/cvn` shows the new number.
- [ ] Enter `/cvn ammo 500`. Reopen the settings page. Expected: the ammo slider is at 500.
- [ ] Clear a checkbox. Expected: its slider is greyed out. That trigger stops asking.
- [ ] Enter `/cvn config`. Expected: the settings page opens.
- [ ] Enter `/cvn`. Enter `/cvn help`. Expected: both print readable lines. No stray symbols. No missing text.
- [ ] Change settings with `/cvn` and on the settings page. Enter `/reload`. Expected: the settings stay.
- [ ] Change settings again. Restart the game. Expected: the settings stay.

## 2. The question

- [ ] Enter `/cvn test sell`, `/cvn test repair`, `/cvn test arrows` and `/cvn test bullets`. Expected: each shows the question with a vendor name and a zone.
- [ ] In a test question, click **Yes**. Expected: the addon sets the waypoint (see section 3).
- [ ] In a test question, click **No** or press Esc. Expected: nothing happens.
- [ ] Fill your bags to the threshold. The default is 2 free slots or fewer. Expected: the sell question appears once.
- [ ] Change your bags again. Expected: the sell question does not repeat.
- [ ] Wear one item below the durability threshold. The default is 20%. Expected: the repair question appears once.
- [ ] Click **Yes** in a real question (not a test). Expected: navigation starts to the vendor named in the question.
- [ ] Click **No**. Expected: the addon does not ask again until the condition clears (you sell something or repair). Then the question comes back.
- [ ] Open a question. Sell or repair while it is open. Expected: the question closes by itself.
- [ ] Make both the repair condition and the sell condition true. Expected: the repair question comes first.
- [ ] Meet a condition during combat. Expected: no question appears in combat.
- [ ] End combat. Expected: the question appears after combat ends.

## 3. Navigation

- [ ] With TomTom: trigger a question and click **Yes**. Expected: the arrow points at the vendor.
- [ ] With TomTom: open any vendor window. Expected: the addon removes the arrow.
- [ ] With WaypointUI (WoW Forever): trigger a question and click **Yes**. Expected: the destination shows.
- [ ] With WaypointUI: arrive, or open a vendor. Expected: the addon removes the destination.
- [ ] With neither addon (WoW Forever): click **Yes**. Expected: the map waypoint shows and is super-tracked.
- [ ] With neither addon (Classic Era): click **Yes**. Expected: a chat line shows the vendor, the zone and the coordinates.
- [ ] Enter `/cvn log` (see section 7). Expected: the report names the navigation method it used.

## 4. Vendors and learning

- [ ] Open a vendor the addon does not know. Use a new WoW Forever zone, for example Mount Hyjal or Zephras Isle. Then enter `/cvn test sell`. Expected: the test can pick that vendor.
- [ ] Open a repair vendor. Then enter `/cvn test repair`. Expected: the test can pick that vendor.
- [ ] Open an ammo vendor. Then enter `/cvn test arrows` or `/cvn test bullets`. Expected: the test can pick that vendor.
- [ ] Compare about 10 known vendors with their real positions. Include cities, remote camps and faction-specific vendors. Note each vendor that is in the wrong place.
- [ ] While you compare vendors, note each "vendor" that refuses to buy some items.

## 5. Ammo

- [ ] Equip a bow. Have fewer arrows than the threshold. Expected: the arrows question appears.
- [ ] Equip a gun. Have fewer bullets than the threshold. Expected: the bullets question appears.
- [ ] Enter `/cvn debug on`. Shoot ammo down to the threshold. Expected: the question appears when you cross the threshold.
- [ ] In the report, note which events fired as the ammo count dropped. Look for `BAG_UPDATE_DELAYED`, `UNIT_INVENTORY_CHANGED` and `PLAYER_EQUIPMENT_CHANGED`.
- [ ] Equip the wrong kind of ammo for the weapon. Expected: the addon counts it as no ammo and asks.
- [ ] Equip a thrown weapon. Expected: the addon never asks.
- [ ] Equip a wand. Expected: the addon never asks.

## 6. Professions

- [ ] Enter `/cvn debug on`. Open a profession trainer (any). Enter `/cvn log`. Expected: the log shows the trainer window event.
- [ ] Check the report. Expected: it lists `trainers: 1 learned` and the profession.
- [ ] Open a class trainer. Expected: the addon records nothing.
- [ ] Reach the threshold. The default is 10 points from the limit, for example 65/75 Mining. Gather. Expected: the trainer question appears on the skill-up.
- [ ] Read the trainer question. Expected: it names the profession, the points left and the trainer.
- [ ] In the trainer question, click **Yes**. Expected: the addon sets the waypoint.
- [ ] Craft with a tradeskill window open, near the limit. Expected: the question appears after every craft. It also appears when no skill-up happened.
- [ ] Note which events fired for a single craft.
- [ ] Note which events fired for a Craft All (WoW Forever). Check whether `UNIT_SPELLCAST_SUCCEEDED` fires once for each item.
- [ ] Answer **No**. Then get a skill-up or craft again. Expected: the addon asks again.
- [ ] Leave the question open. Craft again. Expected: the addon does not show the question a second time.
- [ ] Reach the tier limit, for example 75/75. Expected: the addon still asks.
- [ ] Reach 300/300 (or the final tier). Expected: the addon never asks.
- [ ] On WoW Forever, check whether any profession can go above 300. Note the `maxRank` the skill list shows.
- [ ] Open the trainer window for that profession. Expected: the waypoint goes away.
- [ ] Open a vendor window on the way to the trainer. Expected: the trainer waypoint stays.
- [ ] Use a profession for which you never opened a trainer or a crafting window. Expected: the addon stays silent.
- [ ] Use a weapon skill. Expected: the addon never asks.
- [ ] Use a known profession that has no trainer on this continent. Expected: the addon prints one chat line, once.
- [ ] Open a tradeskill window. Note whether the addon learns the profession (report line `professions seen`).
- [ ] Open a trainer window. Note whether it has its services loaded at `TRAINER_SHOW`, or only after `TRAINER_UPDATE`. The log shows which event recorded it.
- [ ] Enter `/cvn trade 25` and `/cvn trade off`. Expected: the commands and the settings page slider agree.

## 7. Report and debug log

- [ ] With the log off, enter `/cvn log`. Expected: a window opens.
- [ ] Read the window. Expected: it shows the version, the game build, the locale, the navigation method, the vendor counts and the settings.
- [ ] Read the window. Expected: it says how to turn the log on.
- [ ] Enter `/cvn debug on`. Trigger a question. Enter `/cvn log`. Expected: the log lists the events.
- [ ] Read the log. Expected: it shows the decision with the bag, durability and ammo values behind it.
- [ ] Read the log. Expected: it shows the vendor found. It shows whether the question was shown and accepted.
- [ ] Open the log window. Expected: the text is selected.
- [ ] Press Ctrl+C. Expected: the window copies all the text.
- [ ] Press Esc. Expected: the window closes.
- [ ] Enter `/cvn log clear`. Expected: the log is empty.
- [ ] Enter `/cvn debug off`. Expected: the log stops recording.

## 8. Safety

- [ ] Enter a dungeon or a battleground. Expected: no error, no question and no waypoint.
- [ ] Leave the dungeon or battleground. Expected: normal behavior returns.
- [ ] Load the game with TomTom disabled. Then enable TomTom and enter `/reload`. Expected: no error either way.
- [ ] Load the game with WaypointUI disabled. Then enable WaypointUI and enter `/reload`. Expected: no error either way.
- [ ] Use a client where a game function is missing. Expected: a line such as `game call failed: <name>` appears once in the log. The addon keeps working.

## 9. Languages

- [ ] Use a non-English client. Expected: the addon sentences are in English. Spell names and zone names are the game's.
- [ ] Install a translation file (see docs/localization.md). Enter `/cvn`. Expected: the output shows the translation.
- [ ] With the translation file installed, trigger a question. Expected: the question shows the translation.
- [ ] With the translation file installed, open the settings page. Expected: the page shows the translation.

## 10. Buying ammo

Use a hunter with a bow (or a gun) and a quiver (or ammo pouch). Enter `/cvn debug on` first.

- [ ] Fill the quiver partly. Use `/cvn buy auto` (the default). Open an ammo vendor. Expected: the addon buys until the quiver is full, with no dialog.
- [ ] Read the chat after that purchase. Expected: one chat line gives the count and the cost.
- [ ] Check the count bought. Expected: it matches the room left.
- [ ] Note how many `BuyMerchantItem` calls the addon needed. Note the batch size of the vendor (the report shows it). This confirms the one-call-per-batch assumption.
- [ ] Open the vendor with a full quiver. Expected: the addon buys nothing.
- [ ] Remove the quiver and the ammo pouch. Open an ammo vendor. Expected: the addon buys nothing.
- [ ] Equip a wand or a thrown weapon. Open an ammo vendor. Expected: the addon buys nothing.
- [ ] Enter `/cvn buy ask`. Open an ammo vendor. Expected: a dialog shows the count and the price.
- [ ] In that dialog, do not click yet. Expected: the addon buys nothing until you click **Yes**.
- [ ] In that dialog, click **No**. Expected: the addon buys nothing.
- [ ] Enter `/cvn buy off`. Open an ammo vendor. Expected: the addon buys nothing.
- [ ] Use a vendor that sells several grades of arrows. Enter `/cvn arrows best`. Expected: the addon buys the highest grade your level allows.
- [ ] Enter `/cvn arrows cheapest`. Expected: the addon buys the cheapest grade.
- [ ] Enter `/cvn arrows equipped`. Expected: the addon buys the ammo that is in your ammo slot.
- [ ] Set the arrow setting and the bullet setting to different values. Expected: a bow follows the arrow setting. A gun follows the bullet setting.
- [ ] Use `equipped` with ammo that this vendor does not sell. Expected: the addon buys nothing. A chat line says so.
- [ ] Open a vendor that sells no ammo at all. Expected: the addon stays silent.
- [ ] Have too little gold for a full purchase. Expected: the addon buys only what you can afford. The chat line says so.
- [ ] Have almost no gold. Expected: the chat line says "You cannot afford any ammo here."
- [ ] Use a quiver that holds a different grade of ammo. Expected: the addon does not overbuy.
- [ ] Open the settings page. Expected: the Arrows and Bullets dropdowns match `/cvn`.

## 11. Targets on another map

Stand near a zone edge. Or stand in a zone where the closest vendor is across the border.

Use `/cvn test sell` (and `/cvn test repair`) so you can repeat the checks. Enter `/cvn debug on` first.

- [ ] Find a vendor on your map that is farther than a vendor on another map. Trigger the question. Expected: the question lists both vendors. Each has its zone and a distance in yards.
- [ ] Read the question. Expected: it has three buttons. The first button is the vendor on your map (`/cvn prefer map`, the default).
- [ ] Click the first button. Expected: the addon sets the waypoint at the vendor on your map.
- [ ] Click the second button. Expected: the addon sets the waypoint at the closer vendor.
- [ ] Click Cancel. Expected: the addon sets no waypoint.
- [ ] Press Esc. Expected: the addon sets no waypoint.
- [ ] Enter `/cvn prefer distance`. Trigger the question. Expected: the closer vendor is now the first button.
- [ ] Stand where the closest vendor is on your own map. Trigger the question. Expected: the plain Yes / No question appears, with that vendor.
- [ ] Stand on a map with no known vendor. Trigger the question. Expected: the plain question names the closest vendor on another map.
- [ ] Enter `/cvn choice auto`. Trigger a question. Expected: no question appears.
- [ ] With `/cvn choice auto` and `prefer map`: expected: the addon sets the waypoint at once, at the vendor on your map.
- [ ] With `/cvn choice auto` and `prefer distance`: expected: the addon sets the waypoint at once, at the closer vendor.
- [ ] With `/cvn choice auto`: expected: one chat line names the target.
- [ ] With `/cvn choice auto`: expected: the same text shows on screen. It names the target with its zone and its distance in yards. When there were two candidates, it also names the other choice.
- [ ] Check the sound. Expected: there is no sound beyond the map waypoint's own sound. (A reminder is different: it plays the reminder sound.)
- [ ] Count the seconds the on-screen text stays. Expected: about five seconds. It sits high and centered. Then it disappears.
- [ ] Set a second waypoint while the text shows. Expected: the new text replaces the old text. The time restarts.
- [ ] Cause a game error, for example try an action that fails. Expected: the error text still looks the same and lasts as long as usual.
- [ ] Enter `/cvn notice off`. Expected: the on-screen text stops. The chat line stays.
- [ ] Enter `/cvn notice on`. Expected: the on-screen text comes back.
- [ ] Open the settings page. Expected: the notice checkbox matches `/cvn notice`.
- [ ] Use `/cvn choice auto` with only one candidate. Expected: the addon sets the waypoint at once.
- [ ] Use `/cvn choice auto` in combat. Expected: the addon sets no waypoint.
- [ ] Repeat the checks with a profession near its cap. Expected: the trainer question and `auto` behave the same.
- [ ] Stand in a city. Expected: "your map" is the city. Note which vendors the addon offers.
- [ ] Open the settings page. Expected: the dropdowns match `/cvn choice` and `/cvn prefer`.
- [ ] Enter `/cvn`. Expected: it shows both settings.
- [ ] Enter `/cvn log`. Expected: it lists the settings (target choice).
- [ ] With debug on, enter `/cvn log`. Expected: it shows which target the addon showed or set.

## 12. Reagents

Use a character whose class has reagents: mage, rogue, priest, paladin, shaman or druid. Enter `/cvn debug on`.

The spell IDs and item IDs were checked against the Classic Era and WoW Forever data tables. This section checks them in the real client.

- [ ] Enter `/cvn`. Expected: it shows the line "Reagents: on, trigger at 5 or fewer".
- [ ] Enter `/cvn log`. Expected: it shows `reagents: class ..., threshold 5, watching: ..., switched off: none`. The `watching` list has the reagents you expect for the spells you know.
- [ ] Spell gating: use a low-level mage. Expected: a reagent for a spell you do not know is not in `watching` (for example, no Rune of Portals).
- [ ] Learn that spell. Expected: the addon adds the reagent without a reload.
- [ ] Note whether `SPELLS_CHANGED` fired in the log.
- [ ] Rank gating: use a druid who knows Rebirth rank 3. Expected: the druid watches Ashwood Seed only. The druid does not watch the rank 1 and rank 2 seeds.
- [ ] Rank gating: use a priest who knows Prayer of Fortitude rank 2. Expected: the priest watches Sacred Candle, not Holy Candle.
- [ ] Check each class list against its spellbook.
- [ ] Check whether lower ranks still report as known (`/dump IsPlayerSpell(<id>)`).
- [ ] Use reagents down to 5 (cast the spell). Expected: the question appears once.
- [ ] Read the reagent question. Expected: it names the reagent and the count.
- [ ] Read the reagent question. Expected: it says "sells <reagent>", so it is clear what to buy. The vendor is one that sells the reagent.
- [ ] In the reagent question, click **Yes**. Expected: the addon sets the waypoint.
- [ ] Counts: carry 1, 5 and 6 Runes of Teleportation in your bags. Expected: 5 asks. 6 does not ask. This tests the threshold boundary.
- [ ] Put reagents in the bank. Expected: the addon does not count them.
- [ ] Open a vendor that sells the reagent. Expected: the question and the waypoint go away.
- [ ] Open a reagent question. Open any other vendor. Expected: the question and the waypoint go away.
- [ ] Get two reagents low, for example Arcane Powder and Rune of Teleportation. Expected: the addon shows one question.
- [ ] Answer the first question, or open the merchant. Expected: the second question appears only then.
- [ ] Order: have a reagent low and gear worn below the threshold. Expected: the repair question comes first. The reagent question comes after the repair question resolves.
- [ ] Order: have a reagent low and full bags. Expected: the reagent question comes before the sell question.
- [ ] Note: no class has both ammo and reagents. The automated tests cover ammo versus reagents.
- [ ] Enter `/cvn reagent 10`. Expected: the command, the settings slider and `/cvn` agree.
- [ ] Enter `/cvn reagent 0` and `/cvn reagent 41`. Expected: the addon refuses both. A message says the range is 1 to 40.
- [ ] Enter `/cvn reagents`. Expected: it lists the reagents of your class, all on.
- [ ] Enter `/cvn reagent off arcane powder`. Expected: the addon turns that reagent off. It asks no more questions for it.
- [ ] Enter `/cvn reagent on arcane powder`. Expected: the reagent comes back.
- [ ] Enter `/cvn reagent` with an unknown reagent name, or a reagent of another class. Expected: a message appears.
- [ ] Open the settings page. Expected: it lists only the reagents of your class. All are on by default. Each has a checkbox that matches `/cvn reagents`.
- [ ] Clear "Ammo and reagents". Expected: the ammo slider, the reagent slider and the reagent checkboxes are greyed out.
- [ ] With "Ammo and reagents" cleared, trigger an ammo question and a reagent question. Expected: the addon silences both.
- [ ] Use a hunter, a warrior and a warlock. Expected: no reagent checkboxes.
- [ ] As a hunter, warrior or warlock, enter `/cvn reagents`. Expected: it says there are none.
- [ ] As a hunter, warrior or warlock, play normally. Expected: no reagent question ever appears.
- [ ] Enter `/cvn test reagent`. Expected: it asks about the first watched reagent, whatever the count.
- [ ] Enter `/cvn test reagent` with nothing watched. Expected: it says so in chat.
- [ ] Vendor data: open a reagent vendor you have not opened before (a druid or priest supplier). Expected: `/cvn log` or `/cvn test reagent` can pick that vendor.
- [ ] Open a shipped reagent vendor. Expected: the addon still picks it. The learned record keeps its reagents.
- [ ] Enter `/cvn choice auto`. Get a reagent low. Expected: the addon sets the waypoint at once.
- [ ] Read the chat line and the on-screen text. Expected: both read "Navigating to <vendor> (<zone>, N yards) to buy <reagent>."
- [ ] Use the other-map choice. Expected: it works as for ammo.
- [ ] Trigger each automatic waypoint. Expected: each one says why. The texts are "... to buy ammo.", "... to repair your gear.", "... to sell items and free bag space." and "... to train <profession>."
- [ ] Check the shipped data. Pick 5 to 10 reagent vendors in cities and camps. Expected: each is where the waypoint says.
- [ ] Check the same vendors with `GetMerchantItemInfo`. Expected: each sells the item.

## 13. Status window, instances and auction house

Enter `/cvn debug on`.

The addon decides these from game calls that the fake-API tests cannot reach. Confirm each one in the real client. Write down the client build.

### 13.1 Settings layout

- [ ] Open Esc, Options, AddOns, **Closest Vendor**. Expected: the main page shows (Warnings, Navigation).
- [ ] Look under the main page. Expected: three subcategories show: Reagents, Ammo, Status window.
- [ ] Check every control from section 1. Expected: each control is still there, on the page it moved to, with its saved value.
- [ ] Note whether `Settings.RegisterVerticalLayoutSubcategory` exists on WoW Forever. Note the same for Classic Era. If it does not exist, expect everything on one page under section headers.
- [ ] Look at the main page. Expected: section headers (Warnings, Navigation, ...) appear on it.
- [ ] The headers and the swatch use the layout that the Register calls return. If either is missing, expected: the log line names the page layout.
- [ ] Open the Status window page. Expected: Lock window position is first.
- [ ] Look at the Status window page. Expected: after Lock window position come the scale, the background opacity (0-100) and the text and icon opacity (20-100).
- [ ] Look at the Status window page. Expected: the background color swatch shows, only where the game has a color picker.
- [ ] Look at the Status window page. Expected: exactly five Only when low / Always / Never dropdowns show, in this order: Ammo, Reagents, Bag space, Durability, Professions.
- [ ] Look at the dropdowns. Expected: there is no dropdown for each profession or for each reagent.
- [ ] As a Hunter, Rogue or Warrior, look at the Ammo row. Expected: the row works.
- [ ] As any other class, look at the Ammo row. Expected: it is greyed out and unselectable.
- [ ] As any other class, hover over the Ammo row. Expected: the text "Your class does not use ammo." shows.
- [ ] As a class with no reagents or display-only items (Hunter, Warrior), look at the Reagents row. Expected: it is greyed out.
- [ ] As a Hunter or Warrior, hover over the Reagents row. Expected: the text "Your class does not use reagents." shows.
- [ ] As a Mage, look at the Reagents row. Expected: it works.
- [ ] As a Warlock (Soul Shards), look at the Reagents row. Expected: it works.
- [ ] As a Rogue (Blinding Powder), look at the Reagents row. Expected: it works.
- [ ] Use a greyed row. Enter `/cvn hud row`. Expected: a greyed row never changes the output.
- [ ] Note whether the row really greys on Classic Era. Note the same for WoW Forever.

### 13.2 The window

- [ ] Set every row to the default. Have nothing low. Expected: the status window is not shown.
- [ ] Bring your bags to the threshold. Expected: the status window appears with Bag space in red.
- [ ] Free the bags. Expected: the status window hides. It never shows empty.
- [ ] Enter `/cvn hud row bags always`. Expected: Bag space shows. It is not red when it is above the threshold.
- [ ] Enter `/cvn hud row bags never`. Expected: Bag space is hidden, even when it is low.
- [ ] Enter `/cvn hud row bags low`. Expected: Bag space returns to the default.
- [ ] Enter `/cvn hud row Professions always` (any case). Expected: every profession line shows.
- [ ] Enter `/cvn hud row reagents never`. Expected: every reagent line is hidden.
- [ ] Enter `/cvn hud row arcane powder always`. Expected: a message names the five groups.
- [ ] Enter `/cvn hud row mining always`. Expected: a message names the five groups.
- [ ] Change some groups. Enter `/cvn`. Expected: it lists the changed groups.
- [ ] Use a character with two professions. Change the Professions dropdown on the settings page. Expected: both profession lines move together.
- [ ] Check the ammo row (hunter, warrior or rogue with a ranged weapon). Expected: it shows Arrows or Bullets.
- [ ] Check the reagent rows. Expected: they show the class reagents with counts.
- [ ] Check the Bag space row and the Durability row. Expected: both show.
- [ ] Check a profession near its cap. Expected: the row shows `skill/max`.
- [ ] Use a row that the game cannot read. Expected: the row is hidden. It never shows 0.
- [ ] Compare the counts with your bags. Expected: they match.
- [ ] Display-only: use a warlock (Soul Shards), a rogue (Blinding Powder) and a mage (Conjured Food and Conjured Water). Set Reagents to Only when low. Expected: those rows are hidden. They are never red.
- [ ] Set Reagents to Always. Expected: the display-only rows show.
- [ ] Compare the display-only counts with your bags. Expected: they match. Food and water sum all ranks. Check each item ID in game.
- [ ] Buy or use ammo. Expected: the window refreshes.
- [ ] Use a reagent. Expected: the window refreshes.
- [ ] Sell, repair, and get a skill-up. Expected: the window refreshes after each one.
- [ ] Note any lag. Ammo use may not fire frequent bag events, so the window may lag by one event.
- [ ] Drag the title. Expected: the window moves.
- [ ] Enter `/reload`, then restart the game. Expected: the position survives both.
- [ ] Shift-drag anywhere on the window. Expected: the window moves.
- [ ] Drag a row without Shift. Expected: the window does not move.
- [ ] Release a drag over a row. Expected: the release does not click the row.
- [ ] Lock the window (checkbox or `/cvn hud lock`). Drag the title. Expected: nothing happens.
- [ ] With the window locked, Shift-drag. Expected: nothing happens.
- [ ] Enter `/cvn hud unlock`. Expected: the title drag and the Shift-drag work again.
- [ ] Enter `/cvn hud reset`. Expected: the window returns to its default position.
- [ ] Enter `/cvn hud scale 150`. Expected: the window is 1.5 times larger.
- [ ] Enter `/cvn hud scale 49` and `/cvn hud scale 201`. Expected: the addon refuses both.
- [ ] Open the settings page. Expected: the scale slider matches.
- [ ] Move the window far to a corner. Change the UI scale in Video settings. Expected: the window stays on screen. Or `/cvn hud reset` recovers it.
- [ ] Click the cog button. Expected: the Closest Vendor main page opens.
- [ ] Check the cog texture. Expected: it shows. It is not blank. It is not a missing-texture square. If it fails, the fallback is an asterisk.
- [ ] Check the window background. Expected: it draws without `BackdropTemplate` errors.
- [ ] Click a low row. Try ammo, a reagent, Bag space, Durability, and a profession within its threshold. Expected: the addon sets a waypoint at the closest vendor at once, with no question.
- [ ] After that click, read the chat and the screen. Expected: the chat line and the on-screen text say "Navigating to ... to buy/repair/sell/train ...".
- [ ] Repeat the row clicks with `/cvn choice ask`. Then repeat with `/cvn choice auto`. Expected: the result is the same.
- [ ] Click a row in combat. Expected: it still sets the waypoint.
- [ ] Open a question. Click a row. Expected: the question closes and the waypoint is set. The addon does not ask again.
- [ ] Set a waypoint with a row click. Trigger an unrelated trigger. Expected: the unrelated trigger does not clear the waypoint.
- [ ] After a row click, open a merchant window. Expected: the waypoint clears.
- [ ] Click a display-only row. Expected: nothing happens.
- [ ] Click a profession row with no known trainer. Expected: chat says so.

### 13.3 Opacity and color

- [ ] On a fresh install, look at the defaults. Expected: the background is pure black at 80 percent. Text and icons are at 100 percent.
- [ ] Enter `/cvn`. Expected: it shows "background 80% of color #000000, text and icons 100%".
- [ ] Set the background opacity to 0 (slider or `/cvn hud opacity 0`). Expected: only the title, the cog and the line text show.
- [ ] At opacity 0, look for fill. Expected: no fill, no border and no faint rectangle. This holds for any color.
- [ ] Enter `/cvn hud color #ffffff`. Then set opacity 0. Expected: the same result.
- [ ] At opacity 0, drag the window by its title. Click its lines. Expected: both still work.
- [ ] Enter `/cvn hud opacity 101` and `/cvn hud opacity -1`. Expected: the addon refuses both.
- [ ] Set the text and icon opacity (slider or `/cvn hud textopacity 40`). Expected: the title, the cog and every line dim together.
- [ ] After that, add a line that was not shown before. Expected: it is dim too.
- [ ] Check the background. Expected: it keeps its own opacity.
- [ ] Enter `/cvn hud textopacity 19` and `/cvn hud textopacity 101`. Expected: the addon refuses both.
- [ ] Move the text opacity slider to its lowest value. Expected: it stops at 20.
- [ ] Swatch look (Classic Era and WoW Forever): open the Status window page. Expected: a Background color row shows. The label is on the left. A small square swatch with a border is on the right.
- [ ] Check the swatch position. Expected: it lines up with the controls of the sliders and the dropdowns. It is not a wide red button.
- [ ] Hover over the swatch. Expected: the tooltip shows. The border turns gold.
- [ ] Click the swatch. Expected: the picker opens.
- [ ] Click the label. Expected: the picker opens.
- [ ] Enter `/cvn log`. Expected: it says "background color control built as a swatch".
- [ ] Fallback look: if the log says "built as a button; no swatch, missing: ..." instead, expect a wide push button with a colored tile in it.
- [ ] In the fallback case, copy that log line into the bug report.
- [ ] Color swatch: check a fresh install. Expected: the swatch shows the saved color, black.
- [ ] Enter `/cvn hud color #101820`. Reopen the page. Expected: the swatch shows that color.
- [ ] Enter `/cvn hud color red`. Expected: a message appears.
- [ ] Enter `/cvn hud color black`. Expected: the color goes back to black.
- [ ] Enter `/cvn hud color reset`. Expected: the color goes back to black.
- [ ] Color picker on WoW Forever: click the swatch. Expected: the game color picker opens at the current color.
- [ ] Look at the picker. Expected: any color is allowed. There is no opacity slider in it.
- [ ] Move the wheel. Expected: the window background changes live.
- [ ] Click OK. Expected: the window keeps the color. The swatch row shows it at once. In the fallback case, the button shows it when the page is next shown.
- [ ] Click Cancel. Expected: the color goes back to the starting color.
- [ ] Note whether `ColorPickerFrame:SetupColorPickerAndShow` exists on WoW Forever. Note the same for Classic Era.
- [ ] Use a client with no picker (or no settings button). Expected: there is no swatch. There is no dead control.
- [ ] On that client, enter `/cvn hud color #rrggbb`. Expected: it still works. Nothing errors.
- [ ] Finding the picker: open Options, AddOns, Closest Vendor, Status window. Expected: the swatch is the Background color row (or, as fallback, the button). It is below the text opacity slider.
- [ ] Enter `/cvn hud color` with no color. Expected: the same game color picker opens at the current color. This holds with or without the swatch.
- [ ] Use the picker from `/cvn hud color`. Expected: the window follows the wheel. Cancel restores the color.
- [ ] Use a client with no picker. Enter `/cvn hud color`. Expected: chat says so. It suggests `/cvn hud color #rrggbb`.
- [ ] Note what each client does.
- [ ] Report line: enter `/cvn log`. Expected: it has a line "color picker: available or missing, settings button: available or missing, background color control built as a swatch".
- [ ] Alternative report line: "... built as a button; no swatch, missing: ..." names `Settings.CreateColorSwatch`, the picker calls or the error.
- [ ] Alternative report line: "... not built, missing: ..." names each missing piece. The pieces are the color picker, the page layout, `layout.AddInitializer`, `CreateSettingsButtonInitializer` or the Settings API.
- [ ] Enter `/cvn debug on` before `/reload`. Expected: the same sentence is in the log.
- [ ] If the swatch is missing on Classic Era or WoW Forever, copy this line into the bug report.
- [ ] OLED check: set the background to 0 and the text opacity to 40. Leave the window up for a minute over a dark area. Expected: nothing static is bright. There is no border and no fixed fill.
- [ ] In the OLED check, look at a low line. Expected: only red text marks it.
- [ ] Set a non-black color at opacity 0. Expected: the screen behind the window is untouched.
- [ ] Enter `/reload`. Expected: the values survive.
- [ ] Enter `/cvn log`. Expected: it shows "opacity N%, color #rrggbb, text opacity N%".

### 13.4 Instances

- [ ] Zone into a dungeon. Enter `/cvn log`. Expected: the instance type is party.
- [ ] Zone into a raid. Enter `/cvn log`. Expected: the instance type is raid.
- [ ] Zone into each battleground (Warsong Gulch, Arathi Basin, Alterac Valley). Enter `/cvn log`. Expected: the instance type is pvp.
- [ ] Go outdoors. Enter `/cvn log`. Expected: the instance type is none.
- [ ] Note what `IsInInstance()` returns on WoW Forever.
- [ ] Note whether each battleground reports a map position. Use `/dump C_Map.GetBestMapForUnit("player")` and `C_Map.GetPlayerMapPosition`.
- [ ] Fill your bags to the threshold inside a battleground. Expected: no question appears there.
- [ ] Leave the battleground. Expected: the sell question appears once. The old bug lost it for good.
- [ ] Wear gear below the repair threshold in a dungeon. Leave the dungeon. Expected: the repair question appears once.
- [ ] Walk outside. Enter a dungeon. Click a row. Expected: the waypoint search starts from the anchor. Chat says so.
- [ ] Enter `/cvn anchor last`. Expected: the anchor matches your last position outside.
- [ ] Enter `/cvn anchor hearth`. Expected: the anchor matches your hearthstone point.
- [ ] Click a row in a battleground. Expected: the search uses the last outdoor position. This holds for either anchor setting.
- [ ] TomTom: set a waypoint from inside an instance. If TomTom refuses it, expected: chat says so.
- [ ] Note what the map waypoint does on WoW Forever.

### 13.5 Anchors and the hearthstone point

- [ ] Enter `/dump GetBindLocation()` on WoW Forever. Expected: the text is a place name.
- [ ] Enter `/dump GetBindLocation()` on Classic Era. Expected: the text is a place name.
- [ ] Set your hearthstone at a new inn. Relog or change zone. Enter `/cvn log`. Expected: it shows the new hearthstone point. It shows it only when the name changed and you stood in the inn area.
- [ ] Cause a failed read of the bind location. Expected: the addon keeps the old hearthstone point.
- [ ] Before the hearthstone point is known, enter `/cvn anchor hearth`. Expected: the addon falls back to the last outdoor position.
- [ ] Enter `/cvn anchor hearth` and `/cvn anchor last`. Expected: both match the "Search from, inside an instance" dropdown.
- [ ] Enter `/cvn anchor` with any other value. Expected: a message appears.

### 13.6 Auction house

- [ ] Enter `/cvn ah on`. Expected: it matches the "Route to the auction house" checkbox.
- [ ] Check the default. Expected: it is off.
- [ ] With it off, click a row. Expected: the click always picks a vendor.
- [ ] Turn it on. Stand near a major city auction house. Click a tradeable row (a reagent or Bag space). Expected: the addon sets the waypoint at the auctioneer when it is closer than the closest vendor.
- [ ] Repeat that click when the vendor is closer. Expected: the addon sets the waypoint at the vendor.
- [ ] Turn it on. Click a row inside an instance. Expected: the addon ignores the auction house.
- [ ] Open an auction house you have never opened. Note the event that fires on WoW Forever. The addon listens for the auction house open event. Confirm its name.
- [ ] After that, enter `/cvn log`. Expected: the log shows that the addon learned the auctioneer.
- [ ] Restart the game. Expected: the learned auctioneer survives.
- [ ] Go to a shipped auctioneer (28 with coordinates). Expected: it is where the waypoint says.
- [ ] Item binding: confirm the tradeable and soulbound handling on 1.60 for the items shown. All current rows are tradeable.

### 13.7 Buying reagents

Use a mage who knows Arcane Brilliance and Teleport (or another class with vendor reagents). Use a reagent vendor. Enter `/cvn debug on`.

- [ ] On a fresh install, enter `/cvn`. Expected: it shows "Reagent buying: off, asks first, up to 20 of each".
- [ ] On a fresh install, enter `/cvn log`. Expected: it has "reagent buying: off, asks first, up to 20 of each".
- [ ] On a fresh install, open a reagent vendor. Expected: the addon buys nothing.
- [ ] Open the settings page, Reagents. Expected: below the reagent checkboxes are Buy reagents, Ask before buying reagents and the amount slider (0-100, default 20).
- [ ] Turn off Buy reagents. Expected: Ask and the slider are greyed out.
- [ ] Enter `/cvn reagentbuy on` and `/cvn reagentbuy off`. Expected: they match the Buy reagents checkbox.
- [ ] Enter `/cvn reagentbuy ask` and `/cvn reagentbuy auto`. Expected: they match the Ask before buying reagents checkbox.
- [ ] Enter `/cvn reagentbuy 35`. Expected: it matches the amount slider.
- [ ] Enter `/cvn reagentbuy 101`, `/cvn reagentbuy -1` and `/cvn reagentbuy 2.5`. Expected: the addon refuses each with a message.
- [ ] As a Hunter, Warrior or Warlock, open the settings page. Expected: all three controls are greyed out. The text "Your class does not use reagents." shows.
- [ ] As a Hunter, Warrior or Warlock, enter `/cvn reagentbuy on`. Expected: it says the same.
- [ ] Buys to N: enter `/cvn reagentbuy on` and `/cvn reagentbuy auto`. Carry 7 Arcane Powder and 0 Runes of Teleportation. Open the vendor. Expected: you end with exactly 20 of each.
- [ ] After that purchase, read the chat. Expected: one chat line names both reagents with counts and the cost.
- [ ] Check the bag counts and the money spent. Expected: they match the chat line.
- [ ] Open the vendor again. Expected: the addon buys nothing more. No chat line shows.
- [ ] Single items in one call: with debug on, check `/cvn log`. Note how many items one `BuyMerchantItem(index, quantity)` call bought. The addon asks for up to `GetMerchantItemMaxStack` per call.
- [ ] If one call buys only one item, the count falls short. Copy the log into a bug report.
- [ ] Note whether `GetMerchantItemMaxStack` exists on WoW Forever. Note the same for Classic Era.
- [ ] Ask first: enter `/cvn reagentbuy ask` (the default). Open the vendor. Expected: a dialog lists the reagents, the counts and the total price.
- [ ] In that dialog, do not click yet. Expected: the addon buys nothing until you click **Yes**.
- [ ] In that dialog, click **No** or press Esc. Expected: the addon buys nothing.
- [ ] Use a rogue with a bow and `/cvn buy ask`. Open a vendor that sells both arrows and Flash Powder. Expected: both dialogs show. Neither replaces the other.
- [ ] Enter `/cvn reagentbuy 0`. Open the vendor. Expected: the addon buys nothing. No dialog shows.
- [ ] No money: have less gold than one reagent costs. Expected: the chat line says "You cannot afford any reagents here."
- [ ] Partial money: have enough gold for part of the list. Expected: the addon buys only that part, in table order.
- [ ] After a partial purchase, read the chat line. Expected: it ends with "(all you could afford)".
- [ ] Full bags: have no free slot in ordinary bags and no partial stack of the reagent. Quivers, soul bags and profession bags do not count. Expected: the chat line says "Your bags have no room for reagents."
- [ ] Have one free slot. Expected: the addon buys only what fits.
- [ ] After that purchase, read the chat line. Expected: it ends with "(all that fits in your bags)".
- [ ] Have a partial stack of the reagent. Expected: the addon tops it up.
- [ ] Switched-off reagent: turn off a reagent on the Reagents page. Expected: the addon does not buy it.
- [ ] Unknown spell: use a reagent for a spell you do not know (a low-level mage: Rune of Portals). Expected: the addon does not buy it.
- [ ] Check Soul Shards, Blinding Powder and conjured items. Expected: the addon never buys them.
- [ ] Use a rogue. Enter `/cvn buy auto` and `/cvn reagentbuy auto`. Buy ammo and Flash Powder at once. Have gold for only the ammo. Expected: the addon buys no Flash Powder. The ammo cost is taken off first.
- [ ] Close the merchant before you answer Yes. Note what the game does with the purchase. The dialog stays. The ammo dialog behaves the same.

## 14. Food, water and pet food

Enter `/cvn debug on`. Use `/cvn` to check the line "Supplies: food on (5), water on (5), pet food on (5), healthstone reminder on".

### 14.1 Food and water

- [ ] As a warrior, carry 6 food items. Eat or drop food until you carry 5 or fewer. Expected: the addon asks about the closest vendor that sells food.
- [ ] Carry cooked, looted or conjured food in the bags. Expected: it counts toward the food total.
- [ ] As a warrior, enter `/cvn test water`. Expected: chat says "Your class does not use water." No question shows.
- [ ] As a rogue, let your drinks run out. Expected: the addon never asks about water.
- [ ] As a priest, carry 5 or fewer drinks. Expected: the addon asks about the closest vendor that sells drink.
- [ ] Answer Yes. Expected: the pin or chat line shows that vendor. A food or water trip does not also ask about selling.
- [ ] Enter `/cvn choice auto`. Expected: one chat line and the on-screen notice, like other triggers.

### 14.2 Pet food

- [ ] As a hunter with no pet out, enter `/cvn test petfood`. Expected: chat says "There is no pet to feed." No question shows.
- [ ] Call a pet. Let its food run low. Expected: the addon asks about the closest vendor that sells food your pet eats.
- [ ] Dismiss the pet. Expected: the addon watches nothing for pet food.
- [ ] Call a pet with a different diet. Expected: the addon now counts the items that this pet eats.
- [ ] Use a pet that eats only meat or fish, in a place where no known vendor sells it. Expected: one chat line. No dialog shows.
- [ ] Run `/dump UnitCreatureFamily("pet")`. Expected: a name and a number. Check that the pet food question names the diets that this family eats. On a non-English client the result is the same.

### 14.3 Reminders

- [ ] As a mage who knows Conjure Food, carry 5 or fewer food items. Expected: a chat line like "You are low on food (2 left). Cast Conjure Food to make more." The addon does not ask about a vendor.
- [ ] Do the same with Conjure Water. Expected: the same kind of reminder for water.
- [ ] As a mage who does not know the spell, carry 5 or fewer food items. Expected: the addon asks about a vendor like other classes.
- [ ] Turn on the on-screen notice (`/cvn notice on`). Expected: the reminder also shows on screen.
- [ ] Stay low. Expected: the reminder shows once, not again. Raise the count above the threshold, then lower it. Expected: it shows again.
- [ ] As a warlock who knows Create Healthstone, carry no healthstone. Expected: chat says "You have no healthstone. Cast Create Healthstone to make one."
- [ ] Carry a healthstone of any rank. Expected: no reminder.
- [ ] Enter `/cvn test remind` as a mage, as a warlock and as another class. Expected: the mage and warlock reminders show. Any other class gets "This is a test reminder. Only mages and warlocks get real ones." Every class hears the sound. It works in combat, too.
- [ ] Start a reminder condition in combat, or in an instance. Expected: the reminder waits. It shows when combat or the instance ends, and the sound plays then, not before.
- [ ] When a reminder shows, listen. Expected: the whisper ping plays once. It does not play again while the reminder stays shown.
- [ ] Let food and water both drop at the same time (a mage who knows both spells). Expected: two chat lines and one sound.
- [ ] Enter `/cvn sound`. Expected: chat shows the current sound and the names whisper, ping, invite, ready and none.
- [ ] Enter `/cvn sound ping`, then `invite`, then `ready`. Expected: each plays at once and `/cvn` shows the new name. Then let a reminder show. Expected: it plays the chosen sound.
- [ ] Enter `/cvn sound none`. Expected: nothing plays. A reminder still shows in chat, with no sound.
- [ ] Enter `/cvn sound banana`. Expected: chat lists the choices and nothing changes.
- [ ] Enter `/cvn test remind` as a mage or a warlock. Expected: the reminder shows and the sound plays.
- [ ] Let a vendor question appear for food (a warrior, or a mage without the spell). Expected: no reminder sound. The map pin makes its own sound when you say Yes.

### 14.4 Settings and commands

- [ ] Open the settings page. Expected: a **Supplies** page sits between Reagents and Ammo. It shows only the rows your class can use. A warlock also sees **Healthstone reminder**.
- [ ] Open the Supplies page as any class. Expected: a **Reminder sound** dropdown with Whisper ping, Minimap ping, Group invite, Ready check and None. Choose one. Expected: it plays at once.
- [ ] Turn off the ammo and reagents master switch (`/cvn ammo off`). Expected: no food, water, pet food or reminder shows.
- [ ] Turn it on again. Turn off food only (`/cvn food off`). Expected: no food question. Water and pet food still work.
- [ ] Repeat for `/cvn water off` and `/cvn petfood off`.
- [ ] Enter `/cvn food 10`. Carry 10 food items. Expected: the addon asks. Carry 11. Expected: it does not ask.
- [ ] Enter `/cvn food 0` and `/cvn food 41`. Expected: the addon rejects both. Repeat for water and petfood.
- [ ] Move a slider on the Supplies page. Expected: `/cvn` shows the new value.
- [ ] Enter `/cvn test food`, `/cvn test water` and `/cvn test petfood`. Expected: each asks now, whatever the count.
- [ ] Enter `/cvn log`. Expected: the report header has a "supplies: ..." line.

### 14.5 Learning and order

- [ ] Open a baker or a water vendor that the addon does not ship. Expected: the addon learns it. It becomes a target for food or water.
- [ ] With reagents and food both low, answer the questions. Expected: the order is repair, ammo, reagent, food, water, pet food, sell, trainer. Reagent comes before food.
- [ ] Open a merchant while food is low. Expected: the addon buys nothing. It does not buy food, water or pet food in this version.
- [ ] Open the status window settings. Expected: a **Show: Supplies** dropdown sits between Reagents and Bag space. `/cvn hud row supplies always` does the same.
- [ ] Set Supplies to Always. Expected: a Food row for every class, a Water row for mana classes, and a Pet food row for a hunter with a pet out. A warrior has no Water row.
- [ ] Set Supplies to Only when low and carry plenty of food. Expected: no supply row. Drop to 5 or fewer food. Expected: the Food row shows in red, at the same time as the warning.
- [ ] Switch food off (`/cvn food off`) or the master switch off. Expected: the Food row is not red.
- [ ] Call a pet, then dismiss it. Expected: the Pet food row appears and goes away. Call a different pet. Expected: the count changes to that pet's food.
- [ ] Click the Food row. Expected: the closest food seller is pinned at once, with no question. Click it in combat. Expected: the same.
- [ ] As a mage with Reagents set to Always, look at the window. Expected: the Conjured Food and Conjured Water rows and the Food and Water rows. They are separate rows and do not conflict.
- [ ] Set Supplies to Never. Expected: no supply rows.

## Not covered yet

- Walking distance. The addon chooses vendors by straight-line distance.
- Warlock shards and rogue poisons.
