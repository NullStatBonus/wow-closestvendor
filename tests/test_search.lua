local ns = {}
loadfile("ClosestVendor/Reagents.lua")("ClosestVendor", ns)
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

H.done()
