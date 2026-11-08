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
    { key = "ammo", label = L["Ammo"], slider = L["Ask when ammo is at or below"],
      tip = L["Ask about the nearest vendor selling your ammo when the equipped ammo drops to this number or fewer."], step = 50 },
    { key = "trade", label = L["Professions"], slider = L["Ask when a skill is this close to its limit"],
      tip = L["Ask about the nearest trainer when a profession is this many points or fewer from its current skill limit."], step = 1 },
}

-- cfg: saved settings table. defaults: default value per cfg key. onChange: called after any change.
-- Returns the category, or nothing if the client has no usable settings API.
function O.Register(cfg, defaults, onChange)
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting
            and Settings.CreateCheckbox and Settings.CreateSlider and Settings.CreateSliderOptions) then
        return
    end
    local category = Settings.RegisterVerticalLayoutCategory(L["Closest Vendor"])
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
    -- Ammo buying. The grade dropdowns need a newer part of the API; without it use /cvn arrows and /cvn bullets.
    local buy = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_AMMOBUY_ENABLED", "ammoBuyEnabled", cfg,
        Settings.VarType.Boolean, L["Buy ammo"], defaults.ammoBuyEnabled)
    Settings.CreateCheckbox(category, buy, L["Fill your quiver or ammo pouch with ammo when a merchant window opens."])
    local ask = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_AMMOBUY_PROMPT", "ammoBuyPrompt", cfg,
        Settings.VarType.Boolean, L["Ask before buying ammo"], defaults.ammoBuyPrompt)
    Settings.CreateCheckbox(category, ask, L["Show the count and price and wait for a Yes instead of buying at once."])
    buy:SetValueChangedCallback(onChange)
    ask:SetValueChangedCallback(onChange)
    if Settings.CreateDropdown and Settings.CreateControlTextContainer and Settings.VarType.String then
        local function choices()
            local c = Settings.CreateControlTextContainer()
            c:Add("equipped", L["same as equipped"])
            c:Add("best", L["best usable"])
            c:Add("cheapest", L["cheapest"])
            return c:GetData()
        end
        for _, g in ipairs({ { "arrowGrade", "ARROW", L["Arrows to buy"] }, { "bulletGrade", "BULLET", L["Bullets to buy"] } }) do
            local setting = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_" .. g[2] .. "_GRADE", g[1], cfg,
                Settings.VarType.String, g[3], defaults[g[1]])
            Settings.CreateDropdown(category, setting, choices,
                L["Same as equipped buys what is in your ammo slot. Best usable buys the highest grade you are high enough level for. Cheapest buys the lowest price per piece."])
            setting:SetValueChangedCallback(onChange)
        end
    end
    local notice = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_AUTO_NOTICE", "autoNotice", cfg,
        Settings.VarType.Boolean, L["On-screen notice"], defaults.autoNotice)
    Settings.CreateCheckbox(category, notice, L["Show a message on screen when a target is chosen without asking."])
    notice:SetValueChangedCallback(onChange)
    -- Which target to take when the closest is on another map; like the grades, needs the dropdown API.
    if Settings.CreateDropdown and Settings.CreateControlTextContainer and Settings.VarType.String then
        local rows = {
            { "vendorMode", "VENDOR_MODE", L["When the closest target is on another map"], {
                { "ask", L["Ask which one"] }, { "auto", L["Navigate without asking"] } },
              L["Ask shows both targets and lets you pick. Navigate without asking sets the waypoint at once using the preference below."] },
            { "vendorPrefer", "VENDOR_PREFER", L["Preferred target"], {
                { "map", L["On your map"] }, { "distance", L["Closest"] } },
              L["On your map prefers the nearest target in the zone you are in. Closest prefers the nearest by distance, whatever the map."] },
        }
        for _, r in ipairs(rows) do
            local setting = Settings.RegisterAddOnSetting(category, "CLOSESTVENDOR_" .. r[2], r[1], cfg,
                Settings.VarType.String, r[3], defaults[r[1]])
            Settings.CreateDropdown(category, setting, function()
                local c = Settings.CreateControlTextContainer()
                for _, o in ipairs(r[4]) do c:Add(o[1], o[2]) end
                return c:GetData()
            end, r[5])
            setting:SetValueChangedCallback(onChange)
        end
    end
    Settings.RegisterAddOnCategory(category)
    return category
end

function O.Open(category)
    Settings.OpenToCategory(category:GetID())
end
