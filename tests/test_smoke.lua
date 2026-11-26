package.path = "tests/?.lua;" .. package.path
local stubs = require("stubs")

stubs.install({ FAKE_API = function() return 42 end })
assert(FAKE_API() == 42, "stub not installed")
stubs.restore()
assert(FAKE_API == nil, "stub not restored")

-- The CheckThat integration loads with no game and no CheckThat, and starts without raising.
local ns = {}
assert(loadfile("ClosestVendor/CheckThat.lua"))("ClosestVendor", ns)
assert(ns.CheckThat and ns.CheckThat.Start({}) == 0, "CheckThat.lua loads and starts with CheckThat missing")
assert(ns.CheckThat.Status() == "not detected", "CheckThat.lua reports CheckThat missing")
print("ok")
