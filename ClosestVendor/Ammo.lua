-- Buying ammo at a merchant: how much fits, which item, how much to buy. No WoW globals:
-- everything the game provides comes in through `env`.
local _, ns = ...

local L = ns.L

local M = {}
ns.Ammo = M

M.GRADES = { "equipped", "best", "cheapest" }

-- Room left in the quivers/pouches for item `id`, in items.
-- slots: one entry per slot of the bags that match the weapon: false when empty, else { id, count }.
-- stack: how many of the item fit in one slot. Unknown (nil) stays unknown.
function M.Space(slots, stack, id)
    if not slots or not stack then return end
    local room = 0
    for _, s in ipairs(slots) do
        if not s then room = room + stack
        elseif s[1] == id then room = room + math.max(0, stack - s[2]) end
    end
    return room
end

local function unitPrice(o)
    if o.price and o.batch and o.batch > 0 then return o.price / o.batch end
end

-- The item to buy. mode: "equipped" | "best" | "cheapest". offers: { index, id, name, price, batch,
-- minLevel, kind, stock }. Falls back to the equipped item when the mode finds nothing.
function M.Pick(mode, kind, offers, equippedID, level)
    local pick
    for _, o in ipairs(offers) do
        if o.kind == kind then
            if mode == "best" and level and o.minLevel and o.minLevel <= level then
                if not pick or o.minLevel > pick.minLevel
                        or (o.minLevel == pick.minLevel and (unitPrice(o) or math.huge) < (unitPrice(pick) or math.huge)) then
                    pick = o
                end
            elseif mode == "cheapest" and unitPrice(o) then
                if not pick or unitPrice(o) < unitPrice(pick) then pick = o end
            end
        end
    end
    if pick then return pick end
    for _, o in ipairs(offers) do
        if o.kind == kind and o.id == equippedID then return o end
    end
end

-- How many purchases of offer `o` to make for `space` items with `money` copper.
-- Returns purchases, items, cost, partial (could not buy it all); nil if anything needed is unknown.
function M.Plan(space, o, money)
    if not (space and o and o.price and o.batch and o.batch > 0 and money) then return end
    local want = math.floor(space / o.batch)
    if o.stock and o.stock >= 0 then want = math.min(want, o.stock) end
    local n = want
    if o.price > 0 then n = math.min(want, math.floor(money / o.price)) end
    return n, n * o.batch, n * o.price, n < want
end

function M.Coins(copper)
    local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    if g > 0 then return L["%dg %ds %dc"]:format(g, s, c) end
    if s > 0 then return L["%ds %dc"]:format(s, c) end
    return L["%dc"]:format(c)
end

-- A merchant window opened. cfg: saved settings. env:
--   kind() -> "arrow"|"bullet"|nil       equippedID() -> id|nil     level() -> number|nil
--   offers() -> list (see Pick)|nil      money() -> copper|nil
--   space(id, kind) -> items|nil         buy(index)                 say(text)
--   confirm(text, accept)                asks the player; calls accept() only on Yes
-- Returns the number of purchases made (0 when none, or when waiting for a Yes) and, when it
-- bought at once, what that cost (so a reagent purchase right after knows the money left).
function M.OnMerchant(cfg, env)
    local function log(text) if env.log then env.log("ammo buy: " .. text) end end
    if not cfg.ammoBuyEnabled then log("off") return 0 end
    local kind = env.kind()
    if not kind then log("no bow, crossbow or gun equipped, or its ammo cannot be read") return 0 end
    local offers = env.offers()
    if not offers then log("merchant list unreadable") return 0 end
    local sells = false
    for _, o in ipairs(offers) do if o.kind == kind then sells = true end end
    if not sells then log("merchant sells no " .. kind .. "s (" .. #offers .. " ammo item(s))") return 0 end

    local mode, equippedID = cfg[kind .. "Grade"] or "equipped", env.equippedID()
    local o = M.Pick(mode, kind, offers, equippedID, env.level())
    if not o then
        log(("no %s offer for mode %s, equipped item %s"):format(kind, mode, tostring(equippedID)))
        env.say(L["This merchant does not sell the ammo your settings ask for."])
        return 0
    end
    local space, money = env.space(o.id, kind), env.money()
    log(("%s item %s, price %s per %s, space %s, money %s"):format(mode, tostring(o.id), tostring(o.price),
        tostring(o.batch), tostring(space), tostring(money)))
    local n, items, cost, partial = M.Plan(space, o, money)
    if not n then log("space, price or money unknown") return 0 end
    if n == 0 then
        log(partial and "cannot afford one purchase" or "less than one purchase of room")
        if partial then env.say(L["You cannot afford any ammo here."]) end
        return 0
    end
    local function buy()
        for _ = 1, n do env.buy(o.index) end
        env.say((partial and L["Bought %d %s for %s (all you could afford)."] or L["Bought %d %s for %s."])
            :format(items, o.name, M.Coins(cost)))
    end
    if cfg.ammoBuyPrompt then
        env.confirm(L["Buy %d %s for %s?"]:format(items, o.name, M.Coins(cost)), buy)
        return 0
    end
    buy()
    return n, cost
end
