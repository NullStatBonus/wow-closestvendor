-- The status window's rows: pure data and logic, no WoW globals. Tracker.lua draws what this returns.
-- A row key is a stable string: "ammo", "bags", "durability", "prof:<profession name>",
-- "reagent:<item id>" (class reagents and display-only items alike), "supply:food", "supply:water",
-- "supply:pet". Every row belongs to one of six groups, and the mode is set per group: cfg.hudRow maps a
-- group key ("ammo", "reagents", "supplies", "professions", "bags", "durability") to "low" (shown only while low), "always" or "never". It holds
-- only the modes the player changed; anything else, or any other key in it, means "low".
-- A display-only item is a reagents row that is never low: it shows only while Reagents is "always".
local _, ns = ...

local L = ns.L

local S = {}
ns.Status = S

S.MODES = { low = true, always = true, never = true }

-- Display-only items are named here: their table names are not item names the game can give.
local DISPLAY_NAMES = {
    [6265] = L["Soul Shards"], [5530] = L["Blinding Powder"],
    [5349] = L["Conjured Food"], [5350] = L["Conjured Water"],
}

-- The window background colour is saved as six hex digits, red green blue; black is the default.
S.BLACK = "000000"

-- "rrggbb" to red, green, blue from 0 to 1; nothing for anything else.
function S.Color(hex)
    if type(hex) ~= "string" then return end
    local r, g, b = hex:match("^(%x%x)(%x%x)(%x%x)$")
    if not r then return end
    return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
end

-- Red, green, blue from 0 to 1 (held to that range) to "rrggbb".
function S.Hex(r, g, b)
    local function byte(v) return math.floor(math.max(0, math.min(1, tonumber(v) or 0)) * 255 + 0.5) end
    return ("%02x%02x%02x"):format(byte(r), byte(g), byte(b))
end

-- What the player typed for a colour, "#rrggbb", "rrggbb", "black" or "reset", to "rrggbb"; nothing
-- for anything else.
function S.ParseColor(text)
    text = (text or ""):lower()
    if text == "black" or text == "reset" then return S.BLACK end
    local hex = text:match("^#?(%x%x%x%x%x%x)$")
    return hex
end

-- The groups, in the order the window draws them and the settings page lists them.
S.GROUPS = { "ammo", "reagents", "supplies", "bags", "durability", "professions" }
S.DEFAULT_MODE = "low"

local GROUP_NAMES = { ammo = L["Ammo"], reagents = L["Reagents"], supplies = L["Supplies"], professions = L["Professions"],
    bags = L["Bag space"], durability = L["Durability"] }

-- The group a row key (or a group key) belongs to; nil for anything else.
function S.Group(key)
    key = tostring(key or "")
    if GROUP_NAMES[key] then return key end
    if key:match("^reagent:%d+$") then return "reagents" end
    if key:match("^prof:.+$") then return "professions" end
    if key:match("^supply:%a+$") then return "supplies" end
end

-- The mode of a row, through its group.
function S.Mode(cfg, key)
    local group = S.Group(key)
    local mode = group and type(cfg.hudRow) == "table" and cfg.hudRow[group]
    if S.MODES[mode] then return mode end
    return S.DEFAULT_MODE
end

-- What a group is called in chat and on the settings page.
function S.KeyName(group)
    return GROUP_NAMES[group] or tostring(group)
end

-- The group a player means by text (case and extra spaces ignored), nil if none.
local WORDS = { ammo = "ammo", arrows = "ammo", bullets = "ammo", reagents = "reagents", reagent = "reagents",
    supplies = "supplies", supply = "supplies", food = "supplies", water = "supplies", petfood = "supplies",
    ["pet food"] = "supplies", professions = "professions", profession = "professions", prof = "professions", profs = "professions",
    bags = "bags", bag = "bags", ["bag space"] = "bags", durability = "durability", dur = "durability" }
function S.Find(text)
    local want = tostring(text or ""):lower():gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    if WORDS[want] then return WORDS[want] end
    for _, group in ipairs(S.GROUPS) do
        if S.KeyName(group):lower() == want then return group end
    end
end

