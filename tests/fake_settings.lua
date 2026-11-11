-- Fake of the Blizzard Settings API (vertical layout) that records what an addon registers.
local M = {}

-- mode: "return" (default, like the game: the Register calls return category, layout), "method" (only
-- category:GetLayout() exists) or "none" (no layout anywhere).
-- opts.swatch: the client has Settings.CreateColorSwatch (as Era and Forever do); its rows go to
-- rec.swatches as { category, setting, tip }. opts.swatchThrows: it is there but raises an error.
function M.new(mode, opts)
    mode = mode or "return"
    opts = opts or {}
    local rec = { settings = {}, checkboxes = {}, sliders = {}, dropdowns = {}, subcategories = {}, headers = {}, buttons = {}, swatches = {} }
    local S = { VarType = { Boolean = "boolean", Number = "number", String = "string" } }

    -- A category, or a subcategory when `parent` is given. Section headers go to rec.headers as
    -- { category, text } and buttons to rec.buttons as { category, init }; they are added through the layout and a global initializer maker, like the game.
    local function newCategory(name, parent)
        local c = { name = name, id = parent and 42 + #rec.subcategories + 1 or 42, parent = parent }
        function c:GetID() return self.id end
        local layout = {}
        function layout.AddInitializer(_, init)
            if init.onClick then rec.buttons[#rec.buttons + 1] = { category = c, init = init }
            else rec.headers[#rec.headers + 1] = { category = c, text = init.text } end
        end
        if mode == "method" then function c:GetLayout() return layout end end
        return c, (mode == "return") and layout or nil
    end
    function S.RegisterVerticalLayoutCategory(name)
        local c, layout = newCategory(name)
        rec.category = c
        return c, layout
    end
    function S.RegisterVerticalLayoutSubcategory(parent, name)
        local c, layout = newCategory(name, parent)
        rec.subcategories[#rec.subcategories + 1] = c
        return c, layout
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
        function i:AddModifyPredicate(pred) self.predicates = self.predicates or {}; self.predicates[#self.predicates + 1] = pred end
        function i:CanModify() for _, p in ipairs(self.predicates or {}) do if not p() then return false end end return true end
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
        function i:AddModifyPredicate(pred) self.predicates = self.predicates or {}; self.predicates[#self.predicates + 1] = pred end
        function i:CanModify() for _, p in ipairs(self.predicates or {}) do if not p() then return false end end return true end
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
        function i:AddModifyPredicate(pred) self.predicates = self.predicates or {}; self.predicates[#self.predicates + 1] = pred end
        function i:CanModify() for _, p in ipairs(self.predicates or {}) do if not p() then return false end end return true end
        rec.dropdowns[#rec.dropdowns + 1] = i
        return i
    end
    if opts.swatch or opts.swatchThrows then
        function S.CreateColorSwatch(category, setting, tip)
            if opts.swatchThrows then error("swatch template missing", 0) end
            local i = { category = category, setting = setting, tip = tip }
            rec.swatches[#rec.swatches + 1] = i
            return i
        end
    end
    function S.RegisterAddOnCategory(category) rec.registered = category end
    function S.OpenToCategory(id) rec.opened = id end
    return S, rec
end

return M
