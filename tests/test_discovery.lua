local ns = {}
loadfile("ClosestVendor/Discovery.lua")("ClosestVendor", ns)
local D = ns.Discovery

package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq
local function count(t) local c = 0 for _ in pairs(t) do c = c + 1 end return c end

-- Record a new vendor.
local learned = {}
eq(D.Record(learned, { 100, "Seller", 1429, 0.5, 0.5, 1, false, 0 }), true, "new vendor stored")
eq(learned[100][2], "Seller", "stored by npc id")

-- Same vendor again: not duplicated, and unchanged data reports no change.
eq(D.Record(learned, { 100, "Seller", 1429, 0.5, 0.5, 1, false, 0 }), false, "identical revisit")
eq(count(learned), 1, "no duplicate")

-- Changed data updates the one record (e.g. now known to repair, or moved).
eq(D.Record(learned, { 100, "Seller", 1429, 0.6, 0.5, 1, true, 0 }), true, "changed revisit")
eq(count(learned), 1, "still one record")
eq(learned[100][7], true, "repair updated")
eq(learned[100][4], 0.6, "position updated")

-- A small move on a repeat visit keeps the saved position (covers: Small moves keep the saved position).
do
    local L = {}
    D.Record(L, { 300, "Baker", 1455, 0.30, 0.60, 1, false, 0, 0, 17 })
    eq(D.Record(L, { 300, "Baker", 1455, 0.302, 0.598, 1, false, 0, 0, 17 }), false, "a step to the side: unchanged")
    eq(L[300][4] .. "," .. L[300][5], "0.3,0.6", "the saved position stays")
    eq(D.Record(L, { 300, "Baker", 1455, 0.3049, 0.5951, 1, false, 0, 0, 17 }), false, "just inside D.NEAR: still unchanged")
    eq(D.Record(L, { 300, "Baker", 1455, 0.302, 0.60, 1, false, 1, 0, 17 }), true, "stock changed: updated")
    eq(L[300][8] .. "/" .. L[300][4], "1/0.3", "the stock is new and the position is kept")
    eq(D.Record(L, { 300, "Baker", 1455, 0.3051, 0.60, 1, false, 1, 0, 17 }), true, "just outside D.NEAR: updated")
    eq(L[300][4], 0.3051, "the new position is saved")
    eq(D.Record(L, { 300, "Baker", 1455, 0.32, 0.60, 1, false, 1, 0, 17 }), true, "moved 0.02: updated")
    eq(L[300][4], 0.32, "the moved position is saved")
    eq(D.Record(L, { 300, "Baker", 1456, 0.32, 0.60, 1, false, 1, 0, 17 }), true, "another map: updated even at the same x and y")
    eq(D.Record(L, { 300, "Baker", 1457, 0.322, 0.60, 1, false, 1, 0, 17 }), true, "another map, a step away: updated")
    eq(L[300][4], 0.322, "on another map the position is the new one, however close")
    local T2 = {}
    D.RecordTrainer(T2, { 40, "Smith", 1455, 0.5, 0.5, 1 }, { "Mining" })
    eq(D.RecordTrainer(T2, { 40, "Smith", 1455, 0.503, 0.5, 1 }, { "Mining" }), false, "trainer: a step to the side is unchanged")
    eq(T2[40][4], 0.5, "trainer keeps its saved position")
    eq(D.RecordTrainer(T2, { 40, "Smith", 1455, 0.503, 0.5, 1 }, { "Mining", "Smelting" }), true, "trainer: a new profession updates")
    eq(T2[40][4], 0.5, "and keeps the saved position")
    eq(D.RecordTrainer(T2, { 40, "Smith", 1455, 0.52, 0.5, 1 }, { "Mining", "Smelting" }), true, "trainer: moved 0.02 updates")
    eq(T2[40][4], 0.52, "trainer saves the moved position")
    eq(D.RecordTrainer(T2, { 40, "Smith", 1456, 0.521, 0.5, 1 }, { "Mining", "Smelting" }), true, "trainer: another map, a step away, updates")
    eq(T2[40][3] .. "/" .. T2[40][4], "1456/0.521", "trainer saves the new map and position")
    local A2 = {}
    D.RecordAuctioneer(A2, { 50, "Banker", 1455, 0.5, 0.5, 1 })
    eq(D.RecordAuctioneer(A2, { 50, "Banker", 1455, 0.5, 0.504, 1 }), false, "auctioneer: a step to the side is unchanged")
    eq(A2[50][5], 0.5, "auctioneer keeps its saved position")
    eq(D.RecordAuctioneer(A2, { 50, "Banker", 1455, 0.5, 0.52, 1 }), true, "auctioneer: moved 0.02 updates")
    eq(A2[50][5], 0.52, "auctioneer saves the moved position")
    eq(D.RecordAuctioneer(A2, { 50, "Banker", 1456, 0.5, 0.521, 1 }), true, "auctioneer: another map, a step away, updates")
    eq(A2[50][3] .. "/" .. A2[50][5], "1456/0.521", "auctioneer saves the new map and position")
