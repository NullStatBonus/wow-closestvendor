-- ClosestVendor/CheckThat.lua (spec checkthat-integration): CheckThat missing, old or raising never
-- breaks the addon; entries return the documented values; nothing writes saved settings.
package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

-- A fresh copy of the module per case: its failure state lasts for the session.
local function load(fake)
    local ns = H.locale({})
    ns.Adapter = { checkThat = function() return fake end }
    assert(loadfile("ClosestVendor/Presentation.lua"))("ClosestVendor", ns)
    assert(loadfile("ClosestVendor/CheckThat.lua"))("ClosestVendor", ns)
    return ns.CheckThat, ns
end

local function count(...) return select("#", ...) end

-- A CheckThat that stores entries and counts calls.
local function fakeCT()
    local f = { entries = {}, calls = 0, reports = 0 }
    function f.Entry(addon, name, fn)
        f.calls = f.calls + 1
        f.entries[name] = fn
        f.addon = addon
        return true
    end
    function f.Report() f.reports = f.reports + 1; return false end
    return f
end

local logged = {}
local function ctx(cfg, version)
    return { cfg = function() return cfg end, version = function() return version end,
             log = function(msg) logged[#logged + 1] = msg end }
end

-- Missing: nothing registers, nothing raises, the status says so.
local CT = load(nil)
eq(CT.Start(ctx({}, "1.11.0")), 0, "missing: no entries")
CT.Report("k", 1)
eq(CT.Status(), "not detected", "missing: not detected")

-- Old: a CheckThat without Entry or Report.
CT = load({})
eq(CT.Start(ctx({}, "1.11.0")), 0, "old: no entries")
CT.Report("k", 1)
eq(CT.Status(), "too old", "old: loaded, but too old to register entries")

-- Working: four entries, registered once.
local f = fakeCT()
local cfg = { bagThreshold = 2 }
CT = load(f)
eq(CT.Start(ctx(cfg, "1.11.0")), 4, "four entries stored")
eq(CT.Start(ctx(cfg, "1.11.0")), 4, "a second start registers nothing more")
eq(f.calls, 4, "Entry called once per entry")
eq(f.addon, "ClosestVendor", "entries belong to ClosestVendor")
eq(logged[#logged], "checkthat: entries registered: 4", "registration logged")
eq(f.entries.version(), 11100, "1.11.0 is 11100")
eq(f.entries.version(), 11100, "the version answers again")
eq(f.entries.setting("bags.threshold"), "2", "setting: the value /cvn get prints")
eq(f.entries.setting("BAGS.THRESHOLD"), "2", "setting: key case does not matter")
eq(count(f.entries.setting("no.such.key")), 0, "setting: unknown key returns nothing")
eq(count(f.entries.setting(42)), 0, "setting: a non-string key returns nothing")
eq(f.entries.integration(), "working", "integration: working")
eq(count(f.entries.active()), 0, "active: no getter, nothing")
CT.Report("k", 1)
eq(f.reports, 1, "Report passes through; a false return is normal")
eq(CT.Status(), "working", "a false Report return does not fail")

-- Version encoding; unknown versions return zero values.
eq(CT.VersionNumber("2.3.4"), 20304, "2.3.4")
eq(CT.VersionNumber("v1.10.12"), 11012, "leading v")
eq(CT.VersionNumber("dev"), nil, "does not parse")
f = fakeCT(); CT = load(f); CT.Start(ctx(cfg, nil))
eq(count(f.entries.version()), 0, "unknown version: zero values")

-- The version is read once, at Start: an entry call never reaches the game (which could log a failure).
local reads = 0
f = fakeCT(); CT = load(f)
CT.Start({ cfg = function() return cfg end, version = function() reads = reads + 1; return "1.11.0" end })
f.entries.version(); f.entries.version()
eq(reads, 1, "version read once at Start")
f = fakeCT(); CT = load(f)
eq(CT.Start({ cfg = function() return cfg end, version = function() error("no metadata", 0) end }), 4, "a version read that raises does not stop registration")
eq(count(f.entries.version()), 0, "and the version is unknown")

-- active: the request Triggers.Active names, with a reagent's item id; nothing when none.
local now = {}
f = fakeCT(); CT = load(f)
CT.Start({ cfg = function() return cfg end, version = function() return "1.11.0" end,
           active = function() return now[1], now[2] end })
eq(count(f.entries.active()), 0, "active: nothing open or active, nothing")
now = { "repair" }
eq(f.entries.active(), "repair", "active: the repair request")
now = { "reagent", 17020 }
eq(f.entries.active(), "reagent 17020", "active: a reagent with its item id")
f = fakeCT(); CT = load(f)
CT.Start({ active = function() error("no controller", 0) end })
eq(f.entries.active(), "error: no controller", "active: an error is returned as a value")

-- No saved-variable change: every entry leaves the settings table as it was.
local before = {}
for k, v in pairs(cfg) do before[k] = v end
f = fakeCT(); CT = load(f); CT.Start(ctx(cfg, "1.11.0"))
for name, fn in pairs(f.entries) do fn("bags.threshold") end
local same = true
for k, v in pairs(cfg) do if before[k] ~= v then same = false end end
for k, v in pairs(before) do if cfg[k] ~= v then same = false end end
eq(same, true, "entries do not change saved settings")

-- An error inside an entry returns "error: ..." (at most 100 characters) and keeps the integration on.
f = fakeCT(); CT = load(f)
CT.Start({ cfg = function() error(("x"):rep(300), 0) end, version = function() return "1.11.0" end,
           log = function(msg) logged[#logged + 1] = msg end })
local before_n = #logged
local r = f.entries.setting("bags.threshold")
eq(#logged, before_n, "an entry error writes nothing to the debug log")
eq(r:sub(1, 7), "error: ", "entry error is reported as a value")
eq(#r <= 100, true, "entry error is cut to 100 characters")
eq(CT.Status(), "working", "an entry error does not turn the integration off")

-- Entry raising on the second registration: off for the session, reason kept, nothing more called.
f = fakeCT()
local n = 0
local entry = f.Entry
f.Entry = function(...) n = n + 1; if n == 2 then error("boom", 0) end return entry(...) end
CT = load(f)
eq(CT.Start(ctx(cfg, "1.11.0")), 1, "one entry stored before the error")
eq(n, 2, "registration stops at the error")
eq(CT.Status(), "failed: Entry: boom", "status keeps the reason")
eq(logged[#logged], "checkthat: FAILED: Entry: boom", "the failure is logged with FAILED:")
CT.Report("k", 1)
eq(f.reports, 0, "no Report after a failure")
eq(count(f.entries.version()), 0, "a stored entry answers nothing after a failure")

-- Report raising, then registration: Entry is never called.
f = fakeCT()
f.Report = function() error("report broke", 0) end
CT = load(f)
CT.Report("k", 1)
eq(CT.Status(), "failed: Report: report broke", "Report raising fails the integration")
eq(CT.Start(ctx(cfg, "1.11.0")), 0, "no registration after a failure")
eq(f.calls, 0, "Entry not called after a failure")

H.done()
