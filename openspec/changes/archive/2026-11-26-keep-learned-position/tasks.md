# Tasks

## 1. Keep the saved position on small moves

- [x] 1.1 Add `D.NEAR = 0.005` and use it in `D.Record`, `D.RecordTrainer` and `D.RecordAuctioneer` in `ClosestVendor/Discovery.lua`: on the same map, within `D.NEAR` on both axes, keep the old x and y before comparing. Verify with new cases in `tests/test_discovery.lua` (a small move does not change the record, a larger move does, a stock change keeps the old position) for all three kinds. Break the rule, see the tests fail, and restore it.

## 2. Docs and release

- [x] 2.1 `README.md`: say that a few steps of difference do not change a learned place. Verify with `make test`.
- [x] 2.2 Run `make test`, `make check` and `make plan`. All pass.

## Workflow follow-up

- At archive: sync the spec, bump both TOCs to 1.13.1, and write the 1.13.1 CHANGELOG section.
