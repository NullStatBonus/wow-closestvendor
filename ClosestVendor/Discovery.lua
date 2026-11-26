-- Pure learned-vendor store: no WoW globals.
-- Vendor record: {npcId, name, uiMapID, mx, my, faction (0 both, 1 Alliance, 2 Horde), repair, ammo (0-3),
--   reagents (bitmask, see Reagents.lua), supplies (bits 0-7, see Supplies.lua)}
local _, ns = ...

local D = {}
ns.Discovery = D

-- A repeat visit this close (a fraction of the map, on both axes) to the saved position keeps it: the
-- player stands a step to the side, not a moved npc. A few yards in a city.
D.NEAR = 0.005

-- On the same map and within D.NEAR of old's position, new takes old's position (index 3 map, 4 x, 5 y).
local function keepNear(old, new)
    if not old or old[3] ~= new[3] then return end
    if type(old[4]) ~= "number" or type(old[5]) ~= "number" or type(new[4]) ~= "number" or type(new[5]) ~= "number" then return end
    if math.abs(old[4] - new[4]) <= D.NEAR and math.abs(old[5] - new[5]) <= D.NEAR then new[4], new[5] = old[4], old[5] end
end

-- learned: table keyed by npc id (the SavedVariables table). Returns true if stored/changed.
function D.Record(learned, rec)
    local id = rec and rec[1]
    if type(id) ~= "number" or id <= 0 then return false end
    local new = { rec[1], rec[2], rec[3], rec[4], rec[5], rec[6], rec[7], rec[8] or 0, rec[9] or 0, rec[10] or 0 }
    local old = learned[id]
    keepNear(old, new)
    if old then
        local same = true
        for i = 1, 10 do if (old[i] or (i >= 8 and 0)) ~= new[i] then same = false break end end
        if same then return false end
    end
    learned[id] = new
    return true
end

-- Profession trainers: learned[npcId] = { npcId, name, uiMapID, mx, my, faction, trades },
-- trades being a set of profession names. rec is { npcId, name, uiMapID, mx, my, faction };
-- trades is a list of names. Returns true if anything was stored or changed.
function D.RecordTrainer(learned, rec, trades)
    local id = rec and rec[1]
    if type(id) ~= "number" or id <= 0 or type(trades) ~= "table" or #trades == 0 then return false end
    local old = learned[id]
    local set, changed = {}, false
    if old then for name in pairs(old[7]) do set[name] = true end end
    for _, name in ipairs(trades) do
        if not set[name] then set[name] = true; changed = true end
    end
    local new = { rec[1], rec[2], rec[3], rec[4], rec[5], rec[6], set }
    keepNear(old, new)
    if old then
        for i = 1, 6 do if old[i] ~= new[i] then changed = true end end
        if not changed then return false end
    end
    learned[id] = new
    return true
end

-- Auctioneers: learned[npcId] = { npcId, name, uiMapID, mx, my, faction }. A learned record replaces
-- the shipped one with the same id (see Merge). Returns true if stored or changed.
function D.RecordAuctioneer(learned, rec)
    local id = rec and rec[1]
    if type(id) ~= "number" or id <= 0 then return false end
    local new = { rec[1], rec[2], rec[3], rec[4], rec[5], rec[6] }
    local old = learned[id]
    keepNear(old, new)
    if old then
        local same = true
        for i = 1, 6 do if old[i] ~= new[i] then same = false break end end
        if same then return false end
    end
    learned[id] = new
    return true
end

-- Shipped list plus learned records; a learned record replaces a shipped one with the same id.
-- Does not modify its inputs.
-- A learned record saved before supplies existed has no supply field: it takes the shipped one.
function D.Merge(shipped, learned)
    local out, shippedById = {}, {}
    for i = 1, #shipped do
        local v = shipped[i]
        shippedById[v[1]] = v
        if not learned[v[1]] then out[#out + 1] = v end
    end
    for id, v in pairs(learned) do
        local s = shippedById[id]
        if s and v[10] == nil and s[10] then
            local copy = {}
            for i = 1, 9 do copy[i] = v[i] end
            copy[10] = s[10]
            v = copy
        end
        out[#out + 1] = v
    end
    return out
end

-- A learned position this far (a fraction of the map) from an external one means the vendor moved.
D.MOVED = 0.03

-- True when the learned record v replaces the external record e's position: another map, or more than
-- D.MOVED away on either axis. A learned record with no position never does.
function D.Moved(v, e)
    if not (type(v[4]) == "number" and type(v[5]) == "number") then return false end
    if v[3] ~= e[3] then return true end
    return math.abs(v[4] - e[4]) > D.MOVED or math.abs(v[5] - e[5]) > D.MOVED
end

-- The search pool from the shipped list, an external list (same record shape) and the learned table.
-- One entry per npc id. Without an external record for an id this is Merge. With one: the external
-- record replaces the shipped one; a learned record supplies faction, repair, ammo, reagents and
-- supplies (Merge takes the external supplies when it has none), and its position only when it is on another map
-- or more than D.MOVED away from the external position. Does not modify its inputs.
function D.Pool(shipped, external, learned)
    local ext = {}
    for i = 1, #external do ext[external[i][1]] = external[i] end
    local base = {}
    for i = 1, #shipped do
        local v = shipped[i]
        if not ext[v[1]] then base[#base + 1] = v end
    end
    for i = 1, #external do base[#base + 1] = external[i] end
    local rest = {}
    for id, v in pairs(learned) do
        local e = ext[id]
        if not e then
            rest[id] = v
        else
            local moved = D.Moved(v, e)
            local function pick(i, default) if v[i] ~= nil then return v[i] end return default end
            local r = { id, v[2] or e[2], e[3], e[4], e[5], pick(6, e[6]), pick(7, e[7]), pick(8, e[8] or 0), pick(9, e[9] or 0), v[10] }
            if moved then r[3], r[4], r[5] = v[3], v[4], v[5] end
            rest[id] = r
        end
    end
    return D.Merge(base, rest)
end

-- The vendors this character can trade with, from a search pool. standing[npcId] is what this
-- character has seen: true (Neutral or better), false (Unfriendly or Hostile), nil (never seen).
-- known is the set of npc ids from the shipped and external lists. Dropped: every vendor seen as
-- Unfriendly or Hostile, and a learned-only vendor of no side (faction 0, such as a reputation
-- quartermaster another character taught) that this character has not seen as Neutral or better.
-- Does not modify its inputs.
function D.Tradable(pool, known, standing)
    local out = {}
    for i = 1, #pool do
        local v = pool[i]
        local seen = standing[v[1]]
        if seen ~= false and (seen == true or v[6] ~= 0 or known[v[1]]) then out[#out + 1] = v end
    end
    return out
end
