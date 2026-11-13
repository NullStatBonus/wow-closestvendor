-- Pure slash-command handling: no WoW globals.
-- Run() edits cfg and returns the lines to print, plus an optional action for the caller:
-- {"test", kind} with kind "sell", "repair", "arrow", "bullet", "reagent", "food", "water", "petfood" or "remind"; {"open"} for the settings page;
-- {"debug", on}; {"log"} to show the report; {"log", "clear"}; {"hud", "pick"} for /cvn hud color with no colour (open the colour picker); {"hud", "reset"} to put the status
-- window back at its default position (lock, scale, opacity, text opacity, colour and row modes are
-- plain settings); {"demo"} for /cvn demo, which is not in the help on purpose.
-- Run(cfg, msg, class): class is the player's class token ("MAGE"), needed by the reagent commands.
local _, ns = ...

local L = ns.L

local M = {}
ns.Commands = M

-- Allowed whole-number range of each threshold: used by the commands and the settings panel.
M.LIMITS = { bag = { 0, 200 }, dur = { 1, 100 }, ammo = { 0, 2000 }, trade = { 0, 300 }, reagent = { 1, 40 }, food = { 1, 40 }, water = { 1, 40 }, petFood = { 1, 40 },
    hudScale = { 50, 200 }, hudAlpha = { 0, 100 }, hudTextAlpha = { 20, 100 }, reagentBuyTarget = { 0, 100 } }

-- Chat treats "|" as an escape character, so no printed line may contain one.
local HELP = {
    L["/cvn  show settings"],
    L["/cvn config  open the settings page"],
    L["/cvn bags <slots>, /cvn dur <percent>, /cvn ammo <count>, /cvn reagent <count>, /cvn trade <points>  set a threshold"],
    L["/cvn bags on/off  switch a question on or off (same for dur, ammo, trade); ammo also switches reagents"],
    L["/cvn reagents  list your class reagents; /cvn reagent on/off <name>  switch one"],
    L["/cvn food <count>, /cvn water <count>, /cvn petfood <count>  set when to ask about food, water or pet food"],
    L["/cvn food on/off  switch it on or off (same for water, petfood)"],
    L["/cvn sound <name>  choose the reminder sound (whisper, ping, invite, ready or none) and play it"],
    L["/cvn buy on/off  buy ammo at merchants; /cvn buy ask/auto  ask first or buy at once"],
    L["/cvn arrows, /cvn bullets  equipped, best or cheapest: which ammo to buy"],
    L["/cvn reagentbuy on/off  buy class reagents at merchants; /cvn reagentbuy ask/auto  ask first or buy at once; /cvn reagentbuy <0-100>  how many of each to carry"],
    L["/cvn choice ask/auto  target on another map: ask which, or navigate without asking"],
    L["/cvn prefer map/distance  prefer the target on your map or the closest"],
    L["/cvn notice on/off  on-screen message when a target is chosen without asking"],
    L["/cvn hud lock/unlock/reset  lock, unlock or reset the status window; /cvn hud scale <50-200>  its size in percent"],
    L["/cvn hud opacity <0-100>  how solid the status window background is (0 shows only text and icons); /cvn hud textopacity <20-100>  how solid its text and icons are"],
    L["/cvn hud color  open the color picker; /cvn hud color <#rrggbb/black/reset>  set the status window background color (black unless you change it)"],
    L["/cvn hud row <ammo/reagents/supplies/professions/bags/durability> low/always/never  when that group of status window rows shows"],
    L["/cvn anchor hearth/last  where a row click searches from inside a dungeon or raid"],
    L["/cvn ah on/off  let a row click go to the auction house when it is closer than a vendor"],
    L["/cvn test sell, repair, arrows, bullets, reagent  ask the question now"],
    L["/cvn test food, water, petfood  ask about food, water or pet food now; /cvn test remind  show the conjure or healthstone reminder now"],
    L["/cvn debug on/off  record what the addon sees; /cvn log  show the report; /cvn log clear  empty it"],
}

local function gradeName(g)
    if g == "best" then return L["best usable"] end
    if g == "cheapest" then return L["cheapest"] end
    return L["same as equipped"]
end

