package.path = "tests/?.lua;" .. package.path
local fake = require("fake_settings")

local H = require("harness")
local eq = H.eq

local DEFAULTS = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10,
    bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true,
    ammoBuyEnabled = true, ammoBuyPrompt = false, arrowGrade = "equipped", bulletGrade = "equipped",
    vendorMode = "ask", vendorPrefer = "map", autoNotice = true }

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
eq(#rec.settings, 15, "two per trigger, four for ammo buying, three for the target choice and notice")
eq(#rec.checkboxes, 7, "a checkbox per trigger, plus two for ammo buying and one for the notice")
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
    eq(s.vtype, (s.key:find("Enabled") or s.key == "ammoBuyPrompt" or s.key == "autoNotice") and "boolean" or (s.key:find("Grade") or s.key:find("^vendor")) and "string" or "number", "type of " .. s.key)
end
for _, k in ipairs({ "bagEnabled", "bagThreshold", "durEnabled", "durThreshold", "ammoEnabled", "ammoThreshold", "tradeEnabled", "tradeThreshold" }) do
    eq(keys[k] ~= nil, true, "registered " .. k)
end

-- Ammo buying: two switches and a grade dropdown per ammo kind.
for _, k in ipairs({ "ammoBuyEnabled", "ammoBuyPrompt", "arrowGrade", "bulletGrade" }) do
    eq(keys[k] ~= nil, true, "registered " .. k)
end
eq(rec.checkboxes[5].setting.key, "ammoBuyEnabled", "buy switch")
eq(rec.checkboxes[6].setting.key, "ammoBuyPrompt", "ask-first switch")
eq(#rec.dropdowns, 4, "a dropdown per ammo kind, plus the two target choices")
eq(rec.dropdowns[1].setting.key, "arrowGrade", "arrow dropdown")
eq(rec.dropdowns[2].setting.key, "bulletGrade", "bullet dropdown")
local vals = {}
for _, o in ipairs(rec.dropdowns[1].options) do vals[#vals + 1] = o.value end
eq(table.concat(vals, ","), table.concat(ns.Ammo and ns.Ammo.GRADES or { "equipped", "best", "cheapest" }, ","), "dropdown offers every grade")
ns.Commands.Run(cfg, "arrows cheapest")
eq(keys.arrowGrade:GetValue(), "cheapest", "page reads what the command set")

-- Target choice: mode and preference dropdowns bound to the same keys the commands edit.
eq(rec.dropdowns[3].setting.key, "vendorMode", "mode dropdown")
eq(rec.dropdowns[4].setting.key, "vendorPrefer", "preference dropdown")
vals = {}
for _, o in ipairs(rec.dropdowns[3].options) do vals[#vals + 1] = o.value end
eq(table.concat(vals, ","), "ask,auto", "mode choices")
vals = {}
for _, o in ipairs(rec.dropdowns[4].options) do vals[#vals + 1] = o.value end
eq(table.concat(vals, ","), "map,distance", "preference choices")
eq(keys.vendorMode:GetValue(), "ask", "mode defaults to ask")
eq(keys.vendorPrefer:GetValue(), "map", "preference defaults to map")
ns.Commands.Run(cfg, "prefer distance")
eq(keys.vendorPrefer:GetValue(), "distance", "page reads the preference the command set")
ns.Commands.Run(cfg, "choice auto")
eq(keys.vendorMode:GetValue(), "auto", "page reads the mode the command set")
local savedChanges = changes
keys.vendorMode:SetValue("ask")
changes = savedChanges
eq(cfg.vendorMode, "ask", "page writes the mode")
cfg.vendorPrefer = "map"

-- On-screen notice: a checkbox on the same key as the command.
eq(rec.checkboxes[7].setting.key, "autoNotice", "notice checkbox")
eq(keys.autoNotice:GetValue(), true, "notice defaults to on")
ns.Commands.Run(cfg, "notice off")
eq(keys.autoNotice:GetValue(), false, "page reads what the command set")
local savedN = changes
keys.autoNotice:SetValue(true)
changes = savedN
eq(cfg.autoNotice, true, "page writes the notice setting")

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