end

-- Unidentifiable merchants are ignored.
eq(D.Record(learned, { nil, "Ghost", 1, 0, 0, 0, false, 0 }), false, "no id")
eq(D.Record(learned, nil), false, "nil record")
eq(D.Record(learned, { 0, "Zero", 1, 0, 0, 0, false, 0 }), false, "zero id")
eq(D.Record(learned, { "x", "Str", 1, 0, 0, 0, false, 0 }), false, "non-numeric id")
eq(count(learned), 1, "ignored records not stored")

-- The ammo code is part of the record: a changed offer updates it; a missing code is stored as 0.
eq(D.Record(learned, { 100, "Seller", 1429, 0.6, 0.5, 1, true, 3 }), true, "ammo offer changed")
eq(learned[100][8], 3, "ammo code stored")
eq(D.Record(learned, { 100, "Seller", 1429, 0.6, 0.5, 1, true, 3 }), false, "same ammo: no change")
eq(D.Record(learned, { 500, "Old Shape", 1429, 0.2, 0.2, 0, false }), true, "seven-field record accepted")
eq(learned[500][8], 0, "missing ammo code becomes 0")
eq(D.Record(learned, { 500, "Old Shape", 1429, 0.2, 0.2, 0, false }), false, "and is stable on revisit")

-- The reagent mask is the 9th field: stored, compared, and 0 when missing.
eq(D.Record(learned, { 600, "Reagents", 1429, 0.4, 0.4, 0, false, 0, 5 }), true, "reagent vendor stored")
eq(learned[600][9], 5, "mask stored")
eq(D.Record(learned, { 600, "Reagents", 1429, 0.4, 0.4, 0, false, 0, 5 }), false, "same mask: no change")
eq(D.Record(learned, { 600, "Reagents", 1429, 0.4, 0.4, 0, false, 0, 1 }), true, "changed offer updates the mask")
eq(learned[600][9], 1, "mask updated")
eq(D.Record(learned, { 600, "Reagents", 1429, 0.4, 0.4, 0, false, 0 }), true, "an offer without reagents clears the mask")
eq(learned[600][9], 0, "missing mask is 0")
learned[700] = { 700, "Saved Before", 1429, 0.5, 0.5, 0, false, 0 } -- a record saved by an older version
eq(D.Record(learned, { 700, "Saved Before", 1429, 0.5, 0.5, 0, false, 0, 0 }), false, "old record without a mask equals an empty one")
eq(D.Record(learned, { 700, "Saved Before", 1429, 0.5, 0.5, 0, false, 0, 4 }), true, "old record gains a mask")
eq(learned[700][9], 4, "mask added to the old record")

-- A learned record keeps the reagents it was learned with when it replaces a shipped one.
local m = D.Merge({ { 600, "Shipped", 1429, 0.1, 0.1, 0, false, 0, 8 } }, { [600] = learned[600] })
eq(m[1][2], "Reagents", "learned record used")
eq(m[1][9], 0, "its own mask, not the shipped one")

