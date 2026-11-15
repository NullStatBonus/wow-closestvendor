-- Local shared presentation contract v1. No sibling addon dependency.
local _, ns = ...
local L = ns.L
local P = { VERSION = 1, SPACE = 4, PAD = 8, CONTENT_PAD = 12, SECTION = 16 }
ns.Presentation = P
P.DEFAULTS = { notificationStyle = "toast", toastAlpha = 100, toastTextAlpha = 100,
    toastScale = 100 }
P.PAGES = { home = true, restock = true, ammo = true, reagents = true, supplies = true, navigation = true,
    appearance = true, sound = true, advanced = true, about = true }
P.KINDS = { notice = true, hud = true, prompt = true }
P.KEYS = {
    ["bags.threshold"] = { storage = "bagThreshold", kind = "integer", limits = "bag", default = 2 },
    ["appearance.notification-style"] = { storage = "notificationStyle", kind = "enum", values = { warning = true, toast = true }, default = "toast" },
    ["appearance.hud.background-opacity"] = { storage = "hudAlpha", kind = "integer", limits = "hudAlpha", default = 80 },
    ["appearance.hud.text-opacity"] = { storage = "hudTextAlpha", kind = "integer", limits = "hudTextAlpha", default = 100 },
    ["appearance.hud.scale"] = { storage = "hudScale", kind = "integer", limits = "hudScale", default = 100 },
    ["appearance.hud.locked"] = { storage = "hudLocked", kind = "boolean", default = false },
    ["appearance.toast.background-opacity"] = { storage = "toastAlpha", kind = "integer", limits = "toastAlpha", default = 100 },
    ["appearance.toast.text-opacity"] = { storage = "toastTextAlpha", kind = "integer", limits = "toastTextAlpha", default = 100 },
    ["appearance.toast.scale"] = { storage = "toastScale", kind = "integer", limits = "toastScale", default = 100 },
}
for _, entry in pairs(P.KEYS) do
    local e = entry
    e.scope = "character"
    e.get = function(cfg) if cfg[e.storage] == nil then return e.default end return cfg[e.storage] end
    e.set = function(cfg, value) cfg[e.storage] = value end
    e.refresh = function(refresh) if refresh then refresh() end end
end
function P.Choices(e)
    if e.kind == "boolean" then return "on/off" end
    if e.values then return "warning/toast" end
    local b = ns.Commands.LIMITS[e.limits]
    return L["whole number %d–%d"]:format(b[1], b[2])
end
function P.Validate(e, value)
    if e.kind == "boolean" then
        if value == true or value == "on" then return true, true end
        if value == false or value == "off" then return true, false end
    elseif e.kind == "enum" then
        if e.values[value] then return true, value end
    else
        local n = tonumber(value)
        local b = ns.Commands.LIMITS[e.limits]
        if n and n % 1 == 0 and n >= b[1] and n <= b[2] then return true, n end
    end
    return false
end
function P.Set(cfg, key, value, refresh)
    local e = P.KEYS[key]
    if not e then return false end
    local ok, v = P.Validate(e, value)
    if not ok then return false end
    e.set(cfg, v); e.refresh(refresh)
    return true
end
function P.Value(cfg, key)
    local v = P.KEYS[key].get(cfg)
    if type(v) == "boolean" then return v and "on" or "off" end
    return tostring(v)
end
function P.Migrate(cfg, existingUser)
    if cfg.notificationStyle ~= "toast" and cfg.notificationStyle ~= "warning" then
        cfg.notificationStyle = existingUser and "warning" or "toast"
    end
    for k, v in pairs(P.DEFAULTS) do if cfg[k] == nil then cfg[k] = v end end
    for key, e in pairs(P.KEYS) do
        if key:match("appearance%.toast%.") then
            local ok, value = P.Validate(e, cfg[e.storage])
            if ok then cfg[e.storage] = value else cfg[e.storage] = e.default end
        end
    end
end

-- Existing client font objects first; a missing preferred template falls back locally.
function P.Font(frame, preferred)
    for _, template in ipairs({ preferred, "GameFontHighlight", "GameFontNormal" }) do
        local ok, font = pcall(frame.CreateFontString, frame, nil, "OVERLAY", template)
        if ok and font then return font end
    end
    error("No supported client font object")
end

-- Native button chrome first; a client without that template gets a text button.
function P.Button(create, parent, label, click)
    local ok, button = pcall(create, "Button", nil, parent, "UIPanelButtonTemplate")
    if ok and button then button:SetText(label)
    else
        button = create("Button", nil, parent)
        button.text = P.Font(button, "GameFontHighlight")
        button.text:SetPoint("CENTER"); button.text:SetText(label)
    end
    button:SetSize(112, 24); button:SetScript("OnClick", click)
    return button
end
