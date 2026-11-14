-- Settings page under Options, AddOns. Uses the native Settings API (Era and Forever).
-- Every control is bound to the saved `cfg` table, the same one the slash commands edit.
local _, ns = ...

local L = ns.L

local O = {}
ns.Options = O

local ROWS = {
    { key = "bag", label = L["Bag space"], slider = L["Ask when free slots are at or below"],
      tip = L["Ask about the nearest vendor when your free bag slots drop to this number or fewer."], step = 1 },
    { key = "dur", label = L["Durability"], slider = L["Ask when an item is below (%)"],
      tip = L["Ask about the nearest repair vendor when any equipped item falls below this durability."], step = 1,
      format = function(v) return v .. "%" end },
    { key = "trade", label = L["Professions"], slider = L["Ask when a skill is this close to its limit"],
      tip = L["Ask about the nearest trainer when a profession is this many points or fewer from its current skill limit."], step = 1 },
}

-- Every settings page is a subcategory of the main one. A client without subcategories gets one page:
-- page() hands back the parent, and a section header separates the groups instead.
-- The layout (it has AddInitializer) is the second value the Register calls return; a client that
-- has category:GetLayout() instead is read through that. layoutOf(category) is nil when neither exists.
local layouts = setmetatable({}, { __mode = "k" })
local function remember(category, layout)
    if category and not layout and type(category) == "table" and category.GetLayout then
        local ok, l = pcall(category.GetLayout, category)
        if ok then layout = l end
    end
    if category and layout then layouts[category] = layout end
    return category
end
local function layoutOf(category) return layouts[category] end

local function page(parent, name)
    if Settings.RegisterVerticalLayoutSubcategory then
        local sub = remember(Settings.RegisterVerticalLayoutSubcategory(parent, name))
        if sub then return sub end
    end
    return parent
end

-- A section header, where the client can draw one.
local function header(category, text)
    local layout = layoutOf(category)
    if layout and layout.AddInitializer and CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end
end

local hasDropdown = function()
    return Settings.CreateDropdown and Settings.CreateControlTextContainer and Settings.VarType.String
end

-- A dropdown on a string key; choices is { { value, label }, ... }.
local function dropdown(category, cfg, defaults, onChange, variable, key, label, choices, tip)
    local setting = Settings.RegisterAddOnSetting(category, variable, key, cfg, Settings.VarType.String, label, defaults[key])
    Settings.CreateDropdown(category, setting, function()
        local c = Settings.CreateControlTextContainer()
        for _, o in ipairs(choices) do c:Add(o[1], o[2]) end
        return c:GetData()
    end, tip)
    setting:SetValueChangedCallback(onChange)
    return setting
end

-- The status window row groups of the settings page, in window order: { group key, reason }. One
-- dropdown per group sets every row of it (each profession, each reagent and display-only item).
-- A group with a reason does not apply to the class: it is shown greyed out, never written to hudRow.
local AMMO_CLASSES = { HUNTER = true, ROGUE = true, WARRIOR = true }