-- The supply mask is the 10th field: stored, compared, 0 when missing, and a record saved before it
-- existed (nil field) takes the shipped value in Merge, while a scanned record keeps its own.
local sup = {}
eq(D.Record(sup, { 900, "Baker", 1429, 0.5, 0.5, 0, false, 0, 0, 17 }), true, "supply vendor stored")
eq(sup[900][10], 17, "supply mask stored")
eq(D.Record(sup, { 900, "Baker", 1429, 0.5, 0.5, 0, false, 0, 0, 17 }), false, "same supplies: no change")
eq(D.Record(sup, { 900, "Baker", 1429, 0.5, 0.5, 0, false, 0, 0, 1 }), true, "changed stock updates the mask")
eq(D.Record(sup, { 900, "Baker", 1429, 0.5, 0.5, 0, false, 0, 0 }), true, "an offer without supplies clears the mask")
eq(sup[900][10], 0, "missing supply mask is 0")
sup[901] = { 901, "Saved Before", 1429, 0.5, 0.5, 0, false, 0, 0 } -- nine fields: saved by an older version
eq(D.Record(sup, { 901, "Saved Before", 1429, 0.5, 0.5, 0, false, 0, 0, 0 }), false, "old record equals an empty supply mask")
sup[902] = { 902, "Saved Before", 1429, 0.5, 0.5, 0, false, 0, 0 }
local sm = D.Merge({ { 902, "Shipped", 1429, 0.5, 0.5, 0, false, 0, 0, 21 }, { 900, "Shipped", 1429, 0.5, 0.5, 0, false, 0, 0, 21 } },
    { [902] = sup[902], [900] = sup[900] })
local sById = {}
for _, v in ipairs(sm) do sById[v[1]] = v end
eq(sById[902][10], 21, "old learned record takes the shipped supplies")
eq(sup[902][10], nil, "and the learned table is not changed")
eq(sById[900][10], 0, "a scanned record keeps its own mask")

-- The stored record is a copy, not the caller's table.
local rec = { 200, "Copy", 1429, 0.1, 0.1, 0, false, 1 }
D.Record(learned, rec)
rec[2] = "Mutated"
eq(learned[200][2], "Copy", "stored copy independent")

