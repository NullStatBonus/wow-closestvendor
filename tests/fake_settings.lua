-- Fake of the Blizzard Settings API (vertical layout) that records what an addon registers.
local M = {}

function M.new()
    local rec = { settings = {}, checkboxes = {}, sliders = {}, dropdowns = {} }
    local S = { VarType = { Boolean = "boolean", Number = "number", String = "string" } }

    function S.RegisterVerticalLayoutCategory(name)
        local c = { name = name, id = 42 }
        function c:GetID() return self.id end
        rec.category = c
        return c
    end
    function S.RegisterAddOnSetting(category, variable, key, tbl, vtype, name, default)
        local s = { category = category, variable = variable, key = key, tbl = tbl, vtype = vtype, name = name, default = default }
        function s:GetValue() return tbl[key] end
        function s:SetValue(v) tbl[key] = v; if self.cb then self.cb(self, v) end end
        function s:SetValueChangedCallback(cb) self.cb = cb end
        rec.settings[#rec.settings + 1] = s
        return s
    end
    function S.CreateCheckbox(category, setting, tip)
        local i = { setting = setting, tip = tip }
        function i:SetParentInitializer(parent, pred) self.parent, self.pred = parent, pred end
        rec.checkboxes[#rec.checkboxes + 1] = i
        return i
    end
    function S.CreateSliderOptions(min, max, step)
        local o = { min = min, max = max, step = step }
        function o:SetLabelFormatter(where, fn) self.where, self.fmt = where, fn end
        return o
    end
    function S.CreateSlider(category, setting, options, tip)
        local i = { setting = setting, options = options, tip = tip }
        function i:SetParentInitializer(parent, pred) self.parent, self.pred = parent, pred end
        rec.sliders[#rec.sliders + 1] = i
        return i
    end
    function S.CreateControlTextContainer()
        local c = { data = {} }
        function c:Add(value, label) self.data[#self.data + 1] = { value = value, label = label } end
        function c:GetData() return self.data end
        return c
    end
    function S.CreateDropdown(category, setting, optionsFn, tip)
        local i = { setting = setting, options = optionsFn(), tip = tip }
        rec.dropdowns[#rec.dropdowns + 1] = i
        return i
    end
    function S.RegisterAddOnCategory(category) rec.registered = category end
    function S.OpenToCategory(id) rec.opened = id end
    return S, rec
end

return M
