-- Loads the real Core.lua against a fake game and drives it with events.
package.path = "tests/?.lua;" .. package.path
local fakeSettings = require("fake_settings")
local H = require("harness")
local eq = H.eq

-- Shipped vendors (disk shape): {npcId, name, uiMapID, mx, my, faction, repair}
local SHIPPED = {
    { 1, "Far Seller", 100, 0.90, 0.50, 0, false },
    { 2, "Far Repairer", 100, 0.80, 0.50, 0, true },
    { 3, "Unconvertible", 999, 0.50, 0.50, 0, false }, -- map the client does not know
    { 4, "Ally Seller", 100, 0.75, 0.50, 1, false },   -- Alliance only: the test player is Alliance
    { 5, "Horde Repairer", 100, 0.55, 0.50, 2, true }, -- closest, but hostile
    { 6, "Arrow Man", 100, 0.77, 0.50, 0, false, 1 },
    { 7, "Gun Shop", 100, 0.78, 0.50, 0, false, 2 },
}

-- Build a fresh fake game + load the addon. `opts` tweaks the world.
local function boot(opts)
    opts = opts or {}
    local g = { printed = {}, timers = {}, handlers = {}, free = 20, dur = 100, combat = false,
                pos = { map = 100, x = 0.5, y = 0.5 }, npc = nil, repairable = false, tomtom = {},
                -- item id -> { class, subclass }
                items = { [100] = { 2, 2 }, [101] = { 2, 3 }, [102] = { 2, 16 }, [103] = { 2, 7 },
                          [200] = { 6, 2 }, [201] = { 6, 3 }, [300] = { 0, 0 },
                          [400] = { 4, 2 }, [401] = { 4, 3 } } }
    g.frames, g.time = {}, 100
    -- A frame that records what the addon needs to see and ignores every other call.
    function g.newFrame(kind, name)
        local f = { kind = kind, name = name, events = {}, scripts = {}, shown = false }
        function f:RegisterEvent(e) self.events[e] = true end
        function f:SetScript(event, fn)
            if event == "OnEvent" then g.onEvent = function(ev, a) fn(self, ev, a) end else self.scripts[event] = fn end
        end
        function f:SetText(t) self.text = t end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:HighlightText() self.highlighted = true end
        function f:SetFocus() self.focused = true end
        function f:CreateTexture() return g.newFrame("Texture") end
        -- Unrecorded API calls (CapitalizedMethods) do nothing; other missing fields stay nil.
        return setmetatable(f, { __index = function(_, k) if k:match("^%u") then return function() end end end })
    end
    local env = {
        print = function(t) g.printed[#g.printed + 1] = t end,
        CreateFrame = function(kind, name)
            if g.frameThrows and name == g.frameThrows then error("no frames today", 0) end
            local f = g.newFrame(kind, name)
            g.frames[#g.frames + 1] = f
            return f
        end,
        UIParent = {}, UISpecialFrames = {}, tinsert = table.insert, ChatFontNormal = {},
        GetTime = function() return g.time end,
        GetBuildInfo = function() return "1.60.1", "70790", "Nov 4 2026", 16001 end,
        GetLocale = function() return "enUS" end,
        GetAddOnMetadata = function(_, key) return key == "Version" and "0.1.0" or nil end,
        CreateVector2D = function(x, y) return { x = x, y = y } end,
        C_Map = {
            GetBestMapForUnit = function() return g.pos and g.pos.map end,
            GetPlayerMapPosition = function() return g.pos and { x = g.pos.x, y = g.pos.y } end,
            GetWorldPosFromMapPos = function(map, v)
                if map == 999 then error("unknown map") end
                return 1, { x = v.x * 1000, y = v.y * 1000 }
            end,
            GetMapInfo = function() return { name = "Test Zone" } end,
        },
        C_Container = { GetContainerNumFreeSlots = function(bag) if bag == 0 then return g.free, 0 end return g.otherBags and g.otherBags[bag] or 0, 0 end },
        GetInventoryItemDurability = function(slot) if slot == 1 then return g.dur, 100 end end,
        InCombatLockdown = function() return g.combat end,
        UnitFactionGroup = function(u) if u == "player" then return "Alliance" end return g.npcFaction end,
        UnitGUID = function() return g.npc and g.npc.guid end,
        UnitName = function() return g.npc and g.npc.name end,
        CanMerchantRepair = function() return g.repairable end,
        C_Timer = { After = function(_, fn) g.timers[#g.timers + 1] = fn end },
        C_AddOns = { IsAddOnLoaded = function(name) return opts.tomtom and name == "TomTom" end },
        NUM_BAG_SLOTS = 4,
        GetInventoryItemID = function(_, slot) return g.equipped and g.equipped[slot] end,
        GetItemInfoInstant = function(id)
            local i = g.items[id]
            if not i then return end
            return id, "type", "sub", "", 0, i[1], i[2]
        end,
        GetItemCount = function(id) return g.counts and g.counts[id] or 0 end,
        GetMerchantNumItems = function() return #(g.stock or {}) end,
        GetMerchantItemLink = function(i) return "|cff|Hitem:" .. g.stock[i] .. ":0:0|h[Thing]|h|r" end,
        GetNumSkillLines = function() return #(g.skillLines or {}) end,
        GetSkillLineInfo = function(i) local k = g.skillLines[i]; return k[1], false, true, k[2], 0, 0, k[3] end,
        TradeSkillFrame = { IsShown = function() return g.tradeWindow ~= nil end },
        GetTradeSkillLine = function() return g.tradeWindow end,
        IsTradeskillTrainer = function() return g.trainer ~= nil end,
        GetNumTrainerServices = function() return g.trainer and #g.trainer or 0 end,
        GetTrainerServiceSkillLine = function(i) return g.trainer[i] end,
        StaticPopup_Visible = function() return g.popup and "StaticPopup1" or nil end,
        SlashCmdList = {},
        StaticPopupDialogs = {},
        StaticPopup_Show = function(which, text, _, data)
            g.popup = { which = which, text = text, accept = data }
            g.shown = (g.shown or 0) + 1
            if g.autoAccept ~= false then data() end -- tests say g.autoAccept = false to hold it open
        end,
        StaticPopup_Hide = function() g.popup = nil; g.hidden = (g.hidden or 0) + 1 end,
        ClosestVendorDB = opts.db,
    }
    if opts.tomtom then
        env.TomTom = { AddWaypoint = function(_, map, x, y, o) g.tomtom[#g.tomtom + 1] = o.title; return {} end,
                       RemoveWaypoint = function() g.tomtom.removed = true end }
    end
    if opts.settings then
        local S, rec = fakeSettings.new()
        if opts.settingsThrows then S.RegisterVerticalLayoutCategory = function() error("settings API changed") end end
        env.Settings, g.settings = S, rec
        env.MinimalSliderWithSteppersMixin = { Label = { Right = "right" } }
    end
    setmetatable(env, { __index = _G })
    env._G = env

    local ns = {}
    for _, f in ipairs({ "Locales/enUS", "Triggers", "Professions", "Adapter", "Search", "Discovery", "Nav", "Controller", "Commands", "Options", "Log", "Report" }) do
        setmetatable(ns, nil)
        local chunk = assert(loadfile("ClosestVendor/" .. f .. ".lua"))
        setfenv(chunk, env)
        chunk("ClosestVendor", ns)
    end
    ns.ShippedVendors = SHIPPED
    local core = assert(loadfile("ClosestVendor/Core.lua"))
    setfenv(core, env)
    core("ClosestVendor", ns)
    g.ns, g.env = ns, env
    return g
end

local function login(g)
    g.onEvent("ADDON_LOADED", "ClosestVendor")
    g.onEvent("PLAYER_LOGIN")
end

local function lastPrinted(g) return g.printed[#g.printed] or "none" end

-- 0. Another addon loading must not create or touch our saved variables.
local g0 = boot()
g0.onEvent("ADDON_LOADED", "SomeOtherAddon")
eq(g0.env.ClosestVendorDB, nil, "other addon's load leaves our saved variables alone")

-- 1. Saved variables get defaults and keep existing values.
local g = boot({ db = { cfg = { bagThreshold = 5 } } })
g.onEvent("ADDON_LOADED", "SomeOtherAddon")
eq(g.env.ClosestVendorDB.cfg.bagThreshold, 5, "other addon's load ignored")
login(g)
local cfg = g.env.ClosestVendorDB.cfg
eq(cfg.bagThreshold, 5, "existing value kept")
eq(cfg.durThreshold, 20, "default filled in")
eq(cfg.bagEnabled, true, "default flag filled in")
eq(cfg.tradeThreshold, 10, "profession threshold default")
eq(cfg.tradeEnabled, true, "profession switch default")
eq(g.env.ClosestVendorDB.trainers ~= nil and g.env.ClosestVendorDB.professions ~= nil, true, "trainer and profession tables created")

-- 2. Registers the events it needs.
for _, e in ipairs({ "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "PLAYER_REGEN_ENABLED", "MERCHANT_SHOW", "PLAYER_LOGIN" }) do
    eq(g.ns.frame.events[e], true, "registered " .. e)
end

-- 3. Full bags -> nearest vendor shown (chat fallback: nothing else installed).
g = boot(); login(g)
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.printed, 0, "plenty of space: silent")
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(lastPrinted(g):find("Ally Seller", 1, true) ~= nil, true, "nearest friendly vendor named: " .. lastPrinted(g))
eq(lastPrinted(g):find("(75.0, 50.0)", 1, true) ~= nil, true, "coordinates shown")
eq(lastPrinted(g):find("Horde Repairer", 1, true), nil, "hostile-faction vendor skipped")
local count = #g.printed
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.printed, count, "no repeat")

-- 4. Worn gear -> a repair vendor. TomTom used when loaded.
g = boot({ tomtom = true }); login(g)
g.dur = 10
g.onEvent("UPDATE_INVENTORY_DURABILITY")
eq(g.tomtom[1], "Far Repairer", "TomTom waypoint for repair vendor")

-- 5. Unconvertible map is skipped without error; the rest still load.
g = boot(); login(g)
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(lastPrinted(g):find("Unconvertible", 1, true), nil, "unknown map vendor never chosen")

-- 6. No map position: silent, retried by the timer once a position exists.
g = boot(); login(g)
g.pos = nil
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.printed, 0, "no position: nothing shown")
eq(#g.timers, 1, "retry timer armed")
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.timers, 1, "timer armed only once")
g.pos = { map = 100, x = 0.5, y = 0.5 }
g.timers[1]()
eq(lastPrinted(g):find("Ally Seller", 1, true) ~= nil, true, "placed when position appeared")
eq(#g.timers, 1, "no more timers once placed")

-- 6b. The retry timer keeps re-arming while a position is still missing.
g = boot(); login(g)
g.pos = nil; g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
g.timers[1]()
eq(#g.timers, 2, "re-armed after an unsuccessful retry")

-- 6c. A (0,0) map position means "no position", same as nil.
g = boot(); login(g)
g.pos = { map = 100, x = 0, y = 0 }; g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.printed, 0, "zero position: nothing shown")
eq(#g.timers, 1, "zero position: retry armed")

-- 6d. Free slots are counted across all bags, not just the backpack.
g = boot(); login(g)
g.free = 1; g.otherBags = { [3] = 5 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.printed, 0, "6 free slots across bags: above threshold")

-- 7. Combat defers; leaving combat fires.
g = boot(); login(g)
g.combat = true; g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.printed, 0, "silent in combat")
g.combat = false
g.onEvent("PLAYER_REGEN_ENABLED")
eq(#g.printed, 1, "fires after combat")

-- 8. Opening a merchant learns it; learned data wins and is used next time.
g = boot(); login(g)
g.npc = { guid = "Creature-0-4372-0-55-1234-0000A1B2C3", name = "Fresh Vendor" } -- zoneUID 55, npc id 1234
g.pos = { map = 100, x = 0.51, y = 0.5 }
g.repairable = true
g.npcFaction = nil
g.onEvent("MERCHANT_SHOW")
local rec = g.env.ClosestVendorDB.learned[1]
eq(rec, nil, "npc id comes from the npcID field, not a neighbouring one")
rec = g.env.ClosestVendorDB.learned[1234]
eq(rec[2], "Fresh Vendor", "learned by npc id")
eq(rec[7], true, "repair capability recorded")
eq(rec[6], 0, "neutral faction")
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(lastPrinted(g):find("Fresh Vendor", 1, true) ~= nil, true, "learned vendor now nearest: " .. lastPrinted(g))

-- 9. Unidentifiable merchants and non-creatures are ignored without error.
g = boot(); login(g)
for _, npc in ipairs({ { guid = nil, name = "Ghost" }, { guid = "Player-0-0-0-0-0-0", name = "Someone" },
                       { guid = "Creature-0-1-1-1-77-1", name = nil } }) do
    g.npc = npc
    g.onEvent("MERCHANT_SHOW")
end
local c = 0
for _ in pairs(g.env.ClosestVendorDB.learned) do c = c + 1 end
eq(c, 0, "nothing learned from unidentifiable merchants")
g.npc = { guid = "Creature-0-1-1-1-88-1", name = "No Position" }
g.pos = nil
g.onEvent("MERCHANT_SHOW")
c = 0
for _ in pairs(g.env.ClosestVendorDB.learned) do c = c + 1 end
eq(c, 0, "no position: not learned, no error")

-- 10. Merchant window clears and does not re-request while condition holds.
g = boot({ tomtom = true }); login(g)
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.tomtom, 1, "shown")
g.npc = { guid = "Creature-0-1-1-1-90-1", name = "Visited" }
g.onEvent("MERCHANT_SHOW")
eq(g.tomtom.removed, true, "cleared at merchant")
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.tomtom, 1, "not re-requested")

-- 12. Slash command: registered, edits the saved settings, and applies at once.
g = boot()
eq(g.env.SLASH_CLOSESTVENDOR1, "/cvn", "slash alias")
eq(g.env.SLASH_CLOSESTVENDOR2, "/closestvendor", "long slash alias")
g.env.SlashCmdList.CLOSESTVENDOR("bags 5") -- before login: ignored, no error
login(g)
g.env.SlashCmdList.CLOSESTVENDOR("bags 25")
eq(g.env.ClosestVendorDB.cfg.bagThreshold, 25, "threshold saved in the saved-variables table")
eq(g.printed[1]:find("25 free slot", 1, true) ~= nil, true, "status printed")
eq(lastPrinted(g):find("Closest vendor:", 1, true) ~= nil, true, "20 free <= 25: navigation starts at once")

-- 11. Events before login do nothing and do not error.
g = boot()
g.onEvent("BAG_UPDATE_DELAYED")
g.onEvent("MERCHANT_SHOW")

-- 13. The question: shown instead of navigating; Yes (through the dialog's own OnAccept) navigates.
g = boot({ tomtom = true }); login(g)
g.autoAccept = false
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup ~= nil, true, "a question is shown")
eq(g.popup.which, "CLOSESTVENDOR_CONFIRM", "uses the registered dialog")
eq(g.popup.text:find("Ally Seller", 1, true) ~= nil, true, "names the vendor: " .. g.popup.text)
eq(g.popup.text:find("Test Zone", 1, true) ~= nil, true, "names the zone")
eq(g.popup.text:find("bags are almost full", 1, true) ~= nil, true, "says why")
eq(#g.tomtom, 0, "nothing navigates before Yes")
local dlg = g.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM
eq(dlg.text, "%s", "text passed as an argument")
eq(dlg.hideOnEscape, true, "Escape declines")
dlg.OnAccept(nil, g.popup.accept)
eq(g.tomtom[1], "Ally Seller", "Yes navigates")

-- 13b. Declining (doing nothing) does not navigate and does not ask again.
g = boot({ tomtom = true }); login(g)
g.autoAccept = false
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.shown, 1, "asked once")
eq(#g.tomtom, 0, "declined: no navigation")

-- 13c. The question closes when the condition clears or a merchant opens.
g = boot(); login(g)
g.autoAccept = false
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup ~= nil, true, "open")
g.free = 20
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "closed when the condition cleared")
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup ~= nil, true, "asked again after recurring")
g.npc = { guid = "Creature-0-1-1-1-90-1", name = "Visited" }
g.onEvent("MERCHANT_SHOW")
eq(g.popup, nil, "closed when a merchant opened")

-- 13d. A new question replaces one that is still open.
g = boot(); login(g)
g.autoAccept = false
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
local hiddenBefore = g.hidden or 0
g.dur = 10
g.onEvent("UPDATE_INVENTORY_DURABILITY")
eq((g.hidden or 0) > hiddenBefore, true, "old question hidden before the new one")
eq(g.popup.text:find("needs repair", 1, true) ~= nil, true, "now asks about repair")

-- 14. /cvn test: shows the dialog whatever the state; Yes sets the closest pin.
g = boot({ tomtom = true }); login(g)
g.autoAccept = false
g.free = 20; g.dur = 100; g.combat = true -- nothing would trigger on its own
g.env.SlashCmdList.CLOSESTVENDOR("test sell")
eq(g.popup ~= nil, true, "test sell shows the dialog")
eq(g.popup.text:find("bags are almost full", 1, true) ~= nil, true, "sell wording")
eq(g.popup.text:find("Ally Seller", 1, true) ~= nil, true, "names the nearest friendly vendor")
eq(#g.tomtom, 0, "no pin before Yes")
g.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM.OnAccept(nil, g.popup.accept)
eq(g.tomtom[1], "Ally Seller", "Yes sets the closest pin")
g.env.SlashCmdList.CLOSESTVENDOR("test repair")
eq(g.popup.text:find("needs repair", 1, true) ~= nil, true, "repair wording")
eq(g.popup.text:find("Far Repairer", 1, true) ~= nil, true, "names the nearest friendly repair vendor")
g.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM.OnAccept(nil, g.popup.accept)
eq(g.tomtom[2], "Far Repairer", "repair pin set")
eq(g.tomtom.removed, true, "previous pin removed")

-- 14b. /cvn test says why when it cannot ask; before login it does nothing.
g = boot(); login(g)
g.autoAccept = false
g.pos = nil
g.env.SlashCmdList.CLOSESTVENDOR("test sell")
eq(g.popup, nil, "no dialog without a position")
eq(lastPrinted(g):find("No map position", 1, true) ~= nil, true, "explained in chat: " .. lastPrinted(g))
g = boot()
g.env.SlashCmdList.CLOSESTVENDOR("test sell") -- before login: ignored, no error
eq(g.popup, nil, "nothing before login")

-- 14c. Between ADDON_LOADED and PLAYER_LOGIN there is no controller yet: no error, no dialog.
g = boot()
g.onEvent("ADDON_LOADED", "ClosestVendor")
g.env.SlashCmdList.CLOSESTVENDOR("test sell")
eq(g.popup, nil, "no dialog before login")

-- 14d. A test dialog is not replaced by a real trigger's dialog.
g = boot(); login(g)
g.autoAccept = false
g.free = 1 -- bags are full, but no event has fired yet
g.env.SlashCmdList.CLOSESTVENDOR("test repair")
eq(g.shown, 1, "only the test dialog was shown")
eq(g.popup.text:find("needs repair", 1, true) ~= nil, true, "the repair test dialog is still showing")

-- 15. Ammo: a bow with few arrows asks for the nearest arrow seller; Yes sets the pin.
g = boot({ tomtom = true }); login(g)
g.autoAccept = false
g.equipped = { [18] = 100, [0] = 200 }
g.counts = { [200] = 500 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "500 arrows: silent")
g.counts[200] = 150
g.onEvent("UNIT_INVENTORY_CHANGED", "player")
eq(g.popup ~= nil, true, "150 arrows: asks")
eq(g.popup.text:find("low on arrows (150 left)", 1, true) ~= nil, true, "text: " .. g.popup.text)
eq(g.popup.text:find("Arrow Man", 1, true) ~= nil, true, "nearest arrow seller, not the nearer non-sellers")
eq(#g.tomtom, 0, "nothing before Yes")
g.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM.OnAccept(nil, g.popup.accept)
eq(g.tomtom[1], "Arrow Man", "Yes sets the pin")

-- 15b. Only the player's inventory changes count; other units are ignored.
g = boot(); login(g)
g.autoAccept = false
g.equipped = { [18] = 100, [0] = 200 }; g.counts = { [200] = 10 }
g.onEvent("UNIT_INVENTORY_CHANGED", "target")
eq(g.popup, nil, "another unit's inventory is ignored")
g.onEvent("UNIT_INVENTORY_CHANGED", "player")
eq(g.popup ~= nil, true, "the player's is not")
eq(g.ns.frame.events.UNIT_INVENTORY_CHANGED, true, "registered UNIT_INVENTORY_CHANGED")
eq(g.ns.frame.events.PLAYER_EQUIPMENT_CHANGED, true, "registered PLAYER_EQUIPMENT_CHANGED")

-- 15c. Gun + arrows equipped counts as 0 and asks for bullets; equipping a weapon is noticed.
g = boot(); login(g)
g.autoAccept = false
g.equipped = { [0] = 200 }; g.counts = { [200] = 900 }
g.onEvent("PLAYER_EQUIPMENT_CHANGED")
eq(g.popup, nil, "no ranged weapon: not monitored")
g.equipped[18] = 101
g.onEvent("PLAYER_EQUIPMENT_CHANGED")
eq(g.popup ~= nil, true, "gun with arrows equipped: asks")
eq(g.popup.text:find("low on bullets", 1, true) ~= nil, true, "asks for bullets: " .. g.popup.text)
eq(g.popup.text:find("Gun Shop", 1, true) ~= nil, true, "bullet seller")

-- 15d. No ammo equipped with a bow: asks; thrown weapons and others never ask.
g = boot(); login(g)
g.autoAccept = false
g.equipped = { [18] = 100 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup ~= nil, true, "bow with no ammo: asks")
for _, weapon in ipairs({ 102, 103 }) do
    g = boot(); login(g)
    g.autoAccept = false
    g.equipped = { [18] = weapon }
    g.onEvent("BAG_UPDATE_DELAYED")
    eq(g.popup, nil, "weapon " .. weapon .. " is not monitored")
end

-- 15e. The ammo setting is used (and /cvn ammo changes it live).
g = boot(); login(g)
g.autoAccept = false
g.equipped = { [18] = 100, [0] = 200 }; g.counts = { [200] = 300 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "300 arrows is above the default 200")
g.env.SlashCmdList.CLOSESTVENDOR("ammo 400")
eq(g.env.ClosestVendorDB.cfg.ammoThreshold, 400, "saved")
eq(g.popup ~= nil, true, "now asks at once")
g = boot(); login(g)
g.autoAccept = false
g.equipped = { [18] = 100, [0] = 200 }; g.counts = { [200] = 0 }
g.env.SlashCmdList.CLOSESTVENDOR("ammo off")
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "ammo trigger off")

-- 16. Opening a merchant records what ammo it sells.
local function learnedAmmo(stock)
    local gg = boot(); login(gg)
    gg.npc = { guid = "Creature-0-1-1-1-777-1", name = "Stock Test" }
    gg.stock = stock
    gg.onEvent("MERCHANT_SHOW")
    return gg.env.ClosestVendorDB.learned[777][8]
end
eq(learnedAmmo({ 300 }), 0, "sells no ammo")
eq(learnedAmmo({ 300, 200 }), 1, "sells arrows")
eq(learnedAmmo({ 201, 300 }), 2, "sells bullets")
eq(learnedAmmo({ 200, 201 }), 3, "sells both")
eq(learnedAmmo({}), 0, "empty stock")
eq(learnedAmmo({ 400, 401 }), 0, "items with an ammo subclass number but another class do not count")

-- 16b. A learned ammo seller is chosen by the ammo trigger; a learned non-seller is not.
g = boot(); login(g)
g.autoAccept = false
g.npc = { guid = "Creature-0-1-1-1-888-1", name = "Quiver Shop" }
g.pos = { map = 100, x = 0.52, y = 0.5 }
g.stock = { 200 }
g.onEvent("MERCHANT_SHOW")
g.npc = { guid = "Creature-0-1-1-1-889-1", name = "Potion Shop" }
g.pos = { map = 100, x = 0.5, y = 0.5 }
g.stock = { 300 }
g.onEvent("MERCHANT_SHOW")
g.equipped = { [18] = 100, [0] = 200 }; g.counts = { [200] = 10 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup.text:find("Quiver Shop", 1, true) ~= nil, true, "learned arrow seller chosen: " .. g.popup.text)

-- 17. /cvn test arrows and bullets.
g = boot({ tomtom = true }); login(g)
g.autoAccept = false
g.env.SlashCmdList.CLOSESTVENDOR("test arrows")
eq(g.popup.text:find("sells arrows, Arrow Man", 1, true) ~= nil, true, "test arrows: " .. g.popup.text)
g.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM.OnAccept(nil, g.popup.accept)
eq(g.tomtom[1], "Arrow Man", "Yes sets the arrow pin")
g.env.SlashCmdList.CLOSESTVENDOR("test bullets")
eq(g.popup.text:find("sells bullets, Gun Shop", 1, true) ~= nil, true, "test bullets: " .. g.popup.text)

-- 18. Nothing printed to chat contains a lone "|" (a chat escape): help, status, errors, navigation text.
g = boot(); login(g)
for _, m in ipairs({ "", "help", "bags", "nonsense", "bags x", "test", "bags 5", "ammo 300", "test sell" }) do
    g.env.SlashCmdList.CLOSESTVENDOR(m)
end
for _, line in ipairs(g.printed) do
    local body = line:gsub("^|cff33ffccClosestVendor|r ", "")
    eq(body:find("|", 1, true), nil, "no pipe in printed text: " .. line)
end
eq(#g.printed >= 9, true, "the commands printed something")
-- ...and a pipe in a vendor name is doubled rather than sent as an escape (chat fallback text).
g = boot(); login(g)
g.npc = { guid = "Creature-0-1-1-1-901-1", name = "Odd|Vendor" }
g.pos = { map = 100, x = 0.51, y = 0.5 }
g.onEvent("MERCHANT_SHOW") -- learned, and now the nearest vendor
g.pos = { map = 100, x = 0.5, y = 0.5 }
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
local line = lastPrinted(g)
eq(line:find("Odd||Vendor", 1, true) ~= nil, true, "pipe doubled in chat: " .. line)
eq((line:gsub("^|cff33ffccClosestVendor|r ", ""):gsub("||", "")):find("|", 1, true), nil, "no lone pipe left")

-- 19. Settings page: registered against the saved settings, changes apply at once.
local function setting(g, key) for _, s in ipairs(g.settings.settings) do if s.key == key then return s end end end
g = boot({ settings = true }); login(g)
eq(g.settings.category.name, "Closest Vendor", "settings page registered")
eq(g.settings.registered, g.settings.category, "listed under AddOns")
eq(setting(g, "bagThreshold").tbl, g.env.ClosestVendorDB.cfg, "page edits the saved settings table")
eq(setting(g, "ammoThreshold").default, 200, "ammo default shown")
eq(setting(g, "bagThreshold").default, 2, "bag default shown")
g.autoAccept = false
g.free = 20
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "plenty of space: silent")
setting(g, "bagThreshold"):SetValue(25)
eq(g.env.ClosestVendorDB.cfg.bagThreshold, 25, "slider saved")
eq(g.popup ~= nil, true, "a slider change applies at once")

g = boot({ settings = true }); login(g)
g.autoAccept = false
g.free = 1
setting(g, "bagEnabled"):SetValue(false)
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "checkbox off: trigger stops asking")
setting(g, "bagEnabled"):SetValue(true)
eq(g.popup ~= nil, true, "checkbox on: asks again at once")

-- 19b. The slash command and the page see the same value.
g = boot({ settings = true }); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("ammo 500")
eq(setting(g, "ammoThreshold"):GetValue(), 500, "page shows what the command set")
setting(g, "durThreshold"):SetValue(35)
g.env.SlashCmdList.CLOSESTVENDOR("")
eq(table.concat(g.printed, "\n"):find("trigger below 35%", 1, true) ~= nil, true, "command shows what the page set")

-- 19c. /cvn config opens the page; without the API it says so; a throwing API never breaks the addon.
g = boot({ settings = true }); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("config")
eq(g.settings.opened, 42, "/cvn config opens the page")
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("config")
eq(lastPrinted(g):find("not available", 1, true) ~= nil, true, "no settings API: says so")
g = boot({ settings = true }); login(g)
g.env.Settings.OpenToCategory = function() error("settings are locked right now") end
g.env.SlashCmdList.CLOSESTVENDOR("config")
eq(lastPrinted(g):find("not available", 1, true) ~= nil, true, "a failing open says so instead of erroring")
g = boot({ settings = true, settingsThrows = true }); login(g)
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.printed >= 1, true, "the addon still works when the settings API throws")
g.env.SlashCmdList.CLOSESTVENDOR("config")
eq(lastPrinted(g):find("not available", 1, true) ~= nil, true, "throwing settings API: says so")

-- 20. Every game function the addon uses can be missing, or throw, without an error reaching the player,
-- and a trigger that does not depend on it keeps working.
local function breakApi(g, name, mode)
    local boom = function() error("game changed this function", 0) end
    local current = rawget(g.env, name)
    if mode == "missing" then
        g.env[name] = false
    elseif type(current) == "table" then
        local broken = {}
        for k, v in pairs(current) do broken[k] = type(v) == "function" and boom or v end
        g.env[name] = broken
    else
        g.env[name] = boom
    end
end

-- name, what must still work: "bags" (full bags still ask), "gear" (worn gear still asks), nil (nothing can be shown)
local APIS = {
    { "C_Container", "gear" },
    { "GetInventoryItemDurability", "bags" }, { "GetInventoryItemID", "bags" }, { "GetItemInfoInstant", "bags" },
    { "GetItemCount", "bags" }, { "UnitGUID", "bags" }, { "UnitName", "bags" }, { "CanMerchantRepair", "bags" },
    { "GetMerchantNumItems", "bags" }, { "GetMerchantItemLink", "bags" }, { "UnitFactionGroup", "bags" },
    { "InCombatLockdown", "bags" }, { "C_Timer", "bags" }, { "C_AddOns", "bags" },
    { "C_Map", false }, { "CreateVector2D", false }, { "StaticPopup_Show", false }, { "StaticPopup_Hide", "bags" },
    { "GetNumSkillLines", false }, { "GetSkillLineInfo", false }, { "TradeSkillFrame", false }, { "GetTradeSkillLine", false },
    { "IsTradeskillTrainer", false }, { "GetNumTrainerServices", false }, { "GetTrainerServiceSkillLine", false },
    { "StaticPopup_Visible", false },
}
for _, spec in ipairs(APIS) do
    for _, mode in ipairs({ "missing", "throws" }) do
        local label = spec[1] .. " " .. mode
        local g = boot({ tomtom = true })
        g.autoAccept = false
        breakApi(g, spec[1], mode)
        local ok, err = pcall(function()
            login(g)
            g.npc = { guid = "Creature-0-1-1-1-4242-1", name = "Visited" }
            g.stock = { 200 }
            g.equipped = { [18] = 100, [0] = 200 }; g.counts = { [200] = 10 }
            g.skillLines = { { "Mining", 70, 75 } }; g.tradeWindow = "Mining"; g.trainer = { "Mining" }
            for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY",
                                  "PLAYER_EQUIPMENT_CHANGED", "PLAYER_REGEN_ENABLED", "MERCHANT_SHOW", "TRAINER_SHOW", "TRAINER_UPDATE",
                                  "SKILL_LINES_CHANGED", "TRADE_SKILL_SHOW" }) do
                g.onEvent(ev)
            end
            g.skillLines = { { "Mining", 71, 75 } }
            g.onEvent("SKILL_LINES_CHANGED")
            g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
            g.onEvent("UNIT_INVENTORY_CHANGED", "player")
            for _, cmd in ipairs({ "", "bags 3", "trade 5", "test sell", "test repair", "test arrows", "test bullets", "config" }) do
                g.env.SlashCmdList.CLOSESTVENDOR(cmd)
            end
        end)
        eq(ok, true, label .. ": no error reaches the player (" .. tostring(err) .. ")")
    end
