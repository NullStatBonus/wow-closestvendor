# Design

## Context

See proposal.md. `A.screenMessage` calls `UIErrorsFrame:AddMessage`, which fades on the frame's own timer (about 3 seconds) shared with game errors. All game calls live in `Adapter.lua`, guarded.

## Goals / Non-Goals

**Goals:**
- About five seconds on screen, silent, isolated from game errors.

**Non-Goals:**
- A setting for the duration, position or colour.
- Any change to the chat line or to `autoNotice`.

## Decisions

**Own frame, created on first use.** `screenMessage` lazily creates one `Frame` on `UIParent` with a centered `FontString` (`GameFontNormalLarge`, near the top third of the screen, `SetPoint("TOP", UIParent, "TOP", 0, -200)`), non-interactive (`EnableMouse(false)`), strata `HIGH`. Created in `pcall` through `call`; if `CreateFrame` or `UIParent` is missing the function returns nil and the failure is reported once. Alternative: `UIErrorsFrame:SetTimeVisible(5)`, rejected because it changes how long real game errors stay. Alternative: `RaidNotice_AddMessage`, rejected as it can not set a duration and shares a frame with raid warnings.

**Hide with `OnUpdate`, no timer.** Each call sets the text, resets a countdown (`left = 5`) and shows the frame; an `OnUpdate` script subtracts elapsed time and hides the frame at zero. A hidden frame gets no `OnUpdate`, so it costs nothing while idle. A newer message resets the countdown, so it replaces the old one and gets its own full time with no stale timer to guard against. Chosen over `A.after` plus a token (an earlier draft): one mechanism, no timer API dependency, no fallback branch.

**Silent.** Showing a frame or setting text plays no sound; nothing here calls a sound API.

**Escape.** `|` is still doubled before the text is set.

## Risks / Trade-offs

- [Another addon draws in the same spot] → fixed offset is small and the message is brief; accepted.
- [Frame API differs in some client] → each call is guarded; a failure leaves chat as the notice.
- [Text covers part of the view for five seconds] → short, centered high on the screen, off by `/cvn notice off`.

## Migration Plan

No saved-data change. Version 0.4.1 at archive.
