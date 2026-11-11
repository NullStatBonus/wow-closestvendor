-- Pure trigger logic: no WoW globals. WoW values are passed in.
local _, ns = ...

local T = {}
ns.Triggers = T

-- Free slots across bags [first..last], counting only general-purpose bags (bagFamily == 0).
-- getFree(bag) -> numFreeSlots, bagFamily  (nil when the bag cannot be read).
-- Returns nil, not 0, when no bag could be read: "unknown" must never look like "full".
function T.FreeSlots(getFree, first, last)
    local total, readable = 0, false
    for bag = first, last do
        local free, family = getFree(bag)
        if free then
            readable = true
            if (family or 0) == 0 then total = total + free end
        end
    end
    if readable then return total end
end

-- Lowest durability percent over slots, ignoring items without durability. nil if none.
-- getDur(slot) -> cur, max  (GetInventoryItemDurability)
function T.LowestDurability(getDur, slots)
    local lowest
    for _, slot in ipairs(slots) do
        local cur, max = getDur(slot)
        if cur and max and max > 0 then
            local pct = cur / max * 100
            if not lowest or pct < lowest then lowest = pct end
        end
    end
    return lowest
end

-- Ammo kind a ranged weapon needs: bows and crossbows use arrows, guns use bullets.
-- Thrown weapons, wands and everything else are not monitored (nil).
-- classID/subClassID come from GetItemInfoInstant: weapons are class 2 (bow 2, gun 3, crossbow 18).
function T.AmmoNeeded(classID, subClassID)
    if classID ~= 2 then return nil end
    if subClassID == 2 or subClassID == 18 then return "arrow" end
    if subClassID == 3 then return "bullet" end
end

-- Count to watch: how many of the equipped ammo the player has, or 0 if the ammo slot
-- is empty or holds the wrong kind. Ammo items are class 6 (arrow 2, bullet 3).
function T.AmmoCount(needed, ammoClassID, ammoSubClassID, total)
    local kind
    if ammoClassID == 6 and ammoSubClassID == 2 then kind = "arrow"
    elseif ammoClassID == 6 and ammoSubClassID == 3 then kind = "bullet" end
    if not needed or kind ~= needed then return 0 end
    return total or 0
end

-- Higher number wins: a lower one never replaces an open or active higher one.
local PRIORITY = { sell = 1, reagent = 2, ammo = 3, repair = 4 }
local ORDER = { "repair", "ammo", "reagent", "sell" }

-- cfg: { bagThreshold, durThreshold, ammoThreshold, bagEnabled, durEnabled, ammoEnabled }
-- (read live, so edits apply at once). ammoEnabled is also the master switch for reagents.
-- Update(free, durPct, inCombat, ammo, reagents): free is the free bag slots, or nil if unknown;
-- ammo is a count, or nil when ammo is not monitored; reagents is the list of item ids of the
-- watched reagents that are low (nil or empty: none).
-- Returns nil | { "go", "sell"|"ammo"|"repair" } | { "go", "reagent", itemId } | { "clear" }.
function T.New(cfg)
    local handled = { sell = false, ammo = false, repair = false }
    local handledReagent = {} -- item id -> true while that reagent stays low
    local active, activeReagent
    local self = {}

    function self.Update(free, durPct, inCombat, ammo, reagents)
        -- sell is true / false, or nil when the bag count is unknown (neither asks nor withdraws).
        local sell
        if not cfg.bagEnabled then sell = false elseif free ~= nil then sell = free <= cfg.bagThreshold end
        local low = {}
        if cfg.ammoEnabled then for _, id in ipairs(reagents or {}) do low[id] = true end end
        local now = {
            sell = sell,
            repair = cfg.durEnabled and durPct ~= nil and durPct < cfg.durThreshold,
            ammo = cfg.ammoEnabled and ammo ~= nil and ammo <= cfg.ammoThreshold,
        }
        -- A cleared condition may fire again later.
        for k in pairs(handled) do if now[k] == false then handled[k] = false end end
        for id in pairs(handledReagent) do if not low[id] then handledReagent[id] = nil end end

        if active == "reagent" and not low[activeReagent] then
            active, activeReagent = nil, nil
            return { "clear" }
        end
        if active and active ~= "reagent" and now[active] == false then
            active = nil
            return { "clear" }
        end

        if inCombat then return nil end

        local want, wantId
        for _, k in ipairs(ORDER) do
            if k == "reagent" then
                for _, id in ipairs(reagents or {}) do
                    if low[id] and not handledReagent[id] then want, wantId = k, id break end
                end
            elseif now[k] and not handled[k] then
                want = k
            end
            if want then break end
        end
        if not want then return nil end
        -- Never replace an equal or higher priority request that is still open or active.
        if active and PRIORITY[want] <= PRIORITY[active] then return nil end

        -- A reagent request that a higher one replaces is asked again once that one is done.
        if active == "reagent" then handledReagent[activeReagent] = nil end
        if want == "reagent" then handledReagent[wantId] = true else handled[want] = true end
        -- A repair or ammo trip also covers selling.
        if want == "repair" or want == "ammo" then handled.sell = now.sell == true end
        active, activeReagent = want, wantId
        if want == "reagent" then return { "go", "reagent", wantId } end
        return { "go", want }
    end

    -- The vendor request that is open or active ("sell"/"ammo"/"reagent"/"repair"), or nil.
    function self.Active() return active end

    function self.OnMerchantShow()
        if active then
            active, activeReagent = nil, nil
            return { "clear" }
        end
    end

    return self
end
