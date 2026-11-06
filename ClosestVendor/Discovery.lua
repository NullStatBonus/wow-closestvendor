-- Pure learned-vendor store: no WoW globals.
-- Vendor record: {npcId, name, uiMapID, mx, my, faction (0 both, 1 Alliance, 2 Horde), repair, ammo (0-3)}
local _, ns = ...

local D = {}
ns.Discovery = D

-- learned: table keyed by npc id (the SavedVariables table). Returns true if stored/changed.
function D.Record(learned, rec)
    local id = rec and rec[1]
    if type(id) ~= "number" or id <= 0 then return false end
    local new = { rec[1], rec[2], rec[3], rec[4], rec[5], rec[6], rec[7], rec[8] or 0 }
    local old = learned[id]
    if old then
        local same = true
        for i = 1, 8 do if old[i] ~= new[i] then same = false break end end
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
    if old then
        for i = 1, 6 do if old[i] ~= new[i] then changed = true end end
        if not changed then return false end
    end
    learned[id] = new
    return true
end

-- Shipped list plus learned records; a learned record replaces a shipped one with the same id.
-- Does not modify its inputs.
function D.Merge(shipped, learned)
    local out = {}
    for i = 1, #shipped do
        local v = shipped[i]
        if not learned[v[1]] then out[#out + 1] = v end
    end
    for _, v in pairs(learned) do out[#out + 1] = v end
    return out
end