end

-- ...and unrelated triggers still work with each of those functions broken.
for _, spec in ipairs(APIS) do
    if spec[2] then
        for _, mode in ipairs({ "missing", "throws" }) do
            local g = boot({ tomtom = true })
            g.autoAccept = false
            breakApi(g, spec[1], mode)
            login(g)
            if spec[2] == "bags" then
                g.free = 1
                g.onEvent("BAG_UPDATE_DELAYED")
                eq(g.popup ~= nil, true, spec[1] .. " " .. mode .. ": full bags still ask")
            else
                g.free = 20; g.dur = 10
                g.onEvent("UPDATE_INVENTORY_DURABILITY")
                eq(g.popup ~= nil, true, spec[1] .. " " .. mode .. ": worn gear still asks")
                eq(g.popup.text:find("needs repair", 1, true) ~= nil, true, spec[1] .. " " .. mode .. ": and says why")
            end
        end
    end
end

-- A failing bag read must not look like full bags.
g = boot({ tomtom = true }); g.autoAccept = false
breakApi(g, "C_Container", "throws")
login(g)
g.free = 0
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "unreadable bags are not treated as full")

-- ...nor an unreadable ammo count as empty.
g = boot({ tomtom = true }); g.autoAccept = false
login(g)
g.equipped = { [18] = 100, [0] = 200 }
breakApi(g, "GetItemCount", "throws")
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "an unreadable ammo count is not treated as no ammo")

