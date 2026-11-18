# Design

## Context

The sound list is the static table `S.SOUNDS` in `Supplies.lua` (`{ key, soundkit id, label }`). `S.SoundId(key)` gives an id, with unknown keys falling back to `whisper`. Three places in `Core.lua` play it through `A.playSound(id)`, which accepts only numbers. Commands (`soundName`, `soundChoices`, `soundCommand`) and the Options dropdown read `S.SOUNDS` directly. Game calls belong in `Adapter.lua` only. Supplies, Commands and Options run under the plain-Lua tests. Don't Do That's `Model/SoundList.lua` already reads LibSharedMedia without embedding it.

## Goals / Non-Goals

**Goals:**
- One sound list, built on demand from the built-in sounds plus whatever LibSharedMedia shares right now.
- No change to saved data, and no embedded library.

**Non-Goals:**
- Registering Closest Vendor's own sounds with LibSharedMedia.
- A sound channel or volume choice. Files play on the same default channel as `PlaySound`.
- Media types other than sound (fonts, textures).

## Decisions

1. **Adapter owns the library.** `A.mediaSounds()` returns sorted sound names, case-insensitive, without "None". `A.mediaSound(name)` returns a file path. Both read `LibStub("LibSharedMedia-3.0", true)` under pcall and return nil when it is missing. This follows Don't Do That's `HashTable("sound")` / `Fetch("sound", name, true)` calls. *Alternative:* read LibStub inside Supplies. Rejected: it breaks the Adapter-only rule.
2. **Supplies gets the reader by injection.** Core sets `ns.Supplies.media = { list = A.mediaSounds, fetch = A.mediaSound }`, the same pattern as `ns.Options.itemName = A.itemName`. With no `media` (tests, or no library), Supplies behaves exactly as today.
3. **One list function.** `S.SoundList()` returns ordered `{ key, label }`: the built-ins (none last among them), then `{ "lsm:"..name, L["%s (sound pack)"]:format(name) }`. Commands and Options use it instead of `S.SOUNDS`. It is built on every call, so a pack that loads late appears without a reload.
4. **`S.SoundId` returns what to play.** A number for a built-in. For an `lsm:` key that `fetch` resolves, the file (a path or a file id) and `true`, since a number alone cannot tell a file id from a sound id. Nil for none. An unresolved `lsm:` key returns the default's id. The saved key is never rewritten, so the choice comes back with the pack.
5. **`A.playSound(x, file)`.** With `file`, a path or file id calls `PlaySoundFile`. Otherwise, a number calls `PlaySound`. Anything else is skipped. Both are guarded by `call()`.
6. **Matching names.** `S.FindSound(text)` also matches a sound-pack name or its label, ignoring case. The built-ins win a tie.
7. **Dropdown values become a function** (AceConfig accepts `values = function`) that maps `S.SoundList()` to `{ [key] = label }`. A saved `lsm:` key whose pack is missing is shown in the list as "<name> (sound pack)", so the dropdown never shows blank. *Alternative:* show it as the default. Rejected: that would hide the real saved choice.
8. **Chat name.** `soundName(key)` uses the same list. A missing pack sound shows its name.

## Risks / Trade-offs

- [A sound pack registers hundreds of sounds, making a long dropdown and a long `/cvn sound` list] → The dropdown scrolls in AceGUI. `/cvn sound` with no name lists the built-ins plus a count, e.g. "and 120 sound-pack sounds: /cvn sound <name>". It does not print every name.
- [A shared name contains a raw `|`] → chat already doubles `|` (Core).
- [`PlaySoundFile` is missing or fails on one client] → `call()` reports it once and skips it, as for `PlaySound` today.
