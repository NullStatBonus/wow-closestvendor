package.path = "tests/?.lua;" .. package.path
local ns = {}
require("harness").locale(ns)
loadfile("ClosestVendor/Reagents.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Supplies.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Professions.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Search.lua")("ClosestVendor", ns)
local S = ns.Search
local bucket = dofile("tests/fixtures/vendors.lua")
local ALLIANCE, HORDE = 1, 2

package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq
local function name(v) return v and v[2] or "nil" end

-- Sell: nearest vendor of any kind; hostile faction is skipped.
eq(name(S.Nearest(bucket, 0, 0, nil, ALLIANCE)), "Near Neutral Sell", "alliance skips horde vendor")
eq(name(S.Nearest(bucket, 0, 0, nil, HORDE)), "Near Horde Sell", "horde takes horde vendor")

-- Repair: only repair-capable vendors.
eq(name(S.Nearest(bucket, 0, 0, "repair", ALLIANCE)), "Mid Alliance Repair", "alliance repair")
eq(name(S.Nearest(bucket, 0, 0, "repair", HORDE)), "Far Neutral Repair", "horde repair skips alliance vendor")

-- Closest changes with player position.
eq(name(S.Nearest(bucket, 95, 0, "repair", ALLIANCE)), "Far Neutral Repair", "position matters")

-- Distance uses both axes: same x, only y differs.
local ys = { { 1, "North", 1, 0, 0, 0, false, 0, 0, 50 }, { 2, "South", 1, 0, 0, 0, false, 0, 0, -5 } }
eq(name(S.Nearest(ys, 0, 40, nil, ALLIANCE)), "North", "y decides (north)")
eq(name(S.Nearest(ys, 0, -1, nil, ALLIANCE)), "South", "y decides (south)")

-- Ammo: only vendors selling that kind; both-kinds vendors count for either; hostile skipped.
eq(name(S.Nearest(bucket, 0, 0, "arrow", ALLIANCE)), "Arrow Seller", "alliance arrows (hostile arrow seller skipped)")
eq(name(S.Nearest(bucket, 0, 0, "arrow", HORDE)), "Horde Arrows", "horde arrows")
eq(name(S.Nearest(bucket, 0, 0, "bullet", ALLIANCE)), "Bullet Seller", "bullets")
eq(name(S.Nearest(bucket, 85, 0, "bullet", ALLIANCE)), "Ammo Emporium", "a seller of both counts for bullets")
eq(name(S.Nearest(bucket, 85, 0, "arrow", ALLIANCE)), "Ammo Emporium", "a seller of both counts for arrows")
eq(name(S.Nearest(bucket, 60, 0, "arrow", ALLIANCE)), "Arrow Seller", "bullet-only vendor never chosen for arrows")
eq(S.Nearest({ bucket[2] }, 0, 0, "arrow", ALLIANCE), nil, "no ammo seller: nothing")
eq(S.Nearest({ { 1, "Old", 1, 0, 0, 0, false } }, 0, 0, "arrow", ALLIANCE), nil, "record without ammo field is not an ammo seller")

-- Map-aware: the nearest overall plus the nearest on a given map.
local mv = {
    { 1, "Border Other", 20, 0, 0, 0, false, 0, 10, 0 },   -- nearest, other map
    { 2, "Home Far",     10, 0, 0, 0, false, 0, 50, 0 },   -- nearest on map 10
    { 3, "Home Farther", 10, 0, 0, 0, false, 0, 90, 0 },
    { 4, "Horde Home",   10, 0, 0, 2, false, 0, 5, 0 },
}
local o, m = S.Nearest(mv, 0, 0, nil, ALLIANCE, 10)
eq(name(o), "Border Other", "overall nearest is on another map")
eq(name(m), "Home Far", "nearest on the player's map, hostile skipped")
o, m = S.Nearest(mv, 60, 0, nil, ALLIANCE, 10)
eq(name(o), "Home Far", "overall nearest")
eq(o == m, true, "same record when the nearest is on the map")
o, m = S.Nearest(mv, 0, 0, nil, ALLIANCE, 99)
eq(name(o), "Border Other", "overall unaffected by an empty map")
eq(m, nil, "nothing on that map")
o, m = S.Nearest(mv, 0, 0, nil, ALLIANCE)
eq(m, nil, "no map id: no map result")
eq(name(o), "Border Other", "no map id: same overall result")
o, m = S.Nearest(mv, 0, 0, "repair", ALLIANCE, 10)
eq(o, nil, "need filter applies to both")
eq(m, nil, "need filter applies to the map result")

