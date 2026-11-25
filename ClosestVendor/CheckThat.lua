-- CheckThat, the in-game test runner (spec checkthat-integration; design D1 to D4; contract in
-- docs/contracts.md). Every CheckThat call lives here, existence-checked and in pcall, so ClosestVendor
-- works the same with CheckThat missing, old or failing. CheckThat is a test harness only: it is not in
-- OptionalDeps (CheckThat lists ClosestVendor, so ClosestVendor loads first) and it has no setting.
--
--   CT.Start(ctx) runs from Core at PLAYER_LOGIN and registers the entries once. ctx gives functions:
--     cfg() (this character's settings, read at call time), version() (the TOC version, read once here, so
--     an entry call never reaches the game), log(msg) (the debug log; only Start and failures write to it),
--     active() (the warning request that is open or active and a reagent's item id, or nil).
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
