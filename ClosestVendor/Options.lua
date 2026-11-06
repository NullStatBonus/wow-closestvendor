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
    Settings.RegisterAddOnCategory(category)
    return category
end

function O.Open(category)
    Settings.OpenToCategory(category:GetID())
end
