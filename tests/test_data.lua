-- Sanity check of the generated vendor data. validate() returns an error string or nil.
local function validate(list)
    if type(list) ~= "table" or #list == 0 then return "empty or missing data" end
    local prev = 0
    for i, v in ipairs(list) do
        local id, name, map, mx, my, fac, rep, ammo, mask, sup = v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9], v[10]
        local where = "record " .. i .. " (npc " .. tostring(id) .. ")"
        if type(id) ~= "number" or id <= prev then return where .. ": id not ascending/unique" end
        prev = id
        if type(name) ~= "string" or name == "" then return where .. ": bad name" end
        if type(map) ~= "number" or map <= 0 or map % 1 ~= 0 then return where .. ": bad uiMapID" end
        if type(mx) ~= "number" or mx < 0 or mx > 1 then return where .. ": mx out of range" end
        if type(my) ~= "number" or my < 0 or my > 1 then return where .. ": my out of range" end
        if fac ~= 0 and fac ~= 1 and fac ~= 2 then return where .. ": bad faction" end
        if type(rep) ~= "boolean" then return where .. ": repair not boolean" end
        if ammo ~= 0 and ammo ~= 1 and ammo ~= 2 and ammo ~= 3 then return where .. ": bad ammo code" end
        if type(mask) ~= "number" or mask < 0 or mask >= 2 ^ 30 or mask % 1 ~= 0 then return where .. ": bad reagent mask" end
        if type(sup) ~= "number" or sup < 0 or sup >= 256 or sup % 1 ~= 0 then return where .. ": bad supply mask" end
        if #v ~= 10 then return where .. ": expected 10 fields, got " .. #v end
    end
end

