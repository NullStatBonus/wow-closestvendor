-- Template for a translation. Not loaded by the game until it is listed in both TOC files.
-- Copy to Locales/<locale>.lua, change "xxXX" to the game's locale name (deDE, frFR, esES, ...)
-- and translate the right-hand sides. Keep every %s, %d and %.1f (same count, same kind);
-- their order may change. Lines you leave out show in English.
local _, ns = ...

if GetLocale() ~= "xxXX" then return end

local L = ns.L

L["Your gear needs repair.\n\nNavigate to the closest repair vendor, %s?"] = "[xx] Your gear needs repair.\n\nNavigate to the closest repair vendor, %s?"
L["Your bags are almost full.\n\nNavigate to the closest vendor, %s?"] = "[xx] Your bags are almost full.\n\nNavigate to the closest vendor, %s?"
L["You are low on arrows (%d left).\n\nNavigate to the closest vendor that sells arrows, %s?"] = "[xx] You are low on arrows (%d left).\n\nNavigate to the closest vendor that sells arrows, %s?"
L["Closest vendor: %s in %s (%.1f, %.1f)"] = "[xx] Closest vendor: %s in %s (%.1f, %.1f)"
L["Bag space"] = "[xx] Bag space"
L["Opening the settings page..."] = "[xx] Opening the settings page..."
