package.path = "tests/?.lua;" .. package.path
local fake = require("fake_settings")

local H = require("harness")
local eq = H.eq

local DEFAULTS = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10,
    bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true, suppliesEnabled = true, reagentsEnabled = true,
    ammoBuyEnabled = true, ammoBuyPrompt = false, arrowGrade = "equipped", bulletGrade = "equipped",
    vendorMode = "ask", vendorPrefer = "map", autoNotice = true, reagentThreshold = 5,
    reagentBuyEnabled = false, reagentBuyPrompt = true, reagentBuyTarget = 20,
    foodEnabled = true, waterEnabled = true, petFoodEnabled = true, healthstoneRemind = true,
    foodThreshold = 5, waterThreshold = 5, petFoodThreshold = 5, remindSound = "whisper", navProvider = "auto",
    instanceAnchor = "hearth", ahEnabled = false, hudLocked = false, hudScale = 100, hudAlpha = 80, hudTextAlpha = 100, hudColor = "000000" }

-- Load Commands and Options with the fake globals in their environment.
local function load(settings, class)
    local env = setmetatable({ Settings = settings, MinimalSliderWithSteppersMixin = { Label = { Right = "right" } },
        CreateSettingsListSectionHeaderInitializer = function(text) return { text = text } end }, { __index = _G })
    local ns = {}
    for _, f in ipairs({ "Locales/enUS", "Reagents", "Supplies", "Nav", "Status", "Commands", "Options" }) do
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
eq(#rec.settings, 42, "main 15 (two per trigger, ammo, reagents and supplies switches, notice, four dropdowns, auction), ammo 5 (threshold, buying, ask, two grades), reagents 7 (threshold, three reagents, three for buying), supplies 5 (a mage: food and water, a switch and a threshold each, and the reminder sound), window 10 (lock, three sliders, six row groups)")
eq(#rec.checkboxes, 18, "a checkbox per trigger, the supplies switch, the ammo and reagents switches, per mage reagent, two for reagent buying, two for ammo buying, notice, auction and lock")
eq(#rec.sliders, 11, "a slider per trigger, the reagent slider, the reagent amount, scale, background and text opacity")
local cbByKey, slByKey = {}, {}
for _, c in ipairs(rec.checkboxes) do cbByKey[c.setting.key] = c end
for _, sl in ipairs(rec.sliders) do slByKey[sl.setting.key] = sl end

-- Subcategories: Reagents, Ammo and Status window, each with its own controls.
local subs = {}
for _, c in ipairs(rec.subcategories) do subs[c.name] = c; eq(c.parent, category, "subcategory of the main page: " .. c.name) end
eq(#rec.subcategories, 4, "four subcategories")
do
    local order = {}
    for _, c in ipairs(rec.subcategories) do order[#order + 1] = c.name end
    eq(table.concat(order, ","), "Ammo,Reagents,Supplies,Status window", "pages in alphabetical order, the status window last")
    local warn = {}
    for _, st in ipairs(rec.settings) do
        if st.category == category and type(st.key) == "string" and st.key:find("Enabled$") and st.key ~= "ahEnabled" then warn[#warn + 1] = st.key end
    end
    eq(table.concat(warn, ","), "bagEnabled,durEnabled,tradeEnabled,ammoEnabled,reagentsEnabled,suppliesEnabled", "Warnings: bags, durability, professions, then ammo, reagents, supplies")
end
eq(subs["Reagents"] ~= nil and subs["Supplies"] ~= nil and subs["Ammo"] ~= nil and subs["Status window"] ~= nil, true, "named")
local function inPage(c)
    local n = {}
    for _, s in ipairs(rec.settings) do if s.category == c then n[#n + 1] = s end end
    return n
end
eq(#inPage(category), 15, "main page controls")
eq(#inPage(subs["Reagents"]), 7, "reagents page")
eq(#inPage(subs["Supplies"]), 5, "supplies page for a mage: food and water, and the reminder sound")
eq(#inPage(subs["Ammo"]), 5, "ammo page")
eq(#inPage(subs["Status window"]), 10, "status window page")
eq(inPage(subs["Status window"])[1].key, "hudLocked", "Lock window position is the first control of the window page")
local hdr = {}
for _, h in ipairs(rec.headers) do eq(h.category, category, "headers only on the main page with subcategories"); hdr[#hdr + 1] = h.text end
eq(table.concat(hdr, ","), "Warnings,Navigation", "main page sections")
eq(rec.registered, category, "only the main category is registered")

-- Settings are bound to the saved table and the right keys, with unique names and defaults.
local keys, vars = {}, {}
local reagentSettings = {}
for _, s in ipairs(rec.settings) do
  if type(s.key) == "number" then
    reagentSettings[#reagentSettings + 1] = s
  else
    if s.key ~= "mode" then eq(s.tbl, cfg, "bound to the saved settings table: " .. s.key) end
    eq(s.category == category or s.category.parent == category, true, "in the page or a subcategory: " .. s.key)
    eq(vars[s.variable], nil, "unique variable name: " .. s.variable)
    vars[s.variable] = true
    if s.key ~= "mode" then keys[s.key] = s end
    if s.key ~= "mode" then
    eq(s.default, DEFAULTS[s.key], "default for " .. s.key)
    eq(s.vtype, (s.key:find("Enabled") or s.key == "ammoBuyPrompt" or s.key == "reagentBuyPrompt" or s.key == "autoNotice" or s.key == "hudLocked") and "boolean" or (s.key:find("Grade") or s.key:find("^vendor") or s.key == "instanceAnchor" or s.key == "remindSound" or s.key == "navProvider") and "string" or "number", "type of " .. s.key)
    end
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
eq(#rec.dropdowns, 4 + 2 + 6 + 1, "four navigation choices, a dropdown per ammo kind, a mode per window row group, the reminder sound")
local ddByKey = {}
for _, d in ipairs(rec.dropdowns) do ddByKey[d.setting.key] = d end
eq(ddByKey.arrowGrade ~= nil and ddByKey.bulletGrade ~= nil, true, "arrow and bullet dropdowns")
local vals = {}
for _, o in ipairs(ddByKey.arrowGrade.options) do vals[#vals + 1] = o.value end
eq(table.concat(vals, ","), table.concat(ns.Ammo and ns.Ammo.GRADES or { "equipped", "best", "cheapest" }, ","), "dropdown offers every grade")
ns.Commands.Run(cfg, "arrows cheapest")
eq(keys.arrowGrade:GetValue(), "cheapest", "page reads what the command set")

-- Target choice: mode and preference dropdowns bound to the same keys the commands edit.
eq(ddByKey.vendorMode ~= nil and ddByKey.vendorPrefer ~= nil, true, "mode and preference dropdowns")
vals = {}
for _, o in ipairs(ddByKey.vendorMode.options) do vals[#vals + 1] = o.value end
eq(table.concat(vals, ","), "ask,auto", "mode choices")
vals = {}
for _, o in ipairs(ddByKey.vendorPrefer.options) do vals[#vals + 1] = o.value end
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
    if key == "ammo" then
        eq(sl.parent, nil, "ammo: on its own page the slider cannot hang off the main page checkbox")
        eq(sl.setting.category, subs["Ammo"], "ammo: the slider is on the Ammo page")
        eq(cb.setting.category, category, "ammo: the checkbox is on the main page")
    else
        eq(sl.parent, cb, key .. ": slider hangs off its checkbox")
    end
    eq(type(sl.tip), "string", key .. ": slider has a tooltip")
end
local labels = {}
for _, key in ipairs({ "bag", "dur", "ammo", "trade" }) do
    local n = cbByKey[key .. "Enabled"].setting.name
    eq(labels[n], nil, "distinct checkbox label: " .. n)
    labels[n] = true
end
eq(cbByKey.tradeEnabled.setting.name, "Professions", "profession checkbox label")
eq(cbByKey.ammoEnabled.setting.name, "Ammo", "the ammo checkbox is the ammo switch only")
eq(cbByKey.reagentsEnabled.setting.name, "Reagents", "reagents have their own switch")
eq(cbByKey.ammoEnabled.setting.category == category and cbByKey.reagentsEnabled.setting.category == category, true, "ammo and reagents switches are on the main page")
eq(slByKey.reagentThreshold.setting.category, subs["Reagents"], "the reagent slider is on the Reagents page")
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
eq(#rec4.sliders, 10, "sliders still created (no class: the food slider is shown, water and pet food are not)")

-- Reagents: the slider, and one checkbox per reagent of the class, all hanging off the reagents switch.
eq(slByKey.reagentThreshold ~= nil, true, "reagent slider")
eq(slByKey.reagentThreshold.options.min .. "-" .. slByKey.reagentThreshold.options.max, "1-40", "limits are the command limits")
eq(slByKey.reagentThreshold.parent, nil, "on its own page the reagent slider cannot hang off the main page switch")
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
        eq(c.parent, nil, "reagent checkbox has no parent on its own page")
        eq(c.setting.category, subs["Reagents"], "reagent checkbox is on the Reagents page")
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
eq(#rec6.sliders, 10, "but the sliders are still there (and the food one)")

-- Reagent buying: at the end of the Reagents page, buy, ask first and the amount, the last two
-- greyed while buying is off; bound to the keys the commands edit.
local rkeys = {}
for _, st in ipairs(inPage(subs["Reagents"])) do rkeys[#rkeys + 1] = tostring(st.key) end
eq(table.concat(rkeys, ","), "reagentThreshold,17020,17031,17032,reagentBuyEnabled,reagentBuyPrompt,reagentBuyTarget", "Reagents page order: warning, reagents, then buying")
local rbBox, raBox, rtSl = cbByKey.reagentBuyEnabled, cbByKey.reagentBuyPrompt, slByKey.reagentBuyTarget
eq(rbBox ~= nil and raBox ~= nil and rtSl ~= nil, true, "buy and ask checkboxes and the amount slider")
eq(rbBox.setting.name .. "|" .. raBox.setting.name, "Buy reagents|Ask before buying reagents", "labels")
eq(rtSl.options.min .. "-" .. rtSl.options.max .. "-" .. rtSl.options.step, "0-100-1", "amount range is the command limit")
eq(rtSl.options.min .. "-" .. rtSl.options.max, table.concat(ns.Commands.LIMITS.reagentBuyTarget, "-"), "same limits as /cvn reagentbuy")
eq(keys.reagentBuyEnabled:GetValue(), false, "buying is off by default")
eq(keys.reagentBuyPrompt:GetValue(), true, "and asks first by default")
eq(keys.reagentBuyTarget:GetValue(), 20, "20 of each by default")
eq(rtSl.parent == rbBox and raBox.parent == rbBox, true, "ask and amount hang off the buy checkbox")
eq(rtSl.pred() or raBox.pred(), false, "greyed while buying is off")
ns.Commands.Run(cfg, "reagentbuy on", "MAGE")
eq(rtSl.pred() and raBox.pred(), true, "usable while buying is on")
ns.Commands.Run(cfg, "reagentbuy 35", "MAGE")
eq(keys.reagentBuyTarget:GetValue(), 35, "page reads what the command set")
local savedB = changes
keys.reagentBuyTarget:SetValue(10)
eq(cfg.reagentBuyTarget .. "/" .. (changes - savedB), "10/1", "page writes the amount and reports it")
keys.reagentBuyPrompt:SetValue(false)
eq(cfg.reagentBuyPrompt, false, "page writes ask first")
eq(rbBox:CanModify() and raBox:CanModify() and rtSl:CanModify(), true, "a mage can use them")
eq(rbBox.tip ~= "Your class does not use reagents.", true, "with the normal tip")
cfg.reagentBuyEnabled, cfg.reagentBuyPrompt, cfg.reagentBuyTarget = false, true, 20
-- A class without vendor reagents (Hunter; Warlock has only display-only Soul Shards): greyed, says why.
for _, cls in ipairs({ "HUNTER", "WARLOCK" }) do
    local Sx, recx = fake.new()
    load(Sx).Options.Register({ reagentOff = {} }, DEFAULTS, function() end, cls)
    local n = 0
    for _, init in ipairs(recx.checkboxes) do
        if init.setting.key == "reagentBuyEnabled" or init.setting.key == "reagentBuyPrompt" then
            n = n + 1
            eq(init:CanModify(), false, cls .. ": " .. init.setting.key .. " greyed out")
            eq(init.tip, "Your class does not use reagents.", cls .. ": tooltip says why")
        end
    end
    for _, init in ipairs(recx.sliders) do
        if init.setting.key == "reagentBuyTarget" then
            n = n + 1
            eq(init:CanModify(), false, cls .. ": amount greyed out")
            eq(init.tip, "Your class does not use reagents.", cls .. ": slider tooltip says why")
        end
    end
    eq(n, 3, cls .. ": all three buying controls are still shown")
end

-- Status window page: Lock, scale, opacity, then one mode dropdown per row group, whatever the class.
local win = subs["Status window"]
local modeDD = {}
for _, d in ipairs(rec.dropdowns) do if d.setting.category == win and d.setting.key == "mode" then modeDD[#modeDD + 1] = d end end
local names = {}
for _, d in ipairs(modeDD) do names[#names + 1] = d.setting.name end
eq(table.concat(names, "|"), "Show: Ammo|Show: Reagents|Show: Supplies|Show: Bag space|Show: Durability|Show: Professions", "six groups in window order, Reagents right below Ammo")
local scale, alpha, textAlpha
for _, sl in ipairs(rec.sliders) do
    if sl.setting.key == "hudScale" then scale = sl elseif sl.setting.key == "hudAlpha" then alpha = sl
    elseif sl.setting.key == "hudTextAlpha" then textAlpha = sl end
end
eq(scale.options.min .. "-" .. scale.options.max, "50-200", "scale range")
eq(alpha.options.min .. "-" .. alpha.options.max, "0-100", "background opacity goes down to 0 (nothing drawn)")
eq(textAlpha.options.min .. "-" .. textAlpha.options.max, "20-100", "text opacity range")
eq(alpha.setting.default .. "/" .. textAlpha.setting.default, "80/100", "opacity defaults")
eq(scale.setting.category, win, "scale on the window page")
eq(alpha.setting.category == win and textAlpha.setting.category == win, true, "both opacities on the window page")
local wkeys = {}
for _, st in ipairs(inPage(win)) do if st.key ~= "mode" then wkeys[#wkeys + 1] = st.key end end
eq(table.concat(wkeys, ","), "hudLocked,hudScale,hudAlpha,hudTextAlpha", "window page order: lock, scale, opacities (the colour is a swatch button, not a setting)")
local ammoMode, reagentsMode, suppliesMode, bagsMode, profMode = modeDD[1], modeDD[2], modeDD[3], modeDD[4], modeDD[6]
local vals7 = {}
for _, o in ipairs(bagsMode.options) do vals7[#vals7 + 1] = o.value end
eq(table.concat(vals7, ","), "low,always,never", "mode choices")
eq(bagsMode.setting:GetValue() .. reagentsMode.setting:GetValue() .. profMode.setting:GetValue(), "lowlowlow", "every group defaults to low")
eq(profMode.setting.default, "low", "and says so")
local before8 = changes
bagsMode.setting:SetValue("always")
eq(cfg.hudRow.bags, "always", "the dropdown writes hudRow")
eq(changes, before8 + 1, "and reports the change")
profMode.setting:SetValue("always")
eq(cfg.hudRow.professions, "always", "one Professions dropdown writes the group key")
reagentsMode.setting:SetValue("never")
eq(cfg.hudRow.reagents, "never", "a mage's Reagents dropdown writes the group key")
suppliesMode.setting:SetValue("always")
eq(cfg.hudRow.supplies, "always", "the Supplies dropdown writes the group key")
cfg.hudRow.durability = "never"
eq(modeDD[5].setting:GetValue(), "never", "reads what /cvn hud row set")
eq(bagsMode.setting:GetValue() == "always" and modeDD[5].setting:GetValue() == "never", true, "each group its own")
cfg.hudRow.reagents, cfg.hudRow.professions, cfg.hudRow.durability, cfg.hudRow.supplies = nil, nil, nil, nil
local S9, rec9 = fake.new()
local ns9 = load(S9)
local cfg9 = {}
for k, v in pairs(DEFAULTS) do cfg9[k] = v end
ns9.Options.Register(cfg9, DEFAULTS, function() end, "HUNTER")
local hasAmmo = false
for _, st in ipairs(rec9.settings) do if st.name == "Show: Ammo" then hasAmmo = true end end
eq(hasAmmo, true, "a hunter gets the ammo row")
eq(type(cfg9.hudRow), "table", "hudRow is created for old saved settings")

-- Rows that do not apply to the class are shown greyed out, say why, and never write hudRow.
local function modeRows(recx, label)
    for _, d in ipairs(recx.dropdowns) do if d.setting.name == label then return d end end
end
eq(ammoMode.setting.name, "Show: Ammo", "mage: ammo row present")
eq(ammoMode.tip, "Your class does not use ammo.", "tooltip says why")
eq(ammoMode:CanModify(), false, "and the row is greyed out (modify predicate)")
eq(bagsMode:CanModify(), true, "an applicable row is not")
ammoMode.setting:SetValue("always")
eq(cfg.hudRow.ammo, nil, "a greyed-out ammo row writes nothing to hudRow")
eq(ammoMode.setting:GetValue(), "low", "and keeps its default")
eq(reagentsMode:CanModify(), true, "a class with reagents: the Reagents row is usable")
eq(reagentsMode.tip ~= "Your class does not use reagents.", true, "with the normal tip")
-- A class with display-only items only (Warlock: Soul Shards) can use the Reagents row too.
local S12, rec12 = fake.new()
load(S12).Options.Register({ reagentOff = {} }, DEFAULTS, function() end, "WARLOCK")
eq(modeRows(rec12, "Show: Reagents"):CanModify(), true, "warlock: Reagents row usable for its soul shards")
-- Hunter: ammo row enabled; no reagents, so a disabled Reagents row.
local S11, rec11 = fake.new()
local ns11 = load(S11)
local cfg11 = {}
for k, v in pairs(DEFAULTS) do cfg11[k] = v end
ns11.Options.Register(cfg11, DEFAULTS, function() end, "HUNTER")
local hAmmo, hReag = modeRows(rec11, "Show: Ammo"), modeRows(rec11, "Show: Reagents")
eq(hAmmo:CanModify(), true, "hunter: ammo row usable")
eq(hAmmo.tip ~= "Your class does not use ammo.", true, "hunter: normal tip")
eq(hReag:CanModify(), false, "hunter: Reagents row greyed out")
eq(hReag.tip, "Your class does not use reagents.", "hunter: reagents reason")
hReag.setting:SetValue("never")
eq(cfg11.hudRow.reagents, nil, "hunter: Reagents row writes nothing")
hAmmo.setting:SetValue("always")
eq(cfg11.hudRow.ammo, "always", "hunter: ammo row writes hudRow")

-- A client without subcategories: one page, headers separate the groups, reagent controls grey with the ammo switch.
local S10, rec10 = fake.new()
S10.RegisterVerticalLayoutSubcategory = nil
local ns10 = load(S10)
local cfg10 = {}
for k, v in pairs(DEFAULTS) do cfg10[k] = v end
cfg10.reagentOff = {}
local cat10 = ns10.Options.Register(cfg10, DEFAULTS, function() end, "MAGE")
eq(#rec10.subcategories, 0, "no subcategories")
eq(#rec10.settings, 42, "same controls")
for _, st in ipairs(rec10.settings) do eq(st.category, cat10, "all on one page: " .. tostring(st.key)) end
local h10 = {}
for _, h in ipairs(rec10.headers) do h10[#h10 + 1] = h.text end
eq(table.concat(h10, ","), "Warnings,Navigation,Ammo,Reagents,Supplies,Status window", "headers for every group")
local ammoCb10, reagentsCb10
for _, c in ipairs(rec10.checkboxes) do
    if c.setting.key == "ammoEnabled" then ammoCb10 = c end
    if c.setting.key == "reagentsEnabled" then reagentsCb10 = c end
end
local rs10
for _, sl in ipairs(rec10.sliders) do if sl.setting.key == "reagentThreshold" then rs10 = sl end end
eq(rs10.parent, reagentsCb10, "reagent slider hangs off the reagents switch, not the ammo switch")
local as10
for _, sl in ipairs(rec10.sliders) do if sl.setting.key == "ammoThreshold" then as10 = sl end end
eq(as10.parent, ammoCb10, "on one page the ammo slider hangs off the ammo switch")
for _, c in ipairs(rec10.checkboxes) do
    if c.setting.key == "foodEnabled" then eq(c.parent ~= ammoCb10, true, "the food switch does not hang off the ammo switch") end
end
eq(rec10.settings[#rec10.settings - 9].key, "hudLocked", "Lock still leads the window group")

-- Navigation: anchor dropdown and auction checkbox on the main page.
eq(ddByKey.instanceAnchor.setting.category, category, "anchor dropdown on the main page")
local anchors = {}
for _, o in ipairs(ddByKey.instanceAnchor.options) do anchors[#anchors + 1] = o.value end
eq(table.concat(anchors, ","), "hearth,last", "anchor choices")
eq(keys.instanceAnchor:GetValue(), "hearth", "anchor defaults to the hearthstone")
eq(cbByKey.suppliesEnabled.setting.name, "Supplies", "a Supplies checkbox in the Warnings section")
eq(cbByKey.suppliesEnabled.setting.category, category, "on the main page")
eq(keys.suppliesEnabled:GetValue(), true, "on by default")
eq(ddByKey.navProvider.setting.category, category, "waypoint dropdown on the main page")
local provs = {}
for _, o in ipairs(ddByKey.navProvider.options) do provs[#provs + 1] = o.value end
eq(table.concat(provs, ","), "auto,tomtom,waypointui,native", "waypoint choices")
eq(keys.navProvider:GetValue(), "auto", "waypoint defaults to automatic")
eq(keys.ahEnabled:GetValue(), false, "auction routing defaults to off")
eq(keys.ahEnabled.category, category, "auction checkbox on the main page")
eq(cbByKey.ahEnabled ~= nil, true, "auction checkbox exists")

-- The background colour swatch button: only where the client has a settings button and the game's
-- colour picker (Adapter.pickColor is passed in only then). The swatch shows the saved colour, the
-- button opens the picker at it and saves the pick.
local function withButtons(pick, saved)
    local Sb, recb = fake.new()
    _G.CreateSettingsButtonInitializer = function(name, text, onClick, tip)
        return { name = name, text = text, onClick = onClick, tip = tip, data = { buttonText = text } }
    end
    local nsb = load(Sb)
    local cfgb = {}
    for k, v in pairs(DEFAULTS) do cfgb[k] = v end
    cfgb.hudColor = saved or cfgb.hudColor
    local changed = 0
    nsb.Options.Register(cfgb, DEFAULTS, function() changed = changed + 1 end, "MAGE", pick)
    _G.CreateSettingsButtonInitializer = nil
    return recb, cfgb, function() return changed end
end
local opened
local recb, cfgb, changedb = withButtons(function(r, g, b, onPick) opened = { r, g, b }; onPick(1, 0, 0.5) end, "336699")
eq(#recb.buttons, 1, "a colour swatch button")
eq(recb.buttons[1].category.name, "Status window", "on the window page")
eq(recb.buttons[1].init.name, "Background color", "labelled")
eq(recb.buttons[1].init.text:find(":51:102:153|t", 1, true) ~= nil, true, "the swatch shows the saved colour (#336699)")
local recd = withButtons(function() end)
eq(recd.buttons[1].init.text:find(":0:0:0|t", 1, true) ~= nil, true, "a fresh install shows black")
for _, d in ipairs(recb.dropdowns) do eq(d.setting.key ~= "hudColor", true, "no colour dropdown") end
recb.buttons[1].init.onClick()
eq(table.concat(opened, ","), 0.2 .. "," .. 0.4 .. "," .. 0.6, "the picker opens at the saved colour")
eq(cfgb.hudColor .. "/" .. changedb(), "ff0080/1", "the picked colour is saved and reported")
eq(recb.buttons[1].init.data.buttonText:find(":255:0:128|t", 1, true) ~= nil, true, "and the swatch shows it")
cfgb.hudColor = "bad"
recb.buttons[1].init.onClick()
eq(table.concat(opened, ","), "0,0,0", "a saved colour that is not one opens at black")
local recn = withButtons(nil)
eq(#recn.buttons, 0, "no colour picker in the game: no control at all")
-- Each missing need is named in the note, so the debug report says why no swatch showed.
local function noteFor(pick, button, layout)
    local Sn, recz = fake.new(layout == false and "none" or layout == "method" and "method" or "return")
    _G.CreateSettingsButtonInitializer = button and function(name, text, onClick) return { onClick = onClick, data = {} } end or nil
    local nn = load(Sn)
    local c = {}
    for k, v in pairs(DEFAULTS) do c[k] = v end
    local notes = {}
    local okr = pcall(nn.Options.Register, c, DEFAULTS, function() end, "MAGE", pick, function(t) notes[#notes + 1] = t end)
    _G.CreateSettingsButtonInitializer = nil
    return okr, table.concat(notes, "|"), recz
end
local _, nAll, recz_ret = noteFor(function() end, true, true)
eq(nAll, "background color control built as a button; no swatch, missing: ColorPickerFrame:SetupColorPickerAndShow or :GetPreviousValues, Settings.CreateColorSwatch", "button built: said so, and why no swatch")
local _, nPick = noteFor(nil, true, true)
eq(nPick, "background color control not built, missing: color picker (ColorPickerFrame); no swatch, missing: color picker (ColorPickerFrame), Settings.CreateColorSwatch", "no picker named")
local _, nBtn = noteFor(function() end, false, true)
eq(nBtn:find("background color control not built, missing: CreateSettingsButtonInitializer;", 1, true) == 1, true, "no button maker named")
local _, nTwo = noteFor(nil, false, true)
local _, nLay = noteFor(function() end, true, false)
local _, nMeth, recMeth = noteFor(function() end, true, "method")
eq(nMeth:find("background color control built as a button", 1, true) == 1, true, "only category:GetLayout(): still built")
eq(#recMeth.buttons, 1, "swatch built through category:GetLayout()")
eq(#recMeth.headers > 0, true, "headers built through category:GetLayout()")
eq(#recz_ret.buttons, 1, "swatch built through the returned layout")
eq(nLay:find("page layout", 1, true) ~= nil and nLay:find("layout.AddInitializer", 1, true) ~= nil, true, "no layout named")
eq(nTwo:find("color picker", 1, true) ~= nil and nTwo:find("CreateSettingsButtonInitializer", 1, true) ~= nil, true, "all missing are listed")
eq(#rec.buttons, 0, "no settings button maker: no control either")

-- The game's own colour swatch row (Settings.CreateColorSwatch): built instead of the button where
-- the client has it and its picker takes the swatch's calls (swatchPicker). Its setting holds
-- "aarrggbb", read from and written to hudColor ("rrggbb").
local function withSwatch(opts, pick, swatchPicker, saved, layout)
    local Sw, recw = fake.new(layout or "return", opts)
    _G.CreateSettingsButtonInitializer = function(name, text, onClick, tip)
        return { name = name, text = text, onClick = onClick, tip = tip, data = { buttonText = text } }
    end
    local nw = load(Sw)
    local c = {}
    for k, v in pairs(DEFAULTS) do c[k] = v end
    c.hudColor = saved or c.hudColor
    local changed, notes = 0, {}
    nw.Options.Register(c, DEFAULTS, function() changed = changed + 1 end, "MAGE", pick,
        function(t) notes[#notes + 1] = t end, swatchPicker)
    _G.CreateSettingsButtonInitializer = nil
    return recw, c, function() return changed end, table.concat(notes, "|")
end
local pickAny = function() end
local recs, cfgs, changeds, notes = withSwatch({ swatch = true }, pickAny, true, "336699")
eq(#recs.swatches, 1, "a swatch row")
eq(#recs.buttons, 0, "and no button")
eq(notes, "background color control built as a swatch", "said so")
local sw = recs.swatches[1]
eq(sw.category.name, "Status window", "swatch on the window page")
eq(sw.setting.name, "Background color", "labelled")
eq(sw.setting.vtype, "string", "a string setting")
eq(sw.setting.variable, "CLOSESTVENDOR_HUD_COLOR", "with the addon's prefix")
eq(sw.setting.default, "ff000000", "black by default, in the game's aarrggbb form")
eq(sw.tip:find("color picker", 1, true) ~= nil, true, "keeps the tooltip")
eq(sw.setting:GetValue(), "ff336699", "shows the saved colour")
sw.setting:SetValue("FFFF0080") -- the player picks; the game writes upper or lower case hex
eq(cfgs.hudColor .. "/" .. changeds(), "ff0080/1", "the pick is saved as rrggbb and reported")
eq(sw.setting:GetValue(), "ffff0080", "and the swatch shows it")
cfgs.hudColor = "101820" -- /cvn hud color #101820 while the page is closed
eq(sw.setting:GetValue(), "ff101820", "a colour set by command shows the next time the page is shown")
cfgs.hudColor = "bad"
eq(sw.setting:GetValue(), "ff000000", "a saved colour that is not one shows black")
cfgs.hudColor = "ff0080"
sw.setting:SetValue("nonsense")
eq(cfgs.hudColor, "ff0080", "a value that is not a colour is ignored")
local wkeys2 = {}
for _, st in ipairs(recs.settings) do if st.category.name == "Status window" and st.key ~= "mode" then wkeys2[#wkeys2 + 1] = st.key end end
eq(table.concat(wkeys2, ","), "hudLocked,hudScale,hudAlpha,hudTextAlpha,hudColor", "swatch after the opacities")
local _, _, _, nNoLayout = withSwatch({ swatch = true }, pickAny, true, nil, "none")
eq(nNoLayout, "background color control built as a swatch", "the swatch needs no layout of ours (the game adds it)")
-- Fallbacks to the button, each naming what the swatch lacked.
local recf, _, _, nf = withSwatch({ swatch = true }, pickAny, nil)
eq(#recf.swatches .. "/" .. #recf.buttons, "0/1", "picker without the swatch's calls: button")
eq(nf, "background color control built as a button; no swatch, missing: ColorPickerFrame:SetupColorPickerAndShow or :GetPreviousValues", "and why")
local recg, _, _, ng = withSwatch(nil, pickAny, true)
eq(#recg.swatches .. "/" .. #recg.buttons, "0/1", "no Settings.CreateColorSwatch: button")
eq(ng, "background color control built as a button; no swatch, missing: Settings.CreateColorSwatch", "and why")
local rech, cfgh, _, nh = withSwatch({ swatchThrows = true }, pickAny, true)
eq(#rech.buttons, 1, "a swatch that raises an error: button instead, page still built")
eq(rech.registered ~= nil, true, "the page is still registered")
eq(nh, "background color control built as a button; no swatch, missing: Settings.CreateColorSwatch failed: swatch template missing", "the error is named")
eq(cfgh.hudColor, "000000", "the failed swatch left the colour alone")
local reci, _, _, ni = withSwatch({ swatch = true }, nil, true)
eq(#reci.swatches .. "/" .. #reci.buttons, "0/0", "no picker at all: neither")
eq(ni:find("background color control not built", 1, true) == 1, true, "said so")

-- Supplies page: food for every class, water for mana users, pet food for hunters, the healthstone reminder for warlocks.
local function supplyKeys(cls)
    local Sx, recx = fake.new()
    local nsx = load(Sx)
    local cx = {}
    for k, v in pairs(DEFAULTS) do cx[k] = v end
    cx.reagentOff = {}
    nsx.Options.Register(cx, DEFAULTS, function() end, cls)
    local sub
    for _, c in ipairs(recx.subcategories) do if c.name == "Supplies" then sub = c end end
    local out = {}
    for _, st in ipairs(recx.settings) do if st.category == sub then out[#out + 1] = st.key end end
    return table.concat(out, ","), recx
end
eq((supplyKeys("MAGE")), "foodEnabled,foodThreshold,waterEnabled,waterThreshold,remindSound", "mage: food, water and the reminder sound")
eq((supplyKeys("WARRIOR")), "foodEnabled,foodThreshold,remindSound", "warrior: food and the sound")
eq((supplyKeys("ROGUE")), "foodEnabled,foodThreshold,remindSound", "rogue: food and the sound, no water")
eq((supplyKeys("HUNTER")), "foodEnabled,foodThreshold,waterEnabled,waterThreshold,petFoodEnabled,petFoodThreshold,remindSound", "hunter: food, water, pet food and the sound")
eq((supplyKeys("WARLOCK")), "foodEnabled,foodThreshold,waterEnabled,waterThreshold,healthstoneRemind,remindSound", "warlock: food, water, the healthstone reminder and the sound")
eq((supplyKeys("PRIEST")):find("petFood", 1, true), nil, "no pet food for a priest")
do
    local _, recx = supplyKeys("HUNTER")
    local sl = {}
    for _, s in ipairs(recx.sliders) do sl[s.setting.key] = s end
    eq(sl.petFoodThreshold.options.min .. "-" .. sl.petFoodThreshold.options.max, "1-40", "pet food limits are the command limits")
    eq(sl.foodThreshold.options.min .. "-" .. sl.foodThreshold.options.max, table.concat(ns.Commands.LIMITS.food, "-"), "food limits match /cvn food")
    local cb = {}
    for _, c in ipairs(recx.checkboxes) do cb[c.setting.key] = c end
    eq(sl.petFoodThreshold.parent, cb.petFoodEnabled, "the slider hangs off its own switch")
    eq(cb.petFoodEnabled.setting.name, "Pet food", "labelled")
end

-- The reminder sound: only a class that is reminded has it; choosing one plays it; the choices are the shared list.
eq((supplyKeys("HUNTER")):find("remindSound", 1, true) ~= nil, true, "every class sees the sound choice")
do
    local Sx, recx = fake.new()
    local nsx = load(Sx)
    local played = {}
    nsx.Adapter = { playSound = function(id) played[#played + 1] = id end }
    local cx = {}
    for k, v in pairs(DEFAULTS) do cx[k] = v end
    cx.reagentOff = {}
    local changed = 0
    nsx.Options.Register(cx, DEFAULTS, function() changed = changed + 1 end, "MAGE")
    local dd
    for _, d in ipairs(recx.dropdowns) do if d.setting.key == "remindSound" then dd = d end end
    eq(dd ~= nil, true, "a sound dropdown")
    eq(dd.setting:GetValue(), "whisper", "defaults to the whisper ping")
    local labels = {}
    for _, o in ipairs(dd.choices or {}) do labels[#labels + 1] = o[1] end
    eq(#nsx.Supplies.SOUNDS, 5, "five choices")
    dd.setting:SetValue("ping")
    eq(cx.remindSound, "ping", "saved as a key")
    eq(played[#played], 3175, "choosing plays the sound")
    dd.setting:SetValue("none")
    eq(#played, 1, "none plays nothing")
    eq(changed >= 2, true, "the page's change callback still runs")
end

H.done()
