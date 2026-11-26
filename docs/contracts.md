# Contracts

What other tools read from ClosestVendor. A change to anything here is a plan change: update the plan that checks it (`plans/closestvendor.yaml`, or a feature plan) in the same change (AGENTS.md, CheckThat). A line or entry marked "Diagnostic, no plan step" is kept for the debug report and for a later check; no plan asserts it now.

## Saved variables

| Global | Scope | Holds |
| --- | --- | --- |
| `ClosestVendorDB` | account | learned vendors, trainers and auctioneers |
| `ClosestVendorCharDB` | character | settings (`cfg`), standing, professions, the hearthstone point, window positions, the debug log (`log`) |

- `ClosestVendorCharDB.realSettings` is present only while test settings are on: `{ cfg, hud, toast }`, deep copies of the player's own settings and positions put aside. `ClosestVendorCharDB.cfg`, `hud` and `toast` then hold the test set. Plans never read it.

## Debug log

- Source `debug` in the plan: `ClosestVendorCharDB.log.entries`, format `entries` (`{ t = seconds, msg = text }`), newest last, at most 1000 (300 before 1.11.3).
- Records only while `/cvn debug on`. A new character starts with it off.
- Lines are `area: text` with no `[tag]`. Many are built by concatenation, so the plan asserts the literal part (`contains`) or a `pattern`.
- Lines from the CheckThat integration, written only at login and on a failure: `checkthat: entries registered: <n>`, `checkthat: FAILED: <why>`. An entry call writes nothing.
- `debug log turned on` and `debug log turned off` mark each toggle; the off line is the last line before the log stops.
- Test settings (`/cvn testsettings on|off`; `Core.lua`, `swapTestSettings` and `start`): `test settings: on (own settings put aside)`, `test settings: reset to defaults` (`on` while on), `test settings: off (own settings restored)` after each switch; `test settings: not on` for an `off` while off; `test settings: on at login` right after `---- login ----` while the mode is on. A switch is never logged as `setting changed:` lines. The setup step of each plan asserts the login line; the last step asserts the off line. `test settings: reset to defaults`, `test settings: not on` and `question withdrawn: test settings switched` (an open route question closed by a switch) are diagnostic, no plan step.
- `---- login ----` starts the lines of each session, at login and after each `/reload`; the setup step of each plan asserts it after its reload.
- `event <name>[ <arg>]` records a game event the addon reacts to (`Core.lua`, OnEvent), for example `event PLAYER_REGEN_ENABLED`.

### Warning decisions

Lines the plan asserts for the warnings. `<kind>` is `sell`, `repair`, `ammo`, `reagent <item id>`, `food`, `water` or `pet` for a trigger, and `sell`, `repair`, `arrow`, `bullet`, `reagent`, `supply` or `trainer` for a question.

