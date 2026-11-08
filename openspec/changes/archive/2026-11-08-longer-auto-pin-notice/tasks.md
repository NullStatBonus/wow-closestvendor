## 1. Adapter

- [x] 1.1 `Adapter.screenMessage`: lazily create an addon-owned frame with a font string, set the text (`|` doubled), show it, hide it after 5 seconds with an `OnUpdate` countdown that a newer message resets; nil and one reported failure when the frame API is missing
- [x] 1.2 `tests/test_adapter.lua`: text shown; hidden after 5 seconds; a second message replaces the first and gets its own full time; `|` doubled; no `CreateFrame`, no `UIParent`, and throwing calls are handled; `UIErrorsFrame` is not used

## 2. Core, docs and release

- [x] 2.1 `tests/test_core.lua`: the notice reaches the frame and disappears after about five seconds
- [x] 2.2 `docs/test-plan.md` section 11: about five seconds, replaced by a newer message, game errors unchanged; README and listing wording if they promise a duration
- [x] 2.3 `make test` and `make check` pass; break the 5-second hide or the restart on a newer message and confirm a test fails
- [x] 2.4 At archive: bump both TOCs to 0.4.1 and add a `## 0.4.1` CHANGELOG section; name 0.4.1 in the commit
