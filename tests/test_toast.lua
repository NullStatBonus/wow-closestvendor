package.path = "tests/?.lua;" .. package.path
local H=require("harness");local eq=H.eq
local frames={}
local function frame(kind,name,parent)
    local f={kind=kind,name=name,parent=parent,scripts={},shown=false,textures={},fonts={}}
    function f:SetScript(k,v)self.scripts[k]=v end
    function f:SetSize(w,h)self.w,self.h=w,h end
    function f:SetHeight(h)self.h=h end
    function f:SetFrameStrata(v)self.strata=v end
    function f:SetScale(v)self.scale=v end
    function f:SetAlpha(v)self.alpha=v end
    function f:EnableMouse(v)self.mouse=v end
    function f:SetClampedToScreen(v)self.clamped=v end
    function f:SetMovable(v)self.movable=v end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    function f:SetPoint(p,a,r,x,y)self.point={p,r,x,y} end
    function f:GetPoint()local p=self.point;return p[1],nil,p[2],p[3],p[4]end
    function f:SetText(v)self.text=v end
    function f:GetStringHeight()return self.text and #self.text>150 and 120 or 16 end
    function f:SetColorTexture(r,g,b,a)self.color={r,g,b,a}end
    function f:CreateTexture()local t=frame("Texture",nil,self);self.textures[#self.textures+1]=t;return t end
    function f:CreateFontString()local t=frame("FontString",nil,self);self.fonts[#self.fonts+1]=t;return t end
    function f:StopMovingOrSizing()end
    setmetatable(f,{__index=function(_,k)if k:match("^%u")then return function()end end end})
    frames[#frames+1]=f;return f
end
local env=setmetatable({CreateFrame=frame,UIParent={}},{__index=_G})
local ns=H.locale({})
for _,name in ipairs({"Presentation","Move","Toast"})do
    local c=assert(loadfile("ClosestVendor/"..name..".lua"));setfenv(c,env);c("ClosestVendor",ns)
end
local c={toastAlpha=80,toastTextAlpha=40,toastScale=150,toastLocked=false};local pos={}
local toggle
local t=ns.Toast.New({cfg=c,pos=pos,name="Toast",escape=function(_,cancel)toggle=cancel;return function()end end})
local f=t.frame
eq(f.w,280,"compact width");eq(f.clamped,true,"clamped");eq(f.mouse,false,"normal mouse transparency")
t.Show("A short route",5);eq(f.scale,1.5,"scale");eq(f.textures[1].color[4],.8,"background alpha")
eq(f.fonts[1].alpha,.4,"title alpha");eq(f.textures[2].alpha,.4,"icon alpha")
local short=f.h;t.Show(string.rep("Long target zone reason alternative ",15),5)
eq(f.h>short,true,"long content grows");eq(f.fonts[2].text:find("alternative",1,true)~=nil,true,"all context retained")
f.scripts.OnUpdate(f,4);eq(f.shown,true,"not expired")
t.Show("replacement",5);f.scripts.OnUpdate(f,2);eq(f.shown,true,"replacement restarts time")
f.scripts.OnUpdate(f,3);eq(f.shown,false,"five-second lifetime")
c.toastAlpha=0;t.Show("again");eq(f.textures[1].shown,false,"zero draws no fill")
eq(f.fonts[1].alpha,.4,"independent text alpha")
eq(t.Move.Begin(),true,"Move placeholder");eq(f.strata,"TOOLTIP","Move renders above Ace FULLSCREEN_DIALOG");eq(f.shown,true,"Move shows placeholder even without a live notice");eq(f.mouse,true,"Move receives mouse")
f:SetPoint("TOP",{},"TOP",12,34);toggle()
eq(pos.x,nil,"Escape cannot save");eq(f.strata,"HIGH","Cancel restores normal toast layer");eq(f.mouse,false,"Cancel restores mouse transparency")
t.Move.Begin();f:SetPoint("TOP",{},"TOP",56,78);t.Move.Done();eq(pos.x,56,"Done persists anchor")
c.toastLocked=true;eq(t.Move.Begin(),true,"legacy toast lock cannot block explicit Move");t.Move.Cancel()
t.Reset();eq(pos.x,nil,"position reset");eq(c.toastAlpha,0,"reset keeps alpha");eq(c.toastScale,150,"reset keeps scale")
H.done()
