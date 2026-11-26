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

## CheckThat entries

Registered at `PLAYER_LOGIN` by `ClosestVendor/CheckThat.lua`, addon name `ClosestVendor`. Each is read-only and writes nothing, not even the debug log. Results are cut to 100 characters. An error inside an entry returns `error: <message>`.

| Entry | Arguments | Returns |
| --- | --- | --- |
| `version` | none | major*10000 + minor*100 + patch (1.11.0 is 11100), from the TOC version read once at login; nothing when it is unknown |
| `setting` | a `/cvn get` key, any case | the text `/cvn get` prints (`bags.threshold` at its default is `2`); nothing for an unknown key |
| `integration` | none | `working`, `not detected`, `too old` or `failed: <why>` |

After a CheckThat call raises, only `integration` answers; the others return nothing.

## CheckThat facts

None reported yet. The plan reads CheckThat's own `CheckThatDB.global.facts` (source `facts`; entry results appear as `entry.<name>`) and `CheckThatDB.global.errors` (source `errors`, quiet).

## Report header

`/cvn log` has the line `CheckThat: working`, `CheckThat: not detected`, `CheckThat: too old` (loaded, but it has no `Entry` to register with) or `CheckThat: failed: <why>`.
