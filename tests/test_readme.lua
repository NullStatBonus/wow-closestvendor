-- Every command shown in README.md must be accepted by the real parser (not answered with help).
package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
H.locale(ns)
loadfile("ClosestVendor/Reagents.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Supplies.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Nav.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Status.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Commands.lua")("ClosestVendor", ns)

local f = assert(io.open("README.md", "r"))
local text = f:read("*a")
f:close()

local block = text:match("## Commands%s+```\n(.-)```")
assert(block, "README has no command block")

local n = 0
for line in block:gmatch("[^\n]+") do
    local msg = line:match("^/cvn%s*(.*)$")
    assert(msg, "unexpected line in command block: " .. line)
    local cfg = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10, bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true, suppliesEnabled = true, reagentThreshold = 5, foodThreshold = 5, waterThreshold = 5, petFoodThreshold = 5, foodEnabled = true, waterEnabled = true, petFoodEnabled = true, reagentOff = {} }
    local out = ns.Commands.Run(cfg, msg, "MAGE")
    assert(not out[1]:find("show settings", 1, true), "README command is not accepted: " .. line)
    n = n + 1
end
assert(n >= 5, "too few documented commands: " .. n)

-- The limits written in the README ("(lo to hi)") must be the real ones: lo/hi accepted, just outside rejected.
local limits = {}
for lo, hi in text:match("## Commands.-## How it finds"):gmatch("%((%d+) to (%d+)%)") do
    limits[#limits + 1] = { tonumber(lo), tonumber(hi) }
end
assert(#limits == 8, "README should document eight limits, found " .. #limits)
for i, key in ipairs({ { "bags", "bagThreshold" }, { "dur", "durThreshold" }, { "ammo", "ammoThreshold" }, { "trade", "tradeThreshold" }, { "reagent", "reagentThreshold" }, { "food", "foodThreshold" }, { "water", "waterThreshold" }, { "petfood", "petFoodThreshold" } }) do
    local lo, hi = limits[i][1], limits[i][2]
    local cfg = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10, bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true, suppliesEnabled = true, reagentThreshold = 5, foodThreshold = 5, waterThreshold = 5, petFoodThreshold = 5, foodEnabled = true, waterEnabled = true, petFoodEnabled = true, reagentOff = {} }
    local function try(v) local before = cfg[key[2]]; ns.Commands.Run(cfg, key[1] .. " " .. v); return cfg[key[2]] == v and before ~= v or cfg[key[2]] == v end
    cfg[key[2]] = -999
    assert(try(lo), key[1] .. ": documented minimum " .. lo .. " not accepted")
    assert(try(hi), key[1] .. ": documented maximum " .. hi .. " not accepted")
    cfg[key[2]] = 50
    ns.Commands.Run(cfg, key[1] .. " " .. (hi + 1)); assert(cfg[key[2]] == 50, key[1] .. ": " .. (hi + 1) .. " should be rejected")
    ns.Commands.Run(cfg, key[1] .. " " .. (lo - 1)); assert(cfg[key[2]] == 50, key[1] .. ": " .. (lo - 1) .. " should be rejected")
end

print("ok (" .. n .. " documented commands, 8 limits)")
