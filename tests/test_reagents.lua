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
eq(#R.ForClass("WARLOCK"), 0, "warlock has none")
eq(#R.ForClass(nil), 0, "no class")

-- Item ids and bits are unique, and bits fit comfortably in a plain number.
local ids, bits = {}, {}
for _, item in ipairs(R.ITEMS) do
    eq(ids[item.id], nil, "duplicate id " .. item.id)
    eq(bits[item.bit], nil, "duplicate bit " .. item.bit)
    ids[item.id], bits[item.bit] = true, true
    eq(item.bit < 30, true, "bit range")
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

-- Masks.
local mask = R.Mask({ [17020] = true, [17032] = true, [99999] = true })
eq(mask, 1 + 4, "bits 0 and 2; unknown ids ignored")
eq(R.Has(mask, R.ById(17020)), true, "has powder")
eq(R.Has(mask, R.ById(17031)), false, "no teleport rune")
eq(R.Has(mask, R.ById(17032)), true, "has portals")
eq(R.Has(nil, R.ById(17020)), false, "nil mask is empty")
eq(R.Has(0, R.ById(17020)), false, "zero mask is empty")
eq(R.Mask({}), 0, "empty set")

H.done()
