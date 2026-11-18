# Tasks

## 1. Adapter

- [x] 1.1 Add `A.mediaSounds()` (sorted names without "None") and `A.mediaSound(name)` (file path), reading `LibStub("LibSharedMedia-3.0", true)` under pcall; nil when LibStub or the library is missing
- [x] 1.2 `A.playSound(x, file)`: file → `PlaySoundFile` (path or file id), number → `PlaySound`, else skip; both through `call()`
- [x] 1.3 `tests/test_adapter.lua`: fake LibStub/LSM (names, None filtered, sort, Fetch path), missing library, number vs path playback

## 2. Supplies

- [x] 2.1 Add `S.SoundList()` (built-ins, then `lsm:<name>` with `L["%s (sound pack)"]`), using the injected `S.media`
- [x] 2.2 `S.SoundId`: resolve `lsm:` keys through `S.media.fetch`; when missing or unresolved, use the default id; none stays nil
- [x] 2.3 `S.FindSound`: also match sound-pack names and labels, ignoring case; built-ins win a tie
- [x] 2.4 `tests/test_supplies.lua`: list with and without media, late media, missing saved pack sound → default, FindSound matching

## 3. Commands, Options, Core

- [x] 3.1 Commands: `soundName`, `soundChoices`, `soundCommand` use `S.SoundList()`; without a name, list the built-ins plus a sound-pack count
- [x] 3.2 Options: Notification sound `values` is a function over `S.SoundList()`, and includes a saved but missing pack sound
- [x] 3.3 Core: set `ns.Supplies.media = { list = A.mediaSounds, fetch = A.mediaSound }`
- [x] 3.4 Add the new locale strings (`%s (sound pack)`, the count line) to the locale files
- [x] 3.5 Tests: `test_commands` (pick by name, any case; count line), `test_options` (values function, missing saved sound), `test_core` (wiring: a sound-pack choice plays its path)
- [x] 3.6 Mutation check: break each new branch and confirm a test fails

## 4. Docs and checks

- [x] 4.1 README (Sound setting, `/cvn sound` line, "Good to know"), `docs/listing.md`
- [x] 4.2 `docs/test-plan.md`: new section, cheap to run (install any SharedMedia pack; pick a sound; disable the pack; reload)
- [x] 4.3 `make test` and `make check` pass
