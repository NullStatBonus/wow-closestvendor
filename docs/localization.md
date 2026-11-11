# Adding a language

The addon text is in English. The game gives the names of spells, items and zones. On a client in another language, these names already show in that language.

A translation file changes the sentences of the addon. These are settings labels, questions, chat replies and help text.

## How it works

The code writes every sentence that the player reads as `L["English sentence"]`. English is the key. If a sentence has no translation, the addon shows the English sentence. A missing entry does not cause an error.

A language is one file in `ClosestVendor/Locales/`. The file assigns translations when the game runs in that locale.

The debug log and the bug report stay in English. This lets the maintainer read the reports.

## Steps

1. Copy `ClosestVendor/Locales/Example.lua` to `ClosestVendor/Locales/<locale>.lua`. Use the locale name of the game: `deDE`, `frFR`, `esES`, `esMX`, `itIT`, `ptBR`, `ruRU`, `koKR`, `zhCN` or `zhTW`.
2. Change `"xxXX"` on the `GetLocale()` line to your locale.
3. Replace the examples with your translations.
   - The left side must be the same as the English sentence.
   - To get the sentences, copy them from the code. Search for `L["`.
   - A line that you omit stays in English.
4. Add the file to **both** TOC files: `ClosestVendor_Vanilla.toc` and `ClosestVendor_Camelot.toc`. Put it directly after `Locales\enUS.lua` and before any other file. The code reads some sentences when it loads, so the translations must load first.
5. Run `luajit tests/run.lua locale`. The test fails in these cases:
   - A sentence does not exist in the code.
   - A translation is empty.
   - The `%s`, `%d` or `%.1f` placeholders do not match the English placeholders.
6. Check the result in the game. Type `/reload`, then `/cvn`, `/cvn config` and `/cvn test sell`.

## Rules for translators

- Keep every placeholder. `%s` is for text. `%d` is for whole numbers. `%.1f` is for numbers with one decimal.
- Change the order of placeholders only if the language needs it. The types must stay in line. The test checks the count and the kind.
- `\n\n` in a question is a blank line. Keep it.
- Write a literal `%` as `%%` when it follows a placeholder, as in `%d%%`.
- Do not translate the commands (for example `/cvn bags 4`). The game does not translate what players type.
- The addon prints a `|` in your text as `||`. Do not use `|`.
- Keep each sentence about the same length as the English sentence. Dialogs and settings labels have limited space.

## For developers

1. Wrap every new player-facing sentence in `L["..."]`. The key is the whole sentence.
2. Do not build sentences from pieces, for example `L["a"] .. x`.
3. Do not look up keys through variables.
4. Use `say(L["..."])`. Do not use `say("...")`.

The locale test rejects pieces and variable keys. Translators cannot reorder the words of such sentences.