local function windowRows(class)
    local rows = {}
    for _, group in ipairs(ns.Status.GROUPS) do
        local reason
        -- A class without ammo or reagents still sees the row, greyed out, with the reason as its tooltip.
        if group == "ammo" and not AMMO_CLASSES[class] then reason = L["Your class does not use ammo."] end
        if group == "reagents" and #ns.Reagents.ForClass(class) == 0 and #ns.Reagents.DisplayOnly(class) == 0 then
            reason = L["Your class does not use reagents."]
        end
        rows[#rows + 1] = { group, reason }
    end
    return rows
end

-- Reagent buying, at the end of the Reagents page: buy, ask first, and how many of each to carry.
-- The ask checkbox and the amount slider are greyed while buying is off. For a class without
-- vendor-sold reagents all three are greyed out (the same modify predicate as the window rows) with
-- the reason as their tooltip.
local function registerReagentBuying(category, cfg, defaults, onChange, class)
    local reason = #ns.Reagents.ForClass(class) == 0 and L["Your class does not use reagents."] or nil
    local buy = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_REAGENTBUY_ENABLED", "reagentBuyEnabled", cfg,
        Settings.VarType.Boolean, L["Buy reagents"], defaults.reagentBuyEnabled)
    local buyBox = Settings.CreateCheckbox(category, buy,
        reason or L["When a merchant window opens, buy the class reagents you use until you carry the amount below of each."])
    local ask = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_REAGENTBUY_PROMPT", "reagentBuyPrompt", cfg,
        Settings.VarType.Boolean, L["Ask before buying reagents"], defaults.reagentBuyPrompt)
    local askBox = Settings.CreateCheckbox(category, ask,
        reason or L["Show the reagents, counts and price and wait for a Yes instead of buying at once."])
    local amount = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_REAGENTBUY_TARGET", "reagentBuyTarget", cfg,
        Settings.VarType.Number, L["Reagents to carry of each"], defaults.reagentBuyTarget)
    local limits = ns.Commands.LIMITS.reagentBuyTarget
    local options = Settings.CreateSliderOptions(limits[1], limits[2], 1)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    local slider = Settings.CreateSlider(category, amount, options,
        reason or L["Buy until you carry this many of each class reagent, counting what is in your bags. 0 buys none."])
    for _, init in ipairs({ askBox, slider }) do
        if init and init.SetParentInitializer then
            init:SetParentInitializer(buyBox, function() return buy:GetValue() end)
        end
    end
    if reason then
        for _, init in ipairs({ buyBox, askBox, slider }) do
            if init and init.AddModifyPredicate then init:AddModifyPredicate(function() return false end) end
        end
    end
    for _, setting in ipairs({ buy, ask, amount }) do setting:SetValueChangedCallback(onChange) end
end

-- The reagent slider and one checkbox per reagent of the player's class. The saved setting is a list
-- of reagents switched off, so a checkbox shows "on" when the item is not in it: a small proxy table
-- turns that around, and anything not switched off (including reagents added later) is on.
-- masterCheckbox/masterSetting (the Reagents switch on the main page) only grey these out when they share the page.
local function registerReagents(category, cfg, defaults, onChange, class, masterCheckbox, masterSetting)
    local amount = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_REAGENT_THRESHOLD", "reagentThreshold", cfg,
        Settings.VarType.Number, L["Ask when a reagent is at or below"], defaults.reagentThreshold)
    local limits = ns.Commands.LIMITS.reagent
    local options = Settings.CreateSliderOptions(limits[1], limits[2], 1)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    local slider = Settings.CreateSlider(category, amount, options,
        L["Ask about the nearest vendor selling a class reagent when you have this many or fewer."])
    amount:SetValueChangedCallback(onChange)
    local function underMaster(initializer)
        if masterCheckbox and initializer.SetParentInitializer then
            initializer:SetParentInitializer(masterCheckbox, function() return masterSetting:GetValue() end)
        end
    end
    underMaster(slider)
    cfg.reagentOff = cfg.reagentOff or {}
    local proxy = setmetatable({}, {
        __index = function(_, id) return not cfg.reagentOff[id] end,
        __newindex = function(_, id, on) cfg.reagentOff[id] = (not on) or nil end,
    })
    for _, item in ipairs(ns.Reagents.ForClass(class)) do
        local setting = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_REAGENT_" .. item.id, item.id, proxy,
            Settings.VarType.Boolean, L["Reagent: %s"]:format(item.name), true)
        underMaster(Settings.CreateCheckbox(category, setting, L["Ask about this reagent when it runs low, and buy it when reagent buying is on."]))
        setting:SetValueChangedCallback(onChange)
    end
    registerReagentBuying(category, cfg, defaults, onChange, class)
end

