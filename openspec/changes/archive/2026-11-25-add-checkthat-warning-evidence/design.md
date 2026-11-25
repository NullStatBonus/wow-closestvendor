# Design

## Context

Phase 2 of #61, stacked on Phase 1 (1.11.0). The plan and both reviews: build plan with an evidence inventory per step, reviewed by Opus and Codex; then the build, an Opus review against the CheckThat card, and Opus and Codex code reviews, all fixed.

## Decisions

**D1. Auto or player.** A step is automatic when a log line or entry proves what it checks (a decision). It stays a player step only when its point is on-screen content (dialog text, the waypoint arrow, two dialogs at once) or it cannot be automated in time (a battleground run past the 300 s limit, a client-caused failure); each such step has required assertions on the outcome and a `notes` reason. Result (auto / player): s2 8/6 (restore step s2.14 added), s5 6/0, s8 3/3 (restore s8.6 added), s23 8/2 (restore s23.10 added), s32 8/1 (restore s32.9 added). Restore steps were also added where earlier sections changed thresholds without setting them back: cv.s1.13, cv.s6.18, cv.s12.35, cv.s14.56, cv.s14.57, cv.s15.4.

**D2. Run fires every command at once.** No required assertion matches a line the Run setup writes (`test command:`, the first `question shown:` from `/cvn test`); the player's outcome (accepted, declined, closed) is asserted.

**D3. Staging and restore.** Slow world changes are staged with thresholds (`/cvn bags 200`, `/cvn dur 100`, `/cvn ammo <n>`). The card shows no cleanup row, so each restore is a visible command ("type your usual value back (default N)") in a later step or in a restore step at the end of the section.

**D4. New lines, once per change.** Hold lines are keyed by reason and kind and reset when nothing is held, so Evaluate bursts write one line. Precedence instance > dead > combat. `Triggers.Update` now returns `nil, want, wantId` when it holds; its one caller uses the extras for logging only. The ammo watch line is keyed by kind and whether the ammo warning is on.

**D5. Purchases.** `A.buyMerchantItem` returns true when the game took the call. The bought line counts only those; a raised call is a `FAILED:` line. A call the game took can still be refused silently (no money); the contract says so.

**D6. `active` entry** reads `Triggers.Active()` through a getter in the CheckThat ctx; a reagent request returns `reagent <id>`.

**D8. Close lines are written after the close.** A question or purchase dialog the addon hides is checked again; still shown writes a `FAILED:` line instead.

**D7. `ct lines` misses.** 87 lines are built by concatenation or `format`, so `ct lines` reports them missing (NullStatBonus/wow-checkthat#144). Each was checked against the source.

## Risks

- s23.6 needs a continent with no known repairer.
- `question shown: supply ` in s32.8 depends on English text.
