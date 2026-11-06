-- A small window with the report text in a plain edit box, so it can be selected and copied
-- (Ctrl+A, Ctrl+C). Built from bare frames, no templates. Show returns true on success; the
-- caller wraps it in pcall and falls back to chat.
local _, ns = ...

local R = {}
ns.Report = R

local NAME = "ClosestVendorReport"
local frame

local function build()
    local f = CreateFrame("Frame", NAME, UIParent)
    f:SetSize(560, 380)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.85)
    local box = CreateFrame("EditBox", nil, f)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFontObject(ChatFontNormal)
    box:SetPoint("TOPLEFT", 10, -10)
    box:SetPoint("BOTTOMRIGHT", -10, 10)
    box:SetScript("OnEscapePressed", function() f:Hide() end)
    f.box = box
    tinsert(UISpecialFrames, NAME) -- Escape closes it
    return f
end

function R.Show(text)
    frame = frame or build()
    frame.box:SetText(text)
    frame.box:HighlightText()
    frame:Show()
    frame.box:SetFocus()
    return true
end