-- 21. Debug log: off by default, switched with /cvn debug, saved with the other settings.
local function logText(g) local t = {} for _, e in ipairs(g.env.ClosestVendorDB.log.entries) do t[#t + 1] = e.msg end return table.concat(t, "\n") end
local function has(text, part) return text:find(part, 1, true) ~= nil end
g = boot(); login(g)
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.env.ClosestVendorDB.log.entries, 0, "nothing recorded by default")
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
eq(g.env.ClosestVendorDB.log.enabled, true, "switched on and saved")
eq(has(lastPrinted(g), "Debug log on"), true, "says so")
g.onEvent("BAG_UPDATE_DELAYED")
g.onEvent("UNIT_INVENTORY_CHANGED", "player")
g.onEvent("UNIT_INVENTORY_CHANGED", "target")
g.onEvent("ADDON_LOADED", "SomeOtherAddon")
local text = logText(g)
eq(has(text, "event BAG_UPDATE_DELAYED"), true, "events recorded")
eq(has(text, "event UNIT_INVENTORY_CHANGED player"), true, "event arguments recorded")
eq(has(text, "UNIT_INVENTORY_CHANGED target"), false, "other units' inventory events are not noise")
eq(has(text, "SomeOtherAddon"), false, "other addons' loads are not recorded")
g.autoAccept = false
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
text = logText(g)
eq(has(text, "trigger go sell (bags=1"), true, "decisions recorded with their values")
eq(has(text, "question shown: sell"), true, "question recorded")
g.env.SlashCmdList.CLOSESTVENDOR("debug off")
local count = #g.env.ClosestVendorDB.log.entries
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.env.ClosestVendorDB.log.entries, count, "off again: nothing more recorded")

