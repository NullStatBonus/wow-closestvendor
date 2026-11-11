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
    g.frames, g.time, g.hudTimers = {}, 100, {}
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
        function f:CreateFontString() self.fontString = g.newFrame("FontString"); return self.fontString end
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
        IsInInstance = function() if g.instance then return true, g.instance end return false, "none" end,
        GetBindLocation = function() return g.bind end,
        UnitFactionGroup = function(u) if u == "player" then return "Alliance" end return g.npcFaction end,
        UnitGUID = function() return g.npc and g.npc.guid end,
        UnitName = function() return g.npc and g.npc.name end,
        CanMerchantRepair = function() return g.repairable end,
        -- The status window's redraw timer (0.25 s) is kept apart from the retry timer.
        C_Timer = { After = function(s, fn) local t = s == 0.25 and g.hudTimers or g.timers; t[#t + 1] = fn end },
        C_AddOns = { IsAddOnLoaded = function(name) return opts.tomtom and name == "TomTom" end },
        NUM_BAG_SLOTS = 4,
        GetInventoryItemID = function(_, slot) return g.equipped and g.equipped[slot] end,
        GetItemInfoInstant = function(id)
            local i = g.items[id]
            if not i then return end
            return id, "type", "sub", "", 0, i[1], i[2]
        end,
        GetItemCount = function(id) return g.counts and g.counts[id] or 0 end,
        UnitClass = function() return "Mage", g.class or "MAGE", 8 end,
        IsPlayerSpell = function(id) return g.spells ~= nil and g.spells[id] == true end,
        GetItemInfo = function(id) return g.itemNames and g.itemNames[id] end,
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
            if g.autoAccept ~= false then (type(data) == "table" and data.accept or data)() end -- tests say g.autoAccept = false to hold it open
        end,
        StaticPopup_Hide = function() g.popup = nil; g.hidden = (g.hidden or 0) + 1 end,
        ClosestVendorDB = opts.db,
    }
    if opts.tomtom then
        env.TomTom = { AddWaypoint = function(_, map, x, y, o) g.tomtom[#g.tomtom + 1] = o.title; return {} end,
                       RemoveWaypoint = function() g.tomtom.removed = true end }
    end
    if opts.settings then
        local S, rec = fakeSettings.new(nil, { swatch = opts.swatch })
        if opts.settingsThrows then S.RegisterVerticalLayoutCategory = function() error("settings API changed") end end
        env.Settings, g.settings = S, rec
        env.MinimalSliderWithSteppersMixin = { Label = { Right = "right" } }
    end
    setmetatable(env, { __index = _G })
    env._G = env

    local ns = {}
    for _, f in ipairs({ "Locales/enUS", "Triggers", "Ammo", "Professions", "Reagents", "Status", "Adapter", "Search", "Discovery", "Nav", "Controller", "Commands", "Options", "Log", "Report", "Tracker" }) do
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
    { "UnitClass", "bags" }, { "IsPlayerSpell", "bags" }, { "GetItemInfo", "bags" },
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
                                  "SKILL_LINES_CHANGED", "TRADE_SKILL_SHOW", "SPELLS_CHANGED" }) do
                g.onEvent(ev)
            end
            g.skillLines = { { "Mining", 71, 75 } }
            g.onEvent("SKILL_LINES_CHANGED")
            g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
            g.onEvent("UNIT_INVENTORY_CHANGED", "player")
            for _, cmd in ipairs({ "", "bags 3", "trade 5", "test sell", "test repair", "test arrows", "test bullets", "test reagent", "config" }) do
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
                        "vendors: 7 shipped, 0 learned, per continent: 1:6", "settings: bags on/2, durability on/20, ammo on/200", "target choice: ask, prefers map, on-screen notice on",
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

-- 30. Closest target on another map: the three-button question and auto mode.
local function twoMaps()
    local g = boot({ tomtom = true })
    g.ns.ShippedVendors = {
        { 91, "Home Shop",  100, 0.9, 0.9, 0, false }, -- on the player's map, farther
        { 92, "Other Shop", 200, 0.55, 0.5, 0, false }, -- on another map, closer
    }
    login(g)
    return g
end
g = twoMaps(); g.autoAccept = false
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup.which, "CLOSESTVENDOR_CONFIRM_MAP", "map preference: the map target is the first button")
eq(g.popup.text:find("Home Shop", 1, true) ~= nil and g.popup.text:find("Other Shop", 1, true) ~= nil, true, "names both targets: " .. g.popup.text)
eq(g.popup.text:find("yards", 1, true) ~= nil, true, "shows distances")
local d3 = g.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM_MAP
eq(d3.hideOnEscape, true, "Escape cancels")
eq(type(d3.button1) == "string" and type(d3.button3) == "string" and type(d3.button2) == "string", true, "three buttons")
eq(g.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM_DISTANCE.button1, d3.button3, "the distance copy swaps the first two buttons")
eq(#g.tomtom, 0, "nothing before a choice")
d3.OnAlt(nil, nil)
eq(#g.tomtom, 0, "missing data is harmless")
local data = g.popup.accept
d3.OnAlt(nil, data)
eq(g.tomtom[1], "Other Shop", "second button navigates to the closer target")
g = twoMaps(); g.autoAccept = false
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
d3.OnAccept(nil, g.popup.accept)
eq(g.tomtom[1], "Home Shop", "first button navigates to the map target")

g = twoMaps(); g.autoAccept = false
g.env.SlashCmdList.CLOSESTVENDOR("prefer distance")
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup.which, "CLOSESTVENDOR_CONFIRM_DISTANCE", "distance preference: the closer target is the first button")

g = twoMaps()
g.env.SlashCmdList.CLOSESTVENDOR("choice auto")
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "auto: no question")
eq(g.tomtom[1], "Home Shop", "auto: pinned the map target")
local note = "Navigating to Home Shop (Test Zone, 566 yards) to sell items and free bag space. The other choice was Other Shop (Test Zone, 50 yards)."
eq(lastPrinted(g):find(note, 1, true) ~= nil, true, "auto: chat names both targets with zone and distance: " .. lastPrinted(g))
local box
for _, f in ipairs(g.frames) do if f.fontString and f.name == nil and f.scripts.OnUpdate then box = f end end
eq(box ~= nil and box.fontString.text, note, "auto: the same text is shown on screen")
eq(box.shown, true, "auto: the message is visible")
box.scripts.OnUpdate(box, 5.1)
eq(box.shown, false, "auto: and gone after about five seconds")
g.env.SlashCmdList.CLOSESTVENDOR("notice off")
g.free = 20
g.onEvent("BAG_UPDATE_DELAYED")
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(box.shown, false, "notice off: nothing more on screen")

