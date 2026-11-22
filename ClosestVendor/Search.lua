-- Pure nearest-vendor search: no WoW globals.
-- Vendor record (array, for low memory): the on-disk shape plus world coordinates
--   { npcId, name, uiMapID, mx, my, faction, repair, ammo, wx, wy, reagents, supplies }
-- faction: 0 = both, 1 = Alliance, 2 = Horde. repair: true if it can repair.
-- ammo: 0 none, 1 arrows, 2 bullets, 3 both. reagents (index 11): bitmask, see Reagents.lua; a
-- record without it sells no reagents. supplies (index 12): bits 0-7, see Supplies.lua; absent sells none.
local _, ns = ...

local S = {}
ns.Search = S

-- need: nil (any vendor), "repair", "arrow", "bullet", or { reagent = item } (an entry of the
-- Reagents table) for a vendor that sells that reagent, or { supply = bits } for a vendor that sells
-- any of those supply bits (food, water, pet diets), or "auction" (any record: the caller passes
-- an auctioneer bucket, same record shape).
local function eligible(v, need)
    if need == nil then return true end
    if type(need) == "table" then
        if need.supply then return ns.Supplies.Sells(v[12], need.supply) end
        return ns.Reagents.Has(v[11], need.reagent)
    end
    if need == "auction" then return true end
    if need == "repair" then return v[7] and true or false end
    local code = v[8] or 0
    if need == "arrow" then return code == 1 or code == 3 end
    return code == 2 or code == 3
end

-- True when record v sells what need asks for (need as above). Faction is not checked.
S.Fits = eligible

-- bucket: list of records on the player's continent. Returns the nearest eligible record or
-- nil. Squared distance only; nothing is converted for non-winners. With mapId, also returns the
-- nearest eligible record on that map (the same record when it is the overall nearest).
function S.Nearest(bucket, px, py, need, playerFaction, mapId)
    local best, bestD, onMap, onMapD
    for i = 1, #bucket do
        local v = bucket[i]
        local fac = v[6]
        if (fac == 0 or fac == playerFaction) and eligible(v, need) then
            local dx, dy = v[9] - px, v[10] - py
            local d = dx * dx + dy * dy
            if not bestD or d < bestD then best, bestD = v, d end
            if mapId and v[3] == mapId and (not onMapD or d < onMapD) then onMap, onMapD = v, d end
        end
    end
    return best, onMap
end

-- Nearest from a place instead of from bare coordinates: at is { continent, x, y, map } (world x,y;
-- map may be nil), the player's position or an anchor such as the hearthstone point. buckets is
-- { [continentId] = bucket }. Returns what Nearest returns; nothing for an unknown continent.
function S.NearestFrom(buckets, at, need, playerFaction)
    return S.Nearest(buckets[at.continent] or {}, at.x, at.y, need, playerFaction, at.map)
end

-- Trainer record: { npcId, name, uiMapID, mx, my, faction, trades, wx, wy }; trades maps a profession
-- name to the highest tier taught (a number) or true when not known (see Professions.Teaches).
-- Returns the nearest trainer that teaches trade, and tier need when given, for the player's faction,
-- or nil; with mapId, also the nearest one on that map, as Nearest does.
function S.NearestTrainer(bucket, px, py, trade, playerFaction, mapId, need)
    local best, bestD, onMap, onMapD
    for i = 1, #bucket do
        local v = bucket[i]
        local fac = v[6]
        if (fac == 0 or fac == playerFaction) and ns.Professions.Teaches(v[7][trade], need) then
            local dx, dy = v[8] - px, v[9] - py
            local d = dx * dx + dy * dy
            if not bestD or d < bestD then best, bestD = v, d end
            if mapId and v[3] == mapId and (not onMapD or d < onMapD) then onMap, onMapD = v, d end
        end
    end
    return best, onMap
end

-- Keep the n nearest records in list (nearest first, with their squared distances in ds), one per
-- npcId (v[1]): a record already listed is replaced only by a closer one. Insertion into a list of
-- size n, so the whole bucket is never sorted.
local function keepNearest(list, ds, v, d, n)
    local id = v[1]
    for i = 1, #list do
        if list[i][1] == id then
            if d >= ds[i] then return end
            table.remove(list, i)
            table.remove(ds, i)
            break
        end
    end
    if #list >= n and d >= ds[#list] then return end
    local at = #list + 1
    while at > 1 and ds[at - 1] > d do at = at - 1 end
    table.insert(list, at, v)
    table.insert(ds, at, d)
    if #list > n then list[#list], ds[#ds] = nil, nil end
end

-- Up to n eligible records (as Nearest), nearest first, at most one per npc (its nearest place).
-- Used to offer alternate sellers.
function S.Several(bucket, px, py, need, playerFaction, n)
    local list, ds = {}, {}
    if n < 1 then return list end
    for i = 1, #bucket do
        local v = bucket[i]
        local fac = v[6]
        if (fac == 0 or fac == playerFaction) and eligible(v, need) then
            local dx, dy = v[9] - px, v[10] - py
            keepNearest(list, ds, v, dx * dx + dy * dy, n)
        end
    end
    return list
end

-- The same for trainers (as NearestTrainer, without the map result): up to n, nearest first, one per npc.
function S.SeveralTrainers(bucket, px, py, trade, playerFaction, n, need)
    local list, ds = {}, {}
    if n < 1 then return list end
    for i = 1, #bucket do
        local v = bucket[i]
        local fac = v[6]
        if (fac == 0 or fac == playerFaction) and ns.Professions.Teaches(v[7][trade], need) then
            local dx, dy = v[8] - px, v[9] - py
            keepNearest(list, ds, v, dx * dx + dy * dy, n)
        end
    end
    return list
end

-- Items an on-demand search can find: the shipped food, drink and pet-food items, and the vendor-sold
-- reagents of class. text is an item link (its id decides) or part of an item name, any letter case.
-- nameOf(id) is the game's name for an item or nil when it is not cached yet; an item with no name
-- matches only by link. Returns a list sorted by name, each { id, name, kind = "supply", key, bits }
-- (key "food", "water" or "pet"; bits the Supplies bits to look for) or { id, name, kind = "reagent",
-- item }. Healthstones are skipped: no vendor record carries them.
function S.FindItems(text, class, nameOf)
    text = tostring(text or "")
    local linked = tonumber(text:match("item:(%d+)"))
    local want = ns.Reagents.Lower(text):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    local out = {}
    local function consider(id, make)
        if linked and id ~= linked then return end -- a link needs one name, not the whole catalog
        local name = nameOf and nameOf(id)
        local hit
        if linked then hit = true
        else hit = want ~= "" and name and ns.Reagents.Lower(name):find(want, 1, true) ~= nil end
        if not hit then return end
        local m = make()
        m.id, m.name = id, name or (m.item and m.item.name) or tostring(id)
        out[#out + 1] = m
    end
    for id, mask in pairs(ns.SupplyItems or {}) do
        local bits = mask % 256
        if bits > 0 then
            local human = bits % 4
            consider(id, function()
                if human > 0 then return { kind = "supply", key = human == 2 and "water" or "food", bits = human } end
                return { kind = "supply", key = "pet", bits = bits }
            end)
        end
    end
    for _, item in ipairs(ns.Reagents.ForClass(class)) do
        consider(item.id, function() return { kind = "reagent", item = item } end)
    end
    table.sort(out, function(a, b) if a.name ~= b.name then return a.name < b.name end return a.id < b.id end)
    return out
end
