# Adding a language

The addon's own text is English. Spell, item and zone names come from the game, so on a client in another language those already appear in that language. A translation file changes the addon's own sentences: settings labels, questions, chat replies and help.

## How it works

Every sentence the player reads is written in the code as `L["English sentence"]`. English is the key, so a sentence without a translation shows as written and a missing entry never raises an error. A language is one file in `ClosestVendor/Locales/` that assigns translations when the game runs in that locale. The debug log and the bug report stay in English on purpose, so reports are readable by the maintainer.

## Steps

1. Copy `ClosestVendor/Locales/Example.lua` to `ClosestVendor/Locales/<locale>.lua`, using the game's locale name: `deDE`, `frFR`, `esES`, `esMX`, `itIT`, `ptBR`, `ruRU`, `koKR`, `zhCN`, `zhTW`.
2. Change `"xxXX"` on the `GetLocale()` line to that locale.
3. Replace the examples with your translations. The left side must match the English sentence exactly; the easiest way is to copy the sentences from the code (search for `L["`). Lines you leave out stay in English.
4. List the file in **both** TOC files (`ClosestVendor_Vanilla.toc` and `ClosestVendor_Camelot.toc`), directly after `Locales\enUS.lua` and before any other file. The code reads some sentences when it loads, so translations must load first.
5. Run `luajit tests/run.lua locale`. It fails if a sentence does not exist in the code, if a translation is empty, or if its `%s`, `%d` or `%.1f` placeholders do not match the English ones.
6. Check it in game: `/reload`, then `/cvn`, `/cvn config` and `/cvn test sell`.

## Rules for translators

- Keep every placeholder (`%s` for text, `%d` for whole numbers, `%.1f` for numbers with one decimal). You may change their order only when the language needs it and the types still line up; the test checks the count and kind.
- `\n\n` in a question is a blank line. Keep it.
- A literal `%` is written `%%` where it follows a placeholder, as in `%d%%`.
- Do not translate the commands themselves (`/cvn bags 4`): the game does not translate what players type.
- A `|` in your text is printed as `||` automatically. Avoid it anyway.
- Keep sentences about the same length as the English: dialogs and settings labels have limited room.

## For developers

Wrap every new player-facing sentence in `L["..."]` with the whole sentence as the key. Do not build sentences from pieces (`L["a"] .. x`) or look keys up through variables: the locale test rejects both, because translators could not reorder the words. Say it with `say(L["..."])`, never `say("...")`.