-- Nothing eligible / empty bucket.
eq(S.Nearest({}, 0, 0, nil, ALLIANCE), nil, "empty bucket")
eq(S.Nearest({ bucket[1] }, 0, 0, nil, ALLIANCE), nil, "only hostile vendors")

-- Trainers: { npcId, name, uiMapID, mx, my, faction, trades, wx, wy }
local trainers = {
    { 1, "Near Herb",   1, 0.1, 0.1, 0, { Herbalism = true }, 10, 0 },
    { 2, "Mid Mining",  1, 0.2, 0.1, 0, { Mining = true, Engineering = true }, 20, 0 },
    { 3, "Far Mining",  1, 0.9, 0.1, 0, { Mining = true }, 90, 0 },
    { 4, "Horde Mine",  1, 0.3, 0.1, 2, { Mining = true }, 5, 0 },
    { 5, "Close Ally",  1, 0.3, 0.1, 1, { Mining = true }, 5, 3 },
}
eq(name(S.NearestTrainer(trainers, 0, 0, "Mining", ALLIANCE)), "Close Ally", "nearest teaching the profession")
eq(name(S.NearestTrainer(trainers, 0, 0, "Herbalism", ALLIANCE)), "Near Herb", "other professions are not mixed in")
eq(name(S.NearestTrainer(trainers, 0, 0, "Mining", HORDE)), "Horde Mine", "horde trainer for horde")
eq(name(S.NearestTrainer(trainers, 80, 0, "Mining", ALLIANCE)), "Far Mining", "closest changes with position")
eq(name(S.NearestTrainer(trainers, 0, 0, "Engineering", ALLIANCE)), "Mid Mining", "a trainer teaching two professions")
-- A tier to learn: a trainer known to teach less is skipped; one not known is trusted below Artisan.
local tiered = {
    { 6, "Journeyman Smith", 1, 0.1, 0.1, 0, { Blacksmithing = 1 }, 1, 0 },
    { 7, "Unknown Smith",    1, 0.2, 0.1, 0, { Blacksmithing = true }, 2, 0 },
    { 8, "Expert Smith",     1, 0.3, 0.1, 0, { Blacksmithing = 2 }, 3, 0 },
    { 9, "Master Smith",     1, 0.9, 0.1, 0, { Blacksmithing = 4 }, 9, 0 },
}
eq(name(S.NearestTrainer(tiered, 0, 0, "Blacksmithing", ALLIANCE)), "Journeyman Smith", "no tier asked: the closest")
eq(name(S.NearestTrainer(tiered, 0, 0, "Blacksmithing", ALLIANCE, nil, 2)), "Unknown Smith", "Journeyman: one that only teaches Apprentice is skipped")
eq(name(S.NearestTrainer({ tiered[1], tiered[3] }, 0, 0, "Blacksmithing", ALLIANCE, nil, 2)), "Expert Smith", "an Expert title teaches Journeyman")
eq(name(S.NearestTrainer(tiered, 0, 0, "Blacksmithing", ALLIANCE, nil, 4)), "Master Smith", "Artisan: only a trainer known to teach it")
eq(S.NearestTrainer({ tiered[2], tiered[3] }, 0, 0, "Blacksmithing", ALLIANCE, nil, 4), nil, "Artisan: an unknown tier is never trusted")
eq(S.NearestTrainer(trainers, 0, 0, "Alchemy", ALLIANCE), nil, "nobody teaches it")
eq(S.NearestTrainer({}, 0, 0, "Mining", ALLIANCE), nil, "empty bucket")
eq(name(S.NearestTrainer({ { 9, "Y Far", 1, 0, 0, 0, { Mining = true }, 0, 50 }, { 8, "X Near", 1, 0, 0, 0, { Mining = true }, 40, 0 } }, 0, 0, "Mining", ALLIANCE)), "X Near", "y distance counts")
eq(name(S.NearestTrainer({ { 9, "X Far", 1, 0, 0, 0, { Mining = true }, 50, 0 }, { 8, "Y Near", 1, 0, 0, 0, { Mining = true }, 0, 40 } }, 0, 0, "Mining", ALLIANCE)), "Y Near", "x distance counts")

