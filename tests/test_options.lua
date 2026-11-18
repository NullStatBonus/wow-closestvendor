package.path = "tests/?.lua;" .. package.path
local H, fake = require("harness"), require("fake_ace")
local eq = H.eq
local function boot(opts, class, cfg)
    local stub, rec = fake.new(opts)
    local env = setmetatable({LibStub = stub}, {__index = _G})
    local ns = H.locale({})
    for _, name in ipairs({"Reagents","Supplies","Nav","Status","Presentation","Commands","Options"}) do
        local chunk = assert(loadfile("ClosestVendor/"..name..".lua")); setfenv(chunk,env); chunk("ClosestVendor", ns)
    end
    cfg = cfg or {bagThreshold=2,bagEnabled=true,hudAlpha=37,hudRow={},suppliesEnabled=true,reagentsEnabled=true}
    ns.Presentation.Migrate(cfg)
    local changes=0
    local picker
    local panel = ns.Options.Register(cfg,{},function() changes=changes+1 end,class or "MAGE",
        function(r,g,b,fn) picker={r,g,b,fn} end)
    return ns,rec,cfg,panel,function() return changes end,function() return picker end
end
local ns,r,c,p,changed,picker=boot()
eq(p,ns.Options.APP,"namespaced app")
eq(r.defaultSize.width,600,"settings starts at KT width")
eq(r.defaultSize.height,460,"settings starts at KT height")
local pages=r.tree.args
local names={"home","restock","navigation","appearance","advanced","about"}
for i,k in ipairs(names) do eq(pages[k].order,i,"landmark order"); eq(pages[k].args.scope,nil,"scope not repeated on pages") end
eq(r.tree.name,"Closest Vendor","title contains only the addon name")
eq(pages.appearance.childGroups,"tab","Appearance separates dense surfaces into tabs")
eq(pages.appearance.args.hud.inline,nil,"Status window has its own tab")
eq(pages.appearance.args.notices.order..","..pages.appearance.args.hud.order,"1,2","two tabs: Notifications, Status window")
eq(pages.appearance.args.toast,nil,"no separate Toast tab")
eq(pages.about.args.title.fontSize,"large","About matches KT title hierarchy")
eq(pages.about.args.version.fontSize,"small","About version is secondary")
eq(pages.about.args.cmd_demo.name:find("/cvn demo",1,true)~=nil,true,"About has a dedicated demo command row")
local function checkWidths(args)
    for _,opt in pairs(args) do
        if opt.type=="select" then
            eq(type(opt.width),"number","dropdown width fits content instead of stretching")
            eq(opt.width>=1.5 and opt.width<=2.2,true,"dropdown labels and choices have bounded room")
        elseif opt.type=="range" or opt.type=="execute" then eq(opt.width,1.5,"sliders and buttons use KT compact widths")
        elseif opt.type=="toggle" then eq(opt.width,"full","checkbox labels retain readable rows") end
        if opt.args then checkWidths(opt.args) end
    end
end
checkWidths(pages)
local R=pages.restock.args
eq(R.ammo.order..","..R.reagents.order..","..R.supplies.order,"1,2,3","Restock holds Ammo, Reagents and Supplies")
pages.ammo,pages.reagents,pages.supplies,pages.sound=R.ammo,R.reagents,R.supplies,pages.appearance.args.sound
eq(pages.sound.order,3,"Sound is the third Appearance tab")
for _,k in ipairs({"vendorMode","vendorPrefer","autoNotice","bagEnabled","ammoEnabled","suppliesEnabled"}) do
    eq(pages.home.args[k]~=nil,true,"critical switch on Home: "..k)
end
eq(pages.navigation.args.vendorMode,nil,"no second destination control on Navigation")
eq(pages.appearance.args.notices.args.autoNotice,nil,"On-screen notice is on Home, not Appearance")
for _,key in ipairs({"home","restock","ammo","reagents","supplies","navigation","appearance","sound","advanced"}) do
    eq(type(pages[key].args.intro.name),"string","page explains its purpose: "..key)
    eq(pages[key].args.intro.order,0,"intro comes first; Ace sorts negative orders last")
end
for _,key in ipairs({"notices","hud"}) do
    eq(type(pages.appearance.args[key].args.intro.name),"string","Appearance tab has context: "..key)
