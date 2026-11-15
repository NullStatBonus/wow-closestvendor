# Embedded settings libraries

Source: https://github.com/WoWUIDev/Ace3/tree/ac3d122 (upstream master tarball retrieved 2026-11-15).

Unmodified upstream Lua files: LibStub minor 2 (public domain notice in source), CallbackHandler-1.0 minor 8, AceGUI-3.0 minor 41 and its standard widgets, AceConfigRegistry-3.0 minor 22 and AceConfigDialog-3.0 minor 93. Ace3's redistribution license is retained in LICENSE.txt. These libraries ship as part of Closest Vendor, never as a standalone library distribution.

Only the registry and dialog portions of AceConfig are needed. The wrapper and command frontend are omitted because Closest Vendor retains its own typed commands; the wrapper would pull in AceConfigCmd/AceConsole. No AceDB, AceAddon, event framework or sibling addon dependency is introduced. Standard AceGUI widgets support the dialog's generated tree, inline groups, scrolling, controls, tooltips and game-options host. Both TOCs list all shipped Lua files in dependency order, without XML indirection.