-- Trainers by map.
local tm = {
    { 1, "Other Miner", 20, 0, 0, 0, { Mining = true }, 10, 0 },
    { 2, "Home Miner",  10, 0, 0, 0, { Mining = true }, 50, 0 },
    { 3, "Home Herb",   10, 0, 0, 0, { Herbalism = true }, 20, 0 },
}
o, m = S.NearestTrainer(tm, 0, 0, "Mining", ALLIANCE, 10)
eq(name(o), "Other Miner", "overall nearest trainer")
eq(name(m), "Home Miner", "nearest trainer for the profession on the map")
o, m = S.NearestTrainer(tm, 0, 0, "Mining", ALLIANCE)
eq(m, nil, "no map id: no map result")


-- Reagents: only vendors whose mask has that reagent; faction rules and the map result still apply.
local powder, portals = ns.Reagents.ById(17020), ns.Reagents.ById(17032)
local rv = {
    { 1, "Plain",       10, 0, 0, 0, false, 0, 5, 0, 0 },
    { 2, "Powder Near", 20, 0, 0, 0, false, 0, 20, 0, 1 },        -- bit 0
    { 3, "Both Home",   10, 0, 0, 0, false, 0, 60, 0, 1 + 4 },    -- bits 0 and 2
    { 4, "Horde Rune",  10, 0, 0, 2, false, 0, 8, 0, 4 },
    { 5, "Old Shape",   10, 0, 0, 0, false, 0, 3, 0 },             -- no mask at all
}
eq(name(S.Nearest(rv, 0, 0, { reagent = powder }, ALLIANCE)), "Powder Near", "nearest powder seller")
eq(name(S.Nearest(rv, 0, 0, { reagent = portals }, ALLIANCE)), "Both Home", "hostile and non-sellers skipped")
eq(name(S.Nearest(rv, 0, 0, { reagent = portals }, HORDE)), "Horde Rune", "horde takes the horde seller")
eq(S.Nearest({ rv[1], rv[5] }, 0, 0, { reagent = powder }, ALLIANCE), nil, "none sell it")
o, m = S.Nearest(rv, 0, 0, { reagent = powder }, ALLIANCE, 10)
eq(name(o), "Powder Near", "overall nearest seller is on another map")
eq(name(m), "Both Home", "nearest seller on the player's map")