-- Saved variables: the switch and the entries survive a reload.
g = boot({ db = { log = { enabled = true, entries = { { t = 1, msg = "from the last session" } } } } }); login(g)
eq(has(logText(g), "from the last session"), true, "entries restored")
eq(has(logText(g), "---- login ----"), true, "a login marker separates sessions")

-- A failing game call is logged once, with its error, however many times it fails.
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
breakApi(g, "GetInventoryItemDurability", "throws")
for _ = 1, 5 do g.onEvent("UPDATE_INVENTORY_DURABILITY") end
local _, failures = logText(g):gsub("game call failed: GetInventoryItemDurability: game changed this function", "")
eq(failures, 1, "five failures, one log line")

-- 22. /cvn log: a copyable window with the facts and the log.
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
g.onEvent("BAG_UPDATE_DELAYED")
g.env.SlashCmdList.CLOSESTVENDOR("log")
local win
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
eq(win ~= nil and win.shown, true, "the report window is shown")
local report = win.box.text
eq(report:find("^Closest Vendor report\n") ~= nil, true, "starts with a title")
for _, part in ipairs({ "addon version: 0.1.0", "game: 1.60.1 build 70790, interface 16001", "locale: enUS", "navigation: chat",
                        "vendors: 7 shipped, 0 learned, per continent: 1:6", "settings: bags on/2, durability on/20, ammo on/200",
                        "Debug log: on", "event BAG_UPDATE_DELAYED" }) do
    eq(has(report, part), true, "report contains '" .. part .. "'")
