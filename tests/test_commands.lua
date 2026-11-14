package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
H.locale(ns)
loadfile("ClosestVendor/Reagents.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Supplies.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Nav.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Status.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Commands.lua")("ClosestVendor", ns)
local M = ns.Commands

local function fresh() return { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10,
    bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true,
    reagentThreshold = 5, reagentOff = {} } end
local function has(lines, text) return table.concat(lines, "\n"):find(text, 1, true) ~= nil end

-- Status.
local c = fresh()
local out = M.Run(c, "")
eq(has(out, "2 free slot"), true, "status shows bag threshold")
eq(has(out, "below 20%"), true, "status shows durability threshold")
eq(has(M.Run(c, nil), "Bags:"), true, "nil message is status")

-- Thresholds.
c = fresh()
out = M.Run(c, "bags 5")
eq(c.bagThreshold, 5, "bag threshold set")
eq(has(out, "5 free slot"), true, "reply shows new value")
M.Run(c, "dur 35")
eq(c.durThreshold, 35, "durability threshold set")
M.Run(c, "  BAGS   0 ")
eq(c.bagThreshold, 0, "case and spacing tolerated, 0 allowed")

-- Toggles are independent and keep thresholds.
c = fresh()
M.Run(c, "bags off")
eq(c.bagEnabled, false, "bag trigger off")
eq(c.durEnabled, true, "durability untouched")
eq(c.bagThreshold, 2, "threshold kept")
M.Run(c, "bags on")
eq(c.bagEnabled, true, "bag trigger back on")
M.Run(c, "dur off")
eq(c.durEnabled, false, "durability off")

-- Bad input changes nothing and explains.
c = fresh()
for _, bad in ipairs({ "bags x", "bags -1", "bags 2.5", "bags 201", "dur 0", "dur 101", "dur abc", "ammo x", "ammo -1", "ammo 2001", "ammo 1.5", "trade x", "trade -1", "trade 301", "trade 2.5" }) do
    eq(c.ammoThreshold, 200, bad .. ": ammo unchanged (before)")
    out = M.Run(c, bad)
    eq(c.bagThreshold, 2, bad .. ": bags unchanged")
    eq(c.durThreshold, 20, bad .. ": dur unchanged")
    eq(c.tradeThreshold, 10, bad .. ": trade unchanged")
    eq(has(out, "must be a whole number"), true, bad .. ": explained")
end

-- Ammo threshold and switch.
c = fresh()
out = M.Run(c, "ammo 300")
eq(c.ammoThreshold, 300, "ammo threshold set")
eq(has(out, "300 or fewer"), true, "reply shows the ammo threshold")
M.Run(c, "ammo 0"); eq(c.ammoThreshold, 0, "0 allowed")
M.Run(c, "ammo 2000"); eq(c.ammoThreshold, 2000, "2000 allowed")
M.Run(c, "ammo off"); eq(c.ammoEnabled, false, "ammo trigger off")
eq(c.bagEnabled and c.durEnabled, true, "other triggers untouched")
M.Run(c, "ammo on"); eq(c.ammoEnabled, true, "ammo trigger on")
eq(has(M.Run(fresh(), ""), "Ammo: on"), true, "status shows ammo")

-- Profession threshold and switch.
c = fresh()
out = M.Run(c, "trade 25")
eq(c.tradeThreshold, 25, "profession threshold set")
eq(has(out, "25 point"), true, "reply shows the profession threshold")
M.Run(c, "trade 0"); eq(c.tradeThreshold, 0, "0 allowed")
M.Run(c, "trade 300"); eq(c.tradeThreshold, 300, "300 allowed")
M.Run(c, "TRADE   12 "); eq(c.tradeThreshold, 12, "case and spacing tolerated")
M.Run(c, "trade off"); eq(c.tradeEnabled, false, "profession trigger off")
eq(c.bagEnabled and c.durEnabled and c.ammoEnabled, true, "other triggers untouched")
eq(c.tradeThreshold, 12, "threshold kept")
M.Run(c, "trade on"); eq(c.tradeEnabled, true, "profession trigger back on")
eq(has(M.Run(fresh(), ""), "Professions: on"), true, "status shows professions")
eq(has(M.Run(c, "trade off"), "Professions: off"), true, "status shows professions off")
eq(has(M.Run(fresh(), "nonsense"), "/cvn trade"), true, "help lists the profession command")
eq(M.LIMITS.trade[1] .. "-" .. M.LIMITS.trade[2], "0-300", "profession limits")

