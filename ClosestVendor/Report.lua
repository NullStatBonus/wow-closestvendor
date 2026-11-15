-- Match KeepThat: standard AceGUI Frame with a scrollable, selectable, read-only report.
-- The bare edit box remains a fallback when settings libraries are unavailable; Core also
-- falls back to chat if neither renderer can be built.
local _, ns = ...

local R = {}
ns.Report = R

local NAME = "ClosestVendorReport"
local frame, window
local L = ns.L

local function aceReport(text)
    if not LibStub then return false end
    local gui = LibStub("AceGUI-3.0", true)
    if not (gui and gui.Create) then return false end
    if window then gui:Release(window); window = nil end
    window = gui:Create("Frame")
    window:SetTitle(L["Closest Vendor debug report"])
    window:SetStatusText(L["Press Ctrl+A to select everything, then Ctrl+C to copy."])
    window:SetLayout("Fill")
    window:SetCallback("OnClose", function(w)
        gui:Release(w)
        if window == w then window = nil end
    end)
    local box = gui:Create("MultiLineEditBox")
    box:SetLabel("")
    box:DisableButton(true)
    box:SetText(text)
    box:SetCallback("OnTextChanged", function(b) b:SetText(text) end)
    window:AddChild(box)
    box:SetFocus()
    box:HighlightText()
    if frame then frame:Hide() end
    return true
end

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
    local ok, shown = pcall(aceReport, text)
    if ok and shown then return true end
    -- A partially constructed Ace window must not cover the working fallback.
    if window then pcall(function() window:Release() end); window = nil end
    frame = frame or build()
    frame.box:SetText(text)
    frame.box:HighlightText()
    frame:Show()
    frame.box:SetFocus()
    return true
end
