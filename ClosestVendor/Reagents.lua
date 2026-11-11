-- Class reagents: pure data and logic, no WoW globals.
-- Item ids, and the spells that use them, were checked against the Classic Era and WoW Forever
-- SpellReagents tables. `bit` numbers are permanent (never reused): they index the reagent mask
-- stored in each vendor record. tools/build_vendors.py reads this file, so keep one item per line
-- in the form  { id = N, bit = N, class = "X", name = "...", spells = {..}, unless = {..} }.
--   spells: the reagent is watched when the player knows any of these spells.
--   unless: ...and none of these (a higher rank that uses a different reagent).
local _, ns = ...

local R = {}
ns.Reagents = R

R.ITEMS = {
    { id = 17020, bit = 0, class = "MAGE", name = "Arcane Powder", spells = { 23028 }, unless = {} },
    { id = 17031, bit = 1, class = "MAGE", name = "Rune of Teleportation", spells = { 3561, 3562, 3563, 3565, 3566, 3567 }, unless = {} },
    { id = 17032, bit = 2, class = "MAGE", name = "Rune of Portals", spells = { 10059, 11416, 11417, 11418, 11419, 11420 }, unless = {} },
    { id = 5140, bit = 3, class = "ROGUE", name = "Flash Powder", spells = { 1856, 1857 }, unless = {} },
    { id = 17028, bit = 4, class = "PRIEST", name = "Holy Candle", spells = { 21562 }, unless = { 21564 } },
    { id = 17029, bit = 5, class = "PRIEST", name = "Sacred Candle", spells = { 21564, 27681, 27683 }, unless = {} },
    { id = 21177, bit = 6, class = "PALADIN", name = "Symbol of Kings", spells = { 25782, 25890, 25894, 25895, 25898, 25899, 25916, 25918, 25919, 25920 }, unless = {} },
    { id = 17033, bit = 7, class = "PALADIN", name = "Symbol of Divinity", spells = { 19752 }, unless = {} },
    { id = 17030, bit = 8, class = "SHAMAN", name = "Ankh", spells = { 20608, 21169, 27740 }, unless = {} },
    { id = 17034, bit = 9, class = "DRUID", name = "Maple Seed", spells = { 20484 }, unless = { 20739, 20742, 20747, 20748 } },
    { id = 17035, bit = 10, class = "DRUID", name = "Stranglethorn Seed", spells = { 20739 }, unless = { 20742, 20747, 20748 } },
    { id = 17036, bit = 11, class = "DRUID", name = "Ashwood Seed", spells = { 20742 }, unless = { 20747, 20748 } },
    { id = 17037, bit = 12, class = "DRUID", name = "Hornbeam Seed", spells = { 20747 }, unless = { 20748 } },
    { id = 17038, bit = 13, class = "DRUID", name = "Ironwood Seed", spells = { 20748 }, unless = {} },
    { id = 17021, bit = 14, class = "DRUID", name = "Wild Berries", spells = { 21849 }, unless = { 21850 } },
    { id = 17026, bit = 15, class = "DRUID", name = "Wild Thornroot", spells = { 21850 }, unless = {} },
}

local byId = {}
for _, item in ipairs(R.ITEMS) do byId[item.id] = item end

-- Item by id, or nil.
function R.ById(id) return byId[id] end

-- The reagents of a class token ("MAGE"), in table order; empty for a class without any.
function R.ForClass(class)
    local out = {}
    for _, item in ipairs(R.ITEMS) do
        if item.class == class then out[#out + 1] = item end
    end
    return out
end

-- The class reagents to watch. knows(spellId) -> true, false or nil (unknown): unknown never
-- counts as known. off is the set of item ids the player switched off.
function R.Watched(class, knows, off)
    local out = {}
    for _, item in ipairs(R.ForClass(class)) do
        if not (off and off[item.id]) then
            local any, blocked = false, false
            for _, s in ipairs(item.spells) do if knows(s) == true then any = true break end end
            for _, s in ipairs(item.unless) do if knows(s) == true then blocked = true break end end
            if any and not blocked then out[#out + 1] = item end
        end
    end
    return out
end

-- Items from watched that are at or below threshold: { { item, count }, ... } in table order.
-- count(itemId) -> number or nil; an unreadable count is never low.
function R.Low(watched, count, threshold)
    local out = {}
    for _, item in ipairs(watched) do
        local n = count(item.id)
        if n and n <= threshold then out[#out + 1] = { item = item, count = n } end
    end
    return out
end

-- A class reagent by name (case-insensitive, extra spaces ignored) or by item id; nil if none.
function R.Find(class, text)
    local want = tostring(text or ""):lower():gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    for _, item in ipairs(R.ForClass(class)) do
        if item.name:lower() == want or tostring(item.id) == want then return item end
    end
end

-- Reagent mask: bit n set when the item with that bit is sold. Plain arithmetic, no bit library.
function R.Mask(ids)
    local mask = 0
    for id in pairs(ids) do
        local item = byId[id]
        if item then mask = mask + 2 ^ item.bit end
    end
    return mask
end

-- True when the mask has the bit of item set.
function R.Has(mask, item)
    return math.floor((mask or 0) / 2 ^ item.bit) % 2 == 1
end
