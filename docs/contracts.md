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
| `question shown: <kind>, <vendor> (npc <id>)` (reagent, supply and trainer lines add the item and the count) | a question is asked; with `/cvn choice auto` the line is `auto: <vendor> (npc <id>)` instead |
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

## CheckThat entries

Registered at `PLAYER_LOGIN` by `ClosestVendor/CheckThat.lua`, addon name `ClosestVendor`. Each is read-only and writes nothing, not even the debug log. Results are cut to 100 characters. An error inside an entry returns `error: <message>`.

| Entry | Arguments | Returns |
| --- | --- | --- |
| `version` | none | major*10000 + minor*100 + patch (1.11.0 is 11100), from the TOC version read once at login; nothing when it is unknown |
| `setting` | a `/cvn get` key, any case | the text `/cvn get` prints (`bags.threshold` at its default is `2`); nothing for an unknown key |
| `integration` | none | `working`, `not detected`, `too old` or `failed: <why>` |
| `active` | none | the warning request that is open or active now (`Triggers.Active`): `sell`, `repair`, `ammo`, `food`, `water`, `pet`, or for a reagent `reagent <item id>` (for example `reagent 17020`); nothing when there is none. A request answered with No is not active, though it waits until its condition clears |

After a CheckThat call raises, only `integration` answers; the others return nothing.

## CheckThat facts

None reported yet. The plan reads CheckThat's own `CheckThatDB.global.facts` (source `facts`; entry results appear as `entry.<name>`) and `CheckThatDB.global.errors` (source `errors`, quiet).

## Report header

`/cvn log` has the line `CheckThat: working`, `CheckThat: not detected`, `CheckThat: too old` (loaded, but it has no `Entry` to register with) or `CheckThat: failed: <why>`.