local ns = {}
local chunk = assert(loadfile("ClosestVendor/Data/Vendors.lua"), "Vendors.lua does not parse")
chunk("ClosestVendor", ns)
local list = ns.ShippedVendors
local err = validate(list)
assert(err == nil, err)
assert(#list > 500, "suspiciously few vendors: " .. #list)

local repairs = 0
for _, v in ipairs(list) do if v[7] then repairs = repairs + 1 end end
assert(repairs > 100 and repairs < #list, "repair count implausible: " .. repairs)

-- Ammo coverage: plenty of sellers of each kind, and not everyone sells ammo.
local arrows, bullets, both = 0, 0, 0
for _, v in ipairs(list) do
    if v[8] == 1 or v[8] == 3 then arrows = arrows + 1 end
    if v[8] == 2 or v[8] == 3 then bullets = bullets + 1 end
    if v[8] == 3 then both = both + 1 end
end
assert(arrows > 40, "too few arrow sellers: " .. arrows)
assert(bullets > 40, "too few bullet sellers: " .. bullets)
assert(arrows < #list / 2 and bullets < #list / 2, "implausibly many ammo sellers")

-- Reagent coverage: the mask only uses bits the addon knows, and a fair number of vendors sell
-- reagents without most vendors doing so.
local ns2 = {}
assert(loadfile("ClosestVendor/Reagents.lua"), "Reagents.lua does not parse")("ClosestVendor", ns2)
local sellers, perItem = 0, {}
for _, v in ipairs(list) do
    if v[9] > 0 then sellers = sellers + 1 end
    local rest = v[9]
    for _, item in ipairs(ns2.Reagents.ITEMS) do
        if item.vendor ~= false and ns2.Reagents.Has(v[9], item) then
            perItem[item.id] = (perItem[item.id] or 0) + 1
            rest = rest - 2 ^ item.bit
        end
    end
    assert(rest == 0, "npc " .. v[1] .. ": reagent bit the addon does not know")
end
assert(sellers > 10 and sellers < #list / 4, "reagent seller count implausible: " .. sellers)
for _, item in ipairs(ns2.Reagents.ITEMS) do
    if item.vendor ~= false then
        assert((perItem[item.id] or 0) > 0, "no shipped vendor sells " .. item.name)
    end
end

-- Supplies: every vendor mask bit is one the addon knows (bits 0-7), plenty of food and water sellers, each diet
-- sold somewhere, and the item table is well formed: masks below 512, every item at least one kind.
local ns3 = {}
assert(loadfile("ClosestVendor/Data/Supplies.lua"), "Data/Supplies.lua does not parse")("ClosestVendor", ns3)
local counts = {}
for _, v in ipairs(list) do
    for bit = 0, 7 do
        if math.floor(v[10] / 2 ^ bit) % 2 == 1 then counts[bit] = (counts[bit] or 0) + 1 end
    end
end
assert((counts[0] or 0) > 50 and (counts[0] or 0) < #list, "food seller count implausible: " .. tostring(counts[0]))
assert((counts[1] or 0) > 20, "water seller count implausible: " .. tostring(counts[1]))
for bit = 2, 7 do assert((counts[bit] or 0) > 0, "no shipped vendor sells diet bit " .. bit) end
local items, hs = 0, 0
for id, m in pairs(ns3.SupplyItems) do
    items = items + 1
    assert(type(id) == "number" and m % 1 == 0 and m >= 1 and m < 512, "bad supply item " .. tostring(id))
    if math.floor(m / 256) % 2 == 1 then hs = hs + 1 end
end
assert(items > 200, "suspiciously few supply items: " .. items)
assert(hs == 15, "expected 15 healthstone items, got " .. hs)
assert(ns3.SupplyItems[117] == 5 and ns3.SupplyItems[159] == 2, "Tough Jerky (food, Meat) and Refreshing Spring Water (drink) expected")

-- Pet families: id -> diet bits 4-128; the common hunter pets are present.
local fams = 0
for id, m in pairs(ns3.PetFamilies) do
    fams = fams + 1
    assert(type(id) == "number" and m % 4 == 0 and m >= 4 and m < 256, "bad pet family " .. tostring(id))
end
assert(fams >= 15, "suspiciously few pet families: " .. fams)
assert(ns3.PetFamilies[4] == 252 and ns3.PetFamilies[1] == 4, "Bear (all diets) and Wolf (Meat) expected")

-- Shipped auctioneers: {npcId, name, uiMapID, mx, my, faction}, ascending ids, and a plausible count.
local function validateAH(list)
    if type(list) ~= "table" or #list == 0 then return "empty or missing auctioneers" end
    local prev = 0
    for i, v in ipairs(list) do
        local where = "auctioneer " .. i
        if type(v[1]) ~= "number" or v[1] <= prev then return where .. ": id not ascending/unique" end
        prev = v[1]
        if type(v[2]) ~= "string" or v[2] == "" then return where .. ": bad name" end
        if type(v[3]) ~= "number" or v[3] <= 0 or v[3] % 1 ~= 0 then return where .. ": bad uiMapID" end
        if type(v[4]) ~= "number" or v[4] < 0 or v[4] > 1 then return where .. ": mx out of range" end
        if type(v[5]) ~= "number" or v[5] < 0 or v[5] > 1 then return where .. ": my out of range" end
        if v[6] ~= 0 and v[6] ~= 1 and v[6] ~= 2 then return where .. ": bad faction" end
        if #v ~= 6 then return where .. ": expected 6 fields, got " .. #v end
    end
end
local ah = ns.ShippedAuctioneers
assert(validateAH(ah) == nil, validateAH(ah))
assert(#ah >= 20 and #ah <= 60, "auctioneer count implausible: " .. #ah)
local f = { 0, 0, 0 }
for _, v in ipairs(ah) do f[v[6] + 1] = f[v[6] + 1] + 1 end
assert(f[1] > 0 and f[2] > 0 and f[3] > 0, "auctioneers missing a faction group")
assert(validateAH({ { 1, "A", 1429, 0.5, 0.5, 1 } }) == nil, "auctioneer baseline must pass")
assert(validateAH({ { 1, "A", 1429, 1.5, 0.5, 1 } }) ~= nil, "auctioneer mx range undetected")
assert(validateAH({ { 1, "A", 1429, 0.5, 0.5, 3 } }) ~= nil, "auctioneer faction undetected")
assert(validateAH({ { 1, "A", 1429, 0.5, 0.5, 1 }, { 1, "B", 1429, 0.5, 0.5, 1 } }) ~= nil, "auctioneer duplicate undetected")
assert(validateAH({}) ~= nil, "empty auctioneers undetected")

-- The check must actually fail on bad data.
local function bad(mut)
    local copy = { { 1, "A", 1429, 0.5, 0.5, 1, false, 0, 0, 0 }, { 2, "B", 1429, 0.5, 0.5, 1, true, 3, 5, 17 } }
    mut(copy)
    return validate(copy) ~= nil
end
assert(validate({ { 1, "A", 1429, 0.5, 0.5, 1, false, 0, 0, 0 } }) == nil, "baseline must pass")
assert(bad(function(c) c[2][4] = 1.5 end), "mx out of range undetected")
assert(bad(function(c) c[2][5] = -0.1 end), "my out of range undetected")
assert(bad(function(c) c[2][2] = "" end), "empty name undetected")
assert(bad(function(c) c[2][1] = 1 end), "duplicate id undetected")
assert(bad(function(c) c[2][6] = 3 end), "bad faction undetected")
assert(bad(function(c) c[2][7] = "yes" end), "non-boolean repair undetected")
assert(bad(function(c) c[2][8] = 4 end), "bad ammo code undetected")
assert(bad(function(c) c[2][8] = nil end), "missing ammo code undetected")
assert(bad(function(c) c[2][9] = nil end), "missing reagent mask undetected")
assert(bad(function(c) c[2][9] = -1 end), "negative reagent mask undetected")
assert(bad(function(c) c[2][9] = 1.5 end), "fractional reagent mask undetected")
assert(bad(function(c) c[2][10] = nil end), "missing supply mask undetected")
assert(bad(function(c) c[2][10] = 256 end), "supply mask above 255 undetected")
assert(bad(function(c) c[2][10] = -1 end), "negative supply mask undetected")
assert(bad(function(c) c[2][10] = 1.5 end), "fractional supply mask undetected")
assert(validate({}) ~= nil, "empty list undetected")

print(("ok (%d vendors, %d repair, %d arrow sellers, %d bullet sellers)"):format(#list, repairs, arrows, bullets))
