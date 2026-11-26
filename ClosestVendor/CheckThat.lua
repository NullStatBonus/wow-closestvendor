-- CheckThat, the in-game test runner (spec checkthat-integration; design D1 to D4; contract in
-- docs/contracts.md). Every CheckThat call lives here, existence-checked and in pcall, so ClosestVendor
-- works the same with CheckThat missing, old or failing. CheckThat is a test harness only: it is not in
-- OptionalDeps (CheckThat lists ClosestVendor, so ClosestVendor loads first) and it has no setting.
--
--   CT.Start(ctx) runs from Core at PLAYER_LOGIN and registers the entries once. ctx gives functions:
--     cfg() (this character's settings, read at call time), version() (the TOC version, read once here, so
--     an entry call never reaches the game), log(msg) (the debug log; only Start and failures write to it),
--     active() (the warning request that is open or active and a reagent's item id, or nil), learned(kind)
--     (the account's learned table for "vendors", "trainers" or "auctioneers"), standing(npcId) (true,
--     false or nil, as this character saw it), nav() (the waypoint method Core keeps, never read from the
--     game here), external() (what NorgannonDB gave, as the report says it), window(group) (what the status
--     window shows, or one row group's rows, as Core kept it after its last redraw) and reagents(id) (the reagents the warning
--     watched at its last check, kept by the controller).
--   CT.Report(key, value) reports the fact [ClosestVendor] key=value. A false return is normal.
--   A raised error from CheckThat turns the integration off for the session and keeps the reason, so
--     /cvn log shows "CheckThat: failed: <why>" with the debug log off. An error inside an entry returns
--     "error: <message>" and leaves the integration on.
local _, ns = ...

local CT = { ADDON = "ClosestVendor", ORDER = {}, entries = {}, TEXT = 100 }
ns.CheckThat = CT

local ctx = {}
local version -- the TOC version text, read once at Start
local failed -- the reason, once a CheckThat call raised

local function api()
    local t = ns.Adapter and ns.Adapter.checkThat and ns.Adapter.checkThat()
    return type(t) == "table" and t or nil
end

local function cut(s) return (tostring(s):sub(1, CT.TEXT)) end

local function log(msg)
    if type(ctx.log) == "function" then pcall(ctx.log, msg) end
end

-- "working", "not detected", "too old" (loaded, but no Entry to register with) or "failed: <why>".
function CT.Status()
    if failed then return "failed: " .. failed end
    local t = api()
    if not t then return "not detected" end
    return type(t.Entry) == "function" and "working" or "too old"
end

-- Turns the integration off for the session. Later calls stop at the check in each caller.
function CT.Fail(why)
    if failed then return end
    failed = cut(why)
    log("checkthat: FAILED: " .. failed)
end

function CT.Report(key, value)
    if failed then return end
    local t = api()
    if not t or type(t.Report) ~= "function" then return end
    local ok, err = pcall(t.Report, CT.ADDON, key, value)
    if not ok then CT.Fail("Report: " .. tostring(err)) end
end

---- Entries ----------------------------------------------------------------------------------------

-- "1.11.0" is 11100: major*10000 + minor*100 + patch, the encoding of CheckThat's own version fact. nil
-- when the version is unknown or does not parse.
function CT.VersionNumber(v)
    if type(v) ~= "string" then return nil end
    local major, minor, patch = v:match("^v?(%d+)%.(%d+)%.(%d+)")
    if not major then return nil end
    return tonumber(major) * 10000 + tonumber(minor) * 100 + tonumber(patch)
end

local function add(name, fn)
    CT.ORDER[#CT.ORDER + 1] = name
    CT.entries[name] = fn
end

-- Nothing (zero values) when the version is unknown: the offline client has no TOC metadata.
add("version", function()
    local n = CT.VersionNumber(version)
    if n then return n end
end)

-- The value /cvn get prints for a setting key, or nothing for an unknown key.
add("setting", function(key)
    local P = ns.Presentation
    if type(key) ~= "string" or not (P and P.KEYS) then return end
    key = key:lower()
    local cfg = ctx.cfg and ctx.cfg()
    if not P.KEYS[key] or type(cfg) ~= "table" then return end
    return cut(P.Value(cfg, key))
end)

-- The integration's own status, as the report shows it.
add("integration", function()
    return cut(CT.Status())
end)

-- The warning request that is open or active now ("repair", "ammo", "reagent 17020", ...), from
-- ctx.active (Triggers.Active), or nothing when there is none. A request answered with No is no
-- longer active, though it stays handled until its condition clears.
add("active", function()
    if type(ctx.active) ~= "function" then return end
    local kind, id = ctx.active()
    if not kind then return end
    return cut(id and (kind .. " " .. tostring(id)) or kind)
end)

-- How many vendors, trainers or auctioneers the account learned (0 included); with an npc id, true when
-- that one is learned, else nothing. An unknown kind returns nothing.
add("learned", function(kind, id)
    local t = type(ctx.learned) == "function" and type(kind) == "string" and ctx.learned(kind:lower())
    if type(t) ~= "table" then return end
    if id ~= nil then
        id = tonumber(id)
        if id and t[id] ~= nil then return true end
        return
    end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end)

-- Whether this character can trade with an npc: true (Neutral or better, or its window opened), false
-- (Unfriendly or Hostile), or nothing when it was never seen.
add("standing", function(id)
    id = tonumber(id)
    if not id or type(ctx.standing) ~= "function" then return end
    local v = ctx.standing(id)
    if type(v) == "boolean" then return v end
end)

-- The waypoint method the addon uses now: tomtom, waypointui, native or chat.
add("nav", function()
    local v = type(ctx.nav) == "function" and ctx.nav()
    if v then return cut(v) end
end)

-- What NorgannonDB gave: "found, schema <s>, <n> vendors added, <n> skipped, <n> trainers with a tier",
-- "installed, but its data is not a supported schema" or "not found".
add("external", function()
    local v = type(ctx.external) == "function" and ctx.external()
    if v then return cut(v) end
end)

-- What the status window shows now: "hidden", "shown: <row keys>" (each key, " low" after a low row:
-- "shown: bags low, durability"), "demo" while made-up rows (a demo, a preview or Move) are drawn, or
-- nothing when there is no window. Core keeps the text after each redraw, so the call reads nothing
-- from the game. With a row group ("supplies", any case), only that group's row keys ("supply:food
-- low") or "none" when the window shows none of them; nothing for another name, while made-up rows
-- are drawn, or while the window state is unknown.
add("window", function(group)
    if type(ctx.window) ~= "function" then return end
    if group ~= nil then
        local S = ns.Status
        group = type(group) == "string" and group:lower() or nil
        if not (group and S and S.Group(group) == group) then return end
    end
    local v = ctx.window(group)
    if v then return cut(v) end
end)

-- The saved settings a step may check that /cvn get does not cover, by their saved name.
CT.CONFIG = {}
for _, k in ipairs({ "bagEnabled", "durEnabled", "ammoEnabled", "tradeEnabled", "suppliesEnabled", "reagentsEnabled",
        "bagThreshold", "durThreshold", "ammoThreshold", "tradeThreshold", "reagentThreshold",
        "ammoBuyEnabled", "ammoBuyPrompt", "arrowGrade", "bulletGrade", "vendorMode", "vendorPrefer", "autoNotice",
        "reagentBuyEnabled", "reagentBuyPrompt", "reagentBuyTarget",
        "hudLocked", "hudScale", "hudAlpha", "hudTextAlpha", "hudColor", "instanceAnchor", "ahEnabled",
        "foodEnabled", "waterEnabled", "petFoodEnabled", "healthstoneRemind", "foodThreshold", "waterThreshold",
        "petFoodThreshold", "remindSound", "navProvider", "notificationStyle" }) do
    CT.CONFIG[k:lower()] = k
end

-- A saved setting as text ("true", "20", "hearth", ...) by its saved name in any case (CT.CONFIG), or
-- a row group's mode as "hudRow.<group>" ("low", "always" or "never"); nothing for any other name or
-- a value that is not set. Only reads this character's settings.
add("config", function(name)
    if type(name) ~= "string" then return end
    local cfg = ctx.cfg and ctx.cfg()
    if type(cfg) ~= "table" then return end
    local group = name:lower():match("^hudrow%.(%a+)$")
    if group then
        local S = ns.Status
        if not (S and S.Group(group) == group) then return end
        return S.Mode(cfg, group)
    end
    local key = CT.CONFIG[name:lower()]
    if key == nil or cfg[key] == nil then return end
    return cut(tostring(cfg[key]))
end)

-- The class reagents the warning watched at its last check: "<item id>:<count>" sorted by id and
-- joined by "," ("17020:5,17031:3"), "none" when none is watched, or nothing before the first check
-- or when the last check could not read them (class unknown).
-- With an item id, that reagent's count, or nothing when it is not watched. A reagent switched off,
-- or one whose spell is not known, is not watched; the count is the bags only, never the bank.
add("reagents", function(id)
    if type(ctx.reagents) ~= "function" then return end
    local v = ctx.reagents(id)
    if v ~= nil then return type(v) == "string" and cut(v) or v end
end)

local function pack(...) return { n = select("#", ...), ... } end

-- fn in pcall; the number of results is kept (zero stays zero: CheckThat shows "(none)"). An error is
-- returned as a value, not logged, so an entry call writes nothing. After a failure only the integration
-- entry answers.
function CT.Wrap(name, fn)
    return function(...)
        if failed and name ~= "integration" then return end
        local r = pack(pcall(fn, ...))
        if r[1] then return unpack(r, 2, r.n) end
        return cut("error: " .. tostring(r[2]))
    end
end

-- Registers every entry once. Returns the number CheckThat stored.
function CT.RegisterEntries()
    if CT.registered then return CT.registered end
    if failed then return 0 end
    local t = api()
    if not t or type(t.Entry) ~= "function" then return 0 end
    CT.registered = 0
    for _, name in ipairs(CT.ORDER) do
        local ok, stored = pcall(t.Entry, CT.ADDON, name, CT.Wrap(name, CT.entries[name]))
        if not ok then
            CT.Fail("Entry: " .. tostring(stored))
            return CT.registered
        end
        if stored then CT.registered = CT.registered + 1 end
    end
    log(("checkthat: entries registered: %d"):format(CT.registered))
    return CT.registered
end

function CT.Start(c)
    ctx = type(c) == "table" and c or {}
    if type(ctx.version) == "function" then
        local ok, v = pcall(ctx.version)
        version = ok and v or nil
    end
    return CT.RegisterEntries()
end