-- Reads what the window shows. src supplies the game reads (each may return nil for "unknown"):
--   src.freeSlots(), src.lowestDurability(), src.ammo() -> kind, count
--   src.knows(spellId), src.itemCount(itemId), src.itemName(itemId), src.skills()
--   src.known   set of profession names the addon has seen
-- Nothing is read for a group whose mode is "never", nor for display-only items unless Reagents is
-- "always" (they are never low, so nothing else shows them). The result (the snapshot Rows takes):
--   free, dur                       numbers, or nil when unknown or not wanted
--   ammoKind, ammoCount             "arrow"/"bullet" and the count, or nil
--   reagents                        { { item, count, name } }: class reagents whose spell is known,
--                                   whether or not their warning is switched off
--   display                         { { item, count } }: display-only items whose spell is known, the
--                                   count summed over every item id of the entry
--   supplies                        { class, totals, knows } as Controller's supplies(), or nil: the bag
--                                   totals of food, water and pet food (nil when unreadable)
--   skills, known                   the skill list and the set of seen professions
function S.Snapshot(src, cfg, class)
    local snap = { reagents = {}, display = {}, known = src.known or {} }
    if S.Mode(cfg, "bags") ~= "never" then snap.free = src.freeSlots() end
    if S.Mode(cfg, "durability") ~= "never" then snap.dur = src.lowestDurability() end
    if S.Mode(cfg, "ammo") ~= "never" then snap.ammoKind, snap.ammoCount = src.ammo() end
    if not class then return snap end
    for _, item in ipairs(ns.Reagents.Watched(class, src.knows, nil)) do
        if S.Mode(cfg, "reagents") ~= "never" then
            local count = src.itemCount(item.id)
            if count then
                snap.reagents[#snap.reagents + 1] = { item = item, count = count, name = src.itemName(item.id) or item.name }
            end
        end
    end
    for _, item in ipairs(ns.Reagents.DisplayOnly(class)) do
        if S.Mode(cfg, "reagents") == "always" then
            local knows = false
            for _, spell in ipairs(item.spells) do if src.knows(spell) == true then knows = true break end end
            local total = knows and 0 or nil
            for _, id in ipairs(knows and ns.Reagents.ItemIds(item) or {}) do
                local n = src.itemCount(id)
                if not n then total = nil break end -- one unreadable count makes the sum unknown
                total = total + n
            end
            if total then snap.display[#snap.display + 1] = { item = item, count = total } end
        end
    end
    if S.Mode(cfg, "supplies") ~= "never" and src.supplies then snap.supplies = src.supplies() end
    if next(snap.known) and S.Mode(cfg, "professions") ~= "never" then snap.skills = src.skills() end
    return snap
end

-- The rows for a snapshot, in window order, whatever their mode (see Visible):
--   { key, kind, id, text, low, routable }
-- kind and id are what Controller.Go takes ("ammo", "reagent" + item id, "sell", "repair",
-- "trainer" + profession name). routable is false for a display-only item: a click does nothing.
-- A value that is unknown has no row. low uses the tests the warnings use: Triggers.Conditions,
-- Reagents.Low and Professions.Within, so a row and a warning cannot disagree. class, when given,
-- drops entries of another class.
function S.Rows(snap, cfg, class)
    local rows = {}
    local ammo = snap.ammoKind and snap.ammoCount or nil
    local cond = ns.Triggers.Conditions(cfg, snap.free, snap.dur, ammo)
    local function add(key, kind, id, text, low, routable)
        rows[#rows + 1] = { key = key, kind = kind, id = id, text = text, low = low and true or false, routable = routable }
    end

    if ammo then
        local text = snap.ammoKind == "bullet" and L["Bullets: %d"]:format(ammo) or L["Arrows: %d"]:format(ammo)
        add("ammo", "ammo", nil, text, cond.ammo, true)
    end

    local items, byId = {}, {}
    for _, r in ipairs(snap.reagents or {}) do
        if r.count and (not class or r.item.class == class) and r.item.vendor ~= false then
            items[#items + 1] = r.item
            byId[r.item.id] = r
        end
    end
    local lowReagent = {}
    -- The ammo switch is also the master switch of the reagent warnings.
    if cfg.ammoEnabled then
        for _, low in ipairs(ns.Reagents.Low(items, function(id) return byId[id].count end, cfg.reagentThreshold)) do
            lowReagent[low.item.id] = true
        end
    end
    for _, item in ipairs(items) do
        local r = byId[item.id]
        add("reagent:" .. item.id, "reagent", item.id, L["%s: %d"]:format(r.name or item.name, r.count), lowReagent[item.id], true)
    end

    -- Food, water and pet food. A row is low when Supplies.Evaluate puts it in go or remind, the test the
    -- warnings use; the ammo switch is the master switch. Water is for mana classes, pet food needs a diet.
    local sup = snap.supplies
    if type(sup) == "table" and sup.totals then
        local low = {}
        if cfg.ammoEnabled then
            local ev = ns.Supplies.Evaluate(sup.class, sup.totals, sup.knows or function() end, cfg)
            for _, e in ipairs(ev.go) do low[e.key] = true end
            for _, e in ipairs(ev.remind) do low[e.key] = true end
        end
        local names = { food = L["Food: %d"], water = L["Water: %d"], pet = L["Pet food: %d"] }
        for _, key in ipairs({ "food", "water", "pet" }) do
            local n = sup.totals[key]
            if n and (key ~= "water" or ns.Supplies.UsesMana(sup.class)) and (key ~= "pet" or sup.class == "HUNTER") then
                add("supply:" .. key, "supply", key, names[key]:format(n), low[key], true)
            end
        end
    end

    if snap.free then add("bags", "sell", nil, L["Bag space: %d free"]:format(snap.free), cond.sell, true) end
    if snap.dur then add("durability", "repair", nil, L["Durability: %d%%"]:format(math.floor(snap.dur)), cond.repair, true) end

    if type(snap.skills) == "table" then
        local near = {}
        if cfg.tradeEnabled then
            for _, p in ipairs(ns.Professions.Within(snap.skills, snap.known or {}, cfg.tradeThreshold)) do near[p.name] = true end
        end
        local profs = {}
        for _, s in ipairs(snap.skills) do
            -- Below its cap: a profession at the last cap has nothing left to train.
            if (snap.known or {})[s.name] and type(s.rank) == "number" and type(s.max) == "number"
                    and s.max > 0 and s.max < ns.Professions.LAST_CAP then
                profs[#profs + 1] = s
            end
        end
        table.sort(profs, function(a, b) return a.name < b.name end)
        for _, s in ipairs(profs) do
            add("prof:" .. s.name, "trainer", s.name, L["%s: %d/%d"]:format(s.name, s.rank, s.max), near[s.name], true)
        end
    end

    for _, r in ipairs(snap.display or {}) do
        if r.count and (not class or r.item.class == class) then
            local name = DISPLAY_NAMES[r.item.id] or r.item.name
            add("reagent:" .. r.item.id, "reagent", r.item.id, L["%s: %d"]:format(name, r.count), false, false)
        end
    end
    return rows
end

-- The rows to show: rows of an "always" group, and low rows of a "low" group. Empty means no window.
function S.Visible(rows, cfg)
    local out = {}
    for _, row in ipairs(rows) do
        local mode = S.Mode(cfg, row.key)
        if mode == "always" or (mode == "low" and row.low) then out[#out + 1] = row end
    end
    return out
end

-- Demo (/cvn demo) --------------------------------------------------------------------------------

-- A roller: roll(n) is a whole number from 1 to n. The same seed (a time in seconds) always gives
-- the same rolls.
function S.Roller(seed)
    local s = math.floor((tonumber(seed) or 0) * 1000) % 2147483646 + 1
    local function step() s = (s * 48271) % 2147483647 end
    step(); step()
    return function(n) step(); return s % n + 1 end
end

local DEMO_PROFESSIONS = { L["Alchemy"], L["Blacksmithing"], L["Enchanting"], L["Engineering"], L["Herbalism"],
    L["Leatherworking"], L["Mining"], L["Skinning"], L["Tailoring"], L["Cooking"], L["First Aid"], L["Fishing"] }
local DEMO_MODES = { "always", "always", "low", "never" }

-- A made-up window: a snapshot for Rows and a copy of cfg for Rows and Visible, with every warning
-- on and made-up group modes. Random rows of any class, random counts and modes; at least one row is
-- low and shown. cfg itself is only read.
function S.Demo(roll, cfg)
    local fake = {}
    for k, v in pairs(cfg) do fake[k] = v end
    fake.bagEnabled, fake.durEnabled, fake.ammoEnabled, fake.tradeEnabled = true, true, true, true
    fake.foodEnabled, fake.waterEnabled, fake.petFoodEnabled = true, true, true
    fake.hudRow = {}
    local snap = { reagents = {}, display = {}, known = {}, skills = {} }
    local sold, shown = {}, {}
    for _, item in ipairs(ns.Reagents.ITEMS) do
        if item.vendor == false then shown[#shown + 1] = item else sold[#sold + 1] = item end
    end
    local function upTo(limit) return roll(limit + 1) - 1 end -- 0 to limit

    -- One maker per row that can be low: it fills the snapshot, low or not, and returns the row key.
    local makers = {
        function(low)
            snap.ammoKind = roll(2) == 1 and "arrow" or "bullet"
            snap.ammoCount = low and upTo(cfg.ammoThreshold) or cfg.ammoThreshold + roll(1000)
            return "ammo"
        end,
        function(low)
            snap.free = low and upTo(cfg.bagThreshold) or cfg.bagThreshold + roll(40)
            return "bags"
        end,
        function(low)
            snap.dur = low and upTo(cfg.durThreshold - 1) or math.min(100, cfg.durThreshold + roll(60))
            return "durability"
        end,
    }
    -- Food, water and pet food rows: a hunter has all three, and each maker fills its own total.
    local function supplies()
        snap.supplies = snap.supplies or { class = "HUNTER", totals = { healthstone = 0 } }
        return snap.supplies.totals
    end
    for _, kind in ipairs({ { "food", "foodThreshold", "supply:food" }, { "water", "waterThreshold", "supply:water" },
            { "pet", "petFoodThreshold", "supply:pet" } }) do
        makers[#makers + 1] = function(low)
            local threshold = cfg[kind[2]] or 5
            supplies()[kind[1]] = low and upTo(threshold) or threshold + roll(40)
            return kind[3]
        end
    end
    local at = roll(#sold)
    for i = 0, 2 do
        local item = sold[(at + i - 1) % #sold + 1]
        makers[#makers + 1] = function(low)
            local count = low and upTo(cfg.reagentThreshold) or cfg.reagentThreshold + roll(40)
            snap.reagents[#snap.reagents + 1] = { item = item, count = count, name = item.name }
            return "reagent:" .. item.id
        end
    end
    at = roll(#DEMO_PROFESSIONS)
    for i = 0, 1 do
        local name = DEMO_PROFESSIONS[(at + i - 1) % #DEMO_PROFESSIONS + 1]
        makers[#makers + 1] = function(low)
            local max = 75 * roll(3)
            local left = low and upTo(cfg.tradeThreshold) or cfg.tradeThreshold + roll(20)
            snap.known[name] = true
            snap.skills[#snap.skills + 1] = { name = name, rank = math.max(1, max - left), max = max }
            return "prof:" .. name
        end
    end

    local must = roll(#makers) -- this row is there and low, and its group shows it
    local mustGroup
    for i, make in ipairs(makers) do
        if i == must or roll(3) > 1 then
            local key = make(i == must or roll(3) == 1)
            if i == must then mustGroup = S.Group(key) end
        end
    end
    for _, group in ipairs(S.GROUPS) do fake.hudRow[group] = DEMO_MODES[roll(#DEMO_MODES)] end
    fake.hudRow[mustGroup] = roll(2) == 1 and "low" or "always"
    if #shown > 0 and roll(2) == 1 then -- shown when Reagents came out as always
        local item = shown[roll(#shown)]
        snap.display[1] = { item = item, count = roll(20) }
    end
    return snap, fake
end