-- Food, water and pet food: a switch and a threshold slider each (the slider greys out with its switch),
-- and the warlock's healthstone reminder. Only what the class uses is listed: water for mana users, pet food
-- for hunters, the healthstone reminder for warlocks.
local function registerSupplies(category, cfg, defaults, onChange, class, masterCheckbox, masterSetting)
    local function underMaster(initializer)
        if masterCheckbox and initializer.SetParentInitializer then
            initializer:SetParentInitializer(masterCheckbox, function() return masterSetting:GetValue() end)
        end
    end
    local function row(key, tag, label, sliderLabel, tip)
        local on = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_" .. tag .. "_ENABLED", key .. "Enabled", cfg,
            Settings.VarType.Boolean, label, defaults[key .. "Enabled"])
        local checkbox = Settings.CreateCheckbox(category, on, tip)
        underMaster(checkbox)
        local amount = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_" .. tag .. "_THRESHOLD", key .. "Threshold", cfg,
            Settings.VarType.Number, sliderLabel, defaults[key .. "Threshold"])
        local limits = ns.Commands.LIMITS[key]
        local options = Settings.CreateSliderOptions(limits[1], limits[2], 1)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        local slider = Settings.CreateSlider(category, amount, options, tip)
        if slider.SetParentInitializer then slider:SetParentInitializer(checkbox, function() return on:GetValue() end) end
        on:SetValueChangedCallback(onChange)
        amount:SetValueChangedCallback(onChange)
    end
    row("food", "FOOD", L["Food"], L["Ask when food is at or below"],
        L["Ask about the nearest vendor selling food when you carry this many food items or fewer. A mage who can conjure food is reminded instead."])
    if ns.Supplies.UsesMana(class) then
        row("water", "WATER", L["Water"], L["Ask when water is at or below"],
            L["Ask about the nearest vendor selling drink when you carry this many drinks or fewer. A mage who can conjure water is reminded instead."])
    end
    if class == "HUNTER" then
        row("petFood", "PETFOOD", L["Pet food"], L["Ask when pet food is at or below"],
            L["Ask about the nearest vendor selling food your pet eats when you carry this many of it or fewer. Nothing is asked while no pet is out."])
    end
    if class == "WARLOCK" then
        local remind = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_HEALTHSTONE_REMIND", "healthstoneRemind", cfg,
            Settings.VarType.Boolean, L["Healthstone reminder"], defaults.healthstoneRemind)
        underMaster(Settings.CreateCheckbox(category, remind, L["Remind you to create a healthstone when you know the spell and carry none."]))
        remind:SetValueChangedCallback(onChange)
    end
    -- Every class sees it (the command works for all); only a mage or a warlock is reminded. Choosing plays it.
    local choices = {}
    for _, sound in ipairs(ns.Supplies.SOUNDS) do choices[#choices + 1] = { sound[1], sound[3] } end
    local setting = dropdown(category, cfg, defaults, onChange, "CLOSESTVENDOR_REMIND_SOUND", "remindSound",
        L["Reminder sound"], choices, L["The sound that plays when a mage is reminded to conjure food or water, or a warlock to create a healthstone."])
    setting:SetValueChangedCallback(function(...)
        onChange(...)
        if ns.Adapter then ns.Adapter.playSound(ns.Supplies.SoundId(setting:GetValue())) end
    end)
end

-- Ammo: its threshold (the switch is in Warnings on the main page), then buying. The grade dropdowns need a newer part of the API; without it
-- use /cvn arrows and /cvn bullets.
local function registerAmmoBuying(category, cfg, defaults, onChange, masterCheckbox, masterSetting)
    local amount = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_AMMO_THRESHOLD", "ammoThreshold", cfg,
        Settings.VarType.Number, L["Ask when ammo is at or below"], defaults.ammoThreshold)
    local limits = ns.Commands.LIMITS.ammo
    local options = Settings.CreateSliderOptions(limits[1], limits[2], 50)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    local slider = Settings.CreateSlider(category, amount, options,
        L["Ask about the nearest vendor selling your ammo when the equipped ammo drops to this number or fewer."])
    if masterCheckbox and slider.SetParentInitializer then
        slider:SetParentInitializer(masterCheckbox, function() return masterSetting:GetValue() end)
    end
    amount:SetValueChangedCallback(onChange)
    local buy = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_AMMOBUY_ENABLED", "ammoBuyEnabled", cfg,
        Settings.VarType.Boolean, L["Buy ammo"], defaults.ammoBuyEnabled)
    Settings.CreateCheckbox(category, buy, L["Fill your quiver or ammo pouch with ammo when a merchant window opens."])
    local ask = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_AMMOBUY_PROMPT", "ammoBuyPrompt", cfg,
        Settings.VarType.Boolean, L["Ask before buying ammo"], defaults.ammoBuyPrompt)
    Settings.CreateCheckbox(category, ask, L["Show the count and price and wait for a Yes instead of buying at once."])
    buy:SetValueChangedCallback(onChange)
    ask:SetValueChangedCallback(onChange)
    if not hasDropdown() then return end
    local grades = { { "equipped", L["same as equipped"] }, { "best", L["best usable"] }, { "cheapest", L["cheapest"] } }
    local tip = L["Same as equipped buys what is in your ammo slot. Best usable buys the highest grade you are high enough level for. Cheapest buys the lowest price per piece."]
    dropdown(category, cfg, defaults, onChange, "CLOSESTVENDOR_ARROW_GRADE", "arrowGrade", L["Arrows to buy"], grades, tip)
    dropdown(category, cfg, defaults, onChange, "CLOSESTVENDOR_BULLET_GRADE", "bulletGrade", L["Bullets to buy"], grades, tip)
