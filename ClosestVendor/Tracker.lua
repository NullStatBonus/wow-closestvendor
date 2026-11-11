-- The status window: a small movable frame with a title, a cog and one line per row. It only draws,
-- moves and forwards clicks; what the rows are is decided in Status.lua. Built from bare frames, no
-- templates, like Report.lua. The caller wraps New and every call in pcall: a client whose frames
-- differ loses the window, nothing else.
--   env.cfg             live settings: hudLocked, hudScale (percent, 50-200), hudAlpha (background,
--                       percent, 0-100), hudColor (background, "rrggbb", black unless the player chose
--                       another) and hudTextAlpha (text and icons, percent, 20-100)
-- OLED-safe: the background is pure black by default and is not drawn at all at 0, whatever its
-- colour; there is no border and no
-- other fill, a low row is marked by its text colour only, and text and icons dim with hudTextAlpha.
--   env.pos             saved position table (DB.hud): { point, relPoint, x, y }; empty means the default
--   env.go(row)         a routable row was clicked
--   env.openSettings()  the cog was clicked
--   env.shiftDown()     true while Shift is held
-- Tracker.New(env) returns { Show(rows), Demo(rows), Apply(), Reset(), frame }.
local _, ns = ...

local L = ns.L

local T = {}
ns.Tracker = T

local NAME = "ClosestVendorTracker"
local PAD, TITLE_H, ROW_H, MIN_W, COG = 6, 16, 14, 130, 14
local DEFAULT = { point = "LEFT", x = 60, y = 60 }

function T.New(env)
    local cfg, pos = env.cfg, env.pos
    local self = {}
    local moving = false
    local buttons = {}
    local textAlpha = 1 -- set by Apply; a line made later starts with it
    local real, demo = {}, nil -- the rows last given to Show, and the demo rows drawn in their place

    local f = CreateFrame("Frame", NAME, UIParent)
    self.frame = f
    f:SetSize(MIN_W, TITLE_H + 2 * PAD)
    f:SetClampedToScreen(true) -- never off screen
    f:SetMovable(true)
    f:EnableMouse(true)
    f:Hide()
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()

    -- A locked window never moves. The title moves it by itself; anywhere else needs Shift.
    local function startMove(needShift)
        if cfg.hudLocked then return end
        if needShift and env.shiftDown() ~= true then return end
        moving = true
        f:StartMoving()
    end
    local function stopMove()
        if not moving then return end
        moving = false
        f:StopMovingOrSizing()
        local point, _, relPoint, x, y = f:GetPoint(1)
        if point then pos.point, pos.relPoint, pos.x, pos.y = point, relPoint, x, y end
    end
    local function draggable(frame, needShift)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function() startMove(needShift) end)
        frame:SetScript("OnDragStop", stopMove)
    end
    draggable(f, true)

    local title = CreateFrame("Frame", nil, f)
    title:SetPoint("TOPLEFT", PAD, -PAD)
    title:SetPoint("TOPRIGHT", -(PAD + COG + 2), -PAD)
    title:SetHeight(TITLE_H)
    title.text = title:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title.text:SetPoint("LEFT")
    title.text:SetText(L["Closest Vendor"])
    draggable(title, false)
    self.title = title

    local cog = CreateFrame("Button", nil, f)
    cog:SetSize(COG, COG)
    cog:SetPoint("TOPRIGHT", -PAD, -PAD)
    local icon = cog:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    if not icon:GetTexture() then -- no such texture on this client: a plain mark instead
        cog.text = cog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cog.text:SetPoint("CENTER")
        cog.text:SetText("*")
    end
    cog:SetScript("OnClick", function() env.openSettings() end)
    self.cog = cog

    local function button(i)
        local b = CreateFrame("Button", nil, f)
        b:SetPoint("TOPLEFT", PAD, -(PAD + TITLE_H + (i - 1) * ROW_H))
        b:SetPoint("TOPRIGHT", -PAD, -(PAD + TITLE_H + (i - 1) * ROW_H))
        b:SetHeight(ROW_H)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.text:SetPoint("LEFT")
        b:SetAlpha(textAlpha)
        draggable(b, true)
        b:SetScript("OnClick", function()
            -- Shift on an unlocked window is the move gesture, and the end of a drag is not a click.
            if moving or (not cfg.hudLocked and env.shiftDown() == true) then return end
            if demo then return end -- demo rows are made up: a click on one goes nowhere
            if b.row and b.row.routable then env.go(b.row) end -- a display-only row does nothing
        end)
        buttons[i] = b
        return b
    end

    -- Scale, background and text opacity and position from the settings and the saved position.
    function self.Apply()
        local scale = tonumber(cfg.hudScale) or 100
        f:SetScale(math.max(50, math.min(200, scale)) / 100)
        -- The player's colour, pure black unless one was chosen (or the saved one is not a colour).
        -- At 0 it is not drawn at all, whatever the colour: only text and icons are left on screen.
        local back = math.max(0, math.min(100, tonumber(cfg.hudAlpha) or 80)) / 100
        if back > 0 then
            local r, g, b = ns.Status.Color(cfg.hudColor)
            if not r then r, g, b = 0, 0, 0 end
            bg:SetColorTexture(r, g, b, back)
            bg:Show()
        else
            bg:Hide()
        end
        -- Text and icons: the title, the cog and every line. The background is not a child of these.
        textAlpha = math.max(20, math.min(100, tonumber(cfg.hudTextAlpha) or 100)) / 100
        title:SetAlpha(textAlpha)
        cog:SetAlpha(textAlpha)
        for _, b in ipairs(buttons) do b:SetAlpha(textAlpha) end
        local point = pos.point or DEFAULT.point
        f:ClearAllPoints()
        f:SetPoint(point, UIParent, pos.relPoint or point, pos.x or DEFAULT.x, pos.y or DEFAULT.y)
    end

    -- Back to the default position.
    function self.Reset()
        pos.point, pos.relPoint, pos.x, pos.y = nil, nil, nil, nil
        self.Apply()
    end

    local function draw(rows)
        if #rows == 0 then f:Hide() return end
        local width = MIN_W
        for i, row in ipairs(rows) do
            local b = buttons[i] or button(i)
            b.row = row
            b.text:SetText(row.text)
            if row.low then b.text:SetTextColor(1, 0.25, 0.25) else b.text:SetTextColor(1, 1, 1) end
            b:Show()
            width = math.max(width, (b.text:GetStringWidth() or 0) + 2 * PAD)
        end
        for i = #rows + 1, #buttons do buttons[i].row = nil; buttons[i]:Hide() end
        f:SetSize(width, TITLE_H + #rows * ROW_H + 2 * PAD)
        f:Show()
    end

    -- Draw these rows (see Status.Visible); with none the window is hidden. During a demo they are
    -- kept for when it ends.
    function self.Show(rows)
        real = rows
        if not demo then draw(rows) end
    end

    -- Draw made-up rows in place of the real ones (/cvn demo); nil ends that and draws the real rows.
    function self.Demo(rows)
        demo = rows
        draw(demo or real)
    end

    -- The row buttons in use, for tests.
    function self.Buttons() return buttons end

    self.Apply()
    return self
end