-- 31. Class reagents: watched when the spell is known, asked about at or below the threshold, learned
-- from merchants, switched off one by one, covered by the master switch.
local function mage(over)
    local gg = boot({ tomtom = true })
    gg.ns.ShippedVendors = {
        { 81, "Plain Shop",   100, 0.51, 0.5, 0, false, 0, 0 },
        { 82, "Reagent Shop", 100, 0.70, 0.5, 0, false, 0, 1 }, -- sells Arcane Powder (bit 0)
    }
    gg.spells = { [23028] = true } -- Arcane Brilliance
    gg.counts = { [17020] = 3 }
    for k, v in pairs(over or {}) do gg[k] = v end
    login(gg)
    gg.autoAccept = false
    return gg
end
g = mage()
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup ~= nil, true, "a low reagent asks")
eq(has(g.popup.text, "Arcane Powder"), true, "names the reagent: " .. g.popup.text)
eq(has(g.popup.text, "3 left") and has(g.popup.text, "Reagent Shop"), true, "count and the seller, not the nearest shop")
eq(has(g.popup.text, "Plain Shop"), false, "the nearest vendor that does not sell it is not offered")
g.popup.accept()
eq(g.tomtom[1], "Reagent Shop", "Yes navigates to the seller")
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.shown, 1, "not asked again")

-- The game's own item name is used when it has one.
g = mage({ itemNames = { [17020] = "Pulver der Arkanen" } })
g.onEvent("BAG_UPDATE_DELAYED")
eq(has(g.popup.text, "Pulver der Arkanen"), true, "uses the client's item name")

-- Plenty, an unknown spell, another class, a switched-off reagent and the master switch all stay quiet.
g = mage({ counts = { [17020] = 40 } }); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "plenty")
g = mage({ spells = {} }); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "spell not known")
g = mage({ class = "WARRIOR" }); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "a class without reagents")
g = mage(); g.env.ClosestVendorDB.cfg.reagentOff[17020] = true; g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "switched off")
g = mage(); g.env.SlashCmdList.CLOSESTVENDOR("ammo off"); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "master switch off")

-- Learning the spell later is noticed.
g = mage({ spells = {} }); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "not yet")
g.spells[23028] = true
g.onEvent("SPELLS_CHANGED")
eq(g.popup ~= nil, true, "asks once the spell is learned")

-- Unreadable counts are not "none".
g = mage(); breakApi(g, "GetItemCount", "throws"); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "an unreadable reagent count is not treated as none")

-- A settings default exists and the off-list is created for old saved data.
g = boot({ tomtom = true, db = { cfg = { ammoThreshold = 100 } } }); login(g)
eq(g.env.ClosestVendorDB.cfg.reagentThreshold, 5, "default reagent threshold")
eq(type(g.env.ClosestVendorDB.cfg.reagentOff), "table", "off-list exists")
eq(g.env.ClosestVendorDB.cfg.ammoThreshold, 100, "saved settings kept")

-- Merchants: the reagents they sell are learned, and a learned record keeps them.
g = mage(); g.autoAccept = true
g.npc = { guid = "Creature-0-4372-0-55-1234-0000A1B2C3", name = "New Shop" }
g.pos = { map = 100, x = 0.51, y = 0.5 }
g.stock = { 300, 17020, 17032 }
g.onEvent("MERCHANT_SHOW")
eq(g.env.ClosestVendorDB.learned[1234][9], 1 + 4, "reagent mask learned")
g = mage(); g.autoAccept = true
g.npc = { guid = "Creature-0-4372-0-55-82-0000A1B2C3", name = "Reagent Shop" }
g.pos = { map = 100, x = 0.7, y = 0.5 }
g.stock = { 17020 }
g.onEvent("MERCHANT_SHOW")
eq(g.env.ClosestVendorDB.learned[82][9], 1, "a shipped reagent vendor keeps its reagent when opened")
g.counts[17020] = 2; g.onEvent("BAG_UPDATE_DELAYED")
eq(g.shown, 1, "and is still found as a seller")
eq(has(g.popup.text, "Reagent Shop"), true, "learned record still offered: " .. g.popup.text)

