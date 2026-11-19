# Tasks

## 1. Specs

- [x] 1.1 Write MODIFIED and ADDED deltas for ammo-purchase, profession-trainer, status-window and vendor-trigger, keeping every original scenario under its original requirement; verify `openspec validate split-long-requirements --strict` passes
- [x] 1.2 Check each new scenario against the code or an existing test, so no new requirement claims behavior the addon does not have; verify by naming the code or test for each

## 2. Integration

- [x] 2.1 After the sync, run `openspec validate --specs --strict` and `make test`; verify both pass

## Workflow follow-up

- Archive without a version bump or CHANGELOG section (spec-only); commit on its own branch and merge, no tag.
