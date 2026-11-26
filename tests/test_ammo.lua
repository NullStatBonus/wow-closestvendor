local ns = {}
assert(loadfile("ClosestVendor/Locales/enUS.lua"))("ClosestVendor", ns)
assert(loadfile("ClosestVendor/Ammo.lua"))("ClosestVendor", ns)
local M = ns.Ammo

package.path = "tests/?.lua;" .. package.path
local eq = require("harness").eq

-- Space: empty slots hold a full stack, same-item stacks top up, other ammo blocks its slot.
eq(M.Space({ false, false }, 200, 7), 400, "empty quiver")
eq(M.Space({ { 7, 50 }, { 7, 200 }, false }, 200, 7), 350, "partial stacks and an empty slot")
eq(M.Space({ { 8, 10 }, false }, 200, 7), 200, "other ammo takes its slot")
eq(M.Space({ { 7, 200 } }, 200, 7), 0, "full")
eq(M.Space({}, 200, 7), 0, "no quiver")
eq(M.Space(nil, 200, 7), nil, "unknown slots")
eq(M.Space({ false }, nil, 7), nil, "unknown stack")

-- Pick
local offers = {
    { index = 1, id = 10, name = "Rough", price = 100, batch = 100, minLevel = 1, kind = "arrow" },
    { index = 2, id = 11, name = "Sharp", price = 400, batch = 100, minLevel = 10, kind = "arrow" },
    { index = 3, id = 12, name = "Razor", price = 900, batch = 100, minLevel = 25, kind = "arrow" },
    { index = 4, id = 13, name = "Jagged", price = 2000, batch = 100, minLevel = 40, kind = "arrow" },
    { index = 5, id = 20, name = "Bullet", price = 50, batch = 20, minLevel = 1, kind = "bullet" },
}
local function pick(mode, kind, eqid, lvl) local p = M.Pick(mode, kind, offers, eqid, lvl); return p and p.id end
eq(pick("equipped", "arrow", 11, 30), 11, "same as equipped")
eq(pick("equipped", "arrow", 99, 30), nil, "equipped not sold")
eq(pick("equipped", "arrow", nil, 30), nil, "nothing equipped")
eq(pick("best", "arrow", 10, 30), 12, "best usable at level 30")
eq(pick("best", "arrow", 10, 45), 13, "best usable at level 45")
eq(pick("best", "arrow", 10, nil), 10, "unknown level falls back to equipped")
eq(pick("best", "arrow", 99, nil), nil, "unknown level, nothing equipped")
eq(pick("cheapest", "arrow", 13, 60), 10, "cheapest")
eq(pick("cheapest", "bullet", nil, 60), 20, "other kind")
eq(pick("equipped", "bullet", 10, 60), nil, "arrow equipped does not satisfy bullets")

-- Plan
local o = { price = 100, batch = 100 }
local n, items, cost, partial = M.Plan(450, o, 10000)
eq(n .. "/" .. items .. "/" .. cost .. "/" .. tostring(partial), "4/400/400/false", "whole batches only")
n, items, cost, partial = M.Plan(450, o, 250)
eq(n .. "/" .. items .. "/" .. cost .. "/" .. tostring(partial), "2/200/200/true", "limited by gold")
eq((M.Plan(450, { price = 100, batch = 100, stock = 1 }, 9999)), 1, "limited by stock")
eq((M.Plan(50, o, 9999)), 0, "less than one batch")
eq(M.Plan(nil, o, 100), nil, "unknown space")
eq(M.Plan(100, o, nil), nil, "unknown money")
eq(M.Plan(100, { batch = 1 }, 10), nil, "unknown price")

eq(M.Coins(31200), "3g 12s 0c", "coins gold")
eq(M.Coins(250), "2s 50c", "coins silver")