-- Test commands return an action and leave the settings alone.
for _, kind in ipairs({ "sell", "repair" }) do
    c = fresh()
    local lines, action = M.Run(c, "test " .. kind)
    eq(action[1], "test", kind .. ": action")
    eq(action[2], kind, kind .. ": kind")
    eq(has(lines, kind), true, kind .. ": says what it is doing")
    eq(c.bagThreshold == 2 and c.durThreshold == 20 and c.bagEnabled and c.durEnabled, true, kind .. ": settings untouched")
end
for kind, word in pairs({ arrow = "arrows", bullet = "bullets" }) do
    local lines3, action3 = M.Run(fresh(), "test " .. word)
    eq(action3 and action3[1], "test", word .. ": action")
    eq(action3 and action3[2], kind, word .. ": kind")
    eq(has(lines3, word), true, word .. ": says what it is doing")
end
eq(select(2, M.Run(fresh(), "test arrow")), nil, "singular is not accepted")
local _, action = M.Run(fresh(), "bags 5")
eq(action, nil, "other commands return no action")
for _, bad in ipairs({ "test", "test x", "test sell2", "test arrowss" }) do
    local lines2, action2 = M.Run(fresh(), bad)
    eq(action2, nil, bad .. ": no action")
    eq(has(lines2, "/cvn test sell, repair, arrows, bullets, reagent"), true, bad .. ": help lists the test command")
end

