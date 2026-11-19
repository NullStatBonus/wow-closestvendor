# Embedded libraries

Upstream: https://github.com/WoWUIDev/Ace3
Commit: ac3d122 (master, 2026-10-28; 21 commits after Release-r1403, no newer release tag)
License: Ace3's license, in `LICENSE.txt` (LibStub's public-domain notice is in its source)
Local patches: none. Every file is copied from upstream unchanged.

Don't Do That and KeepThat embed the same commit. When two addons ship one library, the game loads the copy with the highest MINOR, so keeping all three on one commit means each runs on the files it was tested with.

## Modules

| Library | MAJOR | MINOR |
| --- | --- | --- |
| LibStub | LibStub | 2 |
| CallbackHandler | CallbackHandler-1.0 | 8 |
| AceGUI | AceGUI-3.0 | 41 |
| AceConfigRegistry | AceConfigRegistry-3.0 | 22 |
| AceConfigDialog | AceConfigDialog-3.0 | 93 |

AceGUI widgets (type and version): BlizOptionsGroup 26, DropdownGroup 22, Frame 30, InlineGroup 22, ScrollFrame 26, SimpleGroup 20, TabGroup 38, TreeGroup 49, Window 8, Button 24, CheckBox 27, ColorPicker 29, Dropdown 36, Dropdown-Pullout 5 (with the item widgets in `AceGUIWidget-DropDown-Items.lua`), EditBox 29, Heading 21, Icon 22, InteractiveLabel 21, Keybinding 27, Label 29, MultiLineEditBox 33, Slider 24.

## Why only these

Only the registry and dialog parts of AceConfig are needed. The AceConfig wrapper and the command frontend are left out because Closest Vendor has its own typed commands; the wrapper would pull in AceConfigCmd and AceConsole. No AceDB, AceAddon, event framework or sibling addon dependency is used. The standard AceGUI widgets support the dialog's tree, inline groups, scrolling, controls, tooltips and game-options host. Both TOCs list every shipped Lua file in dependency order, without XML. These libraries ship as part of Closest Vendor, never as a standalone library.

## Updating

1. Download the upstream tarball for the new commit.
2. Replace each file listed above with the upstream file of the same path. Do not add modules.
3. Update the commit line and every MAJOR, MINOR and widget version above from the new files.
4. Compare against Don't Do That and KeepThat: every file the addons share must have the same hash. Update them in the same round.
5. Run `make test` and `make check`, then open the settings window on Classic Era and WoW Forever.