-- Supplies: a vendor qualifies when its supply mask (index 12) has any wanted bit; no field sells none.
local sv = {
    { 1, "No Field",  10, 0, 0, 0, false, 0, 3, 0, 0 },
    { 2, "Cheese",    10, 0, 0, 0, false, 0, 10, 0, 0, 1 + 32 },   -- food + Cheese
    { 3, "Water",     10, 0, 0, 0, false, 0, 20, 0, 0, 2 },
    { 4, "Horde Bread", 10, 0, 0, 2, false, 0, 5, 0, 0, 1 + 16 },
}
eq(name(S.Nearest(sv, 0, 0, { supply = ns.Supplies.FOOD }, ALLIANCE)), "Cheese", "nearest food seller")
eq(name(S.Nearest(sv, 0, 0, { supply = ns.Supplies.FOOD }, HORDE)), "Horde Bread", "horde takes the horde seller")
eq(name(S.Nearest(sv, 0, 0, { supply = ns.Supplies.WATER }, ALLIANCE)), "Water", "water seller")
eq(name(S.Nearest(sv, 0, 0, { supply = ns.Supplies.DietBits({ Bread = true, Cheese = true }) }, ALLIANCE)), "Cheese", "any of several diets")
eq(S.Nearest(sv, 0, 0, { supply = ns.Supplies.DietBits({ Fruit = true }) }, ALLIANCE), nil, "no fruit seller")
eq(S.Nearest({ sv[1] }, 0, 0, { supply = ns.Supplies.FOOD }, ALLIANCE), nil, "old record sells no supplies")

-- From an anchor: the search starts at the given place (its continent, position and map), not at
-- the player.
local buckets = { [1] = mv, [2] = { { 9, "Other Continent", 30, 0, 0, 0, false, 0, 1, 0 } } }
o, m = S.NearestFrom(buckets, { continent = 1, x = 0, y = 0, map = 10 }, nil, ALLIANCE)
eq(name(o), "Border Other", "nearest to the anchor")
eq(name(m), "Home Far", "nearest on the anchor's map")
o, m = S.NearestFrom(buckets, { continent = 1, x = 95, y = 0, map = 10 }, nil, ALLIANCE)
eq(name(o), "Home Farther", "a different anchor gives a different vendor")
eq(o == m, true, "which is on the anchor's map")
eq(name(S.NearestFrom(buckets, { continent = 2, x = 0, y = 0 }, nil, ALLIANCE)), "Other Continent", "the anchor's continent is searched")
o, m = S.NearestFrom(buckets, { continent = 1, x = 0, y = 0 }, nil, ALLIANCE)
eq(m, nil, "an anchor without a map gives no map result")
eq(S.NearestFrom(buckets, { continent = 7, x = 0, y = 0 }, nil, ALLIANCE), nil, "unknown continent: nothing")
eq(S.NearestFrom(buckets, { continent = 1, x = 0, y = 0 }, "repair", ALLIANCE), nil, "the need still filters")

-- Need "auction": every eligible-by-faction record, nearest wins.
local AUC = {
    { 1, "Far AH",   10, 0.9, 0.1, 0, nil, 0, 90, 0 },
    { 2, "Near AH",  10, 0.1, 0.1, 0, nil, 0, 10, 0 },
    { 3, "Horde AH", 10, 0.0, 0.1, 2, nil, 0, 1, 0 },
}
eq(name(S.Nearest(AUC, 0, 0, "auction", ALLIANCE)), "Near AH", "nearest auctioneer, other faction skipped")
eq(name(S.NearestFrom({ [1] = AUC }, { continent = 1, x = 95, y = 0 }, "auction", ALLIANCE)), "Far AH", "from an anchor")
eq(S.Nearest({}, 0, 0, "auction", ALLIANCE), nil, "none known")

-- Several: up to n nearest, one per npc.
local function names(list)
    local t = {}
    for i = 1, #list do t[i] = list[i][2] end
    return table.concat(t, ",")
