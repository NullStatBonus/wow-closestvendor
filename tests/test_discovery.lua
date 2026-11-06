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
eq(#merged, 4, "100(learned) + 300 + 200 + 500")
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

H.done()