end

-- The background colour swatch: a texture tinted with the colour, as the button's text.
local function swatch(hex)
    local r, g, b = ns.Status.Color(hex)
    if not r then r, g, b = 0, 0, 0 end
    return string.format("|TInterface\\Buttons\\WHITE8X8:16:48:0:0:8:8:0:8:0:8:%d:%d:%d|t",
        math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local COLOR_TIP = L["Click the swatch to choose any color for the status window background with the game's color picker. Black is the default and the kindest to an OLED screen; /cvn hud color black puts it back."]

-- The game's own colour swatch row (Settings.CreateColorSwatch, in Blizzard_Settings_Shared on Era
-- and Forever): label on the left, a small bordered square on the right that opens ColorPickerFrame.
-- Its setting holds "aarrggbb" (what CreateColorFromHexString reads and GenerateHexColor writes), so
-- a proxy turns cfg.hudColor ("rrggbb") into that and back; anything that is not a colour is ignored.
-- The value is read each time the page is shown, so /cvn hud color shows on the next visit.
-- Returns true when the row was added; false and the error when the game refused it.
local function nativeSwatch(category, cfg, onChange)
    local proxy = setmetatable({}, {
        __index = function()
            return "ff" .. (ns.Status.Color(cfg.hudColor) and cfg.hudColor:lower() or ns.Status.BLACK)
        end,
        __newindex = function(_, _, value)
            local hex = type(value) == "string" and value:match("^%x%x(%x%x%x%x%x%x)$")
            if hex then cfg.hudColor = hex:lower() end
        end,
    })
    return pcall(function()
        local setting = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_HUD_COLOR", "hudColor", proxy,
            Settings.VarType.String, L["Background color"], "ff" .. ns.Status.BLACK)
        Settings.CreateColorSwatch(category, setting, COLOR_TIP)
        setting:SetValueChangedCallback(onChange)
    end)
end

