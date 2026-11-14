package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
H.locale(ns)
for _, f in ipairs({ "Triggers", "Professions", "Reagents", "Supplies", "Status" }) do
    loadfile("ClosestVendor/" .. f .. ".lua")("ClosestVendor", ns)
end
local S = ns.Status

local function cfg(over)
    local c = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10, reagentThreshold = 5,
        bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true, suppliesEnabled = true, reagentsEnabled = true, hudRow = {},
        foodEnabled = true, waterEnabled = true, petFoodEnabled = true, healthstoneRemind = true,
        foodThreshold = 5, waterThreshold = 5, petFoodThreshold = 5 }
    for k, v in pairs(over or {}) do c[k] = v end
    return c
end
local function keys(rows)
    local t = {}
    for i, r in ipairs(rows) do t[i] = r.key .. (r.low and "!" or "") end
    return table.concat(t, ",")
end
local function row(rows, key)
    for _, r in ipairs(rows) do if r.key == key then return r end end
end
local POWDER, RUNE = ns.Reagents.ById(17020), ns.Reagents.ById(17031)
local function display(class, i) return ns.Reagents.DisplayOnly(class)[i] end

-- Background colour: six hex digits to and from 0-1 numbers; anything else is no colour.
eq(table.concat({ S.Color("000000") }, ","), "0,0,0", "black")
eq(table.concat({ S.Color("FF8000") }, ","), "1," .. (128 / 255) .. ",0", "hex digits in either case")
for _, bad in ipairs({ "", "fff", "#000000", "00000g", "0000000", 0, true }) do
    eq(S.Color(bad), nil, "not a colour: " .. tostring(bad))
end
eq(S.Color(nil), nil, "no colour saved")
eq(S.Hex(1, 0.5, 0), "ff8000", "numbers to hex")
eq(S.Hex(-1, 2, "x"), "00ff00", "held to 0-1, an unreadable part is 0")
eq(S.Hex(S.Color("1a2b3c")), "1a2b3c", "there and back")
eq(S.ParseColor("#1A2b3C") .. "/" .. S.ParseColor("1a2b3c"), "1a2b3c/1a2b3c", "typed with or without #, any case")
eq(S.ParseColor("black") .. "/" .. S.ParseColor("RESET"), "000000/000000", "black and reset are the default")
for _, bad in ipairs({ "", "#fff", "red", "#12345g", "##000000", "#0000000" }) do
    eq(S.ParseColor(bad), nil, "not a colour: " .. bad)
end
eq(S.ParseColor(nil), nil, "nothing typed")
eq(S.BLACK, "000000", "the default is pure black")

-- Rows: one line per item, in a fixed order, with the value in the text.
local snap = { free = 10, dur = 80.7, reagents = { { item = POWDER, count = 12, name = "Arcane Powder" }, { item = RUNE, count = 3, name = "Rune of Teleportation" } },
    display = {}, known = {} }
local rows = S.Rows(snap, cfg(), "MAGE")
eq(keys(rows), "reagent:17020,reagent:17031!,bags,durability", "a mage: two reagents, bags, durability, no ammo")
eq(row(rows, "bags").text, "Bag space: 10 free", "bag text")
eq(row(rows, "durability").text, "Durability: 80%", "durability text")
eq(row(rows, "reagent:17020").text, "Arcane Powder: 12", "reagent text")
local r = row(rows, "reagent:17031")
eq(r.kind .. ":" .. r.id .. ":" .. tostring(r.routable), "reagent:17031:true", "what a click on a reagent row asks the controller for")
eq(row(rows, "bags").kind .. "," .. row(rows, "durability").kind, "sell,repair", "kinds of the bag and durability rows")

