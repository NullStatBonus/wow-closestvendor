# Design

## Context

See proposal.md. `Controller.offer` in `auto` mode pins and calls `say(L["Navigating to %s."]:format(pick[2]))`. The two-target question already formats targets as `name (zone, N yards)` in `Controller.target`, and `Core.lua` supplies zone names through `A.mapName`. All game calls are in `Adapter.lua`, guarded and returning nil when missing.

## Goals / Non-Goals

**Goals:**
- Same target format in the notice as in the question.
- A silent on-screen message in addition to chat.

**Non-Goals:**
- A sound, a popup, or a raid-warning frame. The map pin already sounds.
- Any change to `ask` mode or to the setting names.

## Decisions

**Text built in the Controller.** `Controller.target` becomes reachable from `offer`; the notice is `L["Navigating to %s."]` for one candidate and `L["Navigating to %s. The other choice was %s."]` for two, with both targets formatted by `target`. Two whole-sentence keys, no concatenation. Zone names come from a new optional `env.zoneName(mapId)` (Core passes `A.mapName`); a nil zone gives the existing `name (N yards)` form.

**On-screen message via `UIErrorsFrame:AddMessage`.** `A.screenMessage(text)` calls `UIErrorsFrame:AddMessage(text, r, g, b)` in `pcall`. `AddMessage` only draws text; the error sounds belong to the `UI_ERROR_MESSAGE` event path, so nothing plays. It exists in Era and Forever. `RaidNotice_AddMessage` was considered, rejected as a louder raid-warning style. Missing frame or a throwing call reports once through the usual `onError` and returns nil.

**Env.** `env.notify(text)` is optional like `env.say`. The Controller calls `say(text)` and `notify(text)` with the same string, so the two cannot drift. Core sets `notify = A.screenMessage`.

**Setting.** `cfg.autoNotice` (boolean, default `true` in `DEFAULTS`). The Controller calls `notify` only when `env.cfg.autoNotice ~= false`, so a missing key behaves as on; chat is unaffected. Command `/cvn notice on|off`, a checkbox on the settings page, a line in the status output and the report header, as for the other switches.

**Chat escape.** Core's `say` already doubles `|`. The on-screen text goes through `AddMessage`, which also treats `|` as an escape, so `A.screenMessage` doubles `|` the same way (vendor names could contain one).

## Risks / Trade-offs

- [`UIErrorsFrame` fades fast and shares space with real errors] → accepted; the chat line stays as the record.
- [Frame absent on some client] → guarded; chat still prints.

## Migration Plan

No saved-data change. Version 0.4.0 at archive; the new key fills with `true` on load.
