package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
H.locale(ns)
loadfile("ClosestVendor/Commands.lua")("ClosestVendor", ns)
local M = ns.Commands

local function fresh() return { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10,
    bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true } end
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
    eq(has(lines2, "/cvn test arrows"), true, bad .. ": help lists the test command")
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
local msgs = { "choice auto", "choice x", "prefer distance", "prefer", "buy on", "buy ask", "arrows best", "arrows x", "bullets cheapest", "", "help", "nonsense", "bags", "dur", "ammo", "test", "test x", "bags 5", "bags x", "dur 30", "dur 0",
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

H.done()