end
eq(pages.ammo.args.buyingHelp.order<pages.ammo.args.ammoBuyEnabled.order,true,"purchase consequence is shown before decision")
eq(pages.reagents.args.buyingHelp.name:find("without confirmation",1,true)~=nil,true,"automatic buying consequence visible")
eq(pages.appearance.args.notices.args.styleHelp.name:find("does not change your settings",1,true)~=nil,true,"safe preview meaning visible")
eq(pages.advanced.args.debugHelp.name:find("repeat the problem",1,true)~=nil,true,"diagnostic workflow explained")
local bag=pages.home.args["bags.threshold"]
bag.set(nil,4);eq(c.bagThreshold,4,"shared setter writes storage");eq(changed(),1,"refresh")
ns.Commands.Run(c,"set bags.threshold 7");eq(bag.get(),7,"CLI/UI parity")
bag.set(nil,201);eq(c.bagThreshold,7,"UI shares validation")
c.bagEnabled=false;eq(bag.disabled(),true,"dependent disabled")
local hud=pages.appearance.args.hud.args
local toast=pages.appearance.args.notices.args
eq(hud["appearance.hud.locked"].order<hud["appearance.hud.scale"].order,true,"lock first")
eq(hud["appearance.hud.background-opacity"].get(),37,"old alpha retained")
eq(toast["appearance.toast.locked"],nil,"toast has no lock control")
local runs={};ns.Options.Run=function(cmd) runs[#runs+1]=cmd end
hud.preview.func();eq(runs[1],"preview hud","preview action")
toast.preview.func();eq(runs[#runs],"preview notice","one notification preview")
eq(toast.remindSound,nil,"no sound control on Appearance")
pages.sound.args.remindSound.set(nil,"none");eq(c.remindSound,"none","one notification sound, on the Sound page")
eq(pages.supplies.args.remindSound,nil,"no second sound control on Supplies")
eq(runs[#runs],"sound none","choosing a sound plays it")
do
    local v = pages.sound.args.remindSound.values
    eq(type(v),"function","sound choices are read when the dropdown opens")
    eq(v().whisper..","..tostring(v()["lsm:Bell"]),"Whisper ping,nil","built-ins only without sound packs")
    ns.Supplies.media={list=function() return {"Bell"} end}
    eq(v()["lsm:Bell"],"Bell (sound pack)","a pack that loads later is listed")
    ns.Supplies.media=nil; c.remindSound="lsm:Gone"
    eq(v()["lsm:Gone"],"Gone (sound pack)","a saved but missing sound still shows by name")
    c.remindSound="none"
end
c.notificationStyle="toast";eq(toast["appearance.toast.scale"].hidden(),false,"Toast look shown for Toast")
eq(toast.warningLook.hidden(),true,"no Warning note for Toast")
c.notificationStyle="warning";eq(toast["appearance.toast.scale"].hidden(),true,"Toast look hidden for Warning")
eq(tostring(toast.move.hidden())..","..tostring(toast.reset.hidden()),"true,true","Toast position hidden for Warning")
eq(toast.warningLook.hidden(),false,"Warning explains why")
c.notificationStyle="toast"
local move;ns.Options.Move=function(k) move=k end;toast.move.func();eq(move,"toast","separate Move target")
local color=hud.color;color.func();local pick=picker();pick[4](1,0,.5);eq(c.hudColor,"ff0080","guarded picker callback")
pick[4](pick[1],pick[2],pick[3]);eq(c.hudColor,"000000","cancel restores original")
ns.Options.Register(c,{},function()end,"MAGE");eq(r.registrations,1,"no duplicate registration")
ns.Options.Open(p);eq(r.page,"home","default Home")
ns.Options.Open(p,"appearance");eq(r.page,"appearance","explicit page")
ns.Options.Open(p,"ammo");eq(r.page,"restock/ammo","a Restock page opens by its own name")
ns.Options.Open(p,"sound");eq(r.page,"appearance/sound","the Sound tab opens by name")
-- The game's AddOns list: Closest Vendor opens Home, with each other top-level page under it.
do
    local e = r.entries or {}
    eq(#e, 6, "one entry and five pages in the AddOns list")
    eq(e[1] and (e[1].name .. "|" .. tostring(e[1].parent) .. "|" .. e[1].path), "Closest Vendor|nil|home", "the entry opens Home")
    local seen = {}
    for i = 2, #e do
        eq(e[i].parent, "Closest Vendor", e[i].path .. " sits under Closest Vendor")
        eq(e[i].name, r.tree.args[e[i].path].name, e[i].path .. " uses its page name")
        seen[#seen + 1] = e[i].path
    end
    eq(table.concat(seen, ","), "restock,navigation,appearance,advanced,about", "pages in tree order")
end
-- Reagent toggles name the item in the player's language when the game has it, English before.
do
    local args = r.tree.args.restock.args.reagents.args
    local t = args.item17020
    eq(type(t.name), "function", "reagent label is computed when shown")
    eq(t.name(), "Reagent: Arcane Powder", "English until the game has the name")
    ns.Options.itemName = function(id) return id == 17020 and "Arkanpulver" or nil end
    eq(t.name(), "Reagent: Arkanpulver", "the game's name once loaded")
    ns.Options.itemName = nil
end
ns,r=boot({noNative=true});eq(ns.Options.Open(ns.Options.APP),true,"standalone without native API")
ns,r,c,p=boot({missing=true});eq(p,nil,"missing libraries tolerated");eq(ns.Options.Open(p),false,"missing libraries fail clearly")
ns,r,c,p=boot({failRegister=true});eq(p,nil,"failed registration tolerated")
ns,r=boot({},"WARRIOR");eq(r.tree.args.appearance.args.hud.args.rowreagents.disabled,true,"irrelevant row disabled")
-- Validate the actual option table using the bundled upstream implementation.
dofile("ClosestVendor/Libs/LibStub/LibStub.lua")
dofile("ClosestVendor/Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("ClosestVendor/Libs/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua")
LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(r.tree,"ClosestVendor")
H.done()
