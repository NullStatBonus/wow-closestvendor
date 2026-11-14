# Proposal

## Why

`UNIT_PET` fires for every party and raid member's pet, and each one ran a full evaluation and a scan of every bag slot. The supply check also scanned the bags when every food, water, pet food and healthstone switch was off.

## What Changes

- Events about another unit's pet are ignored, as already done for gear changes and casts.
- The supply check reads the bags only when the master switch is on and at least one supply warning or the healthstone reminder is on.

## Capabilities

### Modified Capabilities
- `vendor-trigger`: adds the no-needless-reads requirement.

## Impact

`Core.lua`, `Controller.lua`, `tests/test_core.lua`. No setting, command or text changes.
