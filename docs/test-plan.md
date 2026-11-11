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

## 13. Status window, instances and auction house

Use `/cvn debug on`. The addon decides these from game calls the fake-API tests cannot reach, so confirm each in the real client. Note the client build.

### 13.1 Settings layout

- [ ] Esc, Options, AddOns, **Closest Vendor** shows the main page (Warnings, Navigation) with three subcategories under it: Reagents, Ammo, Status window. Every control from section 1 is still there, on the page it moved to, with its saved value. Note whether `Settings.RegisterVerticalLayoutSubcategory` exists on Forever and on Era; if not, everything is on one page under section headers. Section headers (Warnings, Navigation, ...) appear on the main page: they and the swatch use the layout the Register calls return, so if either is missing the log line names the page layout.
- [ ] Status window page: Lock window position is first, then scale, background opacity (0-100), text and icon opacity (20-100), the background color swatch (only where the game has a color picker) and exactly five Only when low / Always / Never dropdowns, in this order: Ammo, Reagents, Bag space, Durability, Professions (no dropdown per profession or per reagent). As a Hunter, Rogue or Warrior the Ammo row works. As any other class it is greyed out and unselectable; hover it: "Your class does not use ammo." As a class with no reagents or display-only items (Hunter, Warrior) the Reagents row is greyed out with "Your class does not use reagents."; a Mage, a Warlock (Soul Shards) and a Rogue (Blinding Powder) can use it. Greyed rows never change `/cvn hud row` output. Note whether the row really greys on Era and Forever.

### 13.2 The window

- [ ] With nothing low and every row on the default, the window is not shown. Bring bags to the threshold: it appears with Bag space in red. Free the bags: it hides. It never shows empty.
- [ ] `/cvn hud row bags always`: Bag space shows and is not red when above the threshold. `/cvn hud row bags never`: it is hidden even when low. `/cvn hud row bags low`: back to the default. `/cvn hud row Professions always` (any case) shows every profession line, `/cvn hud row reagents never` hides every reagent line; `/cvn hud row arcane powder always` or `/cvn hud row mining always` gets a message naming the five groups. `/cvn` lists the changed groups. With two professions, the Professions dropdown on the settings page moves both lines together.
- [ ] Rows: ammo (hunter, warrior or rogue with a ranged weapon; Arrows or Bullets), class reagents with counts, Bag space, Durability, a profession near its cap as `skill/max`. A row the game cannot read is hidden, never 0. Counts match the bags.
- [ ] Display-only: Soul Shards (warlock), Blinding Powder (rogue), Conjured Food and Conjured Water (mage) are hidden while Reagents is Only when low (never red); set Reagents to Always and they show, with counts matching the bags (food and water sum all ranks, check each item id in game).
- [ ] The window refreshes after buying or using ammo, using a reagent, selling, repairing and a skill-up. Note any lag: ammo use may not fire frequent bag events, so it may lag by one event.
- [ ] Drag the title: it moves; the position survives `/reload` and a restart. Shift-drag anywhere on the window moves it; dragging a row without Shift does not. Releasing a drag over a row does not click it.
- [ ] Lock (checkbox or `/cvn hud lock`): title drag and Shift-drag both do nothing; `/cvn hud unlock` allows them again. `/cvn hud reset` returns the window to its default position.
- [ ] `/cvn hud scale 150` makes it 1.5 times larger; 49 and 201 are refused; the scale slider matches. Change the UI scale in Video settings with the window moved far to a corner: it stays on screen or `/cvn hud reset` recovers it.
- [ ] The cog button opens the Closest Vendor main page. Check the cog texture shows (not blank, not a missing-texture square); if not, the fallback is an asterisk. Check the window background draws without `BackdropTemplate` errors.
- [ ] Click a low row (try ammo, a reagent, Bag space, Durability, a profession within its threshold): the closest vendor is pinned at once, no question, with the "Navigating to ... to buy/repair/sell/train ..." chat line and on-screen text. Same with `/cvn choice ask` and `auto`.
- [ ] Click a row in combat: it still pins. Click a row while a question is open: the question closes and the pin is set; it is not asked again. A pin made from a click is not cleared by an unrelated trigger, but opening a merchant window clears it.
- [ ] Click a display-only row: nothing happens. Click a profession row with no known trainer: chat says so.

### 13.3 Opacity and color

