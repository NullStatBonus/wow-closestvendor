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
L["%s (sound pack)"] = "[xx] %s (sound pack)"
L["%s, or one of %d sound-pack sounds by name"] = "[xx] %s, or one of %d sound-pack sounds by name"
L["Opening the settings page..."] = "[xx] Opening the settings page..."
L["Other repair vendors"] = "[xx] Other repair vendors"
L["Other ammo vendors"] = "[xx] Other ammo vendors"
L["Other vendors to sell to"] = "[xx] Other vendors to sell to"
L["Other food vendors"] = "[xx] Other food vendors"
L["Other water vendors"] = "[xx] Other water vendors"
L["Other pet food vendors"] = "[xx] Other pet food vendors"
L["The seller list changed. Open it again to choose."] = "[xx] The seller list changed. Open it again to choose."
L["Other sellers of %s"] = "[xx] Other sellers of %s"
L["Other %s trainers"] = "[xx] Other %s trainers"
