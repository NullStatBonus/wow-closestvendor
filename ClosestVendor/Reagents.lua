-- Class reagents: pure data and logic, no WoW globals.
-- Item ids, and the spells that use them, were checked against the Classic Era and WoW Forever
-- SpellReagents tables. `bit` numbers are permanent (never reused): they index the reagent mask
-- stored in each vendor record. tools/build_vendors.py reads this file, so keep one item per line
-- in the form  { id = N, bit = N, class = "X", name = "...", spells = {..}, unless = {..} }.
--   spells: the reagent is watched when the player knows any of these spells.
--   unless: ...and none of these (a higher rank that uses a different reagent).
-- Display-only entries (`vendor = false`, no bit) are tracked for the status window but no vendor
-- sells them: they are never watched, never in a vendor record, and not seen by ForClass, Find or
-- ById. They are checked against the same tables (SpellReagents for the spells that consume
-- Soul Shard and Blinding Powder, SpellEffect for the spells that create the conjured items).
-- `ids` lists every item id whose counts are summed (see R.ItemIds); `id` is the first of them.
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
    { id = 6265, vendor = false, class = "WARLOCK", name = "Soul Shards", spells = { 5699, 6201, 6202, 11729, 11730 }, unless = {} },
    { id = 5530, vendor = false, class = "ROGUE", name = "Blinding Powder", spells = { 2094 }, unless = {} },
    { id = 5349, vendor = false, class = "MAGE", name = "Conjured Food", spells = { 587, 597, 990, 6129, 10144, 10145, 28612 }, unless = {},
      ids = { 5349, 1113, 1114, 1487, 8075, 8076, 22895 } },
    { id = 5350, vendor = false, class = "MAGE", name = "Conjured Water", spells = { 5504, 5505, 5506, 6127, 10138, 10139, 10140 }, unless = {},
      ids = { 5350, 2288, 2136, 3772, 8077, 8078, 8079 } },
}

local byId = {}
for _, item in ipairs(R.ITEMS) do
    if item.vendor ~= false then byId[item.id] = item end
end

-- Item by id, or nil.
function R.ById(id) return byId[id] end

