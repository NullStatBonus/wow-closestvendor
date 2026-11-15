## 1. Implementation

- [x] 1.1 Add `Discovery.Tradable(pool, known, standing)` with tests.
- [x] 1.2 Add `Adapter.canTrade(unit)` and a unit argument to `A.npc`.
- [x] 1.3 Record standing on merchant open, target, mouseover and nameplate for known vendors; rebuild the search when it changes.
- [x] 1.4 Count standing in the debug report.
- [x] 1.5 README limitation and test plan section 21.

## 2. Verification

- [x] 2.1 `make test`, `make check`; mutation check: removing the filter fails the end-to-end test.
- [ ] 2.2 In-game checks in docs/test-plan.md section 21.
