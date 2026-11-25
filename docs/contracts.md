# Contracts

What other tools read from ClosestVendor. A change to anything here is a plan change: update `plans/closestvendor.yaml` in the same change (AGENTS.md, CheckThat).

## Saved variables

| Global | Scope | Holds |
| --- | --- | --- |
| `ClosestVendorDB` | account | learned vendors, trainers and auctioneers |
| `ClosestVendorCharDB` | character | settings (`cfg`), standing, professions, the hearthstone point, window positions, the debug log (`log`) |

## Debug log

- Source `debug` in the plan: `ClosestVendorCharDB.log.entries`, format `entries` (`{ t = seconds, msg = text }`), newest last, at most 300.
- Records only while `/cvn debug on`. A new character starts with it off.
- Lines are `area: text` with no `[tag]`. Many are built by concatenation, so the plan asserts the literal part (`contains`) or a `pattern`.
- Lines from the CheckThat integration, written only at login and on a failure: `checkthat: entries registered: <n>`, `checkthat: FAILED: <why>`. An entry call writes nothing.
- `debug log turned on` and `debug log turned off` mark each toggle; the off line is the last line before the log stops.

### Warning decisions

Lines the plan asserts for the warnings. `<kind>` is `sell`, `repair`, `ammo`, `reagent <item id>`, `food`, `water` or `pet` for a trigger, and `sell`, `repair`, `arrow`, `bullet`, `reagent`, `supply` or `trainer` for a question.

| Line | Written |
| --- | --- |
| `trigger go <kind> (bags=… durability=… ammo=<arrow or bullet>:<n> combat=…)`, `trigger clear <kind>` | a request starts or ends (`Controller.lua`, Evaluate). `ammo=n/a` when no bow, crossbow or gun is equipped or its ammo cannot be read (with the ammo warning off and a bow equipped it still writes `ammo=arrow:<n>`); `durability=n/a` when no item has durability |
| `trigger held in an instance: <kind>`, `trigger held while dead: <kind>`, `trigger held in combat: <kind>` | a request that would go now waits; once per reason and kind while that reason lasts (a later check in the same fight logs nothing, also after the request ended and came back), again after the reason ended or changed. An instance comes before death, and death comes before combat (dead in a fight is `while dead`) |
| `question shown: <kind>, <vendor> (npc <id>)` (reagent, supply and trainer lines add the item and the count) | a question is asked; with `/cvn choice auto` the line is `auto: <vendor> (npc <id>)` instead, ending ` chosen from two candidates: the one on your map` or `: the closest` when there were two (which one was taken, not the setting); the waypoint is proven by the next line, `accepted: <vendor> via <method>` (`nothing available` when no method took it) |
| `question declined: <kind>`, `accepted: <vendor> via <provider>` (`via nothing available` when no waypoint was set) | No, Cancel or Escape; Yes, This map or Closest |
| `question closed: merchant opened (<kind>)` | a merchant window opened while a vendor question showed and closed it; written after the close, once the question is no longer shown (`Controller.lua`, OnMerchantShow). A trainer question stays open and writes nothing |
| `FAILED: question still shown after the merchant opened (<kind>)` | the vendor question was still shown after the close; no `question closed` line then |
| `request released: <kind>`, `request put back: <kind> (a click replaced it)`, `question withdrawn: the player changed zone`, `ammo request restarted: <old> -> <new>`, `pet request restarted: <old> -> <new>` | a request ends without a trip, a click replaced it, a zone change withdrew it, a new weapon or pet asked again |
| `ammo watched: arrow` (or `bullet`), `ammo not watched: no bow, crossbow or gun equipped, or its ammo cannot be read`, `ammo not watched: the ammo warning is off` | the watched ammo changes; once per change. A weapon read that fails for a moment can write a not-watched and watched pair |
| `purchase question closed with the merchant: ammo`, `purchase question closed with the merchant: reagents` | the merchant closed with that purchase question open; written after the hide, once the question is no longer shown (`Core.lua`, MERCHANT_CLOSED) |
| `FAILED: purchase question still shown after the merchant closed: ammo`, `... : reagents` | that purchase question was still shown after the hide; no `closed with the merchant` line then |
| `ammo buy: bought <n> of item <id>`, `reagent buy: bought <id>x<n> ...` | the purchase calls the game took; only those are counted. A call the game took can still be refused without an error (no money, bags full) |
| `ammo buy: FAILED: <n> of <m> purchases of item <id> did not go through`, `reagent buy: FAILED: did not go through: <id>x<n> ...` | a purchase call raised an error; no `bought` line when none went through |
| `instance: <old> -> <new>` | the instance type changed (`none`, `party`, `raid`, `pvp`) |
| `two targets: on your map <vendor> (npc <id>), closest <vendor> (npc <id>), prefer map` (or `prefer distance`) | the nearest target is on another map and one is on the player's map; written just before the `question shown:` or `auto:` line it belongs to. `prefer map` puts the map one first |

