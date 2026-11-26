# Design

## Context

Phase 4 of #61, stacked on Phase 3 (1.11.2). The build plan had an evidence inventory for each step (318 steps) and was reviewed by Opus before the build. Codex was out of quota at that point, so its plan review and code review ran after the build, and their findings were fixed before commit. The build was reviewed against the CheckThat card by Opus and code-reviewed by Opus and Codex, and every finding was fixed.

## Decisions

**D1.** Rules as in Phases 2 and 3.

**D2. No fake evidence.** Report-header text and saved-variable names never reach the debug log; those checks now use the `setting changed:` line, the new entries, or stay player steps with a reviewer line.

**D3. Window line only on change.** The signature is the shown state, the row set and the low flags; counts, demo, preview and Move never write. Move's Done or Cancel redraws so the state stays current. The note runs in its own pcall: a logging error writes `FAILED:` and keeps the window.

**D4. Setting changes.** A slash command writes at once; the settings page and colour picker write once, 1 s after the last change (through `A.after`); a slash command flushes a pending page change first.

**D5. Purchase questions.** `asked` is written after the game confirms the dialog is shown; Yes and No or Escape write; a replaced question writes nothing.

**D6. The debug log keeps 1000 lines (was 300).** A full plan run writes several hundred lines; with 300, late absence and upper-count checks could not be proven and `ct replay-flow` stalled at the cap (NullStatBonus/wow-checkthat#158). 1000 short entries add little to the saved file.

## Deferred

- Remaining bare `accepted:` checks: #66.
- `reagents` entry with every count unreadable: #67.

## Risks

- The debug log keeps 300 lines. Late in a long run, an upper count or an absence can only be proven when the last lines are unique; replay-flow hit this near s13.75. Filed for CheckThat.
- `ct lines` false misses for concatenated or formatted lines: NullStatBonus/wow-checkthat#144.