-- Ammo: arrows or bullets, only with a ranged weapon and a readable count.
rows = S.Rows({ ammoKind = "arrow", ammoCount = 150 }, cfg())
eq(rows[1].text .. "/" .. rows[1].kind .. "/" .. tostring(rows[1].low), "Arrows: 150/ammo/true", "arrows row, low")
eq(S.Rows({ ammoKind = "bullet", ammoCount = 900 }, cfg())[1].text, "Bullets: 900", "bullets row")
eq(S.Rows({ ammoKind = "bullet", ammoCount = 900 }, cfg())[1].low, false, "plenty: not low")
eq(#S.Rows({ ammoKind = "arrow" }, cfg()), 0, "unreadable ammo count: no row")

-- A value the game cannot read has no row, and is never shown as zero.
eq(keys(S.Rows({ free = nil, dur = nil }, cfg())), "", "nothing readable: no rows")
eq(keys(S.Rows({ free = 0 }, cfg())), "bags!", "a real zero is a row")
eq(keys(S.Rows({ dur = 50, reagents = { { item = POWDER } } }, cfg())), "durability", "a reagent without a count has no row")

-- Low uses the warning's own thresholds: at the threshold for bags, ammo and reagents, below it for durability.
eq(keys(S.Rows({ free = 2, dur = 20, ammoKind = "arrow", ammoCount = 200 }, cfg())), "ammo!,bags!,durability", "at the thresholds")
eq(keys(S.Rows({ free = 3, dur = 19.9, ammoKind = "arrow", ammoCount = 201 }, cfg())), "ammo,bags,durability!", "just past them")
eq(keys(S.Rows({ free = 6 }, cfg({ bagThreshold = 6 }))), "bags!", "the bag threshold is read from the settings")
eq(keys(S.Rows({ reagents = { { item = POWDER, count = 5 } } }, cfg())), "reagent:17020!", "reagent at its threshold")
eq(keys(S.Rows({ reagents = { { item = POWDER, count = 6 } } }, cfg())), "reagent:17020", "reagent above its threshold")
-- A switched-off warning is never low.
eq(keys(S.Rows({ free = 0, dur = 1, ammoKind = "arrow", ammoCount = 0, reagents = { { item = POWDER, count = 0 } } },
    cfg({ bagEnabled = false, durEnabled = false, ammoEnabled = false, reagentsEnabled = false }))), "ammo,reagent:17020,bags,durability", "warnings off: rows but none low")
eq(keys(S.Rows({ ammoKind = "arrow", ammoCount = 0, reagents = { { item = POWDER, count = 0 } } }, cfg({ ammoEnabled = false }))), "ammo,reagent:17020!", "ammo off: the reagent row is still low")

-- Professions: a row per known profession below the last cap, low when within the threshold.
local skills = { { name = "Mining", rank = 70, max = 75 }, { name = "Cooking", rank = 100, max = 150 },
    { name = "Fishing", rank = 300, max = 300 }, { name = "Swords", rank = 10, max = 300 }, { name = "Herbalism", rank = 75, max = 75 } }
rows = S.Rows({ skills = skills, known = { Mining = true, Cooking = true, Fishing = true } }, cfg())
eq(keys(rows), "prof:Cooking,prof:Mining!", "known professions below the last cap, by name; near the cap is low")
eq(row(rows, "prof:Mining").text, "Mining: 70/75", "profession text")
eq(row(rows, "prof:Mining").kind .. ":" .. row(rows, "prof:Mining").id, "trainer:Mining", "a profession row goes to a trainer")
eq(keys(S.Rows({ skills = skills, known = { Mining = true } }, cfg({ tradeEnabled = false }))), "prof:Mining", "profession warning off: not low")
eq(keys(S.Rows({ skills = { { name = "Mining", rank = 75, max = 75 } }, known = { Mining = true }, level = 5 }, cfg())), "prof:Mining", "too low a level for the next tier: shown, not low")
eq(keys(S.Rows({ skills = { { name = "Mining", rank = 75, max = 75 } }, known = { Mining = true }, level = 10 }, cfg())), "prof:Mining!", "level reached: low")
eq(keys(S.Rows({ skills = "broken", known = { Mining = true } }, cfg())), "", "unreadable skills: no rows")

-- Display-only items: a row that is never low and cannot be routed to.
rows = S.Rows({ display = { { item = display("WARLOCK", 1), count = 0 } } }, cfg(), "WARLOCK")
eq(keys(rows), "reagent:6265", "soul shards row")
eq(rows[1].text .. "/" .. tostring(rows[1].routable) .. "/" .. tostring(rows[1].low), "Soul Shards: 0/false/false", "display-only: inert and never low")
eq(#S.Rows({ display = { { item = display("WARLOCK", 1), count = 3 } }, reagents = { { item = POWDER, count = 1 } } }, cfg(), "ROGUE"), 0, "entries of another class are dropped")

-- Groups, modes and defaults: one mode per group, every row of the group follows it.
eq(table.concat(S.GROUPS, ","), "ammo,reagents,supplies,bags,durability,professions", "the groups, in window order")
eq(S.Group("prof:Mining") .. "," .. S.Group("reagent:17020") .. "," .. S.Group("reagent:6265") .. "," .. S.Group("bags"),
    "professions,reagents,reagents,bags", "a row key to its group")
eq(S.Group("prof:") or S.Group("reagent:x") or S.Group("bag") or S.Group(nil), nil, "not a row key: no group")
eq(S.DEFAULT_MODE, "low", "every group defaults to low")
eq(S.Mode(cfg(), "bags") .. S.Mode(cfg(), "prof:Mining") .. S.Mode(cfg(), "reagent:6265"), "lowlowlow", "no choice: low")
eq(S.Mode(cfg({ hudRow = { bags = "always" } }), "bags"), "always", "a chosen mode")
local pc = cfg({ hudRow = { professions = "always", reagents = "never" } })
eq(S.Mode(pc, "prof:Mining") .. S.Mode(pc, "prof:Cooking") .. S.Mode(pc, "professions"), "alwaysalwaysalways", "every profession row follows the Professions group")
eq(S.Mode(pc, "reagent:17020") .. S.Mode(pc, "reagent:5350"), "nevernever", "reagents and display-only items follow the Reagents group")
eq(S.Mode(cfg({ hudRow = { bags = "sometimes" } }), "bags"), "low", "a bad saved mode falls back to the default")
eq(S.Mode({}, "bags"), "low", "no hudRow table at all")
eq(S.Mode({ hudRow = "broken" }, "bags"), "low", "hudRow not a table")
-- Keys saved by an earlier build (per row) are ignored, not read as a group.
local stale = cfg({ hudRow = { ["prof:Mining"] = "always", ["reagent:17020"] = "never", ["reagent:6265"] = "always" } })
eq(S.Mode(stale, "prof:Mining") .. S.Mode(stale, "reagent:17020") .. S.Mode(stale, "reagent:6265"), "lowlowlow", "stale row keys: defaults")

-- Visible: only low rows by default.
rows = S.Rows({ free = 10, dur = 90, ammoKind = "arrow", ammoCount = 50 }, cfg())
eq(keys(S.Visible(rows, cfg())), "ammo!", "ammo low, bags not, both in mode low: the ammo row only")
-- Mixed modes.
local c = cfg({ hudRow = { durability = "always", bags = "never" } })
rows = S.Rows({ free = 0, dur = 90, reagents = { { item = POWDER, count = 12 } } }, c)
eq(keys(S.Visible(rows, c)), "durability", "durability always, reagents low and not low, bags never")
-- Nothing to show.
eq(#S.Visible(S.Rows({ free = 10, dur = 90 }, cfg()), cfg()), 0, "no row qualifies: empty, so no window")
-- Professions: one mode for every profession row.
rows = S.Rows({ skills = skills, known = { Mining = true, Cooking = true } }, cfg())
eq(keys(S.Visible(rows, cfg())), "prof:Mining!", "Professions low: only the one near its cap")
eq(keys(S.Visible(rows, cfg({ hudRow = { professions = "always" } }))), "prof:Cooking,prof:Mining!", "Professions always: every profession row")
eq(#S.Visible(rows, cfg({ hudRow = { professions = "never" } })), 0, "Professions never: none")
-- Display-only items follow Reagents but are never low: only Reagents always shows them.
local WATER
for _, item in ipairs(ns.Reagents.DisplayOnly("MAGE")) do if item.id == 5350 then WATER = item end end
rows = S.Rows({ display = { { item = WATER, count = 4 } }, reagents = { { item = POWDER, count = 0 } } }, cfg(), "MAGE")
eq(keys(S.Visible(rows, cfg())), "reagent:17020!", "Reagents low: the low reagent, conjured water hidden")
eq(keys(S.Visible(rows, cfg({ hudRow = { reagents = "always" } }))), "reagent:17020!,reagent:5350", "Reagents always: conjured water shown")
eq(#S.Visible(rows, cfg({ hudRow = { reagents = "never" } })), 0, "Reagents never: none")

-- Snapshot: reads through src, sums conjured items, needs the spell, skips rows that are never.
local reads = {}
local function src(over)
    local counts = { [17020] = 12, [17031] = 3, [5350] = 3, [2288] = 10, [5349] = 2 }
    local spells = { [23028] = true, [3561] = true, [5504] = true }
    local s = {
        freeSlots = function() reads.free = (reads.free or 0) + 1 return 7 end,
        lowestDurability = function() reads.dur = (reads.dur or 0) + 1 return 55 end,
        ammo = function() reads.ammo = (reads.ammo or 0) + 1 return "arrow", 400 end,
        knows = function(id) return spells[id] == true end,
        itemCount = function(id) reads.count = (reads.count or 0) + 1 return counts[id] or 0 end,
        itemName = function(id) return id == 17020 and "Arkanpulver" or nil end,
        skills = function() reads.skills = (reads.skills or 0) + 1 return skills end,
        known = { Mining = true },
    }
    for k, v in pairs(over or {}) do s[k] = v end
    return s
end
c = cfg({ hudRow = { reagents = "always" } })
snap = S.Snapshot(src(), c, "MAGE")
eq(snap.free .. "/" .. snap.dur .. "/" .. snap.ammoKind .. "/" .. snap.ammoCount, "7/55/arrow/400", "plain values")
eq(#snap.reagents, 2, "the two reagents whose spell is known")
eq(snap.reagents[1].name .. "," .. snap.reagents[2].name, "Arkanpulver,Rune of Teleportation", "the game's item name, else the table's")
eq(#snap.display, 1, "conjured water (spell known); conjured food needs its spell")
eq(snap.display[1].count, 13, "3 Conjured Water and 10 Conjured Spring Water show as 13")
rows = S.Rows(snap, c, "MAGE")
eq(keys(S.Visible(rows, c)), "reagent:17020,reagent:17031!,prof:Mining!,reagent:5350", "the whole path: snapshot, rows, visible")
eq(row(rows, "reagent:5350").text, "Conjured Water: 13", "summed row text")
-- A reagent whose warning is switched off still has its row.
c = cfg({ reagentOff = { [17020] = true }, hudRow = { reagents = "always" } })
eq(keys(S.Visible(S.Rows(S.Snapshot(src(), c, "MAGE"), c, "MAGE"), c)), "reagent:17020,reagent:17031!,prof:Mining!,reagent:5350", "warning off, Reagents always: shown")
-- Display-only items are not read unless Reagents is always: nothing else could show them.
eq(#S.Snapshot(src(), cfg(), "MAGE").display, 0, "Reagents low: display-only items not read")
-- One unreadable count makes a sum unknown, not smaller.
c = cfg({ hudRow = { reagents = "always" } })
snap = S.Snapshot(src({ itemCount = function(id) if id == 2288 then return nil end return 3 end }), c, "MAGE")
eq(#snap.display, 0, "an unreadable rank: no conjured water row")
snap = S.Snapshot(src({ itemCount = function() return nil end, freeSlots = function() return nil end }), cfg(), "MAGE")
eq(#snap.reagents .. "/" .. tostring(snap.free), "0/nil", "unreadable counts are left out")
-- Unknown spell knowledge is not knowledge.
snap = S.Snapshot(src({ knows = function() return nil end }), c, "MAGE")
eq(#snap.reagents + #snap.display, 0, "spells unknown: no reagent or display rows")
-- No class: the plain rows still work.
eq(S.Snapshot(src(), cfg(), nil).free, 7, "class unknown: bags still read")
-- Rows set to never are not read at all.
reads = {}
c = cfg({ hudRow = { bags = "never", durability = "never", ammo = "never", professions = "never", reagents = "never" } })
snap = S.Snapshot(src(), c, "MAGE")
eq(next(reads), nil, "every group never: nothing is read")
eq(#S.Rows(snap, c, "MAGE"), 0, "and there are no rows")

-- Supply rows: Food for everyone, Water for mana classes, Pet food for a hunter with a diet; low by the warnings' test.
local function sup(class, totals, knows) return { supplies = { class = class, totals = totals, knows = knows or function() end } } end
local function srows(class, totals, over, knows) return S.Rows(sup(class, totals, knows), cfg(over), class) end
eq(keys(srows("WARRIOR", { food = 3, water = 2, healthstone = 0 })), "supply:food!", "a warrior: food only, low")
eq(keys(srows("MAGE", { food = 20, water = 3, healthstone = 0 })), "supply:food,supply:water!", "a mage: water is low, food is not")
eq(keys(srows("MAGE", { food = 3, water = 3, healthstone = 0 }, nil, function() return true end)), "supply:food!,supply:water!",
    "a mage who can conjure: the row is low too (it is reminded)")
eq(keys(srows("PRIEST", { food = 5, water = 6, healthstone = 0 })), "supply:food!,supply:water", "at the threshold is low, above is not")
eq(keys(srows("MAGE", { food = 3, water = 3, healthstone = 0 }, { ammoEnabled = false })), "supply:food!,supply:water!", "ammo switch off: supplies are still low")
eq(keys(srows("MAGE", { food = 3, water = 3, healthstone = 0 }, { suppliesEnabled = false })), "supply:food,supply:water", "supplies switch off: never low")
eq(keys(srows("MAGE", { food = 3, water = 3, healthstone = 0 }, { foodEnabled = false })), "supply:food,supply:water!", "food off: the row stays, not low")
eq(keys(srows("HUNTER", { food = 9, water = 9, pet = 2, healthstone = 0 })), "supply:food,supply:water,supply:pet!", "a hunter with a pet diet: pet food row")
eq(keys(srows("HUNTER", { food = 9, water = 9, healthstone = 0 })), "supply:food,supply:water", "no pet diet: no pet row")
eq(keys(srows("WARRIOR", { food = 9, pet = 1, healthstone = 0 })), "supply:food", "pet food is for hunters only")
eq(#S.Rows({ supplies = { class = "MAGE" } }, cfg(), "MAGE"), 0, "unreadable bags: no rows")
eq(#S.Rows({}, cfg(), "MAGE"), 0, "no supplies read: no rows")
do
    local r = srows("MAGE", { food = 3, water = 9, healthstone = 0 })
    eq(r[1].text .. "/" .. r[1].kind .. "/" .. r[1].id .. "/" .. tostring(r[1].routable), "Food: 3/supply/food/true", "text, kind, id, routable")
    eq(r[2].text, "Water: 9", "water text")
    eq(S.Group("supply:food") .. S.Group("supply:pet"), "suppliessupplies", "rows belong to the Supplies group")
    eq(S.Find("food") .. S.Find("Pet Food") .. S.Find("water") .. S.Find("supplies"), "suppliessuppliessuppliessupplies", "names for the group")
    eq(S.Mode(cfg(), "supply:food"), "low", "default mode")
    eq(keys(S.Visible(srows("MAGE", { food = 3, water = 9, healthstone = 0 }), cfg())), "supply:food!", "mode low: only the low row")
    eq(keys(S.Visible(srows("MAGE", { food = 3, water = 9, healthstone = 0 }), cfg({ hudRow = { supplies = "always" } }))), "supply:food!,supply:water", "always: both")
    eq(#S.Visible(srows("MAGE", { food = 3, water = 9, healthstone = 0 }), cfg({ hudRow = { supplies = "never" } })), 0, "never: none")
end
do -- the bags are not read for a group set to never
    local reads = 0
    local src = { freeSlots = function() end, lowestDurability = function() end, ammo = function() end,
        knows = function() end, itemCount = function() end, itemName = function() end, skills = function() end,
        supplies = function() reads = reads + 1 return { class = "MAGE", totals = { food = 1, water = 1, healthstone = 0 } } end }
    S.Snapshot(src, cfg({ hudRow = { supplies = "never" } }), "MAGE")
    eq(reads, 0, "Supplies never: no read")
    local snap = S.Snapshot(src, cfg(), "MAGE")
    eq(reads .. "/" .. tostring(snap.supplies ~= nil), "1/true", "otherwise one read")
end

-- Names and lookup by name.
eq(table.concat({ S.KeyName("ammo"), S.KeyName("reagents"), S.KeyName("bags"), S.KeyName("durability"), S.KeyName("professions") }, ","),
    "Ammo,Reagents,Bag space,Durability,Professions", "group names")
eq(S.KeyName("supplies"), "Supplies", "the Supplies group name")
eq(S.Find("  Bag   SPACE ") .. S.Find("dur") .. S.Find("arrows") .. S.Find("Reagents") .. S.Find("profession"),
    "bagsdurabilityammoreagentsprofessions", "groups by name and short name, case and spaces ignored")
eq(S.Find("arcane powder") or S.Find("mining") or S.Find("prof:Mining") or S.Find(""), nil, "a single reagent or profession is not a group")

-- Demo: a roller that repeats for a seed, and a made-up window with at least one low row shown.
local function sample(seed)
    local roll, out = S.Roller(seed), {}
    for i = 1, 20 do out[i] = roll(6) end
    return table.concat(out, "")
end
eq(sample(100), sample(100), "the same seed gives the same rolls")
eq(sample(100) ~= sample(100.001), true, "a millisecond later gives other rolls")
eq(sample(nil), sample(0), "no time: still a roller")
local seen = {}
for _, n in ipairs({ sample(1):byte(1, -1) }) do seen[n - 48] = true end
eq(seen[0] == nil and seen[7] == nil and seen[1] and seen[6], true, "rolls stay within 1 to n and reach both ends")
local function flatCfg(t)
    local parts = {}
    for k, v in pairs(t) do parts[#parts + 1] = tostring(k) .. "=" .. tostring(v) end
    table.sort(parts)
    return table.concat(parts, ",")
end
local windows, kinds = {}, {}
for _, over in ipairs({ {}, { bagEnabled = false, durEnabled = false, ammoEnabled = false, tradeEnabled = false },
        { bagThreshold = 0, durThreshold = 1, ammoThreshold = 0, tradeThreshold = 0, reagentThreshold = 1 },
        { durThreshold = 100, tradeThreshold = 300 } }) do
    for seed = 1, 150 do
        local real = cfg(over)
        real.hudRow = { bags = "never", ammo = "never", durability = "never", reagents = "never", professions = "never" }
        local was, wasRows = flatCfg(real), flatCfg(real.hudRow)
        local dsnap, fake = S.Demo(S.Roller(seed), real)
        local shown = S.Visible(S.Rows(dsnap, fake), fake)
        local low = 0
        for _, r in ipairs(shown) do
            if r.low then low = low + 1 end
            kinds[r.kind] = true
        end
        if low == 0 then eq(seed, "a low row", "every demo window shows at least one low row") end
        if flatCfg(real) ~= was or flatCfg(real.hudRow) ~= wasRows then eq(seed, "unchanged", "the demo leaves the settings alone") end
        windows[keys(shown)] = true
    end
end
H.eq(true, true, "600 demo windows each show a low row and change no setting")
local different = 0
for _ in pairs(windows) do different = different + 1 end
eq(different > 50, true, "the windows differ from one roll to the next")
eq(kinds.ammo and kinds.sell and kinds.repair and kinds.reagent and kinds.trainer, true, "every kind of row turns up")
do -- the made-up window shows the supply rows too, low or not, whatever the real class
    local seen = {}
    for seed = 1, 120 do
        local dsnap, fake = S.Demo(S.Roller(seed), cfg())
        for _, r in ipairs(S.Rows(dsnap, fake)) do if r.kind == "supply" then seen[r.key] = (seen[r.key] or 0) + 1 end end
    end
    eq((seen["supply:food"] or 0) > 0 and (seen["supply:water"] or 0) > 0 and (seen["supply:pet"] or 0) > 0, true,
        "food, water and pet food rows all turn up in the demo")
end
local a1, a2 = S.Demo(S.Roller(7), cfg()), S.Demo(S.Roller(7), cfg())
eq(keys(S.Rows(a1, cfg())), keys(S.Rows(a2, cfg())), "the same seed gives the same window")

H.done()