-- The background colour. Best: the game's swatch row (nativeSwatch), where the client has
-- Settings.CreateColorSwatch and a picker that takes its calls (swatchPicker). Otherwise a settings
-- button whose text is a tinted square, opening the picker through pickColor, where the client has a
-- button maker, a page layout and a picker. Without any of that there is no control (it would do
-- nothing) and /cvn hud color still sets it. Both are read when the page is shown, so a colour set by
-- command appears the next time the page opens.
-- note(text) is told which control was built and exactly which needs are missing for the others.
local function colorControls(category, cfg, onChange, pickColor, note, swatchPicker)
    local noSwatch = {}
    if not pickColor then noSwatch[#noSwatch + 1] = "color picker (ColorPickerFrame)"
    elseif not swatchPicker then noSwatch[#noSwatch + 1] = "ColorPickerFrame:SetupColorPickerAndShow or :GetPreviousValues" end
    if not (Settings.CreateColorSwatch and Settings.VarType.String) then noSwatch[#noSwatch + 1] = "Settings.CreateColorSwatch" end
    if #noSwatch == 0 then
        local ok, err = nativeSwatch(category, cfg, onChange)
        if ok then
            if note then note("background color control built as a swatch") end
            return
        end
        noSwatch = { "Settings.CreateColorSwatch failed: " .. tostring(err) }
    end
    local layout = layoutOf(category)
    local missing = {}
    if not pickColor then missing[#missing + 1] = "color picker (ColorPickerFrame)" end
    if not layout then missing[#missing + 1] = "page layout (second value of Settings.RegisterVerticalLayoutCategory, or category:GetLayout())" end
    if not (layout and layout.AddInitializer) then missing[#missing + 1] = "layout.AddInitializer" end
    if not CreateSettingsButtonInitializer then missing[#missing + 1] = "CreateSettingsButtonInitializer" end
    if #missing > 0 then
        if note then
            note("background color control not built, missing: " .. table.concat(missing, ", ")
                .. "; no swatch, missing: " .. table.concat(noSwatch, ", "))
        end
        return
    end
    local init
    init = CreateSettingsButtonInitializer(L["Background color"], swatch(cfg.hudColor), function()
        local r, g, b = ns.Status.Color(cfg.hudColor)
        if not r then r, g, b = 0, 0, 0 end
        pickColor(r, g, b, function(nr, ng, nb)
            cfg.hudColor = ns.Status.Hex(nr, ng, nb)
            if init and init.data then init.data.buttonText = swatch(cfg.hudColor) end
            onChange()
        end)
    end, COLOR_TIP, true)
    layout:AddInitializer(init)
    if note then note("background color control built as a button; no swatch, missing: " .. table.concat(noSwatch, ", ")) end
end

-- The status window page: Lock first, then scale, background opacity, text opacity, the background
-- colour and one mode dropdown per row group.
-- swatchPicker: see O.Register.
-- hudRow holds only the modes the player changed; a group not in it shows the default.
-- pickColor(r, g, b, onPick) opens the game's colour picker; nil where there is none.
local function registerWindow(category, cfg, defaults, onChange, class, pickColor, note, swatchPicker)
    local lock = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_HUD_LOCKED", "hudLocked", cfg,
        Settings.VarType.Boolean, L["Lock window position"], defaults.hudLocked)
    Settings.CreateCheckbox(category, lock, L["Stop the status window from being moved, Shift-drag included."])
    lock:SetValueChangedCallback(onChange)
    for _, s in ipairs({
        { "hudScale", "SCALE", L["Window scale (%)"], 5, L["Size of the status window, in percent of normal."] },
        { "hudAlpha", "ALPHA", L["Background opacity (%)"], 5, L["How solid the status window background is, in percent. At 0 no background is drawn: only the text and icons show."] },
        { "hudTextAlpha", "TEXT_ALPHA", L["Text and icon opacity (%)"], 5, L["How solid the status window text and icons are, in percent."] },
    }) do
        local setting = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_HUD_" .. s[2], s[1], cfg,
            Settings.VarType.Number, s[3], defaults[s[1]])
        local limits = ns.Commands.LIMITS[s[1]]
        local options = Settings.CreateSliderOptions(limits[1], limits[2], s[4])
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        Settings.CreateSlider(category, setting, options, s[5])
        setting:SetValueChangedCallback(onChange)
    end
    colorControls(category, cfg, onChange, pickColor, note, swatchPicker)
    if not hasDropdown() then return end
    if type(cfg.hudRow) ~= "table" then cfg.hudRow = {} end
    local modes = { { "low", L["Only when low"] }, { "always", L["Always"] }, { "never", L["Never"] } }
    local tip = L["Only when low shows the row while it needs attention. Always keeps it in the window. Never hides it."]
    local default = ns.Status.DEFAULT_MODE
    for _, row in ipairs(windowRows(class)) do
        local key, reason = row[1], row[2]
        local proxy = setmetatable({}, {
            __index = function() return not reason and cfg.hudRow[key] or default end,
            __newindex = function(_, _, mode) if not reason then cfg.hudRow[key] = mode end end,
        })
        local setting = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_HUDROW_" .. key:upper():gsub("[^%w]", "_"),
            "mode", proxy, Settings.VarType.String, L["Show: %s"]:format(ns.Status.KeyName(key)), default)
        local init = Settings.CreateDropdown(category, setting, function()
            local c = Settings.CreateControlTextContainer()
            for _, o in ipairs(modes) do c:Add(o[1], o[2]) end
            return c:GetData()
        end, reason or tip)
        -- The game's own way to grey a row out: a modify predicate (Blizzard_SettingControls.lua,
        -- SettingsElementHierarchyMixin:AddModifyPredicate, as Accessibility.lua uses it). Without it the
        -- row stays usable but writes nothing.
        if reason and init and init.AddModifyPredicate then init:AddModifyPredicate(function() return false end) end
        setting:SetValueChangedCallback(onChange)
    end
end

-- cfg: saved settings table. defaults: default value per cfg key. onChange: called after any change.
-- class: the player's class token, for the reagent and row lists (no list without it).
-- pickColor: opens the game's colour picker (Adapter.pickColor), or nil when the client has none.
-- note(text): told which background colour control was built (swatch or button) and what was missing.
-- swatchPicker: true when the game's picker takes the calls of the game's own settings swatch
-- (Adapter.hasSwatchPicker); the swatch row is only built then.
-- Returns the main category, or nothing if the client has no usable settings API.
function O.Register(cfg, defaults, onChange, class, pickColor, note, swatchPicker)
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting
            and Settings.CreateCheckbox and Settings.CreateSlider and Settings.CreateSliderOptions) then
        if note then note("background color control not built, missing: the Settings API (no settings page)") end
        return
    end
    local category = remember(Settings.RegisterVerticalLayoutCategory(L["Closest Vendor"]))
    header(category, L["Warnings"])
    local ammoSwitch, ammoSetting, reagentsSwitch, reagentsSetting, suppliesSwitch, suppliesSetting
    for _, row in ipairs(ROWS) do
        local tag = row.key:upper()
        local on = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_" .. tag .. "_ENABLED",
            row.key .. "Enabled", cfg, Settings.VarType.Boolean, row.label, defaults[row.key .. "Enabled"])
        local checkbox = Settings.CreateCheckbox(category, on, row.tip)

        local amount = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_" .. tag .. "_THRESHOLD",
            row.key .. "Threshold", cfg, Settings.VarType.Number, row.slider, defaults[row.key .. "Threshold"])
        local limits = ns.Commands.LIMITS[row.key]
        local options = Settings.CreateSliderOptions(limits[1], limits[2], row.step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, row.format)
        local slider = Settings.CreateSlider(category, amount, options, row.tip)
        -- The slider is greyed out while its trigger is off.
        if slider.SetParentInitializer then
            slider:SetParentInitializer(checkbox, function() return on:GetValue() end)
        end

        on:SetValueChangedCallback(onChange)
        amount:SetValueChangedCallback(onChange)
    end
    -- Ammo, reagents and supplies: one switch each here; their thresholds and details are on their own pages.
    local function switchRow(key, tag, label, tip)
        local setting = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_" .. tag .. "_ENABLED", key, cfg,
            Settings.VarType.Boolean, label, defaults[key])
        local checkbox = Settings.CreateCheckbox(category, setting, tip)
        setting:SetValueChangedCallback(onChange)
        return checkbox, setting
    end
    ammoSwitch, ammoSetting = switchRow("ammoEnabled", "AMMO", L["Ammo"],
        L["Ask about the nearest vendor selling your ammo when the equipped ammo runs low. Set the amount on the Ammo page."])
    reagentsSwitch, reagentsSetting = switchRow("reagentsEnabled", "REAGENTS", L["Reagents"],
        L["Ask about the nearest vendor selling a class reagent when it runs low. Set the amount and each reagent on the Reagents page."])
    suppliesSwitch, suppliesSetting = switchRow("suppliesEnabled", "SUPPLIES", L["Supplies"],
        L["Ask about the nearest vendor when food, water or pet food runs low, and remind a mage or warlock who can make their own. Set each one on the Supplies page."])
    local notice = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_AUTO_NOTICE", "autoNotice", cfg,
        Settings.VarType.Boolean, L["On-screen notice"], defaults.autoNotice)
    Settings.CreateCheckbox(category, notice, L["Show a message on screen when a target is chosen without asking."])
    notice:SetValueChangedCallback(onChange)

    -- Navigation: which target to take, where to search from inside an instance, auctioneers.
    header(category, L["Navigation"])
    if hasDropdown() then
        dropdown(category, cfg, defaults, onChange, "CLOSESTVENDOR_VENDOR_MODE", "vendorMode",
            L["When the closest target is on another map"],
            { { "ask", L["Ask which one"] }, { "auto", L["Navigate without asking"] } },
            L["Ask shows both targets and lets you pick. Navigate without asking sets the waypoint at once using the preference below."])
        dropdown(category, cfg, defaults, onChange, "CLOSESTVENDOR_VENDOR_PREFER", "vendorPrefer", L["Preferred target"],
            { { "map", L["On your map"] }, { "distance", L["Closest"] } },
            L["On your map prefers the nearest target in the zone you are in. Closest prefers the nearest by distance, whatever the map."])
        local providers = {}
        for _, p in ipairs(ns.Nav.PROVIDERS) do providers[#providers + 1] = { p[1], p[2] } end
        dropdown(category, cfg, defaults, onChange, "CLOSESTVENDOR_NAV_PROVIDER", "navProvider", L["Waypoint"], providers,
            L["Automatic uses TomTom if you have it, then WaypointUI, then the game's own waypoint. Choose one to use it first; if it is not available the usual order applies."])
        dropdown(category, cfg, defaults, onChange, "CLOSESTVENDOR_INSTANCE_ANCHOR", "instanceAnchor",
            L["Search from, inside an instance"],
            { { "hearth", L["Hearthstone location"] }, { "last", L["Last outdoor position"] } },
            L["Clicking a status window row inside a dungeon or raid looks for the closest vendor to this place."])
    end
    local ah = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_AH_ENABLED", "ahEnabled", cfg,
        Settings.VarType.Boolean, L["Route to the auction house"], defaults.ahEnabled)
    Settings.CreateCheckbox(category, ah, L["When a status window row item can be traded, navigate to the auction house if it is closer than a vendor."])
    ah:SetValueChangedCallback(onChange)

    -- The pages are in alphabetical order, with the status window last.
    local ammo = page(category, L["Ammo"])
    if ammo == category then header(category, L["Ammo"]) end
    registerAmmoBuying(ammo, cfg, defaults, onChange, ammo == category and ammoSwitch or nil, ammoSetting)

    local reagents = page(category, L["Reagents"])
    if reagents == category then header(category, L["Reagents"]) end
    registerReagents(reagents, cfg, defaults, onChange, class, reagents == category and reagentsSwitch or nil, reagentsSetting)

    local supplies = page(category, L["Supplies"])
    if supplies == category then header(category, L["Supplies"]) end
    registerSupplies(supplies, cfg, defaults, onChange, class, supplies == category and suppliesSwitch or nil, suppliesSetting)

    local window = page(category, L["Status window"])
    if window == category then header(category, L["Status window"]) end
    registerWindow(window, cfg, defaults, onChange, class, pickColor, note, swatchPicker)

    Settings.RegisterAddOnCategory(category)
    return category
end

function O.Open(category)
    Settings.OpenToCategory(category:GetID())
end