-- The vendor-sold reagents of a class token ("MAGE"), in table order; empty for a class without any.
function R.ForClass(class)
    local out = {}
    for _, item in ipairs(R.ITEMS) do
        if item.class == class and item.vendor ~= false then out[#out + 1] = item end
    end
    return out
end

-- The display-only items of a class token, in table order.
function R.DisplayOnly(class)
    local out = {}
    for _, item in ipairs(R.ITEMS) do
        if item.class == class and item.vendor == false then out[#out + 1] = item end
    end
    return out
end

-- The item ids to count for an item (summed): its `ids` list, or just its id.
function R.ItemIds(item) return item.ids or { item.id } end

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

-- Buying reagents at a merchant -----------------------------------------------------------------

-- What to buy so the player carries `target` of each reagent in `want`, never more.
-- want: { { item = reagent, count = carried (bags included) }, ... }, in buying order.
-- offers: the merchant's class reagents { index, id, name, price, batch, stock } (price per batch).
-- slots: every slot of the general bags: false when empty, else { id, count }.
-- stack(id) -> how many fit in one bag slot, or nil. money: copper.
-- Returns lines { { offer, purchases, items, cost } } (only those with a purchase), the total cost
-- and why it fell short: "money", "bags" or nil. Returns nil when slots or money are unknown. A
-- reagent whose count, stack size or price is unknown is skipped. Empty slots are shared: what one
-- reagent fills is gone for the next.
function R.BuyPlan(want, offers, slots, stack, money, target)
    if not (slots and money and target) then return end
    local empty = 0
    for _, s in ipairs(slots) do if not s then empty = empty + 1 end end
    local sold = {}
    for _, o in ipairs(offers) do if not sold[o.id] then sold[o.id] = o end end
    local lines, total, short = {}, 0, nil
    for _, w in ipairs(want) do
        local o = sold[w.item.id]
        local st = o and stack(o.id)
        local need = w.count and (target - w.count) or 0
        if o and need > 0 and st and st > 0 and o.price and o.batch and o.batch > 0 then
            local top = 0
            for _, s in ipairs(slots) do
                if s and s[1] == o.id then top = top + math.max(0, st - s[2]) end
            end
            local room = top + empty * st
            local n = math.floor(math.min(need, room) / o.batch)
            if o.stock and o.stock >= 0 then n = math.min(n, o.stock) end
            local afford = n
            if o.price > 0 then afford = math.min(n, math.floor((money - total) / o.price)) end
            if afford < n then short = "money" elseif room < need and not short then short = "bags" end
            if afford > 0 then
                local items = afford * o.batch
                empty = empty - math.ceil(math.max(0, items - top) / st)
                total = total + afford * o.price
                lines[#lines + 1] = { offer = o, purchases = afford, items = items, cost = afford * o.price }
            end
        end
    end
    return lines, total, short
end

-- A merchant window opened. cfg: saved settings. env:
--   watched() -> { { item, count } } (the reagents the warning watches, with their counts) or nil
--   offers() -> list (see BuyPlan) or nil    slots() -> list (see BuyPlan) or nil
--   stack(id) -> number or nil               money() -> copper or nil
--   buy(index, quantity)  quantity nil buys one batch     say(text)     log(text)
--   confirm(text, accept)  asks the player; calls accept() only on Yes
-- Returns the number of purchases made (0 when none, or when waiting for a Yes).
function R.OnMerchant(cfg, env)
    local L = ns.L
    local function log(text) if env.log then env.log("reagent buy: " .. text) end end
    if not cfg.reagentBuyEnabled then log("off") return 0 end
    local target = cfg.reagentBuyTarget or 0
    if target <= 0 then log("amount is 0") return 0 end
    local watched = env.watched()
    if not watched then log("class unknown") return 0 end
    if #watched == 0 then log("no class reagent watched") return 0 end
    local offers = env.offers()
    if not offers then log("merchant list unreadable") return 0 end
    if #offers == 0 then log("merchant sells no class reagents") return 0 end
    local slots, money = env.slots(), env.money()
    local lines, cost, short = R.BuyPlan(watched, offers, slots, env.stack, money, target)
    if not lines then log("bags or money unknown") return 0 end
    local parts, plan = {}, {}
    for _, l in ipairs(lines) do
        parts[#parts + 1] = L["%d %s"]:format(l.items, l.offer.name)
        plan[#plan + 1] = l.offer.id .. "x" .. l.items
    end
    log(("target %d, money %s, plan: %s, cost %d, short: %s"):format(target, tostring(money),
        #plan > 0 and table.concat(plan, " ") or "nothing", cost, tostring(short)))
    if #lines == 0 then
        if short == "money" then env.say(L["You cannot afford any reagents here."])
        elseif short == "bags" then env.say(L["Your bags have no room for reagents."]) end
        return 0
    end
    local list, coins = table.concat(parts, ", "), ns.Ammo.Coins(cost)
    local purchases = 0
    local function buy()
        for _, l in ipairs(lines) do
            local o = l.offer
            if o.batch == 1 and o.maxBuy and o.maxBuy > 1 then
                -- Single items: as many per call as the merchant allows.
                local left = l.items
                while left > 0 do
                    local q = math.min(left, o.maxBuy)
                    env.buy(o.index, q)
                    left = left - q
                end
            else
                for _ = 1, l.purchases do env.buy(o.index) end
            end
            purchases = purchases + l.purchases
        end
        local text = L["Bought %s for %s."]
        if short == "money" then text = L["Bought %s for %s (all you could afford)."]
        elseif short == "bags" then text = L["Bought %s for %s (all that fits in your bags)."] end
        env.say(text:format(list, coins))
    end
    if cfg.reagentBuyPrompt then
        env.confirm(L["Buy %s for %s?"]:format(list, coins), buy)
        return 0
    end
    buy()
    return purchases, cost
end