- [ ] Defaults on a fresh install: background pure black at 80 percent, text and icons at 100 percent. `/cvn` shows "background 80% of color #000000, text and icons 100%".
- [ ] Background opacity slider (or `/cvn hud opacity 0`) at 0: only the title, the cog and the line text show; no fill, no border, no faint rectangle, whatever color is set (try `/cvn hud color #ffffff` then opacity 0). The window can still be dragged by its title and its lines clicked. `/cvn hud opacity 101` and `-1` are refused.
- [ ] Text and icon opacity slider (or `/cvn hud textopacity 40`): the title, the cog and every line dim together, also lines that appear later; the background keeps its own opacity. 19 and 101 are refused; the slider stops at 20.
- [ ] Swatch look (Era and Forever): the Status window page has a Background color row with the label on the left and a small square bordered swatch on the right, lined up with the sliders' and dropdowns' controls, not a wide red button. Hovering it shows the tooltip (and the border turns gold); clicking the swatch or the label opens the picker. `/cvn log` says "background color control built as a swatch". Fallback look: where it says "built as a button; no swatch, missing: ..." instead, the row is a wide push button with a colored tile in it; copy that line into the bug report.
- [ ] Color swatch: it shows the saved color (black on a fresh install). `/cvn hud color #101820` then reopening the page shows that color in the swatch; `/cvn hud color red` gets a message; `/cvn hud color black` and `reset` go back to black.
- [ ] Color picker on Forever: clicking the swatch opens the game's color picker at the current color, any color allowed, with no opacity slider in it. Moving the wheel changes the window background live; OK keeps it (the swatch row shows it at once; the fallback button when the page is next shown), Cancel goes back to the starting color. Note whether `ColorPickerFrame:SetupColorPickerAndShow` exists on Forever and on Era. Where there is no picker (or no settings button), there is no swatch (no dead control), `/cvn hud color #rrggbb` still works, and nothing errors.
- [ ] Finding the picker: the swatch is the Background color row (or, as fallback, button) on the Status window page (Options, AddOns, Closest Vendor, Status window), below the text opacity slider. `/cvn hud color` with no color opens the same game color picker at the current color, with or without the swatch; the window follows the wheel and Cancel restores it. Where the game has no picker, chat says so and suggests `/cvn hud color #rrggbb`. Note what each client does.
- [ ] Report line: `/cvn log` has a line "color picker: available or missing, settings button: available or missing, background color control built as a swatch" (or "... built as a button; no swatch, missing: ..." naming `Settings.CreateColorSwatch`, the picker calls or the error) or "... not built, missing: ..." naming each missing piece (color picker, the page layout, `layout.AddInitializer`, `CreateSettingsButtonInitializer`, or the Settings API). With `/cvn debug on` before `/reload`, the same sentence is in the log. If the swatch is missing on Era or Forever, copy this line into the bug report.
- [ ] OLED check: with background 0 and text opacity 40, leave the window up for a minute over a dark area. Nothing static is bright: no border, no fixed fill, a low line is marked only by red text. With a non-black color at opacity 0, the screen behind is untouched.
- [ ] The values survive `/reload`; `/cvn log` shows "opacity N%, color #rrggbb, text opacity N%".

### 13.4 Instances

- [ ] `/cvn log` after zoning into a dungeon, a raid and each battleground (Warsong Gulch, Arathi Basin, Alterac Valley) shows the instance type as party, raid or pvp; outdoors, none. Note what `IsInInstance()` returns on Forever.
- [ ] Note whether each battleground reports a map position (`/dump C_Map.GetBestMapForUnit("player")` and `C_Map.GetPlayerMapPosition`).
- [ ] Fill your bags to the threshold inside a battleground: no question appears there; after you leave, the sell question appears once (the old bug lost it for good). Same for repair in a dungeon.
- [ ] Walk outside, enter a dungeon, click a row: the pin searches from the anchor (chat says so). Check `/cvn anchor last` against your last position outside and `/cvn anchor hearth` against your hearthstone point.
- [ ] Battleground row click uses the last outdoor position whichever anchor is set.
- [ ] TomTom: set a waypoint from inside an instance. If it is refused, chat says so; note what the map pin does on Forever.

### 13.5 Anchors and the hearthstone point