end
eq(win.box.highlighted and win.box.focused, true, "text is selected, ready to copy")
eq(g.env.UISpecialFrames[1], "ClosestVendorReport", "Escape closes the window")
g.env.SlashCmdList.CLOSESTVENDOR("log")
local windows = 0
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then windows = windows + 1 end end
eq(windows, 1, "asking again reuses the window")

-- The report works with the log off, and says how to turn it on.
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("log")
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
eq(has(win.box.text, "Debug log: off (turn it on with /cvn debug on"), true, "log off: report says how to turn it on")
eq(has(win.box.text, "addon version: 0.1.0"), true, "log off: still has the facts")

-- Navigation shown in the report follows what is installed.
g = boot({ tomtom = true }); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("log")
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
eq(has(win.box.text, "navigation: tomtom"), true, "report names the navigation method in use")

-- No window available: the facts and the newest entries go to chat; a pipe cannot escape.
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
g.env.ClosestVendorDB.log.entries[#g.env.ClosestVendorDB.log.entries + 1] = { t = 1, msg = "odd|text" }
g.frameThrows = "ClosestVendorReport"
g.env.SlashCmdList.CLOSESTVENDOR("log")
local chat = table.concat(g.printed, "\n")
eq(has(chat, "addon version: 0.1.0"), true, "fallback prints the facts")
eq(has(chat, "odd||text"), true, "fallback prints the entries, pipe doubled")
for i = 1, 40 do g.env.ClosestVendorDB.log.entries[#g.env.ClosestVendorDB.log.entries + 1] = { t = i, msg = "filler " .. i } end
g.printed = {}
g.env.SlashCmdList.CLOSESTVENDOR("log")
local filler = 0
for _, line in ipairs(g.printed) do if line:find("filler", 1, true) then filler = filler + 1 end end
eq(filler, 20, "fallback prints only the newest 20 entries")
eq(has(table.concat(g.printed, "\n"), "filler 40"), true, "the newest is among them")

-- /cvn log clear.
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.env.ClosestVendorDB.log.entries > 0, true, "something to clear")
g.env.SlashCmdList.CLOSESTVENDOR("log clear")
eq(#g.env.ClosestVendorDB.log.entries, 0, "cleared")
eq(g.env.ClosestVendorDB.log.enabled, true, "clearing does not switch it off")
eq(has(lastPrinted(g), "Debug log cleared"), true, "says so")

-- Before login the commands do nothing and do not error.
g = boot()
g.env.SlashCmdList.CLOSESTVENDOR("log")
g.env.SlashCmdList.CLOSESTVENDOR("debug on")

-- 23. A translation containing "|" cannot start a chat escape: it is doubled when printed.
g = boot(); login(g)
g.ns.L["Opening the settings page..."] = "translated|text"
g.env.SlashCmdList.CLOSESTVENDOR("config")
local printedAll = table.concat(g.printed, "\n")
eq(has(printedAll, "translated||text"), true, "pipe doubled in translated chat text")
eq(has((printedAll:gsub("||", "")):gsub("|cff33ffccClosestVendor|r", ""), "|"), false, "no lone pipe is left")

-- 24. Profession trainers: learned from the trainer window, used when a profession nears its cap.
local function visit(g, id, name, trades, at)
    g.npc = { guid = "Creature-0-4372-0-55-" .. id .. "-0000A1B2C3", name = name }
    g.npcFaction = "Alliance"
    g.trainer = trades
    if at then g.pos = at end
    g.onEvent("TRAINER_SHOW")
    g.npc, g.trainer = nil, nil
end

g = boot({ tomtom = true }); login(g)
visit(g, 5513, "Gelman Stonehand", { "Mining", "Engineering" }, { map = 100, x = 0.6, y = 0.5 })
local DB = g.env.ClosestVendorDB
eq(DB.trainers[5513][2], "Gelman Stonehand", "trainer learned")
eq(DB.trainers[5513][7].Mining and DB.trainers[5513][7].Engineering, true, "with what it teaches")
eq(DB.trainers[5513][6], 1, "and its faction")
eq(DB.professions.Mining and DB.professions.Engineering, true, "professions seen at the trainer")
g.onEvent("TRAINER_UPDATE")
local npcCount = 0
for _ in pairs(DB.trainers) do npcCount = npcCount + 1 end
eq(npcCount, 1, "a second event does not add a record")

-- A class trainer, an unloaded trainer window and an unidentified NPC are not recorded.
g.npc = { guid = "Creature-0-1-1-1-777-1", name = "Class Trainer" }
g.onEvent("TRAINER_SHOW")
eq(DB.trainers[777], nil, "class trainer not recorded")
g.trainer = {}
g.onEvent("TRAINER_SHOW")
eq(DB.trainers[777], nil, "services not loaded: not recorded")
g.trainer, g.npc = { "Mining" }, nil
g.onEvent("TRAINER_SHOW")
npcCount = 0
for _ in pairs(DB.trainers) do npcCount = npcCount + 1 end
eq(npcCount, 1, "no NPC: nothing recorded")

-- Skill-up near the cap: asks, names the trainer, Yes sets the pin.
g.autoAccept = false
g.pos = { map = 100, x = 0.5, y = 0.5 }
g.skillLines = { { "Mining", 70, 75 } }
g.onEvent("SKILL_LINES_CHANGED")
eq(g.popup, nil, "first skill read only stores")
g.skillLines = { { "Mining", 71, 75 } }
g.onEvent("SKILL_LINES_CHANGED")
eq(g.popup ~= nil, true, "a skill-up near the cap asks")
eq(has(g.popup.text, "Mining") and has(g.popup.text, "4 point") and has(g.popup.text, "Gelman Stonehand") and has(g.popup.text, "Test Zone"), true, "text names profession, points, trainer and zone")
g.popup.accept()
eq(g.tomtom[#g.tomtom], "Gelman Stonehand", "Yes points at the trainer")

-- A craft with a tradeskill window open asks too (after the trip is over); other units and closed windows do not.
g.onEvent("TRAINER_SHOW") -- no npc: nothing, pin stays
g.npc = { guid = "Creature-0-4372-0-55-5513-0000A1B2C3", name = "Gelman Stonehand" }; g.trainer = { "Mining" }
g.onEvent("TRAINER_SHOW")
g.npc, g.trainer = nil, nil
g.popup = nil
g.tradeWindow = nil
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g.popup, nil, "a cast with no tradeskill window is not a craft")
g.tradeWindow = "Mining"
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "target")
eq(g.popup, nil, "another unit's cast is ignored")
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g.popup ~= nil, true, "a craft near the cap asks (no skill-up needed)")
g.popup = nil

-- Learned trainers are saved and used after a reload.
local saved = g.env.ClosestVendorDB
local g2 = boot({ tomtom = true, db = saved }); login(g2)
g2.autoAccept = false
g2.skillLines = { { "Mining", 70, 75 } }; g2.tradeWindow = "Mining"
g2.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g2.popup ~= nil and has(g2.popup.text, "Gelman Stonehand"), true, "learned trainer survives a reload")

