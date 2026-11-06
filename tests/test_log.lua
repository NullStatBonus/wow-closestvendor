package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
loadfile("ClosestVendor/Log.lua")("ClosestVendor", ns)
local Log = ns.Log

local t = 0
local function clock() t = t + 1; return t end

-- Off by default: nothing is recorded.
local store = {}
local log = Log.New(store, clock)
eq(log.Enabled(), false, "off by default")
log.Add("hello")
eq(#log.Entries(), 0, "nothing recorded while off")
eq(t, 0, "the clock is not even read while off")

-- On: records in order with the time.
log.SetEnabled(true)
eq(log.Enabled(), true, "on")
eq(store.enabled, true, "persisted in the saved table")
log.Add("first"); log.Add("second"); log.Add(42)
eq(#log.Entries(), 3, "three entries")
eq(log.Entries()[1].msg, "first", "oldest first")
eq(log.Entries()[3].msg, "42", "non-strings are stored as text")
eq(log.Entries()[2].t, 2, "time recorded")
log.SetEnabled(false)
log.Add("ignored")
eq(#log.Entries(), 3, "off again: nothing more recorded")
eq(log.Enabled(), false, "off")

-- A new log over the same saved table sees the same state (persistence across sessions).
local again = Log.New(store, clock)
eq(again.Enabled(), false, "state restored")
eq(#again.Entries(), 3, "entries restored")

-- Bounded: only the newest `max` are kept.
local small = Log.New({ enabled = true }, clock, 5)
for i = 1, 12 do small.Add("m" .. i) end
eq(#small.Entries(), 5, "bounded at the maximum")
eq(small.Entries()[1].msg, "m8", "oldest dropped")
eq(small.Entries()[5].msg, "m12", "newest kept")
eq(Log.MAX, 300, "default limit is 300")
local big = Log.New({ enabled = true }, clock)
for i = 1, 400 do big.Add("x" .. i) end
eq(#big.Entries(), 300, "default limit applied")
eq(big.Entries()[1].msg, "x101", "keeps the newest 300")

-- Clear.
small.Clear()
eq(#small.Entries(), 0, "cleared")
small.Add("after")
eq(#small.Entries(), 1, "records again after clearing")

-- Format.
local lines = Log.Format({ { t = 1.5, msg = "a" }, { t = 12.25, msg = "b" }, { t = 3, msg = "c" } })
eq(table.concat(lines, "|"), "[1.5] a|[12.2] b|[3.0] c", "formatted, oldest first")
lines = Log.Format({ { t = 1, msg = "a" }, { t = 2, msg = "b" }, { t = 3, msg = "c" } }, 2)
eq(table.concat(lines, "|"), "[2.0] b|[3.0] c", "limit keeps the newest")
eq(#Log.Format({}), 0, "empty")

-- Report.
local header = { "version: 0.1.0", "client: 16001" }
local report = Log.Report(header, {}, false)
eq(report:find("^Closest Vendor report\nversion: 0.1.0\nclient: 16001\n") ~= nil, true, "header first")
eq(report:find("Debug log: off", 1, true) ~= nil, true, "says the log is off")
eq(report:find("/cvn debug on", 1, true) ~= nil, true, "says how to turn it on")
report = Log.Report(header, { { t = 1, msg = "event BAG_UPDATE_DELAYED" }, { t = 2, msg = "trigger go sell" } }, true)
eq(report:find("Debug log: on, 2 entries", 1, true) ~= nil, true, "on, with the count")
eq(report:find("[1.0] event BAG_UPDATE_DELAYED\n[2.0] trigger go sell", 1, true) ~= nil, true, "entries in order")
eq(Log.Report({}, {}, true):find("on, 0 entries", 1, true) ~= nil, true, "on with nothing recorded")

H.done()
