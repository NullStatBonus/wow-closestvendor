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
local PRIORITY = { sell = 1, ammo = 2, repair = 3 }
local ORDER = { "repair", "ammo", "sell" }

-- cfg: { bagThreshold, durThreshold, ammoThreshold, bagEnabled, durEnabled, ammoEnabled }
-- (read live, so edits apply at once).
-- Update(free, durPct, inCombat, ammo): free is the free bag slots, or nil if unknown;
-- ammo is a count, or nil when ammo is not monitored.
-- Returns nil | { "go", "sell"|"ammo"|"repair" } | { "clear" }.
function T.New(cfg)
    local handled = { sell = false, ammo = false, repair = false }
    local active
    local self = {}

    function self.Update(free, durPct, inCombat, ammo)
        -- sell is true / false, or nil when the bag count is unknown (neither asks nor withdraws).
        local sell
        if not cfg.bagEnabled then sell = false elseif free ~= nil then sell = free <= cfg.bagThreshold end
        local now = {
            sell = sell,
            repair = cfg.durEnabled and durPct ~= nil and durPct < cfg.durThreshold,
            ammo = cfg.ammoEnabled and ammo ~= nil and ammo <= cfg.ammoThreshold,
        }
        -- A cleared condition may fire again later.
        for k in pairs(handled) do if now[k] == false then handled[k] = false end end

        if active and now[active] == false then
            active = nil
            return { "clear" }
        end

        if inCombat then return nil end

        local want
        for _, k in ipairs(ORDER) do
            if now[k] and not handled[k] then want = k break end
        end
        if not want then return nil end
        -- Never replace an equal or higher priority request that is still open or active.
        if active and PRIORITY[want] <= PRIORITY[active] then return nil end

        handled[want] = true
        -- A repair or ammo trip also covers selling.
        if want ~= "sell" then handled.sell = now.sell == true end
        active = want
        return { "go", want }
    end

    -- The vendor request that is open or active ("sell"/"ammo"/"repair"), or nil.
    function self.Active() return active end

    function self.OnMerchantShow()
        if active then
            active = nil
            return { "clear" }
        end
    end

    return self
end