### Vendors, trainers and navigation

| Line | Written |
| --- | --- |
| `NorgannonDB: not found` (or `NorgannonDB: found, schema ...`, `NorgannonDB: installed, but ...`: the `external` entry's text) | at each login, after `---- login ----`, and when NorgannonDB loads late |
| `vendor learned: <name> (npc <id>), new` (or `updated`, `unchanged`) | a merchant window opened and was read (`Core.lua`, learnMerchant). `new` means new to the account's learned table; a vendor that was not shipped, not from NorgannonDB and not learned before adds `; it was not in the search pool`. A NorgannonDB vendor adds `; replaces the NorgannonDB position` (a learned position on another map, or more than 0.03 away; a learned record with no position never replaces it) or `; the NorgannonDB position is kept`. A later read of the same window (item data arrived) writes a line only when it stored something |
| `merchant list not fully loaded: kept what is known about <name>` | a known vendor's list was only partly readable; once per window |
| `trainer learned: <name> (npc <id>), new, teaches <professions>` (or `updated`, `unchanged`) | a profession trainer's window was read: once per window, at the first read that lists its services (`TRAINER_SHOW`, or a later `TRAINER_UPDATE` when the services arrive late). Another `TRAINER_UPDATE` writes it again only when it stored something |
| `trainer not learned: <name> (npc <id>): no map position here`, `vendor not learned: <name> (npc <id>): no map position here` | the window was read but the game gave no map position, so nothing was stored; once per window |
| `trainer window: nothing learned: not a profession trainer` (or `the game cannot tell whether it is a profession trainer`, `the trainer cannot be identified`, `no profession services listed yet`) | a trainer window opened that taught nothing; once per `TRAINER_SHOW`. `the game cannot tell ...` means `IsTradeskillTrainer` is missing or raised an error, so the kind of trainer is unknown |
| `standing: npc <id> will trade`, `standing: npc <id> will not trade (Unfriendly or Hostile)` | target, mouseover or nameplate of a known vendor, trainer or auctioneer changed what this character knows |
| `standing: npc <id> will not trade (Unfriendly or Hostile), already known` | the player targeted one this character already knows will not trade (target only). Once, then again only after another standing line or 30 seconds, so retargeting does not flood the log |
| `waypoint cleared: a merchant window opened`, `waypoint kept: it leads to a <profession> trainer` | a merchant window opened with a waypoint set (`Controller.lua`, OnMerchantShow), after the clear |
| `FAILED: waypoint not cleared: a merchant window opened` | the waypoint method (TomTom, WaypointUI, the game waypoint) raised an error while removing it; the addon forgets the waypoint either way |
| `waypoint clear not confirmed: a merchant window opened` | the waypoint method cannot confirm the removal (`Nav.Clear` returned nil: TomTom without RemoveWaypoint, WaypointUI without GetUserNavigation, the game without ClearUserWaypoint); the waypoint may still show, and the addon forgets it |
| `trainer waypoint cleared: the <profession> trainer window opened`, `trainer waypoint cleared: <profession> is no longer near its cap`, `trainer waypoint cleared: <profession> was unlearned` | the trainer waypoint ended, after the clear. `FAILED: trainer waypoint not cleared: <the same reason>` when the waypoint method raised an error while removing it, `trainer waypoint clear not confirmed: <the same reason>` when it cannot confirm the removal (as above) |
| `choice menu shown: <row>, <n> entries` | a row's arrow opened the game's menu of other sellers, after the menu control took it; picking nothing writes no `chosen pin: ` |
| `direct pin: <kind>[ <id>]`, `chosen pin: <kind>[ <id>], <seller>` | a row click or a menu pick, written before the target is checked; `accepted: ` follows when a waypoint was set |
| `direct pin: the search started from your hearthstone point` (or `your last position outside`) | a row click inside an instance searched from that anchor |
| `direct pin: Artisan <profession> is not routed: trainer tiers unknown` | a profession row click for Artisan near its cap (within the threshold) without NorgannonDB trainer tiers |
| `direct pin: profession is not routed: <why>`, `direct pin: profession is not near its cap` | a profession row click the addon does not route. `<why>` is the profession check's reason (`level <n> needed`, `the last tier`, `no trainer or crafting window seen`); `not near its cap` when it is not within the threshold |
| `demo: your game waypoint restored, tracked` (or `, not tracked`) | `/cvn demo` ended and put the player's own game waypoint back |

### Professions

One line per check (a skill change or a craft), only with the profession warning on. The `left out` and `skipped` lines are written when they differ from the last such line (for `left out`, the skills and reasons, not the ranks: a skill-up alone writes nothing new), after a change of state (a question shown or declined, a waypoint set or cleared), or after 30 seconds; a craft repeated with nothing changed writes `a craft finished` only.

| Line | Written |
| --- | --- |
| `a skill changed`, `a craft finished` | a check runs |
| `profession check: left out: <skill> <rank>/<max> (<why>)`, ... | skills within the threshold of their cap that are not asked about. `<why>` is `no trainer or crafting window seen` (also weapon skills; only below 300), `the last tier`, `Artisan: trainer tiers unknown` or `level <n> needed` |
| `profession check skipped: a question is open`, `... : a <profession> trainer waypoint is set`, `... : the <kind> request is open or active`, `... : in combat or dead`, `... : in an instance` | a profession is near its cap, but this check asks nothing |
| `trainer search: <profession> needs tier <n>; nearest <trainer> (npc <id>) teaches tier <n>` (or `an unknown tier`) | a trainer was found for a tier the profession needs (Journeyman or higher). The next line is always the offer: `question shown: trainer for <profession>, ...` when the target choice is Ask, or `auto: <trainer> ...` when it is Automatic (`offer` in `Controller.lua` has no other outcome). A check asserts the one it needs. Tiers: 2 Journeyman, 3 Expert, 4 Artisan |
| `no known trainer for <profession>` | no trainer is known on this continent; once per profession per session |

## CheckThat entries

Registered at `PLAYER_LOGIN` by `ClosestVendor/CheckThat.lua`, addon name `ClosestVendor`. Each is read-only and writes nothing, not even the debug log. Results are cut to 100 characters. An error inside an entry returns `error: <message>`.

| Entry | Arguments | Returns |
| --- | --- | --- |
| `version` | none | major*10000 + minor*100 + patch (1.11.0 is 11100), from the TOC version read once at login; nothing when it is unknown |
| `setting` | a `/cvn get` key, any case | the text `/cvn get` prints (`bags.threshold` at its default is `2`); nothing for an unknown key |
| `integration` | none | `working`, `not detected`, `too old` or `failed: <why>` |
| `active` | none | the warning request that is open or active now (`Triggers.Active`): `sell`, `repair`, `ammo`, `food`, `water`, `pet`, or for a reagent `reagent <item id>` (for example `reagent 17020`); nothing when there is none. A request answered with No is not active, though it waits until its condition clears |
| `learned` | `vendors`, `trainers` or `auctioneers` (any case), and optionally an npc id (number or text) | without an id, how many the account learned (a number, `0` included); with an id, `true` when that one is learned, else nothing. An unknown kind returns nothing |
| `standing` | an npc id (number or text) | `true` (Neutral or better, or its window opened), `false` (Unfriendly or Hostile) as this character saw it, or nothing when it never saw that npc |
| `nav` | none | the waypoint method the addon uses now: `tomtom`, `waypointui`, `native` or `chat`. Core keeps it from login, each world entry, each slash command, each settings page change and each addon that loads, so the call never reaches the game |
| `external` | none | what NorgannonDB gave: `found, schema <s>, <n> vendors added, <n> skipped, <n> trainers with a tier`, `installed, but its data is not a supported schema` or `not found` (the same text as the report's NorgannonDB line) |

After a CheckThat call raises, only `integration` answers; the others return nothing.

## CheckThat facts

None reported yet. The plan reads CheckThat's own `CheckThatDB.global.facts` (source `facts`; entry results appear as `entry.<name>`) and `CheckThatDB.global.errors` (source `errors`, quiet).

## Report header

`/cvn log` has the line `CheckThat: working`, `CheckThat: not detected`, `CheckThat: too old` (loaded, but it has no `Entry` to register with) or `CheckThat: failed: <why>`.