| Line | Written |
| --- | --- |
| `trigger go <kind> (bags=… durability=… ammo=<arrow or bullet>:<n> combat=…)`, `trigger clear <kind>` | a request starts or ends (`Controller.lua`, Evaluate). `ammo=n/a` when no bow, crossbow or gun is equipped or its ammo cannot be read (with the ammo warning off and a bow equipped it still writes `ammo=arrow:<n>`); `durability=n/a` when no item has durability |
| `trigger held in an instance: <kind>`, `trigger held while dead: <kind>`, `trigger held in combat: <kind>` | a request that would go now waits; once per reason and kind while that reason lasts (a later check in the same fight logs nothing, also after the request ended and came back), again after the reason ended or changed. An instance comes before death, and death comes before combat (dead in a fight is `while dead`). Diagnostic, no plan step. |
| `reminder held in an instance: <key>`, `reminder held while dead: <key>`, `reminder held in combat: <key>` | a notice-only reminder (`food`, `water`, `healthstone`) that is due waits (`Triggers.Reminders` names the keys it held back); once per reason and key, like the trigger lines. The `reminder: <key> (<n>)` line follows once the reason ends. Diagnostic, no plan step. |
| `question shown: <kind>, <vendor> (npc <id>), <source>, <n> yd` (reagent and supply lines put the item before the vendor and add `, <count> left` at the end; trainer lines name `trainer for <profession>` and add `, <points> point(s) left` at the end when a skill check asked, never for `/cvn test trainer`) | a question is asked; `<source>` is where the target came from (`learned` when this account learned it, `NorgannonDB` when only that addon gave it, otherwise `shipped`) and `<n>` is the distance in whole yards from where the search started (the player, or the hearthstone point or last position outside in an instance); with `/cvn choice auto` the line is `auto: <vendor> (npc <id>)` instead, ending ` chosen from two candidates: the one on your map` or `: the closest` when there were two (which one was taken, not the setting); the waypoint is proven by the next line, `accepted: <vendor> via <method>` (`nothing available` when no method took it) |
| `test command: <kind>`, then `test command: nothing asked: <why>` | `/cvn test` ran; the second line when it asked nothing: `the class does not use water`, `no pet to feed`, `no class reagent watched`, `no map position here`, `no known vendor`, `no known trainer`, `the bags cannot be read` (the chat line says the same). `<kind>` also covers `trainer` (`/cvn test trainer`, the nearest known profession trainer) |
| `question declined: <kind>`, `accepted: <vendor> via <provider>` (`via nothing available` when no waypoint was set) | No, Cancel or Escape; Yes, This map or Closest |
| `question closed: merchant opened (<kind>)` | a merchant window opened while a vendor question showed and closed it; written after the close, once the question is no longer shown (`Controller.lua`, OnMerchantShow). A trainer question stays open and writes nothing. Diagnostic, no plan step. |
| `FAILED: question still shown after the merchant opened (<kind>)` | the vendor question was still shown after the close; no `question closed` line then. Diagnostic, no plan step. |
| `request released: <kind>`, `request put back: <kind> (a click replaced it)`, `question withdrawn: the player changed zone`, `ammo request restarted: <old> -> <new>`, `pet request restarted: <old> -> <new>` | a request ends without a trip, a click replaced it, a zone change withdrew it, a new weapon or pet asked again. No plan step asserts them now: diagnostic, no plan step |
| `ammo watched: arrow` (or `bullet`), `ammo not watched: no bow, crossbow or gun equipped, or its ammo cannot be read`, `ammo not watched: the ammo warning is off` | the watched ammo changes; once per change. A weapon read that fails for a moment can write a not-watched and watched pair. Diagnostic, no plan step. |
| `purchase question closed with the merchant: ammo`, `purchase question closed with the merchant: reagents` | the merchant closed with that purchase question open; written after the hide, once the question is no longer shown (`Core.lua`, MERCHANT_CLOSED). Diagnostic, no plan step. |
| `FAILED: purchase question still shown after the merchant closed: ammo`, `... : reagents` | that purchase question was still shown after the hide; no `closed with the merchant` line then. Diagnostic, no plan step. |
| `ammo buy: bought <n> of item <id>`, `reagent buy: bought <id>x<n> ...` | the purchase calls the game took; only those are counted. A call the game took can still be refused without an error (no money, bags full). The ammo line ends ` (all you could afford)` when gold cut the purchase short. Diagnostic, no plan step. |
| `ammo buy: <mode> <arrow or bullet> item <id>, price <copper> per <n>, space <n>, money <copper>` | the ammo purchase is planned: `<mode>` is the grade setting for that kind (`equipped`, `best`, `cheapest`). Written before the purchase or the question. Then `ammo buy: cannot afford one purchase` or `less than one purchase of room` when nothing can be bought. Diagnostic, no plan step. |
| `ammo buy: off`, `ammo buy: no bow, crossbow or gun equipped, or its ammo cannot be read`, `ammo buy: merchant sells no <kind>s (<n> ammo item(s))`, `ammo buy: no <kind> offer for mode <mode>, equipped item <id>` | a merchant opened and the ammo purchase stopped there. Diagnostic, no plan step. |
| `reagent buy: target <n>, money <copper>, plan: <id>x<n> ... (or nothing), cost <copper>, short: money (or bags, nil)` | the reagent purchase is planned; `reagent buy: off`, `amount is 0`, `no class reagent watched`, `merchant sells no class reagents` when it stopped first. Diagnostic, no plan step. |
| `ammo buy: asked`, `reagent buy: asked` | the purchase question is on screen (`Core.lua`, askPurchase; written after `StaticPopup_Visible` confirms it). `ammo buy: FAILED: the question did not show` (or `reagent buy: ...`) when it is not. Diagnostic, no plan step. |
| `ammo buy: at Yes: fewer than asked: <n> of <m> purchases, space <items>`, `reagent buy: at Yes: fewer than asked: <id>x<n> ... (asked <id>x<n> ...)` | at Yes the room, the money or the reagents carried had changed (for example after buying some by hand), so the addon buys less than the question named. Written after the purchase, from the purchases that went through (`<n>` and the `<id>x<n>` list are what was bought), only when they match the smaller plan, just before the `bought` line. Buying the asked amount writes no such line, and neither does a failed call (`FAILED:` instead). Not written when nothing is left (`nothing left to buy`). Diagnostic, no plan step. |
| `ammo buy: declined`, `reagent buy: declined` | the player answered No or pressed Escape; nothing is bought. Yes writes the purchase's own lines (`bought`, `nothing left to buy`, `purchase dropped: the merchant window changed`). Diagnostic, no plan step. |
| `ammo buy: FAILED: <n> of <m> purchases of item <id> did not go through`, `reagent buy: FAILED: did not go through: <id>x<n> ...` | a purchase call raised an error; no `bought` line when none went through. Diagnostic, no plan step. |
| `instance: <old> -> <new>` | the instance type changed (`none`, `party`, `raid`, `pvp`). Diagnostic, no plan step. |
| `two targets: on your map <vendor> (npc <id>), closest <vendor> (npc <id>), prefer map` (or `prefer distance`) | the nearest target is on another map and one is on the player's map; written just before the `question shown:` or `auto:` line it belongs to. `prefer map` puts the map one first. Diagnostic, no plan step. |

