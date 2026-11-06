local ns = {}
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

H.done()
