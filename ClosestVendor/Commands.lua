-- Pure slash-command handling: no WoW globals.
-- Run() edits cfg and returns the lines to print, plus an optional action for the caller:
-- {"test", kind} with kind "sell", "repair", "arrow", "bullet" or "reagent"; {"open"} for the settings page;
-- {"debug", on}; {"log"} to show the report; {"log", "clear"}.
-- Run(cfg, msg, class): class is the player's class token ("MAGE"), needed by the reagent commands.
local _, ns = ...

local L = ns.L

local M = {}
ns.Commands = M

-- Allowed whole-number range of each threshold: used by the commands and the settings panel.
M.LIMITS = { bag = { 0, 200 }, dur = { 1, 100 }, ammo = { 0, 2000 }, trade = { 0, 300 }, reagent = { 1, 40 } }

-- Chat treats "|" as an escape character, so no printed line may contain one.
local HELP = {
    L["/cvn  show settings"],
    L["/cvn config  open the settings page"],
    L["/cvn bags <slots>, /cvn dur <percent>, /cvn ammo <count>, /cvn reagent <count>, /cvn trade <points>  set a threshold"],
    L["/cvn bags on/off  switch a question on or off (same for dur, ammo, trade); ammo also switches reagents"],
    L["/cvn reagents  list your class reagents; /cvn reagent on/off <name>  switch one"],
    L["/cvn buy on/off  buy ammo at merchants; /cvn buy ask/auto  ask first or buy at once"],
    L["/cvn arrows, /cvn bullets  equipped, best or cheapest: which ammo to buy"],
    L["/cvn choice ask/auto  target on another map: ask which, or navigate without asking"],
    L["/cvn prefer map/distance  prefer the target on your map or the closest"],
    L["/cvn notice on/off  on-screen message when a target is chosen without asking"],
    L["/cvn test sell, repair, arrows, bullets, reagent  ask the question now"],
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
    return lines
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
    if cmd == "reagents" then return reagentList(cfg, class) end
    if cmd == "reagent" and arg ~= "" then return reagentCommand(cfg, arg, rest:match("^%S*%s*(.*)$"), class) end
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
