-- Pure nearest-vendor search: no WoW globals.
-- Vendor record (array, for low memory): the on-disk shape plus world coordinates
--   { npcId, name, uiMapID, mx, my, faction, repair, ammo, wx, wy }
-- faction: 0 = both, 1 = Alliance, 2 = Horde. repair: true if it can repair.
-- ammo: 0 none, 1 arrows, 2 bullets, 3 both.
local _, ns = ...

local S = {}
ns.Search = S

-- need: nil (any vendor), "repair", "arrow" or "bullet".
local function eligible(v, need)
    if need == nil then return true end
    if need == "repair" then return v[7] and true or false end
    local code = v[8] or 0
    if need == "arrow" then return code == 1 or code == 3 end
    return code == 2 or code == 3
end

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

-- Trainer record: { npcId, name, uiMapID, mx, my, faction, trades (set of profession names), wx, wy }.
-- Returns the nearest trainer that teaches trade for the player's faction, or nil; with mapId,
-- also the nearest one on that map, as Nearest does.
function S.NearestTrainer(bucket, px, py, trade, playerFaction, mapId)
    local best, bestD, onMap, onMapD
    for i = 1, #bucket do
        local v = bucket[i]
        local fac = v[6]
        if (fac == 0 or fac == playerFaction) and v[7][trade] then
            local dx, dy = v[8] - px, v[9] - py
            local d = dx * dx + dy * dy
            if not bestD or d < bestD then best, bestD = v, d end
            if mapId and v[3] == mapId and (not onMapD or d < onMapD) then onMap, onMapD = v, d end
        end
    end
    return best, onMap
end