end
local sev = {
    { 1, "A30",    1, 0, 0, 0, true,  0, 30, 0 },
    { 2, "B10",    1, 0, 0, 0, false, 0, 10, 0 },
    { 3, "C20",    1, 0, 0, 0, true,  0, 0, 20 },
    { 4, "Horde5", 1, 0, 0, 2, true,  0, 5, 0 },
    { 5, "D40",    1, 0, 0, 0, true,  0, 40, 0 },
}
eq(names(S.Several(sev, 0, 0, nil, ALLIANCE, 10)), "B10,C20,A30,D40", "several: nearest first, hostile skipped")
eq(names(S.Several(sev, 0, 0, nil, HORDE, 2)), "Horde5,B10", "several: horde sees its own")
eq(names(S.Several(sev, 0, 0, nil, ALLIANCE, 2)), "B10,C20", "several: capped at n")
eq(names(S.Several(sev, 0, 0, "repair", ALLIANCE, 10)), "C20,A30,D40", "several: need filter")
eq(names(S.Several(sev, 28, 0, nil, ALLIANCE, 3)), "A30,D40,B10", "several: position matters")
eq(#S.Several(sev, 0, 0, nil, ALLIANCE, 0), 0, "several: n of 0 is empty")
eq(#S.Several({}, 0, 0, nil, ALLIANCE, 3), 0, "several: empty bucket")
eq(#S.Several(sev, 0, 0, "arrow", ALLIANCE, 3), 0, "several: nothing eligible")
local dup = {
    { 1, "Dup far",  1, 0, 0, 0, false, 0, 50, 0 },
    { 2, "Other",    1, 0, 0, 0, false, 0, 20, 0 },
    { 1, "Dup near", 1, 0, 0, 0, false, 0, 10, 0 },
    { 3, "Third",    1, 0, 0, 0, false, 0, 30, 0 },
    { 3, "Third far", 1, 0, 0, 0, false, 0, 90, 0 },
}
eq(names(S.Several(dup, 0, 0, nil, ALLIANCE, 10)), "Dup near,Other,Third", "several: one record per npc, the nearest, even when it comes later")
eq(names(S.Several({ dup[3], dup[1] }, 0, 0, nil, ALLIANCE, 10)), "Dup near", "several: a far duplicate after the near one is ignored")
eq(names(S.Several(dup, 0, 0, nil, ALLIANCE, 2)), "Dup near,Other", "several: a duplicate takes one slot")
eq(names(S.Several(dup, 0, 0, nil, ALLIANCE, 3)), "Dup near,Other,Third", "several: duplicates leave room for others")

-- SeveralTrainers: same rules; the tier rule applies.
eq(names(S.SeveralTrainers(trainers, 0, 0, "Mining", ALLIANCE, 10)), "Close Ally,Mid Mining,Far Mining", "several trainers: nearest first, hostile skipped")
eq(names(S.SeveralTrainers(trainers, 0, 0, "Mining", ALLIANCE, 2)), "Close Ally,Mid Mining", "several trainers: capped at n")
eq(names(S.SeveralTrainers(tiered, 0, 0, "Blacksmithing", ALLIANCE, 10, 2)), "Unknown Smith,Expert Smith,Master Smith", "several trainers: tier rule skips lower tiers")
eq(names(S.SeveralTrainers(tiered, 0, 0, "Blacksmithing", ALLIANCE, 10, 4)), "Master Smith", "several trainers: Artisan needs a known tier")
eq(#S.SeveralTrainers(trainers, 0, 0, "Alchemy", ALLIANCE, 3), 0, "several trainers: nobody teaches it")
eq(#S.SeveralTrainers({}, 0, 0, "Mining", ALLIANCE, 3), 0, "several trainers: empty bucket")
local tdup = {
    { 1, "Mine far",  1, 0, 0, 0, { Mining = true }, 50, 0 },
    { 2, "Other",     1, 0, 0, 0, { Mining = true }, 20, 0 },
    { 1, "Mine near", 1, 0, 0, 0, { Mining = true }, 0, 10 },
}
eq(names(S.SeveralTrainers(tdup, 0, 0, "Mining", ALLIANCE, 10)), "Mine near,Other", "several trainers: one per npc, the nearest")
eq(names(S.SeveralTrainers(tdup, 0, 0, "Mining", ALLIANCE, 1)), "Mine near", "several trainers: a duplicate takes one slot")

H.done()
