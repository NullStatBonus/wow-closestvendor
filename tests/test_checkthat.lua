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

-- Working: eleven entries, registered once.
local f = fakeCT()
local cfg = { bagThreshold = 2 }
CT = load(f)
eq(CT.Start(ctx(cfg, "1.11.0")), 11, "eleven entries stored")
eq(CT.Start(ctx(cfg, "1.11.0")), 11, "a second start registers nothing more")
eq(f.calls, 11, "Entry called once per entry")
eq(f.addon, "ClosestVendor", "entries belong to ClosestVendor")
eq(logged[#logged], "checkthat: entries registered: 11", "registration logged")
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
eq(CT.Start({ cfg = function() return cfg end, version = function() error("no metadata", 0) end }), 11, "a version read that raises does not stop registration")
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

-- learned, standing, nav and external: read through the getters Core passes; nothing without them.
eq(count(f.entries.learned("vendors")), 0, "learned: no getter, nothing")
eq(count(f.entries.standing(5)), 0, "standing: no getter, nothing")
eq(count(f.entries.nav()), 0, "nav: no getter, nothing")
eq(count(f.entries.external()), 0, "external: no getter, nothing")
local learnedDB = { vendors = { [100] = {}, [253139] = {} }, trainers = {}, auctioneers = { [9858] = {} } }
local standing = { [253139] = false, [9858] = true }
local navNow, navReads = "tomtom", 0
f = fakeCT(); CT = load(f)
CT.Start({ learned = function(kind) return learnedDB[kind] end, standing = function(id) return standing[id] end,
           nav = function() navReads = navReads + 1; return navNow end, external = function() return "not found" end })
eq(f.entries.learned("vendors"), 2, "learned: the number of vendors")
eq(f.entries.learned("Trainers"), 0, "learned: zero is a number, kind case does not matter")
eq(f.entries.learned("auctioneers"), 1, "learned: auctioneers")
eq(f.entries.learned("vendors", 253139), true, "learned: that vendor is learned")
eq(f.entries.learned("vendors", "253139"), true, "learned: an id typed as text")
eq(count(f.entries.learned("vendors", 7)), 0, "learned: an unknown id returns nothing")
eq(count(f.entries.learned("vendors", "x")), 0, "learned: an id that is not a number returns nothing")
eq(count(f.entries.learned("bankers")), 0, "learned: an unknown kind returns nothing")
eq(count(f.entries.learned()), 0, "learned: no kind returns nothing")
eq(f.entries.standing(253139), false, "standing: will not trade")
eq(f.entries.standing("9858"), true, "standing: will trade, id typed as text")
eq(count(f.entries.standing(1)), 0, "standing: never seen returns nothing")
eq(count(f.entries.standing("x")), 0, "standing: not a number returns nothing")
eq(f.entries.nav(), "tomtom", "nav: the method Core keeps")
navNow = nil
eq(count(f.entries.nav()), 0, "nav: unknown returns nothing")
eq(f.entries.external(), "not found", "external: what NorgannonDB gave")

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

-- window, config and reagents: read through the getters Core passes; nothing without them.
do
    local fw = fakeCT(); local CW, nsw = load(fw)
    assert(loadfile("ClosestVendor/Status.lua"))("ClosestVendor", nsw)
    CW.Start({})
    eq(count(fw.entries.window()), 0, "window: no getter, nothing")
    eq(count(fw.entries.config("hudScale")), 0, "config: no settings, nothing")
    eq(count(fw.entries.reagents()), 0, "reagents: no getter, nothing")
    local state, reads = "shown: bags low", 0
    local c = { hudScale = 150, ammoBuyEnabled = false, instanceAnchor = "last", hudRow = { bags = "always", ammo = "bogus" }, secret = "x" }
    local watched = { [17020] = 5 }
    fw = fakeCT(); CW, nsw = load(fw)
    assert(loadfile("ClosestVendor/Status.lua"))("ClosestVendor", nsw)
    CW.Start({ cfg = function() return c end, window = function() reads = reads + 1; return state end,
               reagents = function(id) if id ~= nil then return watched[tonumber(id)] end return "17020:5" end })
    eq(fw.entries.window(), "shown: bags low", "window: what Core kept")
    state = nil
    eq(count(fw.entries.window()), 0, "window: unknown returns nothing")
    eq(reads, 2, "window: one getter read per call")
    eq(fw.entries.config("hudScale"), "150", "config: a number as text")
    eq(fw.entries.config("AMMOBUYENABLED"), "false", "config: a boolean as text, any case")
    eq(fw.entries.config("instanceAnchor"), "last", "config: a word")
    eq(fw.entries.config("hudRow.bags"), "always", "config: a row group's mode")
    eq(fw.entries.config("hudRow.ammo"), "low", "config: a bad saved mode is the default")
    eq(fw.entries.config("hudRow.durability"), "low", "config: a group not changed is the default")
    eq(count(fw.entries.config("hudRow.nothing")), 0, "config: an unknown group returns nothing")
    eq(count(fw.entries.config("secret")), 0, "config: a name not on the list returns nothing")
    eq(count(fw.entries.config("hudAlpha")), 0, "config: a value not set returns nothing")
    eq(count(fw.entries.config()), 0, "config: no name returns nothing")
    eq(fw.entries.reagents(), "17020:5", "reagents: what the controller kept")
    eq(fw.entries.reagents(17020), 5, "reagents: one count")
    eq(count(fw.entries.reagents(1)), 0, "reagents: not watched returns nothing")
    eq(c.hudRow.ammo, "bogus", "config does not change saved settings")
end

-- window with a row group: only a known group is passed on, in lower case.
do
    local asked
    local fw = fakeCT(); local CW, nsw = load(fw)
    assert(loadfile("ClosestVendor/Status.lua"))("ClosestVendor", nsw)
    CW.Start({ window = function(g) asked = g; return g and "supply:food low" or "shown: x" end })
    eq(fw.entries.window("Supplies"), "supply:food low", "window: a row group, any case, is passed on")
    eq(asked, "supplies", "window: the group in lower case")
    asked = "untouched"
    eq(count(fw.entries.window("bogus")), 0, "window: a name that is not a row group returns nothing")
    eq(asked, "untouched", "window: an unknown group is not passed on")
    eq(count(fw.entries.window(5)), 0, "window: a group that is not text returns nothing")
    eq(fw.entries.window(), "shown: x", "window: no group, the whole window")
    eq(asked, nil, "window: no group passes nothing")
end

-- The run callback (spec checkthat-integration, "Test settings follow the CheckThat run").
do
    local function runCT(open)
        local f = fakeCT()
        f.open, f.onRunCalls = open, 0
        function f.OnRun(addon, fn) f.onRunCalls = f.onRunCalls + 1; f.run = fn; f.runAddon = addon; return true end
        function f.ActiveRun() return f.open end
        return f
    end
    local seen
    local function runCtx(extra)
        seen = {}
        local c = ctx({}, "1.14.0")
        c.runStarted = function(id) seen[#seen + 1] = "start " .. tostring(id) end
        c.runEnded = function(reason) seen[#seen + 1] = "end " .. tostring(reason) end
        c.runGone = function() seen[#seen + 1] = "gone" end
        for k, v in pairs(extra or {}) do c[k] = v end
        return c
    end

    -- Registered once for ClosestVendor; a second Start does not register again.
    local fr = runCT("Some plan"); local CR = load(fr)
    eq(CR.Start(runCtx()), 11, "run hook: entries still register")
    CR.Start(runCtx())
    eq(fr.onRunCalls, 1, "run hook: registered once")
    eq(fr.runAddon, "ClosestVendor", "run hook: for ClosestVendor")
    local found = false
    for _, m in ipairs(logged) do if m == "checkthat: run hook registered" then found = true end end
    eq(found, true, "run hook: registration logged")

    -- Start and end reach Core's handlers with the run id and the reason.
    fr.run("start", { runId = "r1", plan = "p" })
    fr.run("end", { runId = "r1", reason = "ended" })
    fr.run("start", { runId = "r2" })
    eq(table.concat(seen, ","), "start r1,end ended,start r2", "run hook: start and end reach the handlers")
    fr.run("pause", {})
    fr.run("start")
    eq(#seen, 4, "run hook: an unknown event is ignored, a missing info table is safe")

    -- A run already open at login: no "gone" call. No run open: "gone" before the callback is registered.
    seen = {}
    fr = runCT("Some plan"); CR = load(fr); CR.Start(runCtx())
    eq(table.concat(seen, ","), "", "run hook: a run is open, nothing restored")
    fr = runCT(nil); CR = load(fr)
    local order = {}
    local base = fr.OnRun
    fr.OnRun = function(...) order[#order + 1] = "OnRun"; return base(...) end
    CR.Start(runCtx({ runGone = function() order[#order + 1] = "gone" end }))
    eq(table.concat(order, ","), "gone,OnRun", "run hook: no run open, restore first, then register")

    -- A CheckThat without the callback changes nothing, and the entries still register.
    local fo = fakeCT(); local CO = load(fo)
    eq(CO.Start(runCtx()), 11, "no run hook: entries register")
    eq(#seen, 0, "no run hook: no handler called")
    eq(CO.Status(), "working", "no run hook: still working")
    found = false
    for _, m in ipairs(logged) do if m == "checkthat: run hook not available" then found = true end end
    eq(found, true, "no run hook: logged")
    -- ...also without ActiveRun: the callback registers, nothing is restored.
    fr = runCT(nil); fr.ActiveRun = nil; CR = load(fr); CR.Start(runCtx())
    eq(fr.onRunCalls, 1, "no ActiveRun: the callback still registers")
    eq(#seen, 0, "no ActiveRun: nothing restored")

    -- A handler that raises is logged and leaves the integration on.
    fr = runCT("p"); CR = load(fr)
    CR.Start(runCtx({ runStarted = function() error("handler broke", 0) end }))
    fr.run("start", { runId = "r1" })
    eq(logged[#logged], "checkthat: FAILED: runStarted: handler broke", "run hook: a handler error is logged")
    eq(CR.Status(), "working", "run hook: a handler error keeps the integration on")
    fr.run("end", { reason = "ended" })
    eq(seen[#seen], "end ended", "run hook: the next event still arrives")

    -- OnRun or ActiveRun raising turns the integration off for the session.
    fr = runCT("p"); fr.OnRun = function() error("onrun broke", 0) end; CR = load(fr)
    eq(CR.Start(runCtx()), 0, "OnRun raising: no entries registered")
    eq(CR.Status(), "failed: OnRun: onrun broke", "OnRun raising: the reason is kept")
    fr = runCT("p"); fr.ActiveRun = function() error("active broke", 0) end; CR = load(fr)
    CR.Start(runCtx())
    eq(CR.Status(), "failed: ActiveRun: active broke", "ActiveRun raising: the reason is kept")
    eq(fr.onRunCalls, 0, "ActiveRun raising: no callback registered")

    -- After a failure the stored callback answers nothing.
    fr = runCT("p"); CR = load(fr); CR.Start(runCtx()); CR.Fail("later")
    seen = {}
    fr.run("start", { runId = "r9" })
    eq(#seen, 0, "after a failure a run start turns nothing on")
    fr.run("end", { runId = "r9", reason = "ended" })
    eq(seen[#seen], "end ended", "after a failure a run end still restores")
end

H.done()
