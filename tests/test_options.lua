package.path = "tests/?.lua;" .. package.path
local fake = require("fake_settings")

local H = require("harness")
local eq = H.eq

local DEFAULTS = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10,
    bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true }

-- Load Commands and Options with the fake globals in their environment.
local function load(settings)
    local env = setmetatable({ Settings = settings, MinimalSliderWithSteppersMixin = { Label = { Right = "right" } } }, { __index = _G })
    local ns = {}
    for _, f in ipairs({ "Locales/enUS", "Commands", "Options" }) do
        local chunk = assert(loadfile("ClosestVendor/" .. f .. ".lua"))
        setfenv(chunk, env)
        chunk("ClosestVendor", ns)
    end
    return ns
end

local S, rec = fake.new()
local ns = load(S)
local cfg = {}
for k, v in pairs(DEFAULTS) do cfg[k] = v end
local changes = 0
local category = ns.Options.Register(cfg, DEFAULTS, function() changes = changes + 1 end)

-- The page.
eq(category, rec.category, "returns the category")
eq(category.name, "Closest Vendor", "page name")
eq(rec.registered, category, "category registered under AddOns")
eq(#rec.settings, 8, "two settings per trigger")
eq(#rec.checkboxes, 4, "a checkbox per trigger")
eq(#rec.sliders, 4, "a slider per trigger")

-- Settings are bound to the saved table and the right keys, with unique names and defaults.
local keys, vars = {}, {}
for _, s in ipairs(rec.settings) do
    eq(s.tbl, cfg, "bound to the saved settings table: " .. s.key)
    eq(s.category, category, "in the page: " .. s.key)
    eq(vars[s.variable], nil, "unique variable name: " .. s.variable)
    vars[s.variable] = true
    keys[s.key] = s
    eq(s.default, DEFAULTS[s.key], "default for " .. s.key)
    eq(s.vtype, s.key:find("Enabled") and "boolean" or "number", "type of " .. s.key)
end
for _, k in ipairs({ "bagEnabled", "bagThreshold", "durEnabled", "durThreshold", "ammoEnabled", "ammoThreshold", "tradeEnabled", "tradeThreshold" }) do
    eq(keys[k] ~= nil, true, "registered " .. k)
end

-- Sliders use the same limits as the commands, in the same order as the checkboxes.
local expect = { bag = { 0, 200, 1 }, dur = { 1, 100, 1 }, ammo = { 0, 2000, 50 }, trade = { 0, 300, 1 } }
for i, key in ipairs({ "bag", "dur", "ammo", "trade" }) do
    local sl, cb = rec.sliders[i], rec.checkboxes[i]
    eq(sl.setting.key, key .. "Threshold", key .. ": slider edits the threshold")
    eq(cb.setting.key, key .. "Enabled", key .. ": checkbox edits the switch")
    eq(sl.options.min, ns.Commands.LIMITS[key][1], key .. ": slider min is the command limit")
    eq(sl.options.max, ns.Commands.LIMITS[key][2], key .. ": slider max is the command limit")
    eq(sl.options.min .. "-" .. sl.options.max .. "-" .. sl.options.step, table.concat(expect[key], "-"), key .. ": range and step")
    eq(sl.options.where, "right", key .. ": value shown on the right")
    eq(sl.parent, cb, key .. ": slider hangs off its checkbox")
    eq(type(sl.tip), "string", key .. ": slider has a tooltip")
end
local labels = {}
for i, key in ipairs({ "bag", "dur", "ammo", "trade" }) do
    local n = rec.checkboxes[i].setting.name
    eq(labels[n], nil, "distinct checkbox label: " .. n)
    labels[n] = true
end
eq(rec.checkboxes[4].setting.name, "Professions", "profession checkbox label")
eq(rec.sliders[4].setting.name, "Ask when a skill is this close to its limit", "profession slider label")
eq(rec.sliders[2].options.fmt(20), "20%", "durability shows a percent sign")
eq(rec.sliders[1].options.fmt, nil, "bag slider has no special format")

-- A slider is enabled only while its trigger is on.
eq(rec.sliders[1].pred(), true, "enabled while on")
cfg.bagEnabled = false
eq(rec.sliders[1].pred(), false, "disabled while off")
cfg.bagEnabled = true

-- Changing a control edits the saved value and reports the change.
keys.bagThreshold:SetValue(4)
eq(cfg.bagThreshold, 4, "slider writes the saved threshold")
eq(changes, 1, "change reported")
keys.ammoEnabled:SetValue(false)
eq(cfg.ammoEnabled, false, "checkbox writes the saved switch")
eq(changes, 2, "second change reported")

-- Opening goes to the page by id.
ns.Options.Open(category)
eq(rec.opened, 42, "opens the page")

keys.tradeThreshold:SetValue(25)
eq(cfg.tradeThreshold, 25, "profession slider writes the saved threshold")
keys.tradeEnabled:SetValue(false)
eq(cfg.tradeEnabled, false, "profession checkbox writes the saved switch")
eq(rec.sliders[4].pred(), false, "profession slider greyed while off")
cfg.tradeEnabled = true
ns.Commands.Run(cfg, "trade 40")
eq(keys.tradeThreshold:GetValue(), 40, "page reads what the profession command set")

-- Slash command and page agree: the command edits the same table the page reads.
ns.Commands.Run(cfg, "ammo 500")
eq(keys.ammoThreshold:GetValue(), 500, "page reads what the command set")

-- Missing or partial API: nothing registered, no error.
local ns2 = load(nil)
eq(ns2.Options.Register({}, DEFAULTS, function() end), nil, "no Settings API")
local S3 = fake.new()
S3.CreateSlider = nil
local ns3 = load(S3)
eq(ns3.Options.Register({}, DEFAULTS, function() end), nil, "partial API")

-- An older slider initializer without SetParentInitializer still works.
local S4, rec4 = fake.new()
local create = S4.CreateSlider
S4.CreateSlider = function(...) local i = create(...); i.SetParentInitializer = nil; return i end
local ns4 = load(S4)
eq(ns4.Options.Register({}, DEFAULTS, function() end) ~= nil, true, "works without SetParentInitializer")
eq(#rec4.sliders, 4, "sliders still created")

H.done()
