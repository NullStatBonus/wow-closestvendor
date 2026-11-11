package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
loadfile("ClosestVendor/Reagents.lua")("ClosestVendor", ns)
local R = ns.Reagents

local function names(list)
    local t = {}
    for i, v in ipairs(list) do t[i] = (v.item or v).name end
    return table.concat(t, ",")
end
local function knowing(...)
    local set = {}
    for _, id in ipairs({ ... }) do set[id] = true end
    return function(id) return set[id] == true end
end

-- Which classes have reagents.
eq(names(R.ForClass("MAGE")), "Arcane Powder,Rune of Teleportation,Rune of Portals", "mage")
eq(names(R.ForClass("PALADIN")), "Symbol of Kings,Symbol of Divinity", "paladin")
eq(names(R.ForClass("SHAMAN")), "Ankh", "shaman")
eq(#R.ForClass("HUNTER"), 0, "hunter has none")
eq(#R.ForClass("WARRIOR"), 0, "warrior has none")
eq(#R.ForClass("WARLOCK"), 0, "warlock has none to watch (shards are display-only)")
eq(#R.ForClass(nil), 0, "no class")

-- Item ids and bits are unique, and bits fit comfortably in a plain number.
local ids, bits = {}, {}
for _, item in ipairs(R.ITEMS) do
    eq(ids[item.id], nil, "duplicate id " .. item.id)
    ids[item.id] = true
    if item.bit then
        eq(bits[item.bit], nil, "duplicate bit " .. item.bit)
        bits[item.bit] = true
    end
    if item.vendor == false then
        eq(item.bit, nil, "display-only items have no bit: " .. item.name)
    else
        eq(item.bit < 30, true, "bit range")
    end
    eq(#item.spells > 0, true, "every reagent has a spell: " .. item.name)
end

-- Spell gating.
eq(names(R.Watched("MAGE", knowing(), nil)), "", "no spells known: nothing watched")
eq(names(R.Watched("MAGE", knowing(10059), nil)), "Rune of Portals", "knows a portal spell")
eq(names(R.Watched("MAGE", knowing(3567, 23028), nil)), "Arcane Powder,Rune of Teleportation", "teleport and brilliance")
eq(names(R.Watched("MAGE", function() return nil end, nil)), "", "unknown spell state is not known")
eq(names(R.Watched("PALADIN", knowing(10059), nil)), "", "another class's spell does nothing")

-- Rank gating: only the reagent of the highest known rank.
eq(names(R.Watched("DRUID", knowing(20484), nil)), "Maple Seed", "rank 1 only")
eq(names(R.Watched("DRUID", knowing(20484, 20739, 20742), nil)), "Ashwood Seed", "rank 3 hides ranks 1 and 2")
eq(names(R.Watched("DRUID", knowing(20484, 20739, 20742, 20747, 20748), nil)), "Ironwood Seed", "rank 5 only")
eq(names(R.Watched("PRIEST", knowing(21562), nil)), "Holy Candle", "fortitude rank 1")
eq(names(R.Watched("PRIEST", knowing(21562, 21564), nil)), "Sacred Candle", "fortitude rank 2 uses sacred")
eq(names(R.Watched("PRIEST", knowing(21564, 27681), nil)), "Sacred Candle", "one entry for several spells")
eq(names(R.Watched("DRUID", knowing(21849), nil)), "Wild Berries", "gift of the wild rank 1")
eq(names(R.Watched("DRUID", knowing(21849, 21850), nil)), "Wild Thornroot", "gift of the wild rank 2")

-- Switched-off reagents are not watched; the rest are.
eq(names(R.Watched("MAGE", knowing(3567, 10059), { [17032] = true })), "Rune of Teleportation", "portals switched off")
eq(names(R.Watched("MAGE", knowing(3567, 10059), {})), "Rune of Teleportation,Rune of Portals", "empty off-list means on")

-- Low counts: at or below the threshold; unreadable is not low.
local watched = R.Watched("MAGE", knowing(3567, 10059, 23028), nil)
local counts = { [17020] = 5, [17031] = 6, [17032] = 0 }
local low = R.Low(watched, function(id) return counts[id] end, 5)
eq(names(low), "Arcane Powder,Rune of Portals", "at or below 5")
eq(low[1].count, 5, "count carried")
eq(#R.Low(watched, function() return nil end, 5), 0, "unreadable counts are never low")
eq(#R.Low(watched, function() return 100 end, 5), 0, "plenty")
eq(names(R.Low(watched, function() return 0 end, 1)), "Arcane Powder,Rune of Teleportation,Rune of Portals", "none left")

-- Names and ids.
eq(R.Find("MAGE", "arcane powder").id, 17020, "case-insensitive")
eq(R.Find("MAGE", "  Rune   of Portals ").id, 17032, "spaces ignored")
eq(R.Find("MAGE", "17031").id, 17031, "by item id")
eq(R.Find("MAGE", "Ankh"), nil, "another class's reagent")
eq(R.Find("MAGE", "nonsense"), nil, "unknown")
eq(R.Find("MAGE", nil), nil, "nil text")

-- Display-only items: listed by DisplayOnly, invisible to the warning-side lookups.
eq(names(R.DisplayOnly("WARLOCK")), "Soul Shards", "warlock shards")
eq(names(R.DisplayOnly("ROGUE")), "Blinding Powder", "rogue powder")
eq(names(R.DisplayOnly("MAGE")), "Conjured Food,Conjured Water", "mage food and water")
eq(#R.DisplayOnly("DRUID"), 0, "druid has none")
eq(#R.DisplayOnly(nil), 0, "no class")
eq(names(R.ForClass("ROGUE")), "Flash Powder", "powder is not a warning reagent")
eq(names(R.ForClass("MAGE")), "Arcane Powder,Rune of Teleportation,Rune of Portals", "food is not a warning reagent")
eq(R.Find("ROGUE", "Blinding Powder"), nil, "Find skips display-only by name")
eq(R.Find("WARLOCK", "6265"), nil, "Find skips display-only by id")
eq(R.ById(6265), nil, "ById skips display-only")
eq(R.Mask({ [6265] = true, [5530] = true, [5350] = true }), 0, "display-only ids never enter a mask")
eq(table.concat(R.ItemIds(R.DisplayOnly("WARLOCK")[1]), ","), "6265", "single id")
eq(table.concat(R.ItemIds(R.DisplayOnly("MAGE")[2]), ","), "5350,2288,2136,3772,8077,8078,8079", "water ids summed")
-- Watched never returns them, even when the class knows every spell.
local all = function() return true end
eq(names(R.Watched("WARLOCK", all, nil)), "", "shards never watched")
eq(names(R.Watched("ROGUE", all, nil)), "Flash Powder", "only flash powder watched")
eq(names(R.Watched("MAGE", all, nil)), "Arcane Powder,Rune of Teleportation,Rune of Portals", "food and water never watched")

-- Masks.
local mask = R.Mask({ [17020] = true, [17032] = true, [99999] = true })
eq(mask, 1 + 4, "bits 0 and 2; unknown ids ignored")
eq(R.Has(mask, R.ById(17020)), true, "has powder")
eq(R.Has(mask, R.ById(17031)), false, "no teleport rune")
eq(R.Has(mask, R.ById(17032)), true, "has portals")
eq(R.Has(nil, R.ById(17020)), false, "nil mask is empty")
eq(R.Has(0, R.ById(17020)), false, "zero mask is empty")
eq(R.Mask({}), 0, "empty set")

-- Buying reagents -------------------------------------------------------------------------------
H.locale(ns)
assert(loadfile("ClosestVendor/Ammo.lua"))("ClosestVendor", ns)
local AP, RT, RP = R.ById(17020), R.ById(17031), R.ById(17032)
local function offer(id, name, index, price, extra)
    local o = { index = index, id = id, name = name, price = price, batch = 1, stock = -1, maxBuy = 20 }
    for k, v in pairs(extra or {}) do o[k] = v end
    return o
end
local OFFERS = { offer(17020, "Arcane Powder", 3, 100), offer(17031, "Rune of Teleportation", 4, 1000), offer(17032, "Rune of Portals", 5, 2000) }
local function stack20() return 20 end
local function free(n) local t = {} for i = 1, n do t[i] = false end return t end
local function plan(want, slots, money, target, offers, stack)
    local lines, cost, short = R.BuyPlan(want, offers or OFFERS, slots, stack or stack20, money, target)
    if not lines then return nil end
    local t = {}
    for _, l in ipairs(lines) do t[#t + 1] = l.offer.id .. "x" .. l.items end
    return table.concat(t, " "), cost, short
end

-- Stock up to the target, counting what is already carried.
eq(plan({ { item = AP, count = 0 } }, free(4), 1e6, 20), "17020x20", "none carried: buys the target")
eq(plan({ { item = AP, count = 7 } }, free(4), 1e6, 20), "17020x13", "7 carried: buys 13")
eq(plan({ { item = AP, count = 20 } }, free(4), 1e6, 20), "", "already at the target: nothing")
eq(plan({ { item = AP, count = 35 } }, free(4), 1e6, 20), "", "above the target: nothing")
eq(plan({ { item = AP, count = 0 } }, free(4), 1e6, 0), "", "target 0 buys none")
eq(plan({ { item = AP, count = 0 } }, free(10), 1e6, 100), "17020x100", "the most, 100")
eq(plan({ { item = AP, count = nil } }, free(4), 1e6, 20), "", "unreadable count: skipped")
local _, c1 = plan({ { item = AP, count = 5 }, { item = RT, count = 0 } }, free(4), 1e6, 10)
eq(plan({ { item = AP, count = 5 }, { item = RT, count = 0 } }, free(4), 1e6, 10), "17020x5 17031x10", "each reagent its own amount")
eq(c1, 5 * 100 + 10 * 1000, "total cost")
-- Stack sizes and bag room: partial stacks of the same item top up, other items block their slot,
-- and empty slots are shared between reagents.
eq(plan({ { item = AP, count = 15 } }, { { 17020, 15 } }, 1e6, 40), "17020x5", "only the partial stack fits")
local p2, _, s2 = plan({ { item = AP, count = 15 } }, { { 17020, 15 }, { 999, 1 } }, 1e6, 40)
eq(p2 .. "/" .. tostring(s2), "17020x5/bags", "full bags stop it, and say so")
eq(plan({ { item = AP, count = 0 } }, free(2), 1e6, 30, nil, function() return 10 end), "17020x20", "stack size limits the room")
local p3, _, s3 = plan({ { item = AP, count = 0 }, { item = RT, count = 0 } }, free(3), 1e6, 30)
eq(p3 .. "/" .. tostring(s3), "17020x30 17031x20/bags", "empty slots used by one reagent are gone for the next (30 take two slots)")
local p4, _, s4 = plan({ { item = AP, count = 0 } }, { { 999, 1 } }, 1e6, 20)
eq(p4 .. "/" .. tostring(s4), "/bags", "no room at all")
eq(plan({ { item = AP, count = 0 } }, free(4), 1e6, 20, nil, function() return nil end), "", "unknown stack size: skipped")
eq(plan({ { item = AP, count = 0 } }, nil, 1e6, 20), nil, "unknown bags: no plan")
-- Money: buys what it can afford, in table order, and says it was short.
local p5, c5, s5 = plan({ { item = AP, count = 0 } }, free(4), 1250, 20)
eq(p5 .. "/" .. c5 .. "/" .. s5, "17020x12/1200/money", "partial buy when short of gold")
local p6, c6, s6 = plan({ { item = AP, count = 0 }, { item = RT, count = 0 } }, free(4), 2500, 20)
eq(p6 .. "/" .. c6 .. "/" .. s6, "17020x20/2000/money", "money spent on one is gone for the next")
local p7, _, s7 = plan({ { item = AP, count = 0 } }, free(4), 50, 20)
eq(p7 .. "/" .. s7, "/money", "cannot afford one")
eq(plan({ { item = AP, count = 0 } }, free(4), nil, 20), nil, "unknown money: no plan")
local p7b, _, s7b = plan({ { item = AP, count = 0 } }, { { 999, 1 } }, 50, 20)
eq(s7b, "bags", "no room and no gold: the bags are named, they are the limit")
-- Batches and stock: whole purchases only, never more than needed; a limited stock caps it.
eq(plan({ { item = AP, count = 0 } }, free(4), 1e6, 25, { offer(17020, "AP", 3, 500, { batch = 10 }) }), "17020x20", "batch of 10: 20 of 25, not 30")
eq(plan({ { item = AP, count = 0 } }, free(4), 1e6, 20, { offer(17020, "AP", 3, 100, { stock = 3 }) }), "17020x3", "limited stock")
eq(plan({ { item = RP, count = 0 } }, free(4), 1e6, 20), "17032x20", "a reagent not sold here is skipped, others bought")
eq(plan({ { item = AP, count = 0 } }, free(4), 1e6, 20, { offer(17031, "RT", 4, 1) }), "", "not sold here: nothing")
eq(plan({ { item = AP, count = 0 } }, free(4), 1e6, 20, { offer(17020, "AP", 3, nil) }), "", "unknown price: skipped")

-- OnMerchant
local function run(cfg, over)
    local bought, said, asked, logged = {}, {}, {}, {}
    local env = {
        watched = function() return { { item = AP, count = 5 }, { item = RT, count = 0 } } end,
        offers = function() return OFFERS end, slots = function() return free(4) end,
        stack = stack20, money = function() return 1e6 end,
        buy = function(i, q) bought[#bought + 1] = i .. ":" .. tostring(q) end,
        say = function(t) said[#said + 1] = t end,
        confirm = function(t, accept) asked[#asked + 1] = { t, accept } end,
        log = function(t) logged[#logged + 1] = t end,
    }
    for k, v in pairs(over or {}) do env[k] = v end
    local c = { reagentBuyEnabled = true, reagentBuyPrompt = false, reagentBuyTarget = 10 }
    for k, v in pairs(cfg or {}) do c[k] = v end
    local n = R.OnMerchant(c, env)
    return bought, said, asked, logged, n
end
local b, s, _, _, n = run()
eq(table.concat(b, ","), "3:5,4:10", "buys each up to the target, single items in one call each")
eq(n, 15, "returns the purchases")
eq(s[1], "Bought 5 Arcane Powder, 10 Rune of Teleportation for 1g 5s 0c.", "one chat line: what and the cost")
b = run({ reagentBuyTarget = 45 })
eq(table.concat(b, ","), "3:20,3:20,4:20,4:20", "more than one stack: calls of at most maxBuy (and four slots hold 80)")
b = run(nil, { offers = function() return { offer(17020, "Arcane Powder", 3, 100, { maxBuy = false }) } end })
eq(#b .. "/" .. b[1], "5/3:nil", "maxBuy unknown: one purchase per call")
b = run(nil, { offers = function() return { offer(17020, "Arcane Powder", 3, 100, { batch = 5, maxBuy = 20 }) } end })
eq(table.concat(b, ","), "3:nil", "a batch of 5 is one purchase")
local l
b, s, _, l = run({ reagentBuyEnabled = false })
eq(#b .. #s .. l[#l], "00reagent buy: off", "off: nothing, logged")
b, s, _, l = run({ reagentBuyTarget = 0 })
eq(#b .. #s .. l[#l], "00reagent buy: amount is 0", "0: nothing")
b, s, _, l = run(nil, { watched = function() return {} end })
eq(#b .. #s .. l[#l], "00reagent buy: no class reagent watched", "a class without reagents (or none known): nothing")
b, _, _, l = run(nil, { watched = function() return nil end })
eq(#b .. l[#l], "0reagent buy: class unknown", "class unknown: nothing")
b, s, _, l = run(nil, { offers = function() return {} end })
eq(#b .. #s .. l[#l], "00reagent buy: merchant sells no class reagents", "merchant without reagents is silent")
b, _, _, l = run(nil, { offers = function() return nil end })
eq(#b .. l[#l], "0reagent buy: merchant list unreadable", "unreadable merchant")
b, _, _, l = run(nil, { money = function() return nil end })
eq(#b .. l[#l], "0reagent buy: bags or money unknown", "unknown money buys nothing")
b, _, _, l = run(nil, { slots = function() return nil end })
eq(#b .. l[#l], "0reagent buy: bags or money unknown", "unknown bags buy nothing")
b, s = run(nil, { money = function() return 50 end })
eq(#b .. "/" .. s[1], "0/You cannot afford any reagents here.", "no gold: says so")
b, s = run(nil, { money = function() return 1000 end })
eq(table.concat(b, ",") .. "/" .. s[1], "3:5/Bought 5 Arcane Powder for 5s 0c (all you could afford).", "partial: says so")
b, s = run(nil, { slots = function() return { { 999, 1 } } end })
eq(#b .. "/" .. s[1], "0/Your bags have no room for reagents.", "full bags: says so")
b, s = run(nil, { slots = function() return { false } end })
eq(table.concat(b, ",") .. "/" .. s[1], "3:5/Bought 5 Arcane Powder for 5s 0c (all that fits in your bags).", "the one free slot holds the powder, none left for runes: says so")
b, s = run(nil, { watched = function() return { { item = AP, count = 10 } } end })
eq(#b + #s, 0, "already stocked: silent")
local asked
b, s, asked = run({ reagentBuyPrompt = true })
eq(#b .. #s, "00", "ask first: nothing bought yet")
eq(asked[1][1], "Buy 5 Arcane Powder, 10 Rune of Teleportation for 1g 5s 0c?", "the question names reagents, counts and price")
asked[1][2]()
eq(table.concat(b, ",") .. "/" .. s[1], "3:5,4:10/Bought 5 Arcane Powder, 10 Rune of Teleportation for 1g 5s 0c.", "bought after Yes")
b, s, asked = run({ reagentBuyPrompt = true }, { money = function() return 50 end })
eq(#asked .. "/" .. s[1], "0/You cannot afford any reagents here.", "nothing to buy: no question")

H.done()