-- The debug report lists the threshold, the watched reagents and the switched-off ones.
g = mage(); g.env.ClosestVendorDB.cfg.reagentOff[17031] = true
g.env.SlashCmdList.CLOSESTVENDOR("log")
local rwin
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then rwin = f end end
eq(has(rwin.box.text, "reagents: class MAGE, threshold 5, watching: Arcane Powder:3, switched off: Rune of Teleportation"), true, "report line")
eq(has(rwin.box.text, "reagent buying: off, asks first, up to 20 of each"), true, "report lists reagent buying")

-- Reagent buying at a merchant: off by default, asks in a dialog of its own, buys up to the amount
-- counting what is carried (the warning's count), uses the money an ammo purchase left.
local function reagentShop(over)
    local gg = mage(over)
    local e = gg.env
    gg.npc = { guid = "Creature-0-4372-0-55-82-0000A1B2C3", name = "Reagent Shop" }
    gg.pos = { map = 100, x = 0.7, y = 0.5 }
    gg.stock = { 17020 }
    gg.bought, gg.money = {}, 100000
    e.GetMerchantItemInfo = function() return "Arcane Powder", "tex", 100, 1, -1, true, false end
    e.GetMerchantItemMaxStack = function() return 20 end
    e.GetMoney = function() return gg.money end
    e.BuyMerchantItem = function(i, q) gg.bought[#gg.bought + 1] = i .. ":" .. tostring(q) end
    e.GetContainerNumSlots = function(b) return b == 0 and 16 or 0 end
    e.GetContainerItemInfo = function() return nil end
    e.GetItemInfo = function() return "Arcane Powder", "l", 1, 1, 1, "", "", 20 end
    return gg
end
g = reagentShop()
cfg = g.env.ClosestVendorDB.cfg
eq(tostring(cfg.reagentBuyEnabled) .. "/" .. tostring(cfg.reagentBuyPrompt) .. "/" .. cfg.reagentBuyTarget, "false/true/20", "defaults: off, ask first, 20")
g.onEvent("MERCHANT_SHOW")
eq(#g.bought, 0, "off by default: nothing bought")
g.env.SlashCmdList.CLOSESTVENDOR("reagentbuy on")
g.onEvent("MERCHANT_SHOW")
eq(g.popup and g.popup.which, "CLOSESTVENDOR_CONFIRM_REAGENTS", "asks in its own dialog")
eq(g.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM_REAGENTS ~= nil, true, "which is registered")
eq(g.popup.text, "Buy 17 Arcane Powder for 17s 0c?", "3 carried: 17 to reach 20")
eq(#g.bought, 0, "nothing before Yes")
g.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM_REAGENTS.OnAccept(nil, g.popup.accept)
eq(table.concat(g.bought, ","), "1:17", "Yes buys, in one call")
eq(has(lastPrinted(g), "Bought 17 Arcane Powder for 17s 0c."), true, "and says so: " .. lastPrinted(g))
g = reagentShop(); g.autoAccept = true
g.env.SlashCmdList.CLOSESTVENDOR("reagentbuy on"); g.env.SlashCmdList.CLOSESTVENDOR("reagentbuy auto")
g.ns.Ammo.OnMerchant = function() return 2, 99000 end -- an ammo purchase a moment before
g.onEvent("MERCHANT_SHOW")
eq(table.concat(g.bought, ","), "1:10", "buys at once with the money the ammo left")
eq(has(lastPrinted(g), "(all you could afford)"), true, "partial: " .. lastPrinted(g))
g = boot({ db = { cfg = { reagentBuyTarget = 150 } } }); login(g)
eq(g.env.ClosestVendorDB.cfg.reagentBuyTarget, 100, "a saved amount above 100 is held to 100")
g = boot({ db = { cfg = { reagentBuyTarget = -3 } } }); login(g)
eq(g.env.ClosestVendorDB.cfg.reagentBuyTarget, 0, "and one below 0 to 0")

-- Instances. Full bags in a battleground: nothing is asked inside, and the question comes after
-- leaving (it used to be lost for good).
g = boot(); login(g); g.autoAccept = false
g.env.ClosestVendorDB.log.enabled = true
g.onEvent("PLAYER_ENTERING_WORLD")
g.instance = "pvp"
g.onEvent("PLAYER_ENTERING_WORLD")
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.shown, nil, "battleground: no question inside")
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.shown, nil, "still none")
g.instance = nil
g.onEvent("PLAYER_ENTERING_WORLD")
eq(g.shown, 1, "asked after leaving with full bags")
local function logged(game, text)
    for _, e in ipairs(game.env.ClosestVendorDB.log.entries or {}) do if e.msg:find(text, 1, true) then return true end end
    return false
end
eq(logged(g, "instance: none -> pvp"), true, "entering is logged")
eq(logged(g, "instance: pvp -> none"), true, "leaving is logged")
-- An unreadable instance state is the open world.
g = boot(); login(g); g.autoAccept = false
g.env.IsInInstance = nil
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.shown, 1, "unknown instance state: asked as in the open world")

-- The last position outside is kept while in the open world, and left alone inside an instance.
g = boot(); login(g)
g.onEvent("PLAYER_ENTERING_WORLD")
local lo = g.env.ClosestVendorDB.lastOutside
eq(lo.continent .. ":" .. lo.map .. ":" .. lo.x .. ":" .. lo.y, "1:100:500:500", "position saved with its continent and map")
g.pos = { map = 100, x = 0.6, y = 0.5 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.env.ClosestVendorDB.lastOutside.x, 600, "follows the player outside")
g.instance = "party"; g.pos = { map = 100, x = 0.1, y = 0.1 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.env.ClosestVendorDB.lastOutside.x, 600, "not updated in a dungeon")
g.instance = nil; g.pos = nil
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.env.ClosestVendorDB.lastOutside.x, 600, "no position: the old one is kept")
g = boot(); login(g); g.pos = nil
g.onEvent("PLAYER_ENTERING_WORLD")
eq(g.env.ClosestVendorDB.lastOutside, nil, "never had a position: nothing saved")

