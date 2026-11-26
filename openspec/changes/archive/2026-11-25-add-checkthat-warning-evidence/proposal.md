# Proposal

## Why

Phase 2 of #61. The plan sections for warnings and the question (s2 The question, s5 Ammo, s8 Safety, s23 Safe questions, s32 Warning flow) are all player steps, though most of what they check is a decision the debug log can prove. Some decisions write no line at all: a warning held back in combat, while dead or in an instance, a purchase question closed with the merchant. A plan cannot prove those.

## What Changes

- **Automatic steps.** Each step in those sections whose result a log line or entry proves becomes an automatic step. Steps whose point is on-screen content stay player steps with required log assertions and a reason in `notes`.
- **New debug log lines** at decision points, each written once per change so bursts do not fill the log: a warning held (combat, dead, in an instance), a purchase question closed with the merchant, and no ammo-using ranged weapon.
- **New CheckThat entry `active`:** the warnings active now.
- **Docs:** `docs/contracts.md` lists the new lines and the entry.

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `diagnostics`: the debug log records held warnings, a closed purchase question and a missing ammo weapon.
- `checkthat-integration`: the entries include `active`.

## Impact

- **Code:** `Controller.lua`, `Core.lua`, `CheckThat.lua` (and `Triggers.lua` if it needs a read-only accessor).
- **Tests:** `test_controller`, `test_core`, `test_checkthat`, `test_plan`.
- **Plan:** `plans/closestvendor.yaml` sections s2, s5, s8, s23, s32; the offline block.
- **Saved data:** no change.
- **Release:** patch, 1.11.1.
