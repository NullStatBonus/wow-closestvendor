package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq
local ns = H.locale({})
for _, name in ipairs({"Status","Reagents","Supplies","Nav","Presentation","Move","Commands"}) do
    assert(loadfile("ClosestVendor/"..name..".lua"))("ClosestVendor",ns)
end
local P,C = ns.Presentation,ns.Commands
local function cfg()
    return {bagThreshold=2,durThreshold=20,ammoThreshold=200,tradeThreshold=10,reagentThreshold=5,
        hudAlpha=43,hudTextAlpha=38,hudScale=150,hudColor="123456",autoNotice=false,hudRow={}}
end
local c=cfg();P.Migrate(c)
eq(c.notificationStyle,"toast","default toast");eq(c.autoNotice,false,"style migration does not enable")
eq(c.hudAlpha,43,"old background brightness");eq(c.hudTextAlpha,38,"old text brightness")
local repaired=cfg();repaired.toastLocked="off";repaired.toastAlpha=999;repaired.notificationStyle="invalid";P.Migrate(repaired)
eq(P.KEYS["appearance.toast.locked"],nil,"toast has no lock control or public key");eq(repaired.toastAlpha,100,"invalid new appearance falls back");eq(repaired.notificationStyle,"toast","invalid style falls back")
local existing=cfg();existing.notificationStyle="warning";P.Migrate(existing)
eq(existing.notificationStyle,"warning","saved Warning choice survives default change")
local legacy=cfg();P.Migrate(legacy,true)
eq(legacy.notificationStyle,"warning","existing user without a choice keeps Warning")
legacy.notificationStyle="toast";P.Migrate(legacy,true)
eq(legacy.notificationStyle,"toast","existing saved Toast choice retained")
local second=cfg();P.Migrate(second)
for key,e in pairs(P.KEYS) do
    eq(e.scope,"character","declared scope")
    local before=P.Value(c,key)
    for _,bad in ipairs({"", "unknown", "1 extra", "1.5", "-1", "201", "nan"}) do
        C.Run(c,"set "..key.." "..bad)
        eq(P.Value(c,key),before,"invalid value does not mutate "..key)
    end
    C.Run(c,"get "..key.." extra");eq(P.Value(c,key),before,"get surplus read only")
    local good=e.kind=="enum" and "toast" or e.kind=="boolean" and "on" or tostring(C.LIMITS[e.limits][1])
    local out=C.Run(c,"set "..key.." "..good)
    eq(#out,1,"single acknowledgement")
    eq(P.Value(c,key),good,"effective typed value")
    eq(P.Value(second,key),before,"character isolation")
end
local _, readAction=C.Run(c,"get bags.threshold");eq(readAction[1],"read","get never schedules gameplay refresh")
local saved=c.bagThreshold
for _,msg in ipairs({"set", "set bags.threshold", "set cfg.bagThreshold 7", "set bags.threshold 7 extra", "get", "get bags.threshold extra"}) do
    C.Run(c,msg);eq(c.bagThreshold,saved,"malformed command read only")
end
local _,a=C.Run(c,"SETTINGS STATUS-WINDOW");eq(a[2],"appearance","case insensitive alias")
_,a=C.Run(c,"options");eq(a[2],"home","Home alias")
for kind in pairs(P.KINDS) do _,a=C.Run(c,"preview "..kind);eq(a[2],kind,"preview allowlist") end
local out=C.Run(c,"preview unknown");eq(out[1]:find("hud",1,true)~=nil,true,"kinds listed")
out=C.Run(c,"help bad");eq(out[1]:find("topics",1,true)~=nil,true,"unknown help topic")
-- Position transaction: no persistence until Done; locking and Cancel never write.
local persisted,tentative,locked,finished=5,5,false,0
local move=ns.Move.New({ locked=function()return locked end,stop=function()end,
    placeholder=function()tentative=99 end, apply=function()tentative=persisted end,
    save=function()persisted=tentative end,finish=function()finished=finished+1 end })
eq(move.Begin(),true,"begin");eq(persisted,5,"no tentative save")
move.Cancel();eq(tentative,5,"cancel restores");eq(persisted,5,"cancel does not write")
move.Begin();move.Done();eq(persisted,99,"Done saves")
locked=true;eq(move.Begin(),false,"locked Begin blocked")
locked=false;move.Begin();locked=true;move.Done();eq(persisted,99,"locked mid move cancels")
-- Font fallback is local and does not modify native fonts.
local seen={};local font={}
local frame={CreateFontString=function(_,_,_,name) seen[#seen+1]=name;if name=="Missing"then error("missing")end;return font end}
eq(P.Font(frame,"Missing"),font,"font fallback");eq(seen[2],"GameFontHighlight","existing fallback")
local clicked=false
local b={CreateFontString=function() return {SetPoint=function()end,SetText=function(self,v)self.text=v end} end,
    SetSize=function()end,SetScript=function(self,_,fn)self.click=fn end}
local function create(_,_,_,template) if template then error("missing template") end; return b end
local result=P.Button(create,{},"Done",function()clicked=true end)
eq(result.text.text,"Done","standard-template fallback preserves full label")
result.click();eq(clicked,true,"fallback action works")
H.done()
