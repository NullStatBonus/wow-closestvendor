package.path = "tests/?.lua;" .. package.path
local fake = require("fake_settings")

local H = require("harness")
local eq = H.eq

local DEFAULTS = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10,
    bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true,
    ammoBuyEnabled = true, ammoBuyPrompt = false, arrowGrade = "equipped", bulletGrade = "equipped",
    vendorMode = "ask", vendorPrefer = "map", autoNotice = true, reagentThreshold = 5 }

-- Load Commands and Options with the fake globals in their environment.
local function load(settings)
    local env = setmetatable({ Settings = settings, MinimalSliderWithSteppersMixin = { Label = { Right = "right" } } }, { __index = _G })
    local ns = {}
    for _, f in ipairs({ "Locales/enUS", "Reagents", "Commands", "Options" }) do
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
cfg.reagentOff = {}
local changes = 0
local category = ns.Options.Register(cfg, DEFAULTS, function() changes = changes + 1 end, "MAGE")

-- The page.
eq(category, rec.category, "returns the category")
eq(category.name, "Closest Vendor", "page name")
eq(rec.registered, category, "category registered under AddOns")
eq(#rec.settings, 19, "two per trigger, the reagent slider, three mage reagents, four for ammo buying, three for the target choice and notice")
eq(#rec.checkboxes, 10, "a checkbox per trigger and per mage reagent, plus two for ammo buying and one for the notice")
eq(#rec.sliders, 5, "a slider per trigger, plus the reagent slider")
local cbByKey, slByKey = {}, {}
for _, c in ipairs(rec.checkboxes) do cbByKey[c.setting.key] = c end
for _, sl in ipairs(rec.sliders) do slByKey[sl.setting.key] = sl end

-- Settings are bound to the saved table and the right keys, with unique names and defaults.
local keys, vars = {}, {}
local reagentSettings = {}
for _, s in ipairs(rec.settings) do
  if type(s.key) == "number" then
    reagentSettings[#reagentSettings + 1] = s
  else
    eq(s.tbl, cfg, "bound to the saved settings table: " .. s.key)
    eq(s.category, category, "in the page: " .. s.key)
    eq(vars[s.variable], nil, "unique variable name: " .. s.variable)
    vars[s.variable] = true
    keys[s.key] = s
    eq(s.default, DEFAULTS[s.key], "default for " .. s.key)
    eq(s.vtype, (s.key:find("Enabled") or s.key == "ammoBuyPrompt" or s.key == "autoNotice") and "boolean" or (s.key:find("Grade") or s.key:find("^vendor")) and "string" or "number", "type of " .. s.key)
  end
end
for _, k in ipairs({ "bagEnabled", "bagThreshold", "durEnabled", "durThreshold", "ammoEnabled", "ammoThreshold", "tradeEnabled", "tradeThreshold" }) do
    eq(keys[k] ~= nil, true, "registered " .. k)
end

-- Ammo buying: two switches and a grade dropdown per ammo kind.
for _, k in ipairs({ "ammoBuyEnabled", "ammoBuyPrompt", "arrowGrade", "bulletGrade" }) do
    eq(keys[k] ~= nil, true, "registered " .. k)
end
eq(cbByKey.ammoBuyEnabled ~= nil, true, "buy switch")
eq(cbByKey.ammoBuyPrompt ~= nil, true, "ask-first switch")
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
eq(cbByKey.autoNotice ~= nil, true, "notice checkbox")
eq(keys.autoNotice:GetValue(), true, "notice defaults to on")
ns.Commands.Run(cfg, "notice off")
eq(keys.autoNotice:GetValue(), false, "page reads what the command set")
local savedN = changes
keys.autoNotice:SetValue(true)
changes = savedN
eq(cfg.autoNotice, true, "page writes the notice setting")

-- Sliders use the same limits as the commands, in the same order as the checkboxes.
local expect = { bag = { 0, 200, 1 }, dur = { 1, 100, 1 }, ammo = { 0, 2000, 50 }, trade = { 0, 300, 1 } }
for _, key in ipairs({ "bag", "dur", "ammo", "trade" }) do
    local sl, cb = slByKey[key .. "Threshold"], cbByKey[key .. "Enabled"]
    eq(sl ~= nil and cb ~= nil, true, key .. ": slider and checkbox exist")
    eq(sl.options.min, ns.Commands.LIMITS[key][1], key .. ": slider min is the command limit")
    eq(sl.options.max, ns.Commands.LIMITS[key][2], key .. ": slider max is the command limit")
    eq(sl.options.min .. "-" .. sl.options.max .. "-" .. sl.options.step, table.concat(expect[key], "-"), key .. ": range and step")
    eq(sl.options.where, "right", key .. ": value shown on the right")
    eq(sl.parent, cb, key .. ": slider hangs off its checkbox")
    eq(type(sl.tip), "string", key .. ": slider has a tooltip")
end
local labels = {}
for _, key in ipairs({ "bag", "dur", "ammo", "trade" }) do
    local n = cbByKey[key .. "Enabled"].setting.name
    eq(labels[n], nil, "distinct checkbox label: " .. n)
    labels[n] = true
end
eq(cbByKey.tradeEnabled.setting.name, "Professions", "profession checkbox label")
eq(cbByKey.ammoEnabled.setting.name, "Ammo and reagents", "the ammo checkbox is the master switch for both")
eq(slByKey.tradeThreshold.setting.name, "Ask when a skill is this close to its limit", "profession slider label")
eq(slByKey.durThreshold.options.fmt(20), "20%", "durability shows a percent sign")
eq(slByKey.bagThreshold.options.fmt, nil, "bag slider has no special format")

-- A slider is enabled only while its trigger is on.
eq(slByKey.bagThreshold.pred(), true, "enabled while on")
cfg.bagEnabled = false
eq(slByKey.bagThreshold.pred(), false, "disabled while off")
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
eq(slByKey.tradeThreshold.pred(), false, "profession slider greyed while off")
cfg.tradeEnabled = true
ns.Commands.Run(cfg, "trade 40")
eq(keys.tradeThreshold:GetValue(), 40, "page reads what the profession command set")

-- Slash command and page agree: the command edits the same table the page reads.
ns.Commands.Run(cfg, "ammo 500")
eq(keys.ammoThreshold:GetValue(), 500, "page reads what the command set")

-- Missing or partial API: nothing registered, no error.
local ns2 = load(nil)
eq(ns2.Options.Register({}, DEFAULTS, function() end, "MAGE"), nil, "no Settings API")
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
eq(#rec4.sliders, 5, "sliders still created")

-- Reagents: the slider, and one checkbox per reagent of the class, all hanging off the master switch.
cfg.ammoEnabled = true -- an earlier check switched it off
eq(slByKey.reagentThreshold ~= nil, true, "reagent slider")
eq(slByKey.reagentThreshold.options.min .. "-" .. slByKey.reagentThreshold.options.max, "1-40", "limits are the command limits")
eq(slByKey.reagentThreshold.parent, cbByKey.ammoEnabled, "the reagent slider hangs off the master switch")
eq(slByKey.reagentThreshold.pred(), true, "enabled while the master switch is on")
cfg.ammoEnabled = false
eq(slByKey.reagentThreshold.pred(), false, "greyed with the master switch")
cfg.ammoEnabled = true
eq(keys.reagentThreshold:GetValue(), 5, "default reagent threshold")
ns.Commands.Run(cfg, "reagent 12")
eq(keys.reagentThreshold:GetValue(), 12, "page reads what the command set")
local savedR = changes
keys.reagentThreshold:SetValue(7)
eq(cfg.reagentThreshold, 7, "page writes the reagent threshold")
eq(changes, savedR + 1, "and reports the change")

eq(#reagentSettings, 3, "one setting per mage reagent, none for other classes")
local seen = {}
for _, s in ipairs(reagentSettings) do
    seen[s.key] = s
    eq(s.vtype, "boolean", "reagent setting is a checkbox")
    eq(s.default, true, "reagents are on by default")
    eq(s:GetValue(), true, "and read as on: " .. s.name)
    eq(vars[s.variable], nil, "unique variable name: " .. s.variable)
    vars[s.variable] = true
end
eq(seen[17020] ~= nil and seen[17031] ~= nil and seen[17032] ~= nil, true, "the three mage reagents")
eq(seen[17020].name, "Reagent: Arcane Powder", "labelled with the reagent name")
local before = changes
seen[17032]:SetValue(false)
eq(cfg.reagentOff[17032], true, "clearing the checkbox puts the reagent in the off-list")
eq(seen[17032]:GetValue(), false, "and it reads as off")
eq(seen[17020]:GetValue(), true, "others untouched")
eq(changes, before + 1, "change reported")
seen[17032]:SetValue(true)
eq(cfg.reagentOff[17032], nil, "setting it back on removes it from the off-list")
cfg.reagentOff[17020] = true
eq(seen[17020]:GetValue(), false, "the page reads what /cvn reagent off set")
cfg.reagentOff[17020] = nil
for _, c in ipairs(rec.checkboxes) do
    if type(c.setting.key) == "number" then
        eq(type(c.tip), "string", "reagent checkbox has a tooltip")
        eq(c.parent, cbByKey.ammoEnabled, "reagent checkbox hangs off the master switch")
        cfg.ammoEnabled = false
        eq(c.pred(), false, "and is greyed with it")
        cfg.ammoEnabled = true
    end
end

-- Another class sees its own reagents only; no class, none.
local S5, rec5 = fake.new()
local ns5 = load(S5)
local cfg5 = {}
for k, v in pairs(DEFAULTS) do cfg5[k] = v end
ns5.Options.Register(cfg5, DEFAULTS, function() end, "SHAMAN")
local names5 = {}
for _, st in ipairs(rec5.settings) do if type(st.key) == "number" then names5[#names5 + 1] = st.name end end
eq(table.concat(names5, ","), "Reagent: Ankh", "a shaman sees only the Ankh")
eq(type(cfg5.reagentOff), "table", "an off-list is created for old saved settings")
local S6, rec6 = fake.new()
load(S6).Options.Register({ reagentOff = {} }, DEFAULTS, function() end, nil)
local n6 = 0
for _, st in ipairs(rec6.settings) do if type(st.key) == "number" then n6 = n6 + 1 end end
eq(n6, 0, "no class: no reagent checkboxes")
eq(#rec6.sliders, 5, "but the slider is still there")

H.done()
