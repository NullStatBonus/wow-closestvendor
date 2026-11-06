-- Sanity check of the generated vendor data. validate() returns an error string or nil.
local function validate(list)
    if type(list) ~= "table" or #list == 0 then return "empty or missing data" end
    local prev = 0
    for i, v in ipairs(list) do
        local id, name, map, mx, my, fac, rep, ammo = v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8]
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
        if #v ~= 8 then return where .. ": expected 8 fields, got " .. #v end
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

-- The check must actually fail on bad data.
local function bad(mut)
    local copy = { { 1, "A", 1429, 0.5, 0.5, 1, false, 0 }, { 2, "B", 1429, 0.5, 0.5, 1, true, 3 } }
    mut(copy)
    return validate(copy) ~= nil
end
assert(validate({ { 1, "A", 1429, 0.5, 0.5, 1, false, 0 } }) == nil, "baseline must pass")
assert(bad(function(c) c[2][4] = 1.5 end), "mx out of range undetected")
assert(bad(function(c) c[2][5] = -0.1 end), "my out of range undetected")
assert(bad(function(c) c[2][2] = "" end), "empty name undetected")
assert(bad(function(c) c[2][1] = 1 end), "duplicate id undetected")
assert(bad(function(c) c[2][6] = 3 end), "bad faction undetected")
assert(bad(function(c) c[2][7] = "yes" end), "non-boolean repair undetected")
assert(bad(function(c) c[2][8] = 4 end), "bad ammo code undetected")
assert(bad(function(c) c[2][8] = nil end), "missing ammo code undetected")
assert(validate({}) ~= nil, "empty list undetected")

print(("ok (%d vendors, %d repair, %d arrow sellers, %d bullet sellers)"):format(#list, repairs, arrows, bullets))
