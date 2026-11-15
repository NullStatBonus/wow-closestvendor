-- Owned compact surface, contract v1; real and sample messages have separate instances.
local _, ns = ...
local L = ns.L
local T = {}
ns.Toast = T
function T.New(env)
    local cfg, pos = env.cfg, env.pos
    local self = {}
    local escapeMode
    local f = CreateFrame("Frame", env.name, UIParent)
    self.frame = f
    f:SetSize(280, 40); f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(false)
    f:SetFrameStrata("HIGH"); f:Hide()
    local bg = f:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
    local icon = f:CreateTexture(nil, "ARTWORK"); icon:SetSize(28,28); icon:SetPoint("TOPLEFT",8,-8)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    local title = ns.Presentation.Font(f, "GameFontNormal")
    title:SetPoint("TOPLEFT",44,-8); title:SetWidth(228); title:SetJustifyH("LEFT")
    title:SetText(L["Closest Vendor"]); title:SetTextColor(.867,.867,.867)
    local text = ns.Presentation.Font(f, "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT",44,-24); text:SetWidth(228); text:SetJustifyH("LEFT")
    text:SetTextColor(.667,.667,.667)
    local controls = CreateFrame("Frame", nil, f)
    controls:SetSize(240,28); controls:SetPoint("TOP",f,"BOTTOM",0,-4); controls:Hide()
    local function apply()
        f:SetScale((cfg.toastScale or 100)/100)
        local alpha = (cfg.toastAlpha or 100)/100
        if alpha == 0 then bg:Hide() else bg:SetColorTexture(0,0,0,alpha); bg:Show() end
        for _, object in ipairs({title,text,icon}) do object:SetAlpha((cfg.toastTextAlpha or 100)/100) end
        if self.Move and self.Move.active then
            return
        end
        f:ClearAllPoints(); f:SetPoint(pos.point or "TOP", UIParent,pos.relPoint or pos.point or "TOP",pos.x or 0,pos.y or -200)
    end
    self.Apply = apply
    function self.Show(message, seconds)
        apply(); text:SetText((message:gsub("|","||")))
        f:SetHeight(math.max(40, 32 + (text:GetStringHeight() or 16) + 8))
        self.left = seconds or 5; f:Show()
    end
    function self.Hide() if not (self.Move and self.Move.active) then f:Hide() end end
    function self.Reset()
        if self.Move then self.Move.Cancel() end
        for k in pairs(pos) do pos[k] = nil end; apply()
    end
    self.Move = ns.Move.New({
        locked = function() return false end,
        stop = function() f:StopMovingOrSizing() end,
        apply = apply,
        save = function() local p,_,r,x,y = f:GetPoint(1); if p then pos.point,pos.relPoint,pos.x,pos.y=p,r,x,y end end,
        placeholder = function() f:SetFrameStrata("TOOLTIP"); self.Show(L["Move toast — Done saves; Cancel restores."],10); f:EnableMouse(true); controls:Show(); if escapeMode then escapeMode(true) end end,
        finish = function() f:SetFrameStrata("HIGH"); if escapeMode then escapeMode(false) end; controls:Hide(); f:EnableMouse(false); f:Hide() end,
    })
    for i,spec in ipairs({{L["Done"],self.Move.Done},{L["Cancel"],self.Move.Cancel}}) do
        local b=ns.Presentation.Button(CreateFrame,controls,spec[1],spec[2])
        b:SetPoint("LEFT",(i-1)*120,0)
    end
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function() if self.Move.active then f:StartMoving() end end)
    f:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
    f:SetScript("OnUpdate",function(_,elapsed)
        if self.Move.active then return end
        self.left=(self.left or 0)-elapsed; if self.left<=0 then f:Hide() end
    end)
    if env.escape then escapeMode = env.escape(f,self.Move.Cancel) end
    apply(); return self
end