-- OnMerchant
local function run(cfg, over)
    local bought, said, asked = {}, {}, {}
    local env = {
        kind = function() return "arrow" end, equippedID = function() return 11 end,
        level = function() return 30 end, offers = function() return offers end,
        money = function() return 100000 end, space = function() return 400 end,
        buy = function(i) bought[#bought + 1] = i; return true end, say = function(t) said[#said + 1] = t end,
        confirm = function(t, accept) asked[#asked + 1] = { t, accept } end,
    }
    for k, v in pairs(over or {}) do env[k] = v end
    local c = { ammoBuyEnabled = true, ammoBuyPrompt = false, arrowGrade = "equipped", bulletGrade = "equipped" }
    for k, v in pairs(cfg or {}) do c[k] = v end
    M.OnMerchant(c, env)
    return bought, said, asked
end
local b, s = run()
eq(#b, 4, "default: buys at once")
local _, spentCost = M.OnMerchant({ ammoBuyEnabled = true, ammoBuyPrompt = false, arrowGrade = "equipped" }, { kind = function() return "arrow" end, equippedID = function() return 11 end, level = function() return 30 end, offers = function() return offers end, money = function() return 100000 end, space = function() return 400 end, buy = function() return true end, say = function() end })
eq(spentCost, 1600, "returns what an immediate purchase cost")
eq(b[1], 2, "buys the equipped item's offer")
eq(s[1], "Bought 400 Sharp for 16s 0c.", "reports")

b = run({ ammoBuyEnabled = false })
eq(#b, 0, "off")
b = run(nil, { kind = function() end })
eq(#b, 0, "no ranged weapon")
b = run(nil, { space = function() return nil end })
eq(#b, 0, "unknown space buys nothing")
b = run(nil, { space = function() return 0 end })
eq(#b, 0, "full")
b = run({ arrowGrade = "best" })
eq(b[1], 3, "arrow mode applies")
b = run({ bulletGrade = "best" })
eq(b[1], 2, "bullet mode does not affect arrows")
b, s = run(nil, { equippedID = function() return 99 end })
eq(#b, 0, "equipped item not sold buys nothing")
eq(s[1], "This merchant does not sell the ammo your settings ask for.", "says why")
b, s = run(nil, { offers = function() return { offers[5] } end })
eq(#s, 0, "merchant without this kind of ammo is silent")
b, s = run(nil, { money = function() return 900 end })
eq(#b, 2, "partial buy")
eq(s[1], "Bought 200 Sharp for 8s 0c (all you could afford).", "partial report")
b, s = run(nil, { money = function() return 10 end })
eq(#b, 0, "no gold")
eq(s[1], "You cannot afford any ammo here.", "says no gold")

local asked
b, s, asked = run({ ammoBuyPrompt = true })
eq(#b, 0, "prompt: nothing bought yet")
eq(asked[1][1], "Buy 400 Sharp for 16s 0c?", "prompt text")
asked[1][2]()
eq(#b, 4, "prompt: bought after Yes")
-- Yes answered after the merchant window changed: the slot no longer holds the item, nothing is bought.
local slot = { [2] = 11 }
b, s, asked = run({ ammoBuyPrompt = true }, { sells = function(i) return slot[i] end })
slot[2] = 99
asked[1][2]()
eq(#b .. "/" .. #s, "0/0", "slot changed: nothing bought and no Bought line")
slot = {}
b, s, asked = run({ ammoBuyPrompt = true }, { sells = function(i) return slot[i] end })
asked[1][2]()
eq(#b, 0, "merchant closed: nothing bought")
slot = { [2] = 11 }
b, s, asked = run({ ammoBuyPrompt = true }, { sells = function(i) return slot[i] end })
asked[1][2]()
eq(#b, 4, "same merchant: bought after Yes")
local lines = {}
run(nil, { space = function() return nil end, log = function(t) lines[#lines + 1] = t end })
eq(lines[#lines], "ammo buy: space, price or money unknown", "silent exits are logged")
run({ ammoBuyEnabled = false }, { log = function(t) lines[#lines + 1] = t end })
eq(lines[#lines], "ammo buy: off", "off is logged")
-- Yes after buying by hand: only the room left, never more than asked.
local room = 400
b, s, asked = run({ ammoBuyPrompt = true }, { space = function() return room end })
room = 100
asked[1][2]()
eq(#b .. "/" .. s[1], "1/Bought 100 Sharp for 4s 0c.", "Yes after buying by hand: only the room left")
-- The smaller amount at Yes is logged with the room left, so an in-game check can tell it from the asked one.
local yl = {}
room = 400
b, s, asked = run({ ammoBuyPrompt = true }, { space = function() return room end, log = function(t) yl[#yl + 1] = t end })
room = 100
asked[1][2]()
eq(yl[#yl - 1], "ammo buy: at Yes: fewer than asked: 1 of 4 purchases, space 100", "Yes after buying by hand: the smaller amount is logged")
eq(yl[#yl], "ammo buy: bought 100 of item 11", "then the purchase")
eq(yl[#yl - 1]:match("fewer than asked: (%d+) of"), tostring(#b), "the fewer line names the purchases that went through")
-- A call that failed at Yes writes no fewer line: the FAILED line says what happened.
yl = {}
room = 400
local calls = 0
b, s, asked = run({ ammoBuyPrompt = true }, { space = function() return room end, log = function(t) yl[#yl + 1] = t end,
    buy = function() calls = calls + 1; return calls == 1 end })
room = 200
asked[1][2]()
eq(calls, 2, "Yes after buying by hand: one call per purchase of the room left")
for _, t in ipairs(yl) do eq(t:find("fewer than asked", 1, true), nil, "a failed call at Yes writes no fewer line: " .. t) end
yl = {}
room = 400
b, s, asked = run({ ammoBuyPrompt = true }, { space = function() return room end, log = function(t) yl[#yl + 1] = t end })
asked[1][2]()
for _, t in ipairs(yl) do eq(t:find("fewer than asked", 1, true), nil, "the asked amount writes no fewer line: " .. t) end
yl = {}
b, s, asked = run({ ammoBuyPrompt = true }, { space = function() return room end, log = function(t) yl[#yl + 1] = t end })
room = 0
asked[1][2]()
eq(yl[#yl], "ammo buy: nothing left to buy", "full at Yes: nothing left, no fewer line")
eq(yl[#yl - 1]:find("fewer", 1, true), nil, "full at Yes: no fewer line before it")
room = 400
b, s, asked = run({ ammoBuyPrompt = true }, { space = function() return room end })
room = 0
asked[1][2]()
eq(#b .. "/" .. #s, "0/0", "full at Yes: nothing bought and no Bought line")
room = 400
b, s, asked = run({ ammoBuyPrompt = true }, { space = function() return room end })
room = 2000
asked[1][2]()
eq(#b, 4, "Yes never buys more than the question named")
-- Best usable: an offer whose required level has not loaded waits for its data, silently.
lines = {}
b, s = run({ arrowGrade = "best" }, { equippedID = function() return 99 end,
    offers = function() return { { index = 1, id = 10, name = "Rough", price = 100, batch = 100, kind = "arrow" } } end,
    log = function(t) lines[#lines + 1] = t end })
eq(#b .. "/" .. #s .. "/" .. lines[#lines], "0/0/ammo buy: item data not loaded", "best: unknown required level waits")
b, s = run({ arrowGrade = "best" }, { equippedID = function() return 99 end, level = function() return nil end,
    offers = function() return { { index = 1, id = 10, name = "Rough", price = 100, batch = 100, kind = "arrow" } } end })
eq(s[1], "This merchant does not sell the ammo your settings ask for.", "best with the player's level unknown still says why")
-- A purchase is logged with how many and which item; a dropped one is not.
lines = {}
run(nil, { log = function(t) lines[#lines + 1] = t end })
eq(lines[#lines], "ammo buy: bought 400 of item 11", "the purchase is logged")
lines, slot = {}, { [2] = 11 }
b, s, asked = run({ ammoBuyPrompt = true }, { sells = function(i) return slot[i] end, log = function(t) lines[#lines + 1] = t end })
slot[2] = 99
asked[1][2]()
eq(lines[#lines], "ammo buy: purchase dropped: the merchant window changed", "a dropped purchase is logged")
local function boughtLine(ls)
    for _, t in ipairs(ls) do if t:find("bought", 1, true) then return t end end
end
eq(boughtLine(lines), nil, "a dropped purchase logs no bought line anywhere")
-- An immediate purchase whose slot cannot be read buys nothing, so it spends nothing either.
local dropN, dropCost = M.OnMerchant({ ammoBuyEnabled = true, ammoBuyPrompt = false, arrowGrade = "equipped" }, { kind = function() return "arrow" end, equippedID = function() return 11 end, level = function() return 30 end, offers = function() return offers end, money = function() return 100000 end, space = function() return 400 end, buy = function() return true end, say = function() end, sells = function() return nil end })
eq(tostring(dropN) .. "/" .. tostring(dropCost), "0/0", "a dropped immediate purchase returns no purchases and no spend")
-- A purchase call the game did not take is not counted: only the calls that went through.
lines = {}
local calls = 0
b, s = run(nil, { log = function(t) lines[#lines + 1] = t end,
    buy = function() calls = calls + 1; return calls ~= 2 or nil end })
eq(boughtLine(lines), "ammo buy: bought 300 of item 11", "a failed call in the batch: only 3 of 4 logged")
eq(lines[#lines - 1], "ammo buy: FAILED: 1 of 4 purchases of item 11 did not go through", "the failed call is logged")
eq(s[1], "Bought 300 Sharp for 12s 0c.", "chat names only what went through")
lines = {}
b, s = run(nil, { log = function(t) lines[#lines + 1] = t end, buy = function() end })
eq(boughtLine(lines), nil, "every call failed: no bought line")
eq(#s, 0, "every call failed: no Bought chat line")
-- The plan line names the mode and the ammo kind; a purchase cut short by gold says so in its bought line.
lines = {}
run({ arrowGrade = "best" }, { log = function(t) lines[#lines + 1] = t end })
eq(lines[1], "ammo buy: best arrow item 12, price 900 per 100, space 400, money 100000", "plan line: mode and kind")
lines = {}
run(nil, { money = function() return 900 end, log = function(t) lines[#lines + 1] = t end })
eq(lines[#lines], "ammo buy: bought 200 of item 11 (all you could afford)", "partial: the bought line says so")
lines = {}
run(nil, { log = function(t) lines[#lines + 1] = t end })
eq(lines[#lines], "ammo buy: bought 400 of item 11", "a full purchase: no suffix")
print("ok")