-- The hearthstone point. The first bind name seen has no position (bound before the addon saw it);
-- a new name takes the player's position.
g = boot(); login(g); g.bind = "Goldshire"
g.env.ClosestVendorDB.log.enabled = true
g.onEvent("PLAYER_ENTERING_WORLD")
local hearth = g.env.ClosestVendorDB.hearth
eq(hearth.name, "Goldshire", "bind name remembered")
eq(hearth.continent, nil, "but no position: it was bound earlier")
g.onEvent("ZONE_CHANGED_NEW_AREA")
eq(g.env.ClosestVendorDB.hearth.continent, nil, "same name: still no position")
g.bind = "Stormwind"; g.pos = { map = 100, x = 0.3, y = 0.4 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.env.ClosestVendorDB.hearth.name, "Goldshire", "only read on login and zone change")
g.instance = "party"
g.onEvent("ZONE_CHANGED_NEW_AREA")
eq(g.env.ClosestVendorDB.hearth.name, "Goldshire", "not learned inside an instance")
g.instance = nil; g.pos = nil
g.onEvent("ZONE_CHANGED_NEW_AREA")
eq(g.env.ClosestVendorDB.hearth.name, "Goldshire", "no position: the old point is kept")
g.pos = { map = 100, x = 0.3, y = 0.4 }
g.onEvent("ZONE_CHANGED_NEW_AREA")
hearth = g.env.ClosestVendorDB.hearth
eq(hearth.name .. ":" .. hearth.continent .. ":" .. hearth.map .. ":" .. hearth.x .. ":" .. hearth.y, "Stormwind:1:100:300:400", "rebind: the player's position becomes the point")
eq(logged(g, "hearthstone point learned: Stormwind"), true, "and it is logged")
g.bind = nil
g.onEvent("ZONE_CHANGED_NEW_AREA")
eq(g.env.ClosestVendorDB.hearth.name, "Stormwind", "an unreadable bind name keeps the point")

-- ---- Status window, its settings and auctioneers ----