local function reagentNamesOff(cfg)
    local names = {}
    for id, off in pairs(cfg.reagentOff or {}) do
        local item = off and ns.Reagents.ById(id)
        if item then names[#names + 1] = item.name end
    end
    table.sort(names)
    return names
end

local function modeName(mode)
    if mode == "always" then return L["always"] end
    if mode == "never" then return L["never"] end
    return L["only when low"]
end

-- The status window row groups whose mode the player changed, as "name: mode", in window order.
local function changedRows(cfg)
    local out = {}
    for _, group in ipairs(ns.Status.GROUPS) do
        local mode = ns.Status.Mode(cfg, group)
        if mode ~= ns.Status.DEFAULT_MODE then out[#out + 1] = L["%s: %s"]:format(ns.Status.KeyName(group), modeName(mode)) end
    end
    return out
end

-- The name of a saved reminder sound key, for chat.
local function soundName(key)
    for _, s in ipairs(ns.Supplies.SOUNDS) do if s[1] == key then return s[3] end end
    return ns.Supplies.SOUNDS[1][3]
end

local function status(cfg)
    local lines = {
        L["Bags: %s, trigger at %d free slot(s) or fewer"]:format(cfg.bagEnabled and L["on"] or L["off"], cfg.bagThreshold),
        L["Durability: %s, trigger below %d%%"]:format(cfg.durEnabled and L["on"] or L["off"], cfg.durThreshold),
        L["Ammo: %s, trigger at %d or fewer"]:format(cfg.ammoEnabled and L["on"] or L["off"], cfg.ammoThreshold),
        L["Ammo buying: %s, %s, arrows: %s, bullets: %s"]:format(cfg.ammoBuyEnabled and L["on"] or L["off"],
            cfg.ammoBuyPrompt and L["asks first"] or L["buys at once"], gradeName(cfg.arrowGrade), gradeName(cfg.bulletGrade)),
        L["Professions: %s, trigger at %d point(s) or fewer from the skill limit"]:format(cfg.tradeEnabled and L["on"] or L["off"], cfg.tradeThreshold),
        L["Target choice: %s, prefers the target %s"]:format(cfg.vendorMode == "auto" and L["navigates without asking"] or L["asks which one"],
            cfg.vendorPrefer == "distance" and L["that is closest"] or L["on your map"]),
        L["On-screen notice when choosing without asking: %s"]:format(cfg.autoNotice ~= false and L["on"] or L["off"]),
    }
    table.insert(lines, 4, L["Reagents: %s, trigger at %d or fewer"]:format(cfg.ammoEnabled and L["on"] or L["off"], cfg.reagentThreshold))
    local off = reagentNamesOff(cfg)
    if #off > 0 then table.insert(lines, 5, L["Reagents switched off: %s"]:format(table.concat(off, ", "))) end
    table.insert(lines, #off > 0 and 6 or 5, L["Supplies: food %s (%d), water %s (%d), pet food %s (%d), healthstone reminder %s"]:format(
        cfg.foodEnabled ~= false and L["on"] or L["off"], cfg.foodThreshold or 5, cfg.waterEnabled ~= false and L["on"] or L["off"],
        cfg.waterThreshold or 5, cfg.petFoodEnabled ~= false and L["on"] or L["off"], cfg.petFoodThreshold or 5,
        cfg.healthstoneRemind ~= false and L["on"] or L["off"]))
    table.insert(lines, #off > 0 and 7 or 6, L["Reminder sound: %s"]:format(soundName(cfg.remindSound)))
    table.insert(lines, #off > 0 and 8 or 7, L["Reagent buying: %s, %s, up to %d of each"]:format(
        cfg.reagentBuyEnabled and L["on"] or L["off"], cfg.reagentBuyPrompt ~= false and L["asks first"] or L["buys at once"],
        cfg.reagentBuyTarget or 20))
    lines[#lines + 1] = L["Status window: %s, scale %d%%, background %d%% of color #%s, text and icons %d%%"]:format(
        cfg.hudLocked and L["locked"] or L["unlocked"], cfg.hudScale or 100, cfg.hudAlpha or 80,
        ns.Status.Color(cfg.hudColor) and cfg.hudColor or ns.Status.BLACK, cfg.hudTextAlpha or 100)
    local rows = changedRows(cfg)
    if #rows > 0 then lines[#lines + 1] = L["Status window rows changed: %s"]:format(table.concat(rows, ", ")) end
    lines[#lines + 1] = L["A row click inside a dungeon or raid searches from: %s"]:format(
        cfg.instanceAnchor == "last" and L["your last position outside"] or L["your hearthstone point"])
    lines[#lines + 1] = L["Auction house routing: %s"]:format(cfg.ahEnabled and L["on"] or L["off"])
    return lines
end

-- A whole number from lo to hi after the hud word, or nothing.
local function percent(rest, lo, hi)
    local v = tonumber(rest:match("^%S+%s+(%S+)$"))
    if v and v % 1 == 0 and v >= lo and v <= hi then return v end
end

-- /cvn hud ...: lock, unlock, reset, scale, opacity and textopacity <percent>, color <colour>,
-- row <group> <mode>.
local function hudCommand(cfg, arg, rest)
    if arg == "lock" or arg == "unlock" then
        cfg.hudLocked = (arg == "lock")
        return status(cfg)
    end
    if arg == "reset" then return { L["Status window moved back to its default position."] }, { "hud", "reset" } end
    if arg == "scale" then
        local lo, hi = M.LIMITS.hudScale[1], M.LIMITS.hudScale[2]
        local v = percent(rest, lo, hi)
        if not v then return { L["Window scale must be a whole number from %d to %d."]:format(lo, hi) } end
        cfg.hudScale = v
        return status(cfg)
    end
    if arg == "opacity" then
        local lo, hi = M.LIMITS.hudAlpha[1], M.LIMITS.hudAlpha[2]
        local v = percent(rest, lo, hi)
        if not v then return { L["Background opacity must be a whole number from %d to %d."]:format(lo, hi) } end
        cfg.hudAlpha = v
        return status(cfg)
    end
    if arg == "textopacity" then
        local lo, hi = M.LIMITS.hudTextAlpha[1], M.LIMITS.hudTextAlpha[2]
        local v = percent(rest, lo, hi)
        if not v then return { L["Text opacity must be a whole number from %d to %d."]:format(lo, hi) } end
        cfg.hudTextAlpha = v
        return status(cfg)
    end
    if (arg == "color" or arg == "colour") and rest:match("^%S+%s*$") then
        return {}, { "hud", "pick" } -- no colour given: open the game's colour picker
    end
    if arg == "color" or arg == "colour" then
        local hex = ns.Status.ParseColor(rest:match("^%S+%s+(%S+)$"))
        if not hex then
            return { L["Give the color as #rrggbb (six hex digits, for example #101820), or black or reset for the default."] }
        end
        cfg.hudColor = hex
        return status(cfg)
    end
    if arg == "row" then
        local name, mode = rest:match("^%S+%s+(.-)%s*(%S+)$")
        if not name or name == "" or not ns.Status.MODES[mode] then
            return { L["Name a row group and choose low, always or never, for example /cvn hud row bags always."] }
        end
        local key = ns.Status.Find(name)
        if not key then
            return { L["No status window row group named %s. Use ammo, reagents, supplies, professions, bags or durability."]:format(name) }
        end
        if type(cfg.hudRow) ~= "table" then cfg.hudRow = {} end
        -- Only a changed mode is kept: a group not in the table has the default.
        cfg.hudRow[key] = mode ~= ns.Status.DEFAULT_MODE and mode or nil
        return { L["Status window row %s: %s"]:format(ns.Status.KeyName(key), modeName(mode)) }
    end
    return { L["Choose lock, unlock, reset, scale, opacity, textopacity, color or row."] }
end

-- /cvn reagent ...: the threshold, or one reagent on or off by name.
local function reagentCommand(cfg, arg, name, class)
    cfg.reagentOff = cfg.reagentOff or {}
    if arg == "on" or arg == "off" then
        if #ns.Reagents.ForClass(class) == 0 then return { L["Your class has no reagents to watch."] } end
        local item = name ~= "" and ns.Reagents.Find(class, name)
        if name == "" then return { L["Name a reagent, for example /cvn reagent off arcane powder (see /cvn reagents)."] } end
        if not item then return { L["No reagent named %s for your class. See /cvn reagents."]:format(name) } end
        cfg.reagentOff[item.id] = (arg == "off") or nil
        return { L["%s: %s"]:format(item.name, arg == "on" and L["on"] or L["off"]) }
    end
    local v = tonumber(arg)
    local lo, hi = M.LIMITS.reagent[1], M.LIMITS.reagent[2]
    if not v or v % 1 ~= 0 or v < lo or v > hi then
        return { L["Reagent threshold must be a whole number from %d to %d."]:format(lo, hi) }
    end
    cfg.reagentThreshold = v
    return status(cfg)
end

-- /cvn reagentbuy on/off, ask/auto or the amount of each reagent to carry (0 buys none).
local function reagentBuyCommand(cfg, arg, class)
    if #ns.Reagents.ForClass(class) == 0 then return { L["Your class does not use reagents."] } end
    if arg == "on" or arg == "off" then
        cfg.reagentBuyEnabled = (arg == "on")
        return status(cfg)
    end
    if arg == "ask" or arg == "auto" then
        cfg.reagentBuyPrompt = (arg == "ask")
        return status(cfg)
    end
    local v = tonumber(arg)
    local lo, hi = M.LIMITS.reagentBuyTarget[1], M.LIMITS.reagentBuyTarget[2]
    if not v or v % 1 ~= 0 or v < lo or v > hi then
        return { L["Reagent amount must be a whole number from %d to %d, or on, off, ask or auto."]:format(lo, hi) }
    end
    cfg.reagentBuyTarget = v
    return status(cfg)
end

-- /cvn reagents: the player's class reagents and whether each is on.
local function reagentList(cfg, class)
    local items = ns.Reagents.ForClass(class)
    if #items == 0 then return { L["Your class has no reagents to watch."] } end
    local lines = { L["Reagents for your class (asked at %d or fewer, switch with /cvn reagent off <name>):"]:format(cfg.reagentThreshold) }
    for _, item in ipairs(items) do
        local off = cfg.reagentOff and cfg.reagentOff[item.id]
        lines[#lines + 1] = L["%s: %s"]:format(item.name, off and L["off"] or L["on"])
    end
    return lines
end

local function soundChoices()
    local names = {}
    for _, s in ipairs(ns.Supplies.SOUNDS) do names[#names + 1] = s[1] end
    return table.concat(names, ", ")
end

-- /cvn sound [name]: show the choices, or pick one (it plays as a preview; "none" is silent).
local function soundCommand(cfg, name)
    if name == "" then
        return { L["Reminder sound: %s"]:format(soundName(cfg.remindSound)), L["Choose a sound: %s."]:format(soundChoices()) }
    end
    local key = ns.Supplies.FindSound(name)
    if not key then return { L["Choose a sound: %s."]:format(soundChoices()) } end
    cfg.remindSound = key
    return { L["Reminder sound: %s"]:format(soundName(key)) }, { "sound" }
end

-- key: "bag", "dur", "ammo" or "trade"; lo/hi: allowed whole-number range; what: the (translated) name of the threshold.
local function setting(cfg, key, arg, lo, hi, what)
    local enabled, threshold = key .. "Enabled", key .. "Threshold"
    if arg == "on" or arg == "off" then
        cfg[enabled] = (arg == "on")
        return status(cfg)
    end
    local v = tonumber(arg)
    if not v or v % 1 ~= 0 or v < lo or v > hi then
        return { L["%s must be a whole number from %d to %d, or on/off."]:format(what, lo, hi) }
    end
    cfg[threshold] = v
    return status(cfg)
end

function M.Run(cfg, msg, class)
    local cmd, rest = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    local arg = rest:match("^%S*")
    if cmd == "" then return status(cfg) end
    if cmd == "sound" then return soundCommand(cfg, rest) end
    if cmd == "reagents" then return reagentList(cfg, class) end
    if cmd == "reagentbuy" then return reagentBuyCommand(cfg, arg, class) end
    if cmd == "reagent" and arg ~= "" then return reagentCommand(cfg, arg, rest:match("^%S*%s*(.*)$"), class) end
    if cmd == "food" and arg ~= "" then return setting(cfg, "food", arg, M.LIMITS.food[1], M.LIMITS.food[2], L["Food threshold"]) end
    if cmd == "water" and arg ~= "" then return setting(cfg, "water", arg, M.LIMITS.water[1], M.LIMITS.water[2], L["Water threshold"]) end
    if cmd == "petfood" and arg ~= "" then return setting(cfg, "petFood", arg, M.LIMITS.petFood[1], M.LIMITS.petFood[2], L["Pet food threshold"]) end
    if cmd == "bags" and arg ~= "" then return setting(cfg, "bag", arg, M.LIMITS.bag[1], M.LIMITS.bag[2], L["Bag threshold"]) end
    if cmd == "debug" and (arg == "on" or arg == "off") then
        local on = arg == "on"
        return { on and L["Debug log on. Repeat the problem, then use /cvn log."] or L["Debug log off."] }, { "debug", on }
    end
    if cmd == "log" and arg == "" then return { L["Showing the report..."] }, { "log" } end
    if cmd == "log" and arg == "clear" then return { L["Debug log cleared."] }, { "log", "clear" } end
    if cmd == "config" or cmd == "options" then
        return { L["Opening the settings page..."] }, { "open" }
    end
    if cmd == "test" and (arg == "sell" or arg == "repair") then
        local line = arg == "repair" and L["Asking about the nearest repair vendor..."] or L["Asking about the nearest sell vendor..."]
        return { line }, { "test", arg }
    end
    if cmd == "test" and (arg == "food" or arg == "water" or arg == "petfood") then
        return { L["Asking about the nearest vendor selling what you need..."] }, { "test", arg }
    end
    if cmd == "test" and arg == "remind" then
        return { L["Showing the reminder for your class..."] }, { "test", "remind" }
    end
    if cmd == "test" and arg == "reagent" then
        return { L["Asking about the nearest vendor selling your reagent..."] }, { "test", "reagent" }
    end
    if cmd == "test" and (arg == "arrows" or arg == "bullets") then
        local line = arg == "arrows" and L["Asking about the nearest vendor selling arrows..."] or L["Asking about the nearest vendor selling bullets..."]
        return { line }, { "test", (arg:gsub("s$", "")) }
    end
    if cmd == "buy" and (arg == "on" or arg == "off") then
        cfg.ammoBuyEnabled = (arg == "on")
        return status(cfg)
    end
    if cmd == "buy" and (arg == "ask" or arg == "auto") then
        cfg.ammoBuyPrompt = (arg == "ask")
        return status(cfg)
    end
    if cmd == "choice" then
        if arg == "ask" or arg == "auto" then
            cfg.vendorMode = arg
            return status(cfg)
        end
        return { L["Choose ask or auto."] }
    end
    if cmd == "notice" then
        if arg == "on" or arg == "off" then
            cfg.autoNotice = (arg == "on")
            return status(cfg)
        end
        return { L["Choose on or off."] }
    end
    if cmd == "demo" then return {}, { "demo" } end
    if cmd == "hud" then return hudCommand(cfg, arg, rest) end
    if cmd == "anchor" then
        if arg == "hearth" or arg == "last" then
            cfg.instanceAnchor = arg
            return status(cfg)
        end
        return { L["Choose hearth or last."] }
    end
    if cmd == "ah" then
        if arg == "on" or arg == "off" then
            cfg.ahEnabled = (arg == "on")
            return status(cfg)
        end
        return { L["Choose on or off."] }
    end
    if cmd == "prefer" then
        if arg == "map" or arg == "distance" then
            cfg.vendorPrefer = arg
            return status(cfg)
        end
        return { L["Choose map or distance."] }
    end
    if cmd == "arrows" or cmd == "bullets" then
        local key = cmd == "arrows" and "arrowGrade" or "bulletGrade"
        if arg == "equipped" or arg == "best" or arg == "cheapest" then
            cfg[key] = arg
            return status(cfg)
        end
        return { L["Choose equipped, best or cheapest."] }
    end
    if cmd == "ammo" and arg ~= "" then return setting(cfg, "ammo", arg, M.LIMITS.ammo[1], M.LIMITS.ammo[2], L["Ammo threshold"]) end
    if cmd == "trade" and arg ~= "" then return setting(cfg, "trade", arg, M.LIMITS.trade[1], M.LIMITS.trade[2], L["Profession threshold"]) end
    if cmd == "dur" and arg ~= "" then return setting(cfg, "dur", arg, M.LIMITS.dur[1], M.LIMITS.dur[2], L["Durability threshold"]) end
    return HELP
end
