## 1. Adapter

- [x] 1.1 `Adapter.screenMessage(text)`: `UIErrorsFrame:AddMessage` in `pcall`, doubling `|`, nil when the frame or method is missing
- [x] 1.2 `tests/test_adapter.lua`: message drawn; `|` doubled; frame missing and call throws return nil and report once

## 2. Controller, Core and settings

- [x] 2.1 `Controller`: auto notice built with `target` (zone, distance), naming the other candidate when there were two; sent to `say` and to optional `env.notify`; optional `env.zoneName`
- [x] 2.2 `Core.lua`: wire `notify = A.screenMessage` and `zoneName = A.mapName`
- [x] 2.3 `autoNotice` (default true): `notify` only when on; `/cvn notice on|off`, status line, settings page checkbox, report header; tests in `test_commands`, `test_options`, `test_core`, `test_controller`
- [x] 2.4 New `L[...]` keys for both notice forms; `tests/test_locale.lua` passes
- [x] 2.5 `tests/test_controller.lua`: one candidate, two candidates (map and distance preference), trainer, no zone, `notify` absent; `tests/test_core.lua`: the message reaches the game call and the chat line shows zone and distance

## 3. Docs and release

- [x] 3.1 README (auto mode paragraph, `/cvn notice`), `docs/listing.md`, `docs/test-plan.md` section 11: check the on-screen text, no extra sound, and the chat line
- [x] 3.2 `make test` and `make check` pass; break the notice and confirm a test fails
- [x] 3.3 At archive: bump both TOCs to 0.4.0 and add a `## 0.4.0` CHANGELOG section; name 0.4.0 in the commit