-- New saved keys get their defaults; old settings are kept.
g = boot({ db = { cfg = { hudScale = 150, hudRow = { bags = "always" } }, hud = { point = "TOP", x = 5, y = -5 } } }); login(g)
cfg = g.env.ClosestVendorDB.cfg
eq(cfg.hudScale, 150, "saved scale kept")
eq(cfg.hudRow.bags, "always", "saved row mode kept")
eq(g.env.ClosestVendorDB.hud.point, "TOP", "saved position kept")
eq(tostring(cfg.hudLocked) .. "/" .. cfg.hudAlpha .. "/" .. cfg.instanceAnchor .. "/" .. tostring(cfg.ahEnabled), "false/80/hearth/false", "defaults: unlocked, opacity 80, hearth anchor, auction house off")
-- Keys an earlier build saved per row, and modes that are not one, are dropped at login.
g = boot({ db = { cfg = { hudRow = { ["prof:Mining"] = "always", ["reagent:17020"] = "never", reagents = "always", bags = "sometimes", [3] = "never" } } } }); login(g)
local kept = {}
for k, v in pairs(g.env.ClosestVendorDB.cfg.hudRow) do kept[#kept + 1] = tostring(k) .. "=" .. tostring(v) end
eq(table.concat(kept, ","), "reagents=always", "only a group key with a real mode is kept")
g = boot({ db = { cfg = { hudRow = "broken" } } }); login(g)
eq(type(g.env.ClosestVendorDB.cfg.hudRow), "table", "a hudRow that is not a table is replaced")
g = boot(); login(g)
cfg = g.env.ClosestVendorDB.cfg
eq(cfg.hudScale, 100, "default scale")
eq(type(cfg.hudRow) == "table" and next(cfg.hudRow) == nil, true, "row modes start empty: every row has its default")
eq(type(g.env.ClosestVendorDB.hud) == "table" and next(g.env.ClosestVendorDB.hud) == nil, true, "no saved position yet")
eq(type(g.env.ClosestVendorDB.auctioneers), "table", "learned auctioneer table created")
local g2 = boot(); login(g2)
eq(g2.env.ClosestVendorDB.cfg.hudRow ~= cfg.hudRow, true, "each saved table is its own")
eq(cfg.hudAlpha .. "/" .. cfg.hudTextAlpha .. "/" .. cfg.hudColor, "80/100/000000", "defaults: background 80%, text 100%, pure black")
-- Saved window numbers outside their ranges are held to them; a colour that is not one is black again.
g = boot({ db = { cfg = { hudAlpha = -5, hudTextAlpha = 5, hudScale = 900, hudColor = "fff" } } }); login(g)
cfg = g.env.ClosestVendorDB.cfg
eq(cfg.hudAlpha .. "/" .. cfg.hudTextAlpha .. "/" .. cfg.hudScale .. "/" .. cfg.hudColor, "0/20/200/000000", "held to the limits, a bad colour is black")
g = boot({ db = { cfg = { hudAlpha = 150, hudTextAlpha = 400, hudColor = 7 } } }); login(g)
cfg = g.env.ClosestVendorDB.cfg
eq(cfg.hudAlpha .. "/" .. cfg.hudTextAlpha .. "/" .. cfg.hudColor, "100/100/000000", "held to 100")
g = boot({ db = { cfg = { hudAlpha = "dim", hudTextAlpha = false, hudColor = "1a2b3c" } } }); login(g)
cfg = g.env.ClosestVendorDB.cfg
eq(cfg.hudAlpha .. "/" .. cfg.hudTextAlpha .. "/" .. cfg.hudColor, "80/100/1a2b3c", "not a number: the default; a real colour is kept")
g = boot({ db = { cfg = { hudAlpha = 0 } } }); login(g)
eq(g.env.ClosestVendorDB.cfg.hudAlpha, 0, "background 0 is kept, not replaced by the default")

-- The window: built at login, drawn once per burst of events by one short timer.
local function window(game)
    local w = { rows = {} }
    for _, f in ipairs(game.frames) do
        if f.name == "ClosestVendorTracker" then w.frame = f
        elseif w.frame and f.kind == "Button" then
            if not w.cog then w.cog = f else w.rows[#w.rows + 1] = f end
        end
    end
    return w
end
local function flush(game)
    local t = game.hudTimers
    game.hudTimers = {}
    for _, fn in ipairs(t) do fn() end
end
local function shownRows(game)
    local out = {}
    for _, b in ipairs(window(game).rows) do if b.shown then out[#out + 1] = b.fontString.text end end
    return table.concat(out, " | ")
end
g = boot({ tomtom = true }); login(g); g.autoAccept = false
local w = window(g)
eq(w.frame ~= nil, true, "the window frame is built at login")
flush(g)
eq(w.frame.shown, false, "nothing low: no window")
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED"); g.onEvent("BAG_UPDATE_DELAYED"); g.onEvent("UNIT_INVENTORY_CHANGED", "player")
eq(#g.hudTimers, 1, "three events, one redraw timer")
eq(w.frame.shown, false, "not redrawn before the timer")
flush(g)
eq(w.frame.shown, true, "bags low: the window shows")
eq(shownRows(g), "Bag space: 1 free", "with the bag row only")
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.hudTimers, 1, "the timer is armed again after it fired")
g.free = 20; flush(g)
eq(w.frame.shown, false, "bags fine again: hidden")
-- Modes: a command applies at once, without waiting for an event.
g.env.SlashCmdList.CLOSESTVENDOR("hud row durability always")
eq(shownRows(g), "Durability: 100%", "row set to always is shown right away")
g.env.SlashCmdList.CLOSESTVENDOR("hud row durability never")
eq(w.frame.shown, false, "and hidden again when set to never")
-- Other addons' unit events do not touch the window.
g.onEvent("UNIT_INVENTORY_CHANGED", "target")
eq(#g.hudTimers, 0, "another unit's inventory: no redraw")

-- Reagents and display-only items in the window; the warning switch does not hide a row.
g = boot(); login(g); g.autoAccept = false
g.spells = { [23028] = true, [5504] = true }; g.counts = { [17020] = 3, [5350] = 3, [2288] = 10 }
g.env.ClosestVendorDB.cfg.reagentOff[17020] = true
g.onEvent("SPELLS_CHANGED"); flush(g)
eq(shownRows(g), "Arcane Powder: 3", "a low reagent shows even with its warning switched off")
eq(g.popup, nil, "and no question is asked about it")
g.env.SlashCmdList.CLOSESTVENDOR("hud row reagents always")
eq(shownRows(g), "Arcane Powder: 3 | Conjured Water: 13", "Reagents always shows conjured water, summed over its ranks")

-- Clicking a row pins at once, without a question, and is logged.
g = boot({ tomtom = true }); login(g); g.autoAccept = false
g.env.ClosestVendorDB.log.enabled = true
g.env.SlashCmdList.CLOSESTVENDOR("hud row durability always")
w = window(g)
eq(g.env.ClosestVendorDB.cfg.vendorMode, "ask", "choice mode is ask")
w.rows[1].scripts.OnClick()
eq(g.tomtom[#g.tomtom], "Far Repairer", "click on the durability row pins the repair vendor")
eq(g.popup, nil, "no question")
eq(has(lastPrinted(g), "Navigating to Far Repairer"), true, "the notice says where: " .. lastPrinted(g))
eq(logged(g, "row click: durability"), true, "the click is logged with its row")
eq(logged(g, "accepted: Far Repairer"), true, "and what was pinned")
-- In combat too.
g.combat = true; g.tomtom = {}
w.rows[1].scripts.OnClick()
eq(g.tomtom[1], "Far Repairer", "a click works in combat")
g.combat = false
-- A display-only row does nothing.
g = boot({ tomtom = true }); login(g); g.class = "WARLOCK"
g.spells = { [5699] = true }; g.counts = { [6265] = 4 }
eq(window(g).frame.shown, false, "soul shards hidden while Reagents is only when low")
g.env.SlashCmdList.CLOSESTVENDOR("hud row reagents always")
eq(shownRows(g), "Soul Shards: 4", "soul shards row once Reagents is always")
window(g).rows[1].scripts.OnClick()
eq(#g.tomtom, 0, "click on a display-only row: no waypoint")
eq(g.popup, nil, "and no question")

-- Lock, Shift-drag and the saved position.
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("hud row bags always")
w = window(g)
local moved = 0
w.frame.StartMoving = function() moved = moved + 1 end
w.frame.GetPoint = function() return "TOPLEFT", nil, "TOPLEFT", 40, -50 end
w.rows[1].scripts.OnDragStart()
eq(moved, 0, "dragging a row without Shift does nothing")
g.env.IsShiftKeyDown = function() return true end
w.rows[1].scripts.OnDragStart(); w.rows[1].scripts.OnDragStop()
eq(moved, 1, "Shift-drag moves the window")
eq(g.env.ClosestVendorDB.hud.x .. ":" .. g.env.ClosestVendorDB.hud.y, "40:-50", "position saved")
g.env.SlashCmdList.CLOSESTVENDOR("hud lock")
w.rows[1].scripts.OnDragStart()
eq(moved, 1, "locked: Shift-drag does nothing")
g.env.SlashCmdList.CLOSESTVENDOR("hud reset")
eq(next(g.env.ClosestVendorDB.hud), nil, "/cvn hud reset forgets the position")
local point
w.frame.SetPoint = function(_, p, _, _, x, y) point = p .. ":" .. x .. ":" .. y end
g.env.SlashCmdList.CLOSESTVENDOR("hud scale 150")
eq(point, "LEFT:60:60", "the window is at its default position")
eq(g.env.ClosestVendorDB.cfg.hudScale, 150, "scale saved")

-- The cog opens the main settings page, or says it cannot.
g = boot({ settings = true }); login(g)
window(g).cog.scripts.OnClick()
eq(g.settings.opened, 42, "cog opens the Closest Vendor page")
g = boot(); login(g)
window(g).cog.scripts.OnClick()
eq(has(lastPrinted(g), "settings page is not available"), true, "no settings page: chat says so")
-- A settings-page change redraws the window at once.
g = boot({ settings = true }); login(g)
g.env.ClosestVendorDB.cfg.hudRow.bags = "always"
for _, st in ipairs(g.settings.settings) do if st.key == "hudLocked" then st:SetValue(true) end end
eq(shownRows(g), "Bag space: 20 free", "changing a setting on the page redraws the window")

-- Skills are read once and kept until they change; every row never reads nothing.
g = boot(); login(g)
local skillReads = 0
g.skillLines = { { "Mining", 70, 75 } }
g.env.GetNumSkillLines = function() skillReads = skillReads + 1 return #g.skillLines end
g.env.ClosestVendorDB.professions.Mining = true
g.onEvent("BAG_UPDATE_DELAYED"); flush(g)
g.onEvent("BAG_UPDATE_DELAYED"); flush(g)
eq(shownRows(g), "Mining: 70/75", "a profession near its cap shows")
eq(skillReads, 1, "two redraws, skills read once")
g.skillLines = { { "Mining", 75, 150 } }
g.onEvent("BAG_UPDATE_DELAYED"); flush(g)
eq(shownRows(g), "Mining: 70/75", "no skill event yet: the kept list is used")
g.onEvent("SKILL_LINES_CHANGED"); flush(g)
eq(window(g).frame.shown, false, "skill event: read again, no longer near the cap")
g.skillLines = { { "Mining", 145, 150 } }
g.onEvent("SKILL_LINES_CHANGED"); flush(g)
eq(shownRows(g), "Mining: 145/150", "near the next cap")
for _, name in ipairs({ "ammo", "bags", "durability", "professions", "reagents" }) do
    g.env.SlashCmdList.CLOSESTVENDOR("hud row " .. name .. " never")
end
eq(window(g).frame.shown, false, "every row never: no window")
g.onEvent("SKILL_LINES_CHANGED")
local before = skillReads -- the warning's own read
local bagReads = 0
local realFree = g.env.C_Container.GetContainerNumFreeSlots
g.env.C_Container = { GetContainerNumFreeSlots = function(bag) bagReads = bagReads + 1 return realFree(bag) end }
flush(g)
eq(skillReads - before .. "/" .. bagReads, "0/0", "every row never: the redraw reads nothing")

-- No frames for the window: the addon works without it.
g = boot(); g.frameThrows = "ClosestVendorTracker"; login(g)
g.env.ClosestVendorDB.log.enabled = true
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.hudTimers, 0, "no window: no redraw timer")
eq(has(lastPrinted(g), "Ally Seller"), true, "warnings still work")
g.env.SlashCmdList.CLOSESTVENDOR("hud scale 120")
eq(g.env.ClosestVendorDB.cfg.hudScale, 120, "and so do the window commands")
-- No timers: the window is redrawn directly.
g = boot(); login(g); flush(g)
g.env.C_Timer = nil
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(shownRows(g), "Bag space: 1 free", "no timers: redrawn at once")

-- The report header lists the window, anchor and auction settings.
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("hud row bags always")
g.env.SlashCmdList.CLOSESTVENDOR("hud row durability low") -- the default: not listed
g.env.SlashCmdList.CLOSESTVENDOR("hud lock")
g.env.SlashCmdList.CLOSESTVENDOR("anchor last")
g.env.SlashCmdList.CLOSESTVENDOR("ah on")
g.env.SlashCmdList.CLOSESTVENDOR("log")
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
for _, part in ipairs({ "status window: locked, scale 100%, opacity 80%, color #000000, text opacity 100%, built, rows: bags=always\n",
                        "instance anchor: last, auction house routing: on, auctioneers: 0 shipped, 0 learned" }) do
    eq(has(win.box.text, part), true, "report contains '" .. part .. "': " .. win.box.text)
end
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("log")
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
eq(has(win.box.text, "status window: unlocked, scale 100%, opacity 80%, color #000000, text opacity 100%, built, rows: all default"), true, "defaults in the report")
eq(has(win.box.text, "instance anchor: hearth, auction house routing: off"), true, "default anchor and auction setting")

-- Auctioneers: shipped ones are loaded, an opened one is learned and replaces the shipped record.
g = boot()
g.ns.ShippedAuctioneers = { { 50, "Auctioneer Far", 100, 0.90, 0.50, 0 }, { 51, "Auctioneer Lost", 999, 0.5, 0.5, 0 } }
login(g)
eq(g.frames[1].events.AUCTION_HOUSE_SHOW, true, "the auction house event is registered")
g.npc = { guid = "Creature-0-4372-0-55-50-0000A1B2C3", name = "Auctioneer Near" }
g.pos = { map = 100, x = 0.52, y = 0.5 }
g.onEvent("AUCTION_HOUSE_SHOW")
local arec = g.env.ClosestVendorDB.auctioneers[50]
eq(arec[2] .. ":" .. arec[3] .. ":" .. arec[4] .. ":" .. arec[6], "Auctioneer Near:100:0.52:0", "auctioneer learned at the player's position")
g.npc = { guid = "Player-0-0-0-0-0-0", name = "Someone" }
g.onEvent("AUCTION_HOUSE_SHOW")
g.npc = { guid = "Creature-0-4372-0-55-60-0000A1B2C3", name = "No Position" }; g.pos = nil
g.onEvent("AUCTION_HOUSE_SHOW")
local an = 0
for _ in pairs(g.env.ClosestVendorDB.auctioneers) do an = an + 1 end
eq(an, 1, "a non-creature or a missing position learns nothing")
g.env.SlashCmdList.CLOSESTVENDOR("log")
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
eq(has(win.box.text, "auctioneers: 2 shipped, 1 learned"), true, "report counts the auctioneers")
-- With auction routing on, a reagent row click goes to the learned auctioneer when it is closer than a vendor.
g = boot({ tomtom = true, db = { learned = { [90] = { 90, "Powder Seller", 100, 0.9, 0.5, 0, false, 0, 1 } } } })
login(g)
g.npc = { guid = "Creature-0-4372-0-55-50-0000A1B2C3", name = "Auctioneer Near" }
g.pos = { map = 100, x = 0.52, y = 0.5 }
g.onEvent("AUCTION_HOUSE_SHOW") -- learned in this session: usable without a reload
g.pos = { map = 100, x = 0.5, y = 0.5 }
g.spells = { [23028] = true }; g.counts = { [17020] = 3 }
g.onEvent("SPELLS_CHANGED"); flush(g)
g.autoAccept = false; g.tomtom = {}
window(g).rows[1].scripts.OnClick()
eq(g.tomtom[#g.tomtom], "Powder Seller", "auction routing off: the vendor")
g.env.SlashCmdList.CLOSESTVENDOR("ah on")
window(g).rows[1].scripts.OnClick()
eq(g.tomtom[#g.tomtom], "Auctioneer Near", "auction routing on: the auctioneer just learned, which is closer")

-- /cvn demo: a made-up window and one warning, rolled from the game time, gone after 10 seconds,
-- with the saved settings exactly as they were.
local function deep(t)
    if type(t) ~= "table" then return tostring(t) end
    local parts = {}
    for k, v in pairs(t) do parts[#parts + 1] = tostring(k) .. "=" .. deep(v) end
    table.sort(parts)
    return "{" .. table.concat(parts, ",") .. "}"
end
g = boot({ tomtom = true }); login(g); g.autoAccept = false; flush(g)
g.env.ClosestVendorDB.cfg.hudRow.bags = "never"
local savedCfg, savedHud = deep(g.env.ClosestVendorDB.cfg), deep(g.env.ClosestVendorDB.hud)
g.time = 123.456
g.env.SlashCmdList.CLOSESTVENDOR("demo")
w = window(g)
local demoRows = shownRows(g)
eq(w.frame.shown and demoRows ~= "", true, "demo: the window shows made-up rows")
eq(g.popup ~= nil or #g.tomtom > 0, true, "demo: and a warning, as a question or a waypoint")
eq(#g.timers, 1, "demo: one timer to end it")
g.onEvent("BAG_UPDATE_DELAYED"); flush(g)
eq(shownRows(g), demoRows, "demo: an ordinary redraw does not bring the real rows back early")
eq(deep(g.env.ClosestVendorDB.cfg), savedCfg, "demo: saved settings untouched while it runs")
g.timers[1]()
eq(w.frame.shown, false, "demo over: the real window (nothing low, so hidden) is back")
eq(g.popup, nil, "demo over: no question left open")
eq(#g.tomtom == 0 or g.tomtom.removed == true, true, "demo over: a waypoint it set is removed")
eq(deep(g.env.ClosestVendorDB.cfg), savedCfg, "demo over: saved settings exactly as before")
eq(deep(g.env.ClosestVendorDB.hud), savedHud, "demo over: saved position exactly as before")
-- The same game time rolls the same demo; other times roll others, through every kind of warning.
g.env.SlashCmdList.CLOSESTVENDOR("demo")
eq(shownRows(g), demoRows, "the same time gives the same window")
g.timers[#g.timers]()
local sawQuestion, sawPin, sawNotice, windowsSeen = false, false, false, {}
for i = 1, 40 do
    g.time = 200 + i * 1.7
    g.tomtom = {}
    local printed = #g.printed
    g.env.SlashCmdList.CLOSESTVENDOR("demo")
    windowsSeen[shownRows(g)] = true
    if g.popup then sawQuestion = true end
    if #g.tomtom > 0 then
        sawPin = true
        if #g.printed > printed and has(lastPrinted(g), "Navigating to") then sawNotice = true end
    end
    eq((g.popup ~= nil) ~= (#g.tomtom > 0), true, "each demo has exactly one warning")
    g.timers[#g.timers]()
    eq(g.popup == nil and (#g.tomtom == 0 or g.tomtom.removed == true), true, "each demo cleans up after itself")
end
eq(sawQuestion and sawPin and sawNotice, true, "questions, pins and notices all turn up")
local n = 0
for _ in pairs(windowsSeen) do n = n + 1 end
eq(n > 10, true, "and the windows differ")
eq(deep(g.env.ClosestVendorDB.cfg), savedCfg, "after 42 demos the saved settings are still exactly as before")
-- A second demo during the first re-rolls and restarts the time: the first timer does nothing.
g.time = 300; g.env.SlashCmdList.CLOSESTVENDOR("demo")
local firstTimer = g.timers[#g.timers]
g.time = 301.3; g.env.SlashCmdList.CLOSESTVENDOR("demo")
local second = shownRows(g)
firstTimer()
eq(w.frame.shown and shownRows(g) == second, true, "the first demo's timer does not end the second demo")
g.timers[#g.timers]()
eq(w.frame.shown, false, "the second demo's timer does")
-- Before login, without a window, and without timers: no error, nothing shown.
g = boot(); g.env.SlashCmdList.CLOSESTVENDOR("demo")
g = boot({ tomtom = true }); g.frameThrows = "ClosestVendorTracker"; login(g); g.autoAccept = false
g.time = 123.456
g.env.SlashCmdList.CLOSESTVENDOR("demo")
eq(g.popup ~= nil or #g.tomtom > 0, true, "no window: the warning is still shown")
g.timers[#g.timers]()
eq(g.popup == nil and (#g.tomtom == 0 or g.tomtom.removed == true), true, "and taken back")
g = boot({ tomtom = true }); login(g); flush(g); g.autoAccept = false
g.env.C_Timer = nil
g.env.SlashCmdList.CLOSESTVENDOR("demo")
eq(window(g).frame.shown == false and g.popup == nil and #g.tomtom == 0, true, "no timers: no demo, since nothing could end it")

-- Background colour: /cvn hud color with no colour opens the game's picker, the report says what the
-- client offers and why the settings swatch was or was not built.
do
    local function reportOf(g)
        g.env.SlashCmdList.CLOSESTVENDOR("log")
        local w
        for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then w = f end end
        return w.box.text
    end
    local function picker(g)
        local p = { shown = false }
        function p:SetColorRGB(r, gg, b) self.rgb = { r, gg, b } end
        function p:GetColorRGB() return self.rgb[1], self.rgb[2], self.rgb[3] end
        function p:Show() self.shown = true end
        g.env.ColorPickerFrame = p
        return p
    end
    g = boot({ settings = true }); g.env.CreateSettingsButtonInitializer = function(n, t, onClick) return { text = t, onClick = onClick, data = {} } end
    local p = picker(g); login(g)
    eq(#g.settings.buttons, 1, "swatch built where picker and button exist")
    eq(has(reportOf(g), "color picker: available, settings button: available, background color control built"), true, "report: built")
    g.env.SlashCmdList.CLOSESTVENDOR("hud color")
    eq(p.shown, true, "/cvn hud color opens the picker")
    eq(p.rgb[1] .. "," .. p.rgb[2] .. "," .. p.rgb[3], "0,0,0", "at the saved colour")
    p.rgb = { 1, 0, 0.5 }; p.func() -- the player picks
    eq(g.env.ClosestVendorDB.cfg.hudColor, "ff0080", "a pick from the command is saved")
    -- No picker, no button maker: say so in chat, log the reasons, show them in the report.
    g = boot({ settings = true }); login(g)
    g.env.SlashCmdList.CLOSESTVENDOR("hud color")
    eq(has(lastPrinted(g), "This game has no color picker; use /cvn hud color #rrggbb"), true, "chat says there is no picker")
    local text = reportOf(g)
    eq(has(text, "color picker: missing, settings button: missing, background color control not built, missing: color picker (ColorPickerFrame), CreateSettingsButtonInitializer"), true, "report names what is missing: " .. text)
    g = boot({ settings = true }); g.env.SlashCmdList = g.env.SlashCmdList; g.env.ClosestVendorDB = { log = { enabled = true, entries = {} } }
    login(g)
    local logged = false
    for _, e in ipairs(g.env.ClosestVendorDB.log.entries) do if has(e.msg, "background color control not built, missing:") then logged = true end end
    eq(logged, true, "the reason is in the debug log")
    -- Era and Forever: the game's own swatch row, where its picker takes the swatch's calls.
    g = boot({ settings = true, swatch = true }); g.env.CreateSettingsButtonInitializer = function(n, t, onClick) return { text = t, onClick = onClick, data = {} } end
    p = picker(g); p.SetupColorPickerAndShow = function() end; p.GetPreviousValues = function() end
    login(g)
    eq(#g.settings.swatches .. "/" .. #g.settings.buttons, "1/0", "swatch row, not a button")
    eq(has(reportOf(g), "background color control built as a swatch"), true, "report: swatch")
    g.settings.swatches[1].setting:SetValue("ff336699")
    eq(g.env.ClosestVendorDB.cfg.hudColor, "336699", "a swatch pick is saved")
    -- A client with no settings page at all.
    g = boot(); login(g)
    eq(has(reportOf(g), "background color control not built, missing: the Settings API"), true, "report: no settings API")
end

H.done()