- [ ] `GetBindLocation()` text on Forever and Era (`/dump GetBindLocation()`): a place name. Set your hearthstone at a new inn and relog or change zone: `/cvn log` shows the new hearth point only when the name changed and you were standing in the inn area; a failed read keeps the old point.
- [ ] Before the hearthstone point is known, `/cvn anchor hearth` falls back to the last outdoor position.
- [ ] `/cvn anchor hearth` and `/cvn anchor last` match the Search from, inside an instance dropdown; anything else gets a message.

### 13.6 Auction house

- [ ] `/cvn ah on` matches the Route to the auction house checkbox; default is off. With it off a row click always picks a vendor.
- [ ] With it on, standing near a major city auction house, click a tradeable row (a reagent or Bag space): the auctioneer is pinned when it is closer than the nearest vendor, and a vendor otherwise. Inside an instance the auction house is ignored.
- [ ] Open an auction house you have never opened: note the event that fires on Forever (the addon listens for the auction house open event; confirm its name) and that the auctioneer is learned (`/cvn log` shows it) and survives a restart. A shipped auctioneer (28 with coordinates) is found where the pin says.
- [ ] Item binding: confirm the tradeable and soulbound handling on 1.60 for the items shown (all current rows are tradeable).

### 13.7 Buying reagents

Use a mage who knows Arcane Brilliance and Teleport (or another class with vendor reagents), a reagent vendor, and `/cvn debug on`.

- [ ] Defaults on a fresh install: `/cvn` shows "Reagent buying: off, asks first, up to 20 of each"; `/cvn log` has "reagent buying: off, asks first, up to 20 of each". Opening a reagent vendor buys nothing.
- [ ] Settings page, Reagents: below the reagent checkboxes are Buy reagents, Ask before buying reagents and the amount slider (0-100, default 20). Ask and the slider are greyed while Buy reagents is off. They match `/cvn reagentbuy on/off`, `ask/auto` and `/cvn reagentbuy 35`; 101, -1 and 2.5 are refused with a message. As a Hunter, Warrior or Warlock all three are greyed out with "Your class does not use reagents." and `/cvn reagentbuy on` says the same.
- [ ] Buys to N: `/cvn reagentbuy on`, `/cvn reagentbuy auto`, carry 7 Arcane Powder and 0 Runes of Teleportation, open the vendor: you end with exactly 20 of each, and one chat line names both with counts and the cost. Open it again: nothing more is bought, no chat line. Check the bag counts and the money spent match the line.
- [ ] Single items in one call: with debug on, note in `/cvn log` how many items one `BuyMerchantItem(index, quantity)` call bought (the addon asks for up to `GetMerchantItemMaxStack` per call). If a call buys only one item, the count will fall short: copy the log into a bug report. Note whether `GetMerchantItemMaxStack` exists on Forever and on Era.
- [ ] Ask first (`/cvn reagentbuy ask`, the default): a dialog lists the reagents, counts and total price; nothing is bought until Yes; No or Esc buys nothing. With an ammo purchase question at the same time (a rogue with a bow and `/cvn buy ask` at a vendor selling both arrows and Flash Powder), both dialogs show and neither replaces the other.
- [ ] 0: `/cvn reagentbuy 0` buys nothing, no dialog.
- [ ] No money: with less gold than one reagent costs, "You cannot afford any reagents here." With enough for part of the list, only that part is bought, in table order, and the line ends "(all you could afford)".
- [ ] Full bags: with no free slot in ordinary bags (quivers, soul bags and profession bags do not count) and no partial stack of the reagent, "Your bags have no room for reagents." With one free slot, only what fits is bought and the line ends "(all that fits in your bags)". A partial stack of the reagent is topped up.
- [ ] Switched-off and unknown: a reagent switched off on the Reagents page, or for a spell you do not know (a low-level mage: Rune of Portals), is not bought. Soul Shards, Blinding Powder and conjured items are never bought.
- [ ] A rogue buying ammo and Flash Powder at once with `/cvn buy auto` and `/cvn reagentbuy auto`: with gold for only the ammo, no Flash Powder is bought (the ammo cost is taken off first).
- [ ] Closing the merchant before answering Yes: note what the game does with the purchase (the dialog stays; the ammo dialog behaves the same).

## Not covered yet

- Walking distance (vendors are chosen by straight-line distance).
- Warlock shards and rogue poisons.
