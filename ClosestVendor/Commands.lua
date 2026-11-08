-- Pure slash-command handling: no WoW globals.
-- Run() edits cfg and returns the lines to print, plus an optional action for the caller:
-- {"test", kind} with kind "sell", "repair", "arrow" or "bullet"; {"open"} for the settings page;
-- {"debug", on}; {"log"} to show the report; {"log", "clear"}.
local _, ns = ...

local L = ns.L

local M = {}
ns.Commands = M

-- Allowed whole-number range of each threshold: used by the commands and the settings panel.
M.LIMITS = { bag = { 0, 200 }, dur = { 1, 100 }, ammo = { 0, 2000 }, trade = { 0, 300 } }

-- Chat treats "|" as an escape character, so no printed line may contain one.
local HELP = {
    L["/cvn  show settings"],
    L["/cvn config  open the settings page (Options, AddOns, Closest Vendor)"],
    L["/cvn bags <slots>  free-slot threshold (default 2); /cvn bags on, /cvn bags off"],
    L["/cvn dur <percent>  durability threshold (default 20); /cvn dur on, /cvn dur off"],
    L["/cvn ammo <count>  ammo threshold (default 200); /cvn ammo on, /cvn ammo off"],
    L["/cvn trade <points>  profession threshold (default 10); /cvn trade on, /cvn trade off"],
    L["/cvn buy on, /cvn buy off  buy ammo to fill your quiver or pouch at merchants (default on)"],
    L["/cvn buy ask, /cvn buy auto  ask first, or buy without asking (default)"],
    L["/cvn arrows equipped/best/cheapest, /cvn bullets equipped/best/cheapest  which ammo to buy (default equipped)"],
    L["/cvn choice ask, /cvn choice auto  when the closest target is on another map: ask which one (default), or navigate without asking"],
    L["/cvn prefer map, /cvn prefer distance  which target to prefer: the one on your map (default) or the closest"],
    L["/cvn notice on, /cvn notice off  show a message on screen when a target is chosen without asking (default on)"],
    L["/cvn test sell, /cvn test repair, /cvn test arrows, /cvn test bullets  ask the question now"],
    L["/cvn debug on, /cvn debug off  record what the addon sees, for bug reports"],
    L["/cvn log  show the report to copy; /cvn log clear  empty the log"],
}

local function gradeName(g)
    if g == "best" then return L["best usable"] end
    if g == "cheapest" then return L["cheapest"] end
    return L["same as equipped"]
end

local function status(cfg)
    return {
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

function M.Run(cfg, msg)
    local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(%S*)")
    if cmd == "" then return status(cfg) end
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