-- A profession first seen in a crafting window, no trainer known: told once in chat, no question.
g = boot({ tomtom = true }); login(g)
g.skillLines = { { "Tailoring", 70, 75 } }; g.tradeWindow = "Tailoring"
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g.env.ClosestVendorDB.professions.Tailoring, true, "profession learned from the crafting window")
eq(g.popup, nil, "no trainer, no question")
eq(has(table.concat(g.printed, "\n"), "No known trainer for Tailoring"), true, "told in chat")
local told = #g.printed
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(#g.printed, told, "not repeated")

-- A skill that was never seen at a trainer or window is ignored (weapon skills).
g = boot({ tomtom = true }); login(g)
g.skillLines = { { "Swords", 70, 75 } }
g.onEvent("SKILL_LINES_CHANGED")
g.skillLines = { { "Swords", 71, 75 } }
g.onEvent("SKILL_LINES_CHANGED")
eq(g.popup, nil, "unseen skill ignored")

-- Settings: command, off switch, report and debug log.
g = boot({ tomtom = true }); login(g)
visit(g, 5513, "Gelman Stonehand", { "Mining" }, { map = 100, x = 0.6, y = 0.5 })
g.pos = { map = 100, x = 0.5, y = 0.5 }
g.autoAccept = false
g.skillLines = { { "Mining", 60, 75 } }; g.tradeWindow = "Mining"
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g.popup, nil, "15 away with the default 10")
g.env.SlashCmdList.CLOSESTVENDOR("trade 20")
eq(g.env.ClosestVendorDB.cfg.tradeThreshold, 20, "/cvn trade sets it")
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g.popup ~= nil, true, "asks with the raised threshold")
g.popup = nil
g.env.SlashCmdList.CLOSESTVENDOR("trade off")
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g.popup, nil, "off: no question")
g.env.SlashCmdList.CLOSESTVENDOR("log")
local rep
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then rep = f end end
local reportBox = rep.box.text
eq(has(reportBox, "trainers: 1 learned, professions seen: Mining"), true, "report counts trainers and professions")
eq(has(reportBox, "professions off/20"), true, "report shows the profession setting")
eq(has(reportBox, "question shown: trainer for Mining"), true, "debug log has the decision")

