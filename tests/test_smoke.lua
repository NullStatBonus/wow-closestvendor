package.path = "tests/?.lua;" .. package.path
local stubs = require("stubs")

stubs.install({ FAKE_API = function() return 42 end })
assert(FAKE_API() == 42, "stub not installed")
stubs.restore()
assert(FAKE_API == nil, "stub not restored")
print("ok")