-- Debug log and report commands return actions and leave the settings alone.
c = fresh()
local dl, da = M.Run(c, "debug on")
eq(da[1] .. tostring(da[2]), "debugtrue", "debug on action")
eq(has(dl, "Debug log on"), true, "debug on reply")
eq(has(dl, "/cvn log"), true, "debug on tells you what to do next")
dl, da = M.Run(c, "debug off")
eq(da[1] .. tostring(da[2]), "debugfalse", "debug off action")
eq(has(dl, "Debug log off"), true, "debug off reply")
local ll, la = M.Run(c, "log")
eq(la[1], "log", "log action")
eq(la[2], nil, "log shows the report")
eq(#ll >= 1, true, "log prints a line (so callers can always read the first)")
ll, la = M.Run(c, "log clear")
eq(la[1] .. la[2], "logclear", "log clear action")
eq(c.bagThreshold == 2 and c.durThreshold == 20 and c.ammoThreshold == 200, true, "settings untouched")
for _, bad in ipairs({ "debug", "debug maybe", "log everything" }) do
    local l3, a3 = M.Run(fresh(), bad)
    eq(a3, nil, bad .. ": no action")
    eq(has(l3, "/cvn debug on"), true, bad .. ": help lists the debug command")
end

-- Missing value or unknown command shows help.
for _, m in ipairs({ "bags", "dur", "trade", "nonsense", "help" }) do
    eq(has(M.Run(fresh(), m), "/cvn bags"), true, m .. ": help shown")
end

-- Chat treats "|" as an escape code: no line the parser returns may contain one.
local msgs = { "notice off", "notice x", "choice auto", "choice x", "prefer distance", "prefer", "buy on", "buy ask", "arrows best", "arrows x", "bullets cheapest", "", "help", "nonsense", "bags", "dur", "ammo", "test", "test x", "bags 5", "bags x", "dur 30", "dur 0",
               "ammo 300", "ammo x", "trade", "trade 20", "trade x", "trade off", "bags off", "dur off", "ammo off", "test sell", "test repair", "test arrows", "test bullets",
               "debug on", "debug off", "debug", "log", "log clear", "log x" }
for _, m in ipairs(msgs) do
    for _, line in ipairs((M.Run(fresh(), m))) do
        eq(line:find("|", 1, true), nil, "no pipe in output of '" .. m .. "': " .. line)
    end
end

-- Ammo buying.
c = fresh()
c.ammoBuyEnabled, c.ammoBuyPrompt, c.arrowGrade, c.bulletGrade = true, false, "equipped", "equipped"
M.Run(c, "buy off")
eq(c.ammoBuyEnabled, false, "buy off")
M.Run(c, "buy on")
eq(c.ammoBuyEnabled, true, "buy on")
M.Run(c, "buy ask")
eq(c.ammoBuyPrompt, true, "buy ask")
M.Run(c, "buy auto")
eq(c.ammoBuyPrompt, false, "buy auto")
out = M.Run(c, "arrows best")
eq(c.arrowGrade, "best", "arrow grade set")
eq(c.bulletGrade, "equipped", "bullet grade untouched")
eq(has(out, "arrows: best usable"), true, "status shows arrow grade")
M.Run(c, "bullets cheapest")
eq(c.bulletGrade, "cheapest", "bullet grade set")
out = M.Run(c, "arrows nonsense")
eq(c.arrowGrade, "best", "bad grade ignored")
eq(has(out, "Choose equipped, best or cheapest."), true, "bad grade explained")

-- Reagent buying: on/off, ask/auto and the amount (0-100), same words as /cvn buy; refused for a
-- class without vendor reagents.
c = fresh()
out = M.Run(c, "", "MAGE")
eq(has(out, "Reagent buying: off, asks first, up to 20 of each"), true, "status shows reagent buying with its defaults")
M.Run(c, "reagentbuy on", "MAGE"); eq(c.reagentBuyEnabled, true, "reagentbuy on")
M.Run(c, "reagentbuy auto", "MAGE"); eq(c.reagentBuyPrompt, false, "reagentbuy auto")
M.Run(c, "reagentbuy ask", "MAGE"); eq(c.reagentBuyPrompt, true, "reagentbuy ask")
out = M.Run(c, "reagentbuy 35", "MAGE")
eq(c.reagentBuyTarget, 35, "reagentbuy amount")
eq(has(out, "Reagent buying: on, asks first, up to 35 of each"), true, "reply shows it")
M.Run(c, "reagentbuy 0", "MAGE"); eq(c.reagentBuyTarget, 0, "0 allowed")
M.Run(c, "reagentbuy 100", "MAGE"); eq(c.reagentBuyTarget, 100, "100 allowed")
for _, bad in ipairs({ "reagentbuy 101", "reagentbuy -1", "reagentbuy 2.5", "reagentbuy x", "reagentbuy" }) do
    out = M.Run(c, bad, "MAGE")
    eq(c.reagentBuyTarget, 100, bad .. ": unchanged")
    eq(has(out, "Reagent amount must be a whole number from 0 to 100, or on, off, ask or auto."), true, bad .. ": explained")
end
M.Run(c, "reagentbuy off", "MAGE"); eq(c.reagentBuyEnabled, false, "reagentbuy off")
eq(M.LIMITS.reagentBuyTarget[1] .. "-" .. M.LIMITS.reagentBuyTarget[2], "0-100", "reagent amount limits")
for _, cls in ipairs({ "HUNTER", "WARLOCK" }) do
    c = fresh()
    out = M.Run(c, "reagentbuy on", cls)
    eq(c.reagentBuyEnabled, nil, cls .. ": nothing set")
    eq(out[1], "Your class does not use reagents.", cls .. ": says why")
end
eq(has(M.Run(fresh(), "help"), "/cvn reagentbuy on/off"), true, "help lists reagentbuy")
for _, m in ipairs({ "reagentbuy on", "reagentbuy 5", "reagentbuy x", "" }) do
    for _, line in ipairs((M.Run(fresh(), m, "MAGE"))) do
        eq(line:find("|", 1, true), nil, "no pipe in output of '" .. m .. "': " .. line)
    end
end

-- Target choice: mode and preference, with the valid values named on bad input.
c = fresh()
out = M.Run(c, "")
eq(has(out, "asks which one"), true, "status: asks by default")
eq(has(out, "on your map"), true, "status: map preference by default")
out = M.Run(c, "choice auto")
eq(c.vendorMode, "auto", "mode set")
eq(has(out, "navigates without asking"), true, "status shows the mode")
M.Run(c, "prefer distance")
eq(c.vendorPrefer, "distance", "preference set")
eq(has(M.Run(c, ""), "that is closest"), true, "status shows the preference")
M.Run(c, "  CHOICE   ASK ")
eq(c.vendorMode, "ask", "case and spacing tolerated")
out = M.Run(c, "choice maybe")
eq(c.vendorMode, "ask", "bad mode leaves the setting")
eq(has(out, "Choose ask or auto."), true, "bad mode names the choices")
out = M.Run(c, "prefer")
eq(c.vendorPrefer, "distance", "missing value leaves the setting")
eq(has(out, "Choose map or distance."), true, "missing value names the choices")
eq(has(M.Run(c, "help"), "/cvn choice"), true, "help lists choice")
eq(has(M.Run(c, "help"), "/cvn prefer"), true, "help lists prefer")

-- On-screen notice switch.
c = fresh()
eq(has(M.Run(c, ""), "On-screen notice when choosing without asking: on"), true, "status: notice on when unset")
M.Run(c, "notice off")
eq(c.autoNotice, false, "notice off")
eq(has(M.Run(c, ""), "without asking: off"), true, "status shows off")
M.Run(c, " NOTICE  ON ")
eq(c.autoNotice, true, "notice back on, case and spacing tolerated")
out = M.Run(c, "notice maybe")
eq(c.autoNotice, true, "bad value leaves the setting")
eq(has(out, "Choose on or off."), true, "bad value names the choices")
eq(has(M.Run(c, "notice"), "Choose on or off."), true, "missing value names the choices")
eq(has(M.Run(c, "help"), "/cvn notice"), true, "help lists notice")

-- Reagents: threshold, listing, switching one by name, the test command.
c = fresh()
eq(has(M.Run(c, ""), "Reagents: on, trigger at 5 or fewer"), true, "status shows the reagent threshold")
eq(has(M.Run(c, ""), "switched off"), false, "nothing switched off: no line")
out = M.Run(c, "reagent 12")
eq(c.reagentThreshold, 12, "reagent threshold set")
eq(has(out, "trigger at 12"), true, "reply shows it")
M.Run(c, "reagent 1"); eq(c.reagentThreshold, 1, "minimum accepted")
M.Run(c, "reagent 40"); eq(c.reagentThreshold, 40, "maximum accepted")
for _, bad in ipairs({ "0", "41", "-1", "2.5", "abc" }) do
    c.reagentThreshold = 7
    out = M.Run(c, "reagent " .. bad)
    eq(c.reagentThreshold, 7, "reagent " .. bad .. " rejected")
    eq(has(out, "from 1 to 40"), true, "range stated for " .. bad)
end
eq(M.LIMITS.reagent[1] == 1 and M.LIMITS.reagent[2] == 40, true, "limits for the settings page")
eq(has(M.Run(c, "ammo off"), "Reagents: off"), true, "the master switch shows as reagents off")

c = fresh()
out = M.Run(c, "reagents", "MAGE")
eq(has(out, "Arcane Powder: on") and has(out, "Rune of Teleportation: on") and has(out, "Rune of Portals: on"), true, "lists the mage reagents, all on")
eq(has(out, "Symbol of Kings"), false, "only the class's reagents")
out = M.Run(c, "reagent off arcane powder", "MAGE")
eq(c.reagentOff[17020], true, "switched off by name")
eq(has(out, "Arcane Powder: off"), true, "confirmed")
eq(has(M.Run(c, "reagents", "MAGE"), "Arcane Powder: off"), true, "the list shows it off")
eq(has(M.Run(c, "reagents", "MAGE"), "Rune of Portals: on"), true, "others stay on")
eq(has(M.Run(c, ""), "Reagents switched off: Arcane Powder"), true, "status lists what is off")
M.Run(c, "reagent on  ARCANE   powder", "MAGE")
eq(c.reagentOff[17020], nil, "switched back on, case and spaces ignored")
M.Run(c, "reagent off 17032", "MAGE")
eq(c.reagentOff[17032], true, "by item id")
out = M.Run(c, "reagent off nonsense", "MAGE")
eq(has(out, "No reagent named nonsense"), true, "unknown name says so")
eq(c.reagentOff[17031], nil, "and changes nothing")
eq(has(M.Run(c, "reagent off ankh", "MAGE"), "No reagent named"), true, "another class's reagent is unknown")
eq(has(M.Run(c, "reagent off", "MAGE"), "Name a reagent"), true, "no name given")
eq(has(M.Run(c, "reagent off ankh", "WARRIOR"), "no reagents"), true, "a class without reagents")
eq(has(M.Run(c, "reagents", "WARRIOR"), "no reagents"), true, "listing for a class without reagents")
eq(has(M.Run(c, "reagents", nil), "no reagents"), true, "unknown class")
local old = fresh(); old.reagentOff = nil
M.Run(old, "reagent off arcane powder", "MAGE")
eq(old.reagentOff[17020], true, "an old settings table gets its off-list")

local out2, action = M.Run(fresh(), "test reagent")
eq(action[1] == "test" and action[2] == "reagent", true, "test reagent action")
eq(has(out2, "reagent"), true, "test reagent line")

-- Status window: lock, scale, reset.
c = fresh()
out = M.Run(c, "")
eq(has(out, "Status window: unlocked, scale 100%"), true, "status shows the window, defaults for an old settings table")
eq(has(out, "Status window rows changed"), false, "no changed rows: no such line")
out = M.Run(c, "hud lock")
eq(c.hudLocked, true, "locked")
eq(has(out, "Status window: locked"), true, "reply shows it")
M.Run(c, "hud unlock")
eq(c.hudLocked, false, "unlocked")
out = M.Run(c, "hud scale 150")
eq(c.hudScale, 150, "scale set in percent")
eq(has(out, "scale 150%"), true, "reply shows the scale")
M.Run(c, "hud scale 50"); eq(c.hudScale, 50, "50 allowed")
M.Run(c, "hud scale 200"); eq(c.hudScale, 200, "200 allowed")
for _, bad in ipairs({ "hud scale", "hud scale 49", "hud scale 201", "hud scale 99.5", "hud scale big", "hud scale 100 100" }) do
    out = M.Run(c, bad)
    eq(c.hudScale, 200, bad .. ": unchanged")
    eq(has(out, "from 50 to 200"), true, bad .. ": explained")
end
local action2
out, action2 = M.Run(c, "hud reset")
eq(action2[1] .. ":" .. action2[2], "hud:reset", "reset is an action for the caller")
eq(has(out, "default position"), true, "reset says what it did")
eq(has(M.Run(c, "hud"), "Choose lock, unlock, reset, scale, opacity, textopacity, color or row."), true, "bare hud explains")
eq(has(M.Run(c, "hud dance"), "Choose lock, unlock, reset, scale, opacity, textopacity, color or row."), true, "unknown hud word explains")

-- Status window: background opacity (0-100), text opacity (20-100) and background colour.
c = fresh()
out = M.Run(c, "")
eq(has(out, "background 80% of color #000000, text and icons 100%"), true, "status shows the defaults for an old settings table")
out = M.Run(c, "hud opacity 0")
eq(c.hudAlpha, 0, "background opacity 0 allowed: only text and icons")
eq(has(out, "background 0%"), true, "reply shows the background opacity")
M.Run(c, "hud opacity 100"); eq(c.hudAlpha, 100, "100 allowed")
for _, bad in ipairs({ "hud opacity", "hud opacity -1", "hud opacity 101", "hud opacity 50.5", "hud opacity dim", "hud opacity 5 5" }) do
    out = M.Run(c, bad)
    eq(c.hudAlpha, 100, bad .. ": unchanged")
    eq(has(out, "Background opacity must be a whole number from 0 to 100."), true, bad .. ": explained")
end
out = M.Run(c, "hud textopacity 20")
eq(c.hudTextAlpha, 20, "text opacity 20 allowed")
eq(has(out, "text and icons 20%"), true, "reply shows the text opacity")
M.Run(c, "hud textopacity 100"); eq(c.hudTextAlpha, 100, "100 allowed")
for _, bad in ipairs({ "hud textopacity", "hud textopacity 19", "hud textopacity 0", "hud textopacity 101", "hud textopacity 30.5" }) do
    out = M.Run(c, bad)
    eq(c.hudTextAlpha, 100, bad .. ": unchanged")
    eq(has(out, "Text opacity must be a whole number from 20 to 100."), true, bad .. ": explained")
end
out = M.Run(c, "hud color #1A2B3C")
eq(c.hudColor, "1a2b3c", "colour set from #rrggbb, saved lower case without the #")
eq(has(out, "of color #1a2b3c"), true, "reply shows the colour")
M.Run(c, "hud color 102030"); eq(c.hudColor, "102030", "without the #")
M.Run(c, "hud color black"); eq(c.hudColor, "000000", "black")
M.Run(c, "hud colour 405060"); eq(c.hudColor, "405060", "colour spelt either way")
M.Run(c, "hud color reset"); eq(c.hudColor, "000000", "reset is black")
for _, bad in ipairs({ "hud color red", "hud color #12345", "hud color #1234567", "hud color 10 20 30" }) do
    out = M.Run(c, bad)
    eq(c.hudColor, "000000", bad .. ": unchanged")
    eq(has(out, "Give the color as #rrggbb"), true, bad .. ": explained")
end
do -- no colour given: the caller opens the colour picker; nothing is changed or printed
    local lines, action = M.Run(c, "hud color")
    eq(#lines, 0, "hud color alone prints nothing itself")
    eq(action and (action[1] .. "/" .. action[2]), "hud/pick", "hud color alone asks for the picker")
    local _, a2 = M.Run(c, "hud colour")
    eq(a2 and a2[2], "pick", "colour spelt either way")
    local _, a3 = M.Run(c, "hud color red")
    eq(a3, nil, "a bad colour does not open the picker")
    eq(c.hudColor, "000000", "unchanged")
end
c.hudColor = "nonsense"
eq(has(M.Run(c, ""), "of color #000000"), true, "a saved colour that is not one shows as black")

-- Row modes, one per group.
c = fresh()
out = M.Run(c, "hud row reagents always", "MAGE")
eq(c.hudRow.reagents, "always", "the Reagents group")
eq(has(out, "Status window row Reagents: always"), true, "confirmed")
eq(has(M.Run(c, ""), "Status window rows changed: Reagents: always"), true, "/cvn reports it")
M.Run(c, "hud row professions never", "MAGE"); eq(c.hudRow.professions, "never", "the Professions group")
M.Run(c, "hud row bags never", "MAGE")
eq(c.hudRow.bags, "never", "bags row")
M.Run(c, "hud row  Bag   Space  always", "MAGE")
eq(c.hudRow.bags, "always", "long name, case and spaces ignored")
M.Run(c, "hud row durability never", "MAGE"); eq(c.hudRow.durability, "never", "durability row")
M.Run(c, "hud row ammo always", "MAGE"); eq(c.hudRow.ammo, "always", "ammo row")
eq(has(M.Run(c, ""), "Ammo: always, Reagents: always, Bag space: always, Durability: never, Professions: never"), true, "changed groups listed in window order")
M.Run(c, "hud row bags low", "MAGE")
eq(c.hudRow.bags, nil, "back to the default: not kept in the table")
for _, name in ipairs({ "arcane powder", "mining", "conjured water" }) do
    eq(has(M.Run(c, "hud row " .. name .. " always", "MAGE"), "No status window row group named " .. name), true, name .. ": not a group")
end
eq(c.hudRow["prof:Mining"] or c.hudRow["reagent:17020"], nil, "no per-row key is written")
c.hudRow["prof:Mining"] = "always" -- left by an earlier build
eq(has(M.Run(c, ""), "Mining"), false, "a stale row key is not listed")
for _, bad in ipairs({ "hud row", "hud row bags", "hud row bags sometimes", "hud row always" }) do
    eq(has(M.Run(c, bad, "MAGE"), "choose low, always or never"), true, bad .. ": explained")
end
eq(c.hudRow.bags, nil, "bad input changes nothing")
local bare = fresh(); bare.hudRow = nil
M.Run(bare, "hud row bags always", "MAGE")
eq(bare.hudRow.bags, "always", "an old settings table gets its row table")

-- Anchor and auction house.
c = fresh()
eq(has(M.Run(c, ""), "searches from: your hearthstone point"), true, "status shows the anchor (hearth by default)")
eq(has(M.Run(c, ""), "Auction house routing: off"), true, "status shows auction routing")
out = M.Run(c, "anchor last")
eq(c.instanceAnchor, "last", "anchor set")
eq(has(out, "searches from: your last position outside"), true, "reply shows it")
M.Run(c, "anchor hearth"); eq(c.instanceAnchor, "hearth", "anchor back to hearth")
eq(has(M.Run(c, "anchor home"), "Choose hearth or last."), true, "bad anchor explains")
eq(c.instanceAnchor, "hearth", "and changes nothing")
out = M.Run(c, "ah on")
eq(c.ahEnabled, true, "auction routing on")
eq(has(out, "Auction house routing: on"), true, "reply shows it")
M.Run(c, "ah off"); eq(c.ahEnabled, false, "auction routing off")
eq(has(M.Run(c, "ah maybe"), "Choose on or off."), true, "bad value explains")

-- Help lists the new commands; no line has a raw pipe.
local help = M.Run(fresh(), "help")
for _, word in ipairs({ "/cvn hud lock/unlock/reset", "/cvn hud scale <50-200>", "/cvn hud opacity <0-100>", "/cvn hud textopacity <20-100>", "/cvn hud color  open the color picker", "/cvn hud color <#rrggbb/black/reset>", "/cvn hud row <ammo/reagents/supplies/professions/bags/durability> low/always/never", "/cvn anchor hearth/last", "/cvn ah on/off", "/cvn sound <name>" }) do
    eq(has(help, word), true, "help lists " .. word)
end
eq(has(help, "|"), false, "no pipe in help")
eq(has(help, "demo"), false, "the demo command is not in help")
-- /cvn demo: an action for the caller, nothing printed, nothing changed.
c = fresh()
local function flat(t)
    local parts = {}
    for k, v in pairs(t) do parts[#parts + 1] = tostring(k) .. "=" .. tostring(v) end
    table.sort(parts)
    return table.concat(parts, ",")
end
local was = flat(c)
local lines, action = M.Run(c, "demo")
eq(#lines, 0, "demo prints nothing itself (and so not the help)")
eq(action and action[1], "demo", "demo is an action for the caller")
eq(flat(c), was, "demo changes no setting")

-- Supplies: food, water and pet food thresholds (1 to 40), switches, test actions and the status line.
c = fresh()
out = M.Run(c, "food 10")
eq(c.foodThreshold, 10, "food threshold set")
eq(has(out, "Supplies: food on (10)"), true, "reply shows the new value: " .. table.concat(out, " | "))
M.Run(c, "water 3"); eq(c.waterThreshold, 3, "water threshold set")
M.Run(c, "petfood 7"); eq(c.petFoodThreshold, 7, "pet food threshold set (command petfood, setting petFood)")
for _, w in ipairs({ { "food", "foodThreshold" }, { "water", "waterThreshold" }, { "petfood", "petFoodThreshold" } }) do
    M.Run(c, w[1] .. " 1"); eq(c[w[2]], 1, w[1] .. ": 1 allowed")
    M.Run(c, w[1] .. " 40"); eq(c[w[2]], 40, w[1] .. ": 40 allowed")
    for _, bad in ipairs({ "0", "41", "-1", "2.5", "x" }) do
        out = M.Run(c, w[1] .. " " .. bad)
        eq(c[w[2]], 40, w[1] .. " " .. bad .. ": unchanged")
        eq(has(out, "from 1 to 40"), true, w[1] .. " " .. bad .. ": says the range")
    end
end
M.Run(c, "food off"); eq(c.foodEnabled, false, "food off")
M.Run(c, "food on"); eq(c.foodEnabled, true, "food on")
M.Run(c, "water off"); eq(c.waterEnabled, false, "water off")
M.Run(c, "petfood off"); eq(c.petFoodEnabled, false, "petfood off")
eq(has(M.Run(c, ""), "Supplies: food on (40), water off (40), pet food off (40), healthstone reminder on"), true, "status line")
eq(has(M.Run(fresh(), ""), "Supplies: food on (5), water on (5), pet food on (5), healthstone reminder on"), true, "status line defaults")
for _, k in ipairs({ "food", "water", "petfood" }) do
    local lines, action = M.Run(fresh(), "test " .. k)
    eq(action[1] .. ":" .. action[2], "test:" .. k, "test " .. k .. " action")
    eq(#lines, 1, "test " .. k .. " says what it does")
end
local _, act = M.Run(fresh(), "test remind")
eq(act[1] .. ":" .. act[2], "test:remind", "test remind action")

-- /cvn sound: show, pick (plays as a preview), refuse a name that is not a choice.
do
    local cs = fresh()
    cs.remindSound = "whisper"
    local out, act2 = M.Run(cs, "sound")
    eq(has(out, "Reminder sound: Whisper ping") and has(out, "whisper, ping, invite, ready, none"), true, "/cvn sound shows the choice and the names")
    eq(act2, nil, "showing plays nothing")
    out, act2 = M.Run(cs, "sound ping")
    eq(cs.remindSound .. "/" .. tostring(act2 and act2[1]), "ping/sound", "a key picks it and asks for the preview")
    eq(has(out, "Reminder sound: Minimap ping"), true, "confirmed by label")
    M.Run(cs, "sound Group Invite")
    eq(cs.remindSound, "invite", "the label works too, case ignored")
    out, act2 = M.Run(cs, "sound none")
    eq(cs.remindSound .. "/" .. tostring(act2 and act2[1]), "none/sound", "none is saved (the preview is silent)")
    out, act2 = M.Run(cs, "sound banana")
    eq(cs.remindSound .. "/" .. tostring(act2), "none/nil", "an unknown name changes nothing")
    eq(has(out, "Choose a sound: whisper, ping, invite, ready, none."), true, "and lists the choices")
    eq(has(M.Run(cs, ""), "Reminder sound: None"), true, "/cvn reports it")
end

-- /cvn nav: show, pick, refuse a name that is not a choice.
do
    local cn = fresh()
    cn.navProvider = "auto"
    local out = M.Run(cn, "nav")
    eq(has(out, "Waypoint: Automatic") and has(out, "auto, tomtom, waypointui, native"), true, "/cvn nav shows the choice and the names")
    out = M.Run(cn, "nav native")
    eq(cn.navProvider, "native", "a key picks it")
    eq(has(out, "Waypoint: Game waypoint"), true, "confirmed by label")
    M.Run(cn, "nav TomTom")
    eq(cn.navProvider, "tomtom", "the label works too, case ignored")
    out = M.Run(cn, "nav banana")
    eq(cn.navProvider, "tomtom", "an unknown name changes nothing")
    eq(has(out, "Choose a waypoint: auto, tomtom, waypointui, native."), true, "and lists the choices")
    eq(has(M.Run(cn, ""), "Waypoint: TomTom"), true, "/cvn reports it")
end
do -- the new row group by name
    local cg = fresh()
    M.Run(cg, "hud row supplies always", "MAGE")
    eq(cg.hudRow.supplies, "always", "/cvn hud row supplies")
    M.Run(cg, "hud row food never", "MAGE")
    eq(cg.hudRow.supplies, "never", "food is the same group")
    eq(has(M.Run(cg, "hud row banana always", "MAGE"), "reagents, supplies, professions"), true, "the error names the group")
end
eq(M.LIMITS.food[1] .. "-" .. M.LIMITS.food[2] .. "," .. M.LIMITS.water[2] .. "," .. M.LIMITS.petFood[2], "1-40,40,40", "limits")
eq(has(M.Run(fresh(), "help"), "/cvn food <count>"), true, "help lists the thresholds")
eq(has(M.Run(fresh(), "help"), "/cvn test food, water, petfood"), true, "help lists the tests")
for _, line in ipairs(M.Run(fresh(), "help")) do eq(line:find("|", 1, true), nil, "no raw | in help") end

H.done()