-- Merge: learned replaces shipped by id, others kept, inputs untouched.
local shipped = {
    { 100, "Old Seller", 1429, 0.1, 0.1, 1, false, 0 },
    { 300, "Shipped Only", 1429, 0.3, 0.3, 0, true, 0 },
}
local merged = D.Merge(shipped, learned)
local byId = {}
for _, v in ipairs(merged) do byId[v[1]] = v end
eq(#merged, 6, "100(learned) + 300 + 200 + 500 + 600 + 700")
eq(byId[100][2], "Seller", "learned wins over shipped")
eq(byId[300][2], "Shipped Only", "unrelated shipped kept")
eq(byId[200][2], "Copy", "learned-only included")
eq(#shipped, 2, "shipped list not modified")
eq(shipped[1][2], "Old Seller", "shipped record not modified")

-- Trainers.
local T = {}
eq(D.RecordTrainer(T, { 7, "Gelman", 1455, 0.5, 0.5, 1 }, { "Mining" }), true, "new trainer")
eq(T[7][2], "Gelman", "stored by npc id")
eq(T[7][7].Mining, true, "teaches mining")
eq(D.RecordTrainer(T, { 7, "Gelman", 1455, 0.5, 0.5, 1 }, { "Mining" }), false, "identical revisit")
eq(count(T), 1, "no duplicate")
eq(D.RecordTrainer(T, { 7, "Gelman", 1455, 0.5, 0.5, 1 }, { "Engineering" }), true, "second profession adds")
eq(T[7][7].Mining and T[7][7].Engineering, true, "both kept")
eq(D.RecordTrainer(T, { 7, "Gelman", 1455, 0.6, 0.5, 1 }, { "Mining" }), true, "moved trainer updates")
eq(T[7][4], 0.6, "new position")
eq(T[7][7].Engineering, true, "professions kept when moved")
eq(D.RecordTrainer(T, { 8, "Class", 1455, 0.5, 0.5, 1 }, {}), false, "no professions: not recorded")
eq(D.RecordTrainer(T, { 8, "Class", 1455, 0.5, 0.5, 1 }, nil), false, "nil professions")
eq(D.RecordTrainer(T, { nil, "Ghost", 1455, 0.5, 0.5, 1 }, { "Mining" }), false, "no npc id")
eq(D.RecordTrainer(T, { 0, "Zero", 1455, 0.5, 0.5, 1 }, { "Mining" }), false, "zero id")
eq(D.RecordTrainer(T, nil, { "Mining" }), false, "nil record")
eq(count(T), 1, "ignored trainers not stored")
local t1 = { 9, "A", 1, 0, 0, 0 }
D.RecordTrainer(T, t1, { "Mining" })
local list = { "Mining" }
D.RecordTrainer(T, { 10, "B", 1, 0, 0, 0 }, list)
list[1] = "Changed"
eq(T[10][7].Mining, true, "stored set does not alias the caller's list")

-- Auctioneers: six-field records, learned wins over shipped in Merge.
local AH = {}
eq(D.RecordAuctioneer(AH, { 8670, "Auctioneer Chilton", 1453, 0.53, 0.6, 1 }), true, "auctioneer stored")
eq(#AH[8670], 6, "six fields")
eq(D.RecordAuctioneer(AH, { 8670, "Auctioneer Chilton", 1453, 0.53, 0.6, 1 }), false, "same auctioneer: no change")
eq(D.RecordAuctioneer(AH, { 8670, "Auctioneer Chilton", 1453, 0.54, 0.6, 1 }), true, "moved auctioneer updates")
eq(count(AH), 1, "still one record")
eq(D.RecordAuctioneer(AH, nil), false, "nil record")
eq(D.RecordAuctioneer(AH, { 0, "Zero", 1, 0, 0, 0 }), false, "zero id")
eq(D.RecordAuctioneer(AH, { "x", "Str", 1, 0, 0, 0 }), false, "non-numeric id")
local am = D.Merge({ { 8670, "Shipped", 1453, 0.1, 0.1, 1 }, { 8669, "Other", 1438, 0.2, 0.2, 1 } }, AH)
eq(count(am), 2, "merged auctioneers")
local got
for _, v in ipairs(am) do if v[1] == 8670 then got = v end end
eq(got[2], "Auctioneer Chilton", "learned auctioneer wins over the shipped one")

-- Pool: shipped + external + learned, one entry per npc id.
local function pid(list) local m = {} for _, v in ipairs(list) do m[v[1]] = v end return m end
local ship = { { 1, "Ship1", 2482, 0.10, 0.10, 0, false, 0, 0, 0 }, { 2, "Ship2", 1429, 0.5, 0.5, 0, true, 0, 0, 0 } }
local ext = { { 1, "Ext1", 2482, 0.20, 0.20, 1, false, 0, 0, 0 }, { 3, "Ext3", 2548, 0.4, 0.4, 0, false, 0, 0, 7 } }
local none = D.Pool(ship, {}, { [2] = { 2, "L2", 1429, 0.51, 0.5, 0, false, 0, 0, 0 } })
local mg = D.Merge(ship, { [2] = { 2, "L2", 1429, 0.51, 0.5, 0, false, 0, 0, 0 } })
eq(#none, #mg, "no external: same size as Merge")
eq(pid(none)[2][4], pid(mg)[2][4], "no external: learned record kept as Merge keeps it")
local p1 = D.Pool(ship, ext, {})
eq(#p1, 3, "one entry per npc id: 1 (external), 2 (shipped), 3 (external)")
eq(pid(p1)[1][2], "Ext1", "external over shipped")
eq(pid(p1)[1][4], 0.20, "external position over shipped")
eq(#ship, 2, "shipped untouched")
eq(#ext, 2, "external untouched")
local agree = D.Pool(ship, ext, { [1] = { 1, "L1", 2482, 0.21, 0.19, 2, true, 0, 0, 0 } })
eq(pid(agree)[1][4], 0.20, "learned within 3% keeps the external position")
eq(pid(agree)[1][5], 0.20, "same on y")
eq(pid(agree)[1][6], 2, "learned faction wins")
eq(pid(agree)[1][7], true, "observed repair flag wins")
eq(#agree, 3, "learned does not add a second entry")
local moved = D.Pool(ship, ext, { [1] = { 1, "L1", 2482, 0.30, 0.20, 1, false, 0, 0, 0 } })
eq(pid(moved)[1][4], 0.30, "vendor moved on x: learned position")
local movedY = D.Pool(ship, ext, { [1] = { 1, "L1", 2482, 0.20, 0.30, 1, false, 0, 0, 0 } })
eq(pid(movedY)[1][5], 0.30, "vendor moved on y: learned position")
-- Moved: the test Pool uses, also for the debug log line when a vendor's window opens.
local E1 = { 1, "Ext1", 2482, 0.20, 0.20, 1 }
eq(D.Moved({ 1, "L1", 2482, 0.22, 0.18 }, E1), false, "within 0.03 on both axes: the external position is kept")
eq(D.Moved({ 1, "L1", 2482, 0.24, 0.20 }, E1), true, "over 0.03 on x: moved")
eq(D.Moved({ 1, "L1", 2482, 0.20, 0.16 }, E1), true, "over 0.03 on y: moved")
eq(D.Moved({ 1, "L1", 1429, 0.20, 0.20 }, E1), true, "another map: moved")
eq(D.Moved({ 1, "L1", 2482 }, E1), false, "no learned position: never moved")
eq(D.Moved({ 1, "L1", 1429 }, E1), false, "another map but no learned position: never moved")
do
    local p = D.Pool({}, { E1 }, { [1] = { 1, "L1", 1429 } })
    local r = p[1]
    eq(r and r[3] .. "," .. tostring(r[4]), "2482,0.2", "the pool keeps the external map and position for a learned record with none")
end
local other = D.Pool(ship, ext, { [1] = { 1, "L1", 1429, 0.20, 0.20, 1, false, 0, 0, 0 } })
eq(pid(other)[1][3], 1429, "learned on another map: learned position")
local old = D.Pool(ship, ext, { [3] = { 3, "L3", 2548, 0.4, 0.4, 0, false, 0, 0 } })
eq(pid(old)[3][10], 7, "learned record from before supplies: external supplies")
eq(pid(D.Pool(ship, ext, { [3] = { 3, "L3", 2548, 0.4, 0.4, 0, false, 0, 0, 1 } }))[3][10], 1, "learned supplies win")
local both = D.Pool(ship, { { 5, "Ext5", 2482, 0.2, 0.2, 1, true, 3, 5, 9 } }, { [5] = { 5, "L5", 2482 } })
eq(pid(both)[5][4], 0.2, "learned record without a position keeps the external one")
eq(pid(both)[5][6], 1, "missing learned faction falls back to the external one")
eq(pid(both)[5][7], true, "missing learned repair flag falls back")
eq(pid(both)[5][8], 3, "missing learned ammo falls back to the external one")
eq(pid(both)[5][9], 5, "missing learned reagents fall back")
eq(#D.Pool(ship, ext, { [99] = { 99, "Only", 1429, 0.1, 0.1, 0, false, 0, 0, 0 } }), 4, "learned-only vendor added")


-- Tradable: what this character has seen decides; a learned neutral vendor needs to have been seen friendly.
do
    local pool = {
        { 1, "Shipped Goblin", 1429, 0.1, 0.1, 0 },
        { 2, "Learned Quartermaster", 1443, 0.2, 0.2, 0 },
        { 3, "Learned Alliance", 1429, 0.3, 0.3, 1 },
        { 4, "Shipped Unfriendly", 1429, 0.4, 0.4, 0 },
    }
    local known = { [1] = true, [4] = true }
    local function ids(list) local t = {}; for _, v in ipairs(list) do t[#t + 1] = v[1] end; return table.concat(t, ",") end
    eq(ids(D.Tradable(pool, known, {})), "1,3,4", "unseen learned neutral vendor is left out")
    eq(ids(D.Tradable(pool, known, { [2] = true })), "1,2,3,4", "seen as Neutral or better: used")
    eq(ids(D.Tradable(pool, known, { [4] = false, [3] = false })), "1", "seen as Unfriendly or Hostile: left out")
    eq(#pool, 4, "the pool is not changed")
end

H.done()