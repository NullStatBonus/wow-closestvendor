# Tasks

## 1. About page

- [x] 1.1 Remove the command heading, rows, tip, summary line and legacy test note from About in `ClosestVendor/Options.lua`
- [x] 1.2 `tests/test_options.lua`: About has title, version and purpose, and no command entries; the mutation check (add a command row back) fails the test

## 2. Docs

- [x] 2.1 README "Advanced and About": About shows name, version and purpose; commands are in `/cvn help`
- [x] 2.2 `docs/test-plan.md`: one check that About shows only name, version and purpose
- [x] 2.3 `make test` and `make check` pass