### Status window and settings

| Line | Written |
| --- | --- |
| `status window: shown, rows: <keys>`, `status window: hidden` | the status window was redrawn with its real rows and the frame was checked: shown with rows, or hidden with none. `<keys>` are the row keys in window order (`ammo`, `reagent:<item id>`, `supply:food`, `supply:water`, `supply:pet`, `bags`, `durability`, `prof:<profession>`), each followed by ` low` when low (`bags low, durability`). Written only when that text changes: shown or hidden, the row set or a low flag, never a count. Nothing is written while a demo, a preview or Move draws made-up rows. The first redraw after a login or reload writes the state once |
| `status window: FAILED: not shown, rows: <keys>`, `status window: FAILED: still shown with no rows` | the frame did not follow the rows. Diagnostic, no plan step. |
| `status window: visibility unknown, rows: <keys>` | the game did not say whether the frame is on screen; `<keys>` as above, or `none` with no rows. Never written as `hidden`. Diagnostic, no plan step. |
| `status window: FAILED: not logged: <error>` | the window was drawn but noting its state raised an error; the window stays on and the next redraw logs its state again. Written once until another line replaces it. Diagnostic, no plan step. |
| `setting changed: <key> <old> -> <new>` | a setting was stored; one line per key that changed. `<key>` is the saved name in `cfg` (`bagThreshold`, `reagentBuyTarget`, `instanceAnchor`, ...), `hudRow.<group>` for a row group's mode (`low`, `always`, `never`), `reagentOff.<item id>` for a reagent switched off; values are as saved (`true`, `false`, numbers, words), `none` when not set. A slash command is written at once; the settings page and the colour picker are written once, a second after the last change, from the value before the first. A page change still waiting when a slash command runs is written first, before the command's own lines. Values set at load (defaults, the notification style migration) are the starting values and are never written. Check 1.5 matches `setting changed: bagThreshold 200 -> 2`. |
| `status window position reset` | `/cvn hud reset`. Diagnostic, no plan step. |
| `row click: <key> (<text>)`, `row click: nothing pinned` | a routable status window row was clicked (`Core.lua`, the row's key and its text); the second line when the click pinned nothing (no known trainer or vendor, or a row that cannot be routed). The `direct pin:` lines follow the first. Diagnostic, no plan step. |

### Vendors, trainers and navigation

| Line | Written |
| --- | --- |
| `NorgannonDB: not found` (or `NorgannonDB: found, schema ...`, `NorgannonDB: installed, but ...`: the `external` entry's text) | at each login, after `---- login ----`, and when NorgannonDB loads late. Diagnostic, no plan step. |
| `vendor learned: <name> (npc <id>), new` (or `updated`, `unchanged`) | a merchant window opened and was read (`Core.lua`, learnMerchant). `new` means new to the account's learned table; `unchanged` means nothing changed, and a position within `D.NEAR` (0.005 of the map on each axis, same map) of the saved one counts as no change (the saved position stays); `updated` means the vendor moved further or another field changed; a vendor that was not shipped, not from NorgannonDB and not learned before adds `; it was not in the search pool`. A NorgannonDB vendor adds `; replaces the NorgannonDB position` (a learned position on another map, or more than 0.03 away; a learned record with no position never replaces it) or `; the NorgannonDB position is kept`. A later read of the same window (item data arrived) writes a line only when it stored something |
| `merchant list not fully loaded: kept what is known about <name>` | a known vendor's list was only partly readable; once per window. Diagnostic, no plan step. |
| `trainer learned: <name> (npc <id>), new, teaches <professions>` (or `updated`, `unchanged`) | a profession trainer's window was read: once per window, at the first read that lists its services (`TRAINER_SHOW`, or a later `TRAINER_UPDATE` when the services arrive late). Another `TRAINER_UPDATE` writes it again only when it stored something |
| `auctioneer learned: <name> (npc <id>), new` (or `updated`, `unchanged`) | an auction house window opened (`AUCTION_HOUSE_SHOW`, `Core.lua`, learnAuctioneer); once per window. `new` means new to the account's learned auctioneers, `updated` that the stored record changed (another position). Diagnostic, no plan step. |
| `trainer not learned: <name> (npc <id>): no map position here`, `vendor not learned: <name> (npc <id>): no map position here`, `auctioneer not learned: <name> (npc <id>): no map position here` | the window was read but the game gave no map position, so nothing was stored; once per window. Diagnostic, no plan step. |
| `trainer window: nothing learned: not a profession trainer` (or `the game cannot tell whether it is a profession trainer`, `the trainer cannot be identified`, `no profession services listed yet`) | a trainer window opened that taught nothing; once per `TRAINER_SHOW`. `the game cannot tell ...` means `IsTradeskillTrainer` is missing or raised an error, so the kind of trainer is unknown. Diagnostic, no plan step. |
| `trainer services: <n> listed; filters available=<v> unavailable=<v> used=<v>`, then one line per service | the trainer probe (spec diagnostics): a profession trainer window became readable with the debug log on; once per window. Values the client does not give are `nil` |
| `standing: npc <id> will trade`, `standing: npc <id> will not trade (Unfriendly or Hostile)` | target, mouseover or nameplate of a known vendor, trainer or auctioneer changed what this character knows. Diagnostic, no plan step. |
| `standing: npc <id> will not trade (Unfriendly or Hostile), already known` | the player targeted one this character already knows will not trade (target only). Once, then again only after another standing line or 30 seconds, so retargeting does not flood the log. Diagnostic, no plan step. |
| `waypoint cleared: a merchant window opened`, `waypoint kept: it leads to a <profession> trainer` | a merchant window opened with a waypoint set (`Controller.lua`, OnMerchantShow), after the clear |
| `FAILED: waypoint not cleared: a merchant window opened` | the waypoint method (TomTom, WaypointUI, the game waypoint) raised an error while removing it; the addon forgets the waypoint either way. Diagnostic, no plan step. |
| `waypoint clear not confirmed: a merchant window opened` | the waypoint method cannot confirm the removal (`Nav.Clear` returned nil: TomTom without RemoveWaypoint, WaypointUI without GetUserNavigation, the game without ClearUserWaypoint); the waypoint may still show, and the addon forgets it. Diagnostic, no plan step. |
| `trainer waypoint cleared: the <profession> trainer window opened`, `trainer waypoint cleared: <profession> is no longer near its cap`, `trainer waypoint cleared: <profession> was unlearned` | the trainer waypoint ended, after the clear. `FAILED: trainer waypoint not cleared: <the same reason>` when the waypoint method raised an error while removing it, `trainer waypoint clear not confirmed: <the same reason>` when it cannot confirm the removal (as above). Diagnostic, no plan step. |
| `choice menu shown: <row>, <n> entries` | a row's arrow opened the game's menu of other sellers, after the menu control took it; picking nothing writes no `chosen pin: `. Diagnostic, no plan step. |
| `direct pin: <kind>[ <id>]`, `chosen pin: <kind>[ <id>], <seller>` | a row click or a menu pick, written before the target is checked; `accepted: ` follows when a waypoint was set. Diagnostic, no plan step. |
| `direct pin: the search started from your hearthstone point` (or `your last position outside`) | a row click inside an instance searched from that anchor. Diagnostic, no plan step. |
| `direct pin: Artisan <profession> is not routed: trainer tiers unknown` | a profession row click for Artisan near its cap (within the threshold) without NorgannonDB trainer tiers. Diagnostic, no plan step. |
| `direct pin: profession is not routed: <why>`, `direct pin: profession is not near its cap` | a profession row click the addon does not route. `<why>` is the profession check's reason (`level <n> needed`, `the last tier`, `no trainer or crafting window seen`); `not near its cap` when it is not within the threshold. Diagnostic, no plan step. |
| `demo: your game waypoint restored, tracked` (or `, not tracked`) | `/cvn demo` ended and put the player's own game waypoint back. Diagnostic, no plan step. |
| `demo: pin without asking, <kind>`, `demo: question, <kind>`, `demo: row click, <row>`, `demo: reminder`, `demo: over`, `demo: previous waypoint restored` | `/cvn demo` ran a tour step, ended, and put the addon's own earlier waypoint back (`Controller.lua`, Demo). Diagnostic, no plan step. |
| `find: "<text>", <n> item(s)`, `find: no item matches` | `/cvn find` or Find supplies ran a search (`Controller.lua`, Find). Diagnostic, no plan step. |
| `find: <item> looked up as <name>`, `find: <item> is known, no seller` | the item was looked up as a supply kind in general, or no known seller sells it |
| `find: seller list for <item>, <n> entries`, `find: chosen <seller>`, `find: nothing pinned`, `find: no menu control` | the seller list opened at the mouse, a seller was picked (`accepted: ` follows when a waypoint was set), the pick pinned nothing, or the client has no menu control. Diagnostic, no plan step. |

### Professions

One line per check (a skill change or a craft), only with the profession warning on. The `left out` and `skipped` lines are written when they differ from the last such line (for `left out`, the skills and reasons, not the ranks: a skill-up alone writes nothing new), after a change of state (a question shown or declined, a waypoint set or cleared), or after 30 seconds; a craft repeated with nothing changed writes `a craft finished` only.

| Line | Written |
| --- | --- |
| `a skill changed`, `a craft finished` | a check runs. Diagnostic, no plan step. |
| `profession check: left out: <skill> <rank>/<max> (<why>)`, ... | skills within the threshold of their cap that are not asked about. `<why>` is `no trainer or crafting window seen` (also weapon skills; only below 300), `the last tier`, `Artisan: trainer tiers unknown` or `level <n> needed`. Diagnostic, no plan step. |
| `profession check skipped: a question is open`, `... : a <profession> trainer waypoint is set`, `... : the <kind> request is open or active`, `... : in combat or dead`, `... : in an instance` | a profession is near its cap, but this check asks nothing. Diagnostic, no plan step. |
| `trainer search: <profession> needs tier <n>; nearest <trainer> (npc <id>) teaches tier <n>` (or `an unknown tier`) | a trainer was found for a tier the profession needs (Journeyman or higher). The next line is always the offer: `question shown: trainer for <profession>, ...` when the target choice is Ask, or `auto: <trainer> ...` when it is Automatic (`offer` in `Controller.lua` has no other outcome). A check asserts the one it needs. Tiers: 2 Journeyman, 3 Expert, 4 Artisan. Diagnostic, no plan step. |
| `no known trainer for <profession>` | no trainer is known on this continent; once per profession per session. Diagnostic, no plan step. |

## CheckThat entries

Registered at `PLAYER_LOGIN` by `ClosestVendor/CheckThat.lua`, addon name `ClosestVendor`. Each is read-only and writes nothing, not even the debug log. Results are cut to 100 characters. An error inside an entry returns `error: <message>`.

| Entry | Arguments | Returns |
| --- | --- | --- |
| `version` | none | major*10000 + minor*100 + patch (1.11.0 is 11100), from the TOC version read once at login; nothing when it is unknown |
| `setting` | a `/cvn get` key, any case | the text `/cvn get` prints (`bags.threshold` at its default is `2`); nothing for an unknown key. Diagnostic, no plan step: only the offline block of `plans/closestvendor.yaml` calls it |
| `integration` | none | `working`, `not detected`, `too old` or `failed: <why>`. Diagnostic, no plan step: only the offline block of `plans/closestvendor.yaml` calls it |
| `active` | none | the warning request that is open or active now (`Triggers.Active`): `sell`, `repair`, `ammo`, `food`, `water`, `pet`, or for a reagent `reagent <item id>` (for example `reagent 17020`); nothing when there is none. A request answered with No is not active, though it waits until its condition clears |
| `learned` | `vendors`, `trainers` or `auctioneers` (any case), and optionally an npc id (number or text) | without an id, how many the account learned (a number, `0` included); with an id, `true` when that one is learned, else nothing. An unknown kind returns nothing. Diagnostic, no plan step: only the offline block of `plans/closestvendor.yaml` calls it |
| `standing` | an npc id (number or text) | `true` (Neutral or better, or its window opened), `false` (Unfriendly or Hostile) as this character saw it, or nothing when it never saw that npc. Diagnostic, no plan step |
| `nav` | none | the waypoint method the addon uses now: `tomtom`, `waypointui`, `native` or `chat`. Core keeps it from login, each world entry, each slash command, each settings page change and each addon that loads, so the call never reaches the game. Diagnostic, no plan step |
| `window` | none, or a row group (`ammo`, `reagents`, `supplies`, `bags`, `durability`, `professions`, any case) | with a group: that group's row keys as the `status window:` line writes them (`supply:food low`), or `none` when the window shows none of them; nothing for another name, while made-up rows show, or while the window state is unknown (as below). Without one: what the status window shows now, as Core kept it after its last redraw: `hidden`, `shown: <keys>` (the keys of the `status window:` line, for example `shown: bags low, durability`), `demo` while a demo, a preview or Move draws made-up rows, or nothing when there is no window, the last draw failed or the game did not say whether the frame is shown. Diagnostic, no plan step |
| `config` | a saved setting's name (any case), or `hudRow.<group>` | the value as text (`true`, `150`, `hearth`, `ask`), or the group's mode (`low`, `always`, `never`). Only the names in `CT.CONFIG` in `CheckThat.lua` (the thresholds and switches, buying, the target choice, the status window, the instance anchor, auction house routing, supplies, the sound, the waypoint choice and the notification style); nothing for any other name or a value that is not set. Diagnostic, no plan step. |
| `reagents` | none, or an item id (number or text) | the class reagents the warning watched at its last check: `<item id>:<count>` sorted by id and joined by `,` (`17020:5,17031:3`), `none` when none is watched, nothing before the first check or when the last check could not read them (class unknown); with an id, that reagent's count, or nothing when it is not watched. A switched-off reagent or one whose spell is not known is not watched; bags only, never the bank. Diagnostic, no plan step |
| `external` | none | what NorgannonDB gave: `found, schema <s>, <n> vendors added, <n> skipped, <n> trainers with a tier`, `installed, but its data is not a supported schema` or `not found` (the same text as the report's NorgannonDB line). Diagnostic, no plan step. |

After a CheckThat call raises, only `integration` answers; the others return nothing.

## CheckThat facts

None reported yet. The plan reads CheckThat's own `CheckThatDB.global.facts` (source `facts`; entry results appear as `entry.<name>`) and `CheckThatDB.global.errors` (source `errors`, quiet).

## Report header

`/cvn log` has the line `test settings: on` or `test settings: off`. Diagnostic, no plan step.

`/cvn log` has the line `CheckThat: working`, `CheckThat: not detected`, `CheckThat: too old` (loaded, but it has no `Entry` to register with) or `CheckThat: failed: <why>`.