-- Edge cases found by mutation testing.
-- The new events are registered.
g = boot(); login(g)
for _, e in ipairs({ "TRAINER_SHOW", "TRAINER_UPDATE", "SKILL_LINES_CHANGED", "TRADE_SKILL_SHOW", "UNIT_SPELLCAST_SUCCEEDED" }) do
    eq(g.ns.frame.events[e], true, e .. " registered")
end

-- A trainer window with services that load late: TRAINER_UPDATE alone records it.
g = boot({ tomtom = true }); login(g)
g.npc = { guid = "Creature-0-4372-0-55-900-0000A1B2C3", name = "Late Trainer" }; g.npcFaction = "Alliance"; g.trainer = { "Mining" }
g.onEvent("TRAINER_UPDATE")
eq(g.env.ClosestVendorDB.trainers[900] ~= nil, true, "recorded on TRAINER_UPDATE")

-- No map position at the trainer: not recorded (a trainer without a place is useless).
g = boot({ tomtom = true }); login(g)
g.pos = nil
visit(g, 901, "Lost Trainer", { "Mining" })
eq(g.env.ClosestVendorDB.trainers[901], nil, "no position: not recorded")
eq(g.env.ClosestVendorDB.professions.Mining, true, "but the profession was still seen")

-- Opening a tradeskill window teaches the profession, but is not a craft.
g = boot({ tomtom = true }); login(g)
visit(g, 5513, "Gelman Stonehand", { "Mining" }, { map = 100, x = 0.6, y = 0.5 })
g.pos = { map = 100, x = 0.5, y = 0.5 }
g.autoAccept = false
g.skillLines = { { "Mining", 70, 75 } }; g.tradeWindow = "Mining"
g.onEvent("TRADE_SKILL_SHOW")
eq(g.popup, nil, "opening the window is not a craft")
-- An open question is not shown again on the next craft.
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g.shown, 1, "asked")
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g.shown, 1, "the question is still showing: not shown again")

-- The trainer nearest the player's real position is chosen (x and y are not swapped).
g = boot({ tomtom = true }); login(g)
visit(g, 1, "Trainer A", { "Mining" }, { map = 100, x = 0.7, y = 0.5 })
visit(g, 2, "Trainer B", { "Mining" }, { map = 100, x = 0.5, y = 0.65 })
g.pos = { map = 100, x = 0.2, y = 0.5 }
g.autoAccept = false
g.skillLines = { { "Mining", 70, 75 } }; g.tradeWindow = "Mining"
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(has(g.popup.text, "Trainer B"), true, "the nearer trainer by real coordinates")

H.done()
