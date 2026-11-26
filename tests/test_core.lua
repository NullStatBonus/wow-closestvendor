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
    g.frames, g.time, g.hudTimers, g.gearTimers = {}, 100, {}, {}
    -- A frame that records what the addon needs to see and ignores every other call.
    function g.newFrame(kind, name)
        local f = { kind = kind, name = name, events = {}, scripts = {}, shown = false }
        function f:RegisterEvent(e) self.events[e] = true end
        function f:SetScript(event, fn)
            if event == "OnEvent" then
                -- Worn-gear events are checked after a short delay; onEvent runs that check at once, rawEvent leaves it queued.
                g.rawEvent = function(ev, a) fn(self, ev, a) end
                g.onEvent = function(ev, a)
                    fn(self, ev, a)
                    if ev == "UPDATE_INVENTORY_DURABILITY" or ev == "UNIT_INVENTORY_CHANGED" then
                        local t = g.gearTimers; g.gearTimers = {}
                        for _, run in ipairs(t) do run() end
                    end
                end
            else self.scripts[event] = fn end
        end
        function f:SetText(t) self.text = t end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:IsShown() return self.shown end
        function f:HighlightText() self.highlighted = true end
        function f:SetFocus() self.focused = true end
        function f:CreateTexture() return g.newFrame("Texture") end
        function f:CreateFontString() local text = g.newFrame("FontString"); self.fontString = self.fontString or text; return text end
        -- Unrecorded API calls (CapitalizedMethods) do nothing; other missing fields stay nil.
        return setmetatable(f, { __index = function(_, k) if k:match("^%u") then return function() end end end })
    end
    local env = {
        print = function(t) g.printed[#g.printed + 1] = t end,
        CreateFrame = function(kind, name, parent)
            if g.frameThrows and name == g.frameThrows then error("no frames today", 0) end
            local f = g.newFrame(kind, name)
            f.parent = parent
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
        UnitIsDeadOrGhost = function(u) return u == "player" and g.dead end,
        IsInInstance = function() if g.instance then return true, g.instance end return false, "none" end,
        GetBindLocation = function() return g.bind end,
        UnitFactionGroup = function(u) if u == "player" then return "Alliance" end return g.npcFaction end,
        UnitGUID = function() return g.npc and g.npc.guid end,
        UnitName = function() return g.npc and g.npc.name end,
        CanMerchantRepair = function() return g.repairable end,
        -- The status window's redraw timer (0.25 s) is kept apart from the retry timer.
        C_Timer = { After = function(s, fn) local t = s == 0.25 and g.hudTimers or s == 0.2 and g.gearTimers or g.timers; t[#t + 1] = fn end },
        C_AddOns = { IsAddOnLoaded = function(name) return opts.tomtom and name == "TomTom" end },
        NUM_BAG_SLOTS = 4,
        GetInventoryItemID = function(_, slot) return g.equipped and g.equipped[slot] end,
        GetItemInfoInstant = function(id)
            -- As in the game, every real item has a class (15 miscellaneous unless listed); only an
            -- id in g.unloaded reads as nothing.
            if g.unloaded and g.unloaded[id] then return end
            local i = g.items[id] or { 15, 0 }
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
        StaticPopup_Visible = function(which) return g.popup and g.popup.which == which and "StaticPopup1" or nil end,
        SlashCmdList = {},
        StaticPopupDialogs = {},
        StaticPopup_Show = function(which, text, _, data)
            g.popup = { which = which, text = text, accept = type(data) == "table" and data.accept or data, data = data }
            g.shown = (g.shown or 0) + 1
            if g.autoAccept ~= false then (type(data) == "table" and data.accept or data)() end -- tests say g.autoAccept = false to hold it open
        end,
        StaticPopup_Hide = function(which) if g.popup and g.popup.which == which then g.popup = nil end; g.hidden = (g.hidden or 0) + 1 end,
        ClosestVendorDB = opts.db,
        NorgannonDB = opts.ng,
        ClosestVendorCharDB = opts.charDb,
        CheckThat = opts.checkThat,
    }
    if opts.tomtom then
        env.TomTom = { AddWaypoint = function(_, map, x, y, o) g.tomtom[#g.tomtom + 1] = o.title; return {} end,
                       RemoveWaypoint = function() g.tomtom.removed = true end }
    end
    if opts.settings then
        local S, rec = fakeSettings.new(nil, { swatch = opts.swatch })
        if opts.settingsThrows then S.RegisterVerticalLayoutCategory = function() error("settings API changed") end end
        env.Settings = S
        env.LibStub, g.settings = require("fake_ace").new({ failRegister = opts.settingsThrows })
        env.MinimalSliderWithSteppersMixin = { Label = { Right = "right" } }
    end
    setmetatable(env, { __index = _G })
    env._G = env

    local ns = {}
    for _, f in ipairs({ "Locales/enUS", "Triggers", "Ammo", "Professions", "Reagents", "Supplies", "Status", "Adapter", "Search", "Discovery", "Nav", "Controller", "Presentation", "Move", "Toast", "Commands", "Options", "Log", "Report", "Tracker", "CheckThat" }) do
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
eq(g.env.ClosestVendorCharDB, nil, "other addon's load ignored")
login(g)
local cfg = g.env.ClosestVendorCharDB.cfg
eq(cfg.bagThreshold, 5, "existing value kept")
eq(cfg.durThreshold, 20, "default filled in")
eq(cfg.bagEnabled, true, "default flag filled in")
eq(cfg.tradeThreshold, 10, "profession threshold default")
eq(cfg.tradeEnabled, true, "profession switch default")
eq(g.env.ClosestVendorDB.trainers ~= nil and g.env.ClosestVendorCharDB.professions ~= nil, true, "trainer and profession tables created")

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

-- 4b. A chosen waypoint is used first, though TomTom is loaded; the choice is saved per character.
do
    local gn = boot({ tomtom = true })
    local pinned = {}
    gn.env.C_Map.CanSetUserWaypointOnMap = function() return true end
    gn.env.C_Map.SetUserWaypoint = function(p) pinned[#pinned + 1] = p end
    gn.env.C_SuperTrack = { SetSuperTrackedUserWaypoint = function() end }
    gn.env.UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { uiMapID = m, position = { x = x, y = y } } end }
    login(gn)
    gn.env.SlashCmdList.CLOSESTVENDOR("nav native")
    eq(gn.env.ClosestVendorCharDB.cfg.navProvider, "native", "/cvn nav saved on the character")
    gn.dur = 10
    gn.onEvent("UPDATE_INVENTORY_DURABILITY")
    eq(#pinned, 1, "the chosen game waypoint was set")
    eq(gn.tomtom[1], nil, "and TomTom was not used")
end

-- 4c. After No, a next warning with no map position is retried once a position comes back (#39).
do
    local gr = boot({ tomtom = true }); login(gr)
    gr.autoAccept = false
    gr.free, gr.dur = 1, 10
    gr.onEvent("UPDATE_INVENTORY_DURABILITY")
    eq(gr.popup.text:find("repair") ~= nil, true, "repair question open")
    gr.pos = nil
    gr.popup.data.decline()
    local function runTimers() local t = gr.timers; gr.timers = {}; for _, fn in ipairs(t) do fn() end end
    runTimers() -- the re-check after No: no position, the sell request waits
    eq(#gr.timers > 0, true, "the position retry is armed")
    gr.pos = { map = 100, x = 0.5, y = 0.5 }
    runTimers()
    eq(gr.popup ~= nil and gr.popup.text:find("bags") ~= nil, true, "the sell question is asked once a position is back")
end

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
eq(g.env.ClosestVendorCharDB.cfg.bagThreshold, 25, "threshold saved in the saved-variables table")
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

-- 13a. No (or Escape) to the first question asks the next need; a replaced question is not a No.
g = boot({ tomtom = true }); login(g)
g.autoAccept = false
g.dur, g.free = 10, 1
g.onEvent("UPDATE_INVENTORY_DURABILITY")
eq(((g.popup and g.popup.text or ""):find("repair", 1, true) ~= nil), true, "repair asked first")
local repairData, before = g.popup.data, g.shown
dlg.OnCancel(nil, repairData, "override")
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.shown, before, "a replaced question is not an answer: nothing new asked")
dlg.OnCancel(nil, repairData, "clicked")
g.onEvent("BAG_UPDATE_DELAYED")
eq(((g.popup and g.popup.text or ""):find("bags are almost full", 1, true) ~= nil), true, "No to repair: selling is asked next")
eq(#g.tomtom, 0, "No navigates nowhere")

-- 13d. Changing zone withdraws a warning's open question; it is asked again from the new place.
g = boot({ tomtom = true }); login(g)
g.autoAccept = false
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
local zoneShown = g.shown
g.instance = "party"
g.onEvent("ZONE_CHANGED_NEW_AREA")
eq(g.popup, nil, "entering an instance closes the question")
g.instance = nil
g.onEvent("ZONE_CHANGED_NEW_AREA")
eq(g.shown, zoneShown + 1, "outside again: asked again")

-- 13c. Dead or a ghost: no question is shown or used up; coming back to life asks.
g = boot({ tomtom = true }); login(g)
g.autoAccept = false
g.dead, g.free = true, 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "dead: no question")
eq(g.ns.frame.events.PLAYER_UNGHOST and g.ns.frame.events.PLAYER_ALIVE, true, "listens for coming back to life")
g.dead = false
g.onEvent("PLAYER_UNGHOST")
eq(((g.popup and g.popup.text or ""):find("bags are almost full", 1, true) ~= nil), true, "alive again: asked")

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

-- Reputation: a neutral vendor another character taught is used only once this character has seen it
-- trade (merchant window, or Neutral or better on target, mouseover or nameplate); one seen as
-- Unfriendly or Hostile is never used.
do
    local gq = boot({ tomtom = true, db = { learned = { [77] = { 77, "Gorhak", 100, 0.52, 0.50, 0, false } } } }); login(gq)
    gq.autoAccept = false
    local reaction
    gq.env.UnitReaction = function() return reaction end
    gq.env.SlashCmdList.CLOSESTVENDOR("test sell")
    eq(gq.popup.text:find("Gorhak", 1, true), nil, "an unseen learned neutral vendor is not offered")
    gq.npc = { guid = "Creature-0-4372-0-55-77-0000A1B2C3", name = "Gorhak" }
    reaction = 5; gq.onEvent("PLAYER_TARGET_CHANGED")
    gq.env.SlashCmdList.CLOSESTVENDOR("test sell")
    eq(gq.popup.text:find("Gorhak", 1, true) ~= nil, true, "seen as Friendly: now the closest")
    reaction = 3; gq.onEvent("UPDATE_MOUSEOVER_UNIT")
    eq(gq.env.ClosestVendorCharDB.standing[77], false, "Unfriendly is remembered for this character")
    gq.env.SlashCmdList.CLOSESTVENDOR("test sell")
    eq(gq.popup.text:find("Gorhak", 1, true), nil, "seen as Unfriendly: never offered")
    reaction = nil; gq.onEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
    eq(gq.env.ClosestVendorCharDB.standing[77], false, "no reaction from the game changes nothing")
    gq.npc = { guid = "Creature-0-4372-0-55-999-0000A1B2C3", name = "Some Mob" }
    reaction = 2; gq.onEvent("PLAYER_TARGET_CHANGED")
    eq(gq.env.ClosestVendorCharDB.standing[999], nil, "a creature that is not a known vendor is not stored")
    gq.env.SlashCmdList.CLOSESTVENDOR("log")
    local rw; for _, f in ipairs(gq.frames) do if f.name == "ClosestVendorReport" then rw = f end end
    eq(rw ~= nil and rw.box.text:find("standing (this character): 0 vendors trade, 1 will not", 1, true) ~= nil, true, "the report counts what this character has seen")
end

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
eq(g.env.ClosestVendorCharDB.cfg.ammoThreshold, 400, "saved")
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
local function setting(g, key)
    local found
    local function scan(args)
        for k, o in pairs(args) do
            if k == key or (g.ns.Presentation.KEYS[k] and g.ns.Presentation.KEYS[k].storage == key) then found = o end
            if o.args then scan(o.args) end
        end
    end
    scan(g.settings.tree.args)
    return { SetValue = function(_, v) found.set(nil,v) end, GetValue = function() return found.get() end }
end
g = boot({ settings = true }); login(g)
eq(g.settings.registrations, 1, "one Ace tree registered")
eq(g.settings.categories, 6, "listed under AddOns with its pages")
eq(setting(g, "ammoThreshold"):GetValue(), 200, "ammo default shown")
eq(setting(g, "bagThreshold"):GetValue(), 2, "bag default shown")
g.autoAccept = false
g.free = 20
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "plenty of space: silent")
setting(g, "bagThreshold"):SetValue(25)
eq(g.env.ClosestVendorCharDB.cfg.bagThreshold, 25, "slider saved")
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
g.env.SlashCmdList.CLOSESTVENDOR("status")
eq(table.concat(g.printed, "\n"):find("trigger below 35%", 1, true) ~= nil, true, "command shows what the page set")

-- 19c. /cvn config opens the page; without the API it says so; a throwing API never breaks the addon.
g = boot({ settings = true }); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("config")
eq(g.settings.opened, 42, "/cvn config opens the page")
g.settings.opened=nil
g.env.SlashCmdList.CLOSESTVENDOR("")
eq(g.settings.opened,42,"bare /cvn opens settings")
eq(g.settings.page,"home","bare /cvn opens Home")
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("config")
eq(lastPrinted(g):find("not available", 1, true) ~= nil, true, "no settings API: says so")
g = boot({ settings = true }); login(g)
g.settings.dialog.Open = function() error("settings are locked right now") end
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
local function logText(g) local t = {} for _, e in ipairs(g.env.ClosestVendorCharDB.log.entries) do t[#t + 1] = e.msg end return table.concat(t, "\n") end
local function has(text, part) return text:find(part, 1, true) ~= nil end
g = boot(); login(g)
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.env.ClosestVendorCharDB.log.entries, 0, "nothing recorded by default")
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
eq(g.env.ClosestVendorCharDB.log.enabled, true, "switched on and saved")
eq(has(lastPrinted(g), "Debug log on"), true, "says so")
g.onEvent("BAG_UPDATE_DELAYED")
g.onEvent("UNIT_INVENTORY_CHANGED", "player")
g.onEvent("UNIT_INVENTORY_CHANGED", "target")
g.onEvent("ADDON_LOADED", "SomeOtherAddon")
local text = logText(g)
eq(has(text, "event BAG_UPDATE_DELAYED"), true, "events recorded")
eq(has(text, "event UNIT_INVENTORY_CHANGED"), false, "gear events are not logged one by one")
eq(has(text, "gear events: 1 folded into one check"), true, "the gear event shows as one folded check")
eq(has(text, "UNIT_INVENTORY_CHANGED target"), false, "other units' inventory events are not noise")
eq(has(text, "SomeOtherAddon"), false, "other addons' loads are not recorded")
-- A burst of gear events: one check, one log line with the count, however many arrive.
do
    local gb = boot({ tomtom = true }); login(gb)
    gb.env.ClosestVendorCharDB.log.enabled = true
    gb.autoAccept = false
    gb.dur = 10
    gb.gearTimers = {}
    for _ = 1, 5 do gb.rawEvent("UPDATE_INVENTORY_DURABILITY") end
    gb.rawEvent("UNIT_INVENTORY_CHANGED", "player")
    eq(#gb.gearTimers, 1, "six gear events arm one timer")
    eq(gb.popup, nil, "nothing is checked before the timer")
    gb.gearTimers[1]()
    eq(gb.popup ~= nil and gb.popup.text:find("needs repair", 1, true) ~= nil, true, "the timer runs one check that finds the low durability")
    eq(logText(gb):find("gear events: 6 folded into one check", 1, true) ~= nil, true, "one line with the count")
    eq(logText(gb):find("event UPDATE_INVENTORY_DURABILITY", 1, true), nil, "no raw line per event")
    -- A client without timers checks at once.
    local gt = boot({ tomtom = true }); login(gt)
    gt.autoAccept = false; gt.dur = 10
    gt.env.C_Timer = nil
    gt.rawEvent("UPDATE_INVENTORY_DURABILITY")
    eq(gt.popup ~= nil, true, "no timer API: the check runs at once")
end
-- A gear check still waiting when a merchant opens runs first, so the merchant dismisses its question.
do
    local gm = boot({ tomtom = true }); login(gm)
    gm.autoAccept = false; gm.dur = 10
    gm.gearTimers = {}
    gm.rawEvent("UPDATE_INVENTORY_DURABILITY")
    gm.rawEvent("MERCHANT_SHOW")
    gm.gearTimers[1]()
    eq(gm.popup, nil, "the merchant opened first: no repair question is left open")
end
-- Old account-level copies and the retired toastLocked key are dropped at load; cfg and hud stay as the seed.
do
    local gs = boot({ tomtom = true, db = { hearth = { name = "x" }, lastOutside = { x = 1 }, professions = { Mining = true },
        log = { entries = { { t = 1, msg = "old" } } }, cfg = { bagThreshold = 3 }, hud = { x = 5 } },
        charDb = { cfg = { toastLocked = true } } })
    login(gs)
    local db = gs.env.ClosestVendorDB
    eq(db.hearth == nil and db.lastOutside == nil and db.professions == nil and db.log == nil, true, "old account-level keys are dropped")
    eq(db.cfg ~= nil and db.hud ~= nil, true, "cfg and hud stay as the seed for new characters")
    eq(gs.env.ClosestVendorCharDB.cfg.toastLocked, nil, "the retired toastLocked key is dropped")
end
g.autoAccept = false
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
text = logText(g)
eq(has(text, "trigger go sell (bags=1"), true, "decisions recorded with their values")
eq(has(text, "question shown: sell"), true, "question recorded")
g.env.SlashCmdList.CLOSESTVENDOR("debug off")
local count = #g.env.ClosestVendorCharDB.log.entries
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.env.ClosestVendorCharDB.log.entries, count, "off again: nothing more recorded")

-- Saved variables: the switch and the entries survive a reload.
g = boot({ charDb = { log = { enabled = true, entries = { { t = 1, msg = "from the last session" } } } } }); login(g)
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
for _, part in ipairs({ "addon version: 0.1.0", "game: 1.60.1 build 70790, interface 16001", "locale: enUS", "navigation: chat (preference auto)",
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

-- Presentation diagnostics (spec diagnostics): the header names the style, the sample state, the notice
-- switch, the toast look and Move. A preview shows as a sample and changes no setting and no decision:
-- a real question open before the preview stays open, and its Yes still navigates.
do
    local fns = {}
    local gp = boot({ checkThat = { Entry = function(_, name, fn) fns[name] = fn; return true end } }); login(gp)
    gp.env.SlashCmdList.CLOSESTVENDOR("debug on")
    gp.env.SlashCmdList.CLOSESTVENDOR("set appearance.notification-style toast")
    local function header()
        gp.env.SlashCmdList.CLOSESTVENDOR("log")
        for _, f in ipairs(gp.frames) do if f.name == "ClosestVendorReport" then return f.box.text end end
        return ""
    end
    local t = header()
    for _, part in ipairs({ "presentation scope: This character; style toast; sample off", "on-screen notice on",
                            "toast: background 100%, text/icons 100%, scale 100%, position ", "Move: hud false, toast false" }) do
        eq(has(t, part), true, "presentation report contains '" .. part .. "'")
    end
    gp.free = 1; gp.onEvent("BAG_UPDATE_DELAYED")
    local real = gp.popup
    eq(real ~= nil and real.text:find("bags are almost full", 1, true) ~= nil, true, "a real sell question is open before the preview")
    eq(fns.active(), "sell", "the sell request is the open one before the preview")
    local before = #gp.env.ClosestVendorCharDB.log.entries
    gp.env.SlashCmdList.CLOSESTVENDOR("preview notice")
    t = header()
    eq(has(t, "presentation scope: This character; style toast; sample notice"), true, "a preview shows in the report as a sample, the style unchanged")
    local added = {}
    for i = before + 1, #gp.env.ClosestVendorCharDB.log.entries do added[#added + 1] = gp.env.ClosestVendorCharDB.log.entries[i].msg end
    eq(has(table.concat(added, "\n"), "setting changed: "), false, "the preview changes no setting")
    eq(has(table.concat(added, "\n"), "question shown: "), false, "the preview records no decision")
    eq(has(table.concat(added, "\n"), "question withdrawn"), false, "the preview withdraws no question")
    eq(gp.popup, real, "the real sell question is still the one shown after the preview")
    eq(fns.active(), "sell", "the sell request is still open after the preview")
    gp.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM.OnAccept(nil, real.accept)
    local after = {}
    for i = before + 1, #gp.env.ClosestVendorCharDB.log.entries do after[#after + 1] = gp.env.ClosestVendorCharDB.log.entries[i].msg end
    eq(has(table.concat(after, "\n"), "accepted: "), true, "Yes on the real question still navigates after the preview")
end

-- The report works with the log off, and says how to turn it on.
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("log")
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
eq(has(win.box.text, "Debug log: off (turn it on with /cvn debug on"), true, "log off: report says how to turn it on")
eq(has(win.box.text, "addon version: 0.1.0"), true, "log off: still has the facts")

-- The report names the CheckThat status (spec checkthat-integration); without CheckThat it is "not detected".
eq(has(win.box.text, "CheckThat: not detected"), true, "report: CheckThat not detected")

-- With CheckThat loaded, the entries register once at login and the report says it works.
do
    local stored, fns = {}, {}
    local ct = { Entry = function(addon, name, fn) stored[#stored + 1] = addon .. "." .. name; fns[name] = fn; return true end }
    g = boot({ checkThat = ct }); login(g)
    eq(table.concat(stored, ","), "ClosestVendor.version,ClosestVendor.setting,ClosestVendor.integration,ClosestVendor.active,ClosestVendor.learned,ClosestVendor.standing,ClosestVendor.nav,ClosestVendor.external,ClosestVendor.window,ClosestVendor.config,ClosestVendor.reagents", "entries registered at login")
    g.free = 20; g.onEvent("BAG_UPDATE_DELAYED")
    eq(select("#", fns.active()), 0, "active: no warning request, nothing")
    g.free = 1; g.onEvent("BAG_UPDATE_DELAYED")
    eq(fns.active(), "sell", "active: the controller's open sell request")
    g.env.SlashCmdList.CLOSESTVENDOR("log")
    for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
    eq(has(win.box.text, "CheckThat: working"), true, "report: CheckThat working")
    -- A CheckThat that raises turns the integration off; the addon still starts and the report says why.
    g = boot({ checkThat = { Entry = function() error("entry broke", 0) end } }); login(g)
    g.env.SlashCmdList.CLOSESTVENDOR("log")
    for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
    eq(has(win.box.text, "CheckThat: failed: Entry: entry broke"), true, "report: CheckThat failed with the reason, log off")
    eq(has(win.box.text, "Debug log: off"), true, "the failure shows with the debug log off")
    -- Start itself raising: start() has already done its work (vendors bucketed), and the report says why.
    g = boot()
    g.ns.CheckThat.Start = function() error("start broke", 0) end
    login(g)
    g.env.SlashCmdList.CLOSESTVENDOR("log")
    for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
    eq(has(win.box.text, "CheckThat: failed: Start: start broke"), true, "report: Start raising is a failure")
    eq(has(win.box.text, "per continent: 1:6"), true, "start() finished its work before the integration")
end

-- The debug log records both toggles: the off line is written before the log stops.
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
g.env.SlashCmdList.CLOSESTVENDOR("debug off")
do
    local e = g.env.ClosestVendorCharDB.log.entries
    eq(e[#e].msg, "debug log turned off", "debug off: its line is the last one recorded")
    eq(e[#e - 1].msg, "debug log turned on", "debug on: its line is recorded")
end

-- Navigation shown in the report follows what is installed.
g = boot({ tomtom = true }); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("log")
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
eq(has(win.box.text, "navigation: tomtom"), true, "report names the navigation method in use")

-- No window available: the facts and the newest entries go to chat; a pipe cannot escape.
g = boot(); login(g)
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
g.env.ClosestVendorCharDB.log.entries[#g.env.ClosestVendorCharDB.log.entries + 1] = { t = 1, msg = "odd|text" }
g.frameThrows = "ClosestVendorReport"
g.env.SlashCmdList.CLOSESTVENDOR("log")
local chat = table.concat(g.printed, "\n")
eq(has(chat, "addon version: 0.1.0"), true, "fallback prints the facts")
eq(has(chat, "odd||text"), true, "fallback prints the entries, pipe doubled")
for i = 1, 40 do g.env.ClosestVendorCharDB.log.entries[#g.env.ClosestVendorCharDB.log.entries + 1] = { t = i, msg = "filler " .. i } end
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
eq(#g.env.ClosestVendorCharDB.log.entries > 0, true, "something to clear")
g.env.SlashCmdList.CLOSESTVENDOR("log clear")
eq(#g.env.ClosestVendorCharDB.log.entries, 0, "cleared")
eq(g.env.ClosestVendorCharDB.log.enabled, true, "clearing does not switch it off")
eq(g.popup.which, "CLOSESTVENDOR_CLEAR_LOG", "dedicated diagnostic confirmation")

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
eq(g.env.ClosestVendorCharDB.standing[5513], true, "an opened trainer trains this character")
eq(DB.trainers[5513][6], 1, "and its faction")
eq(g.env.ClosestVendorCharDB.professions.Mining and g.env.ClosestVendorCharDB.professions.Engineering, true, "professions seen at the trainer")
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
-- Trainer tier probe: with debugging on, each listed service is logged with its requirements.
do
    local function logged(game, text)
        for _, e in ipairs(game.env.ClosestVendorCharDB.log.entries or {}) do if e.msg:find(text, 1, true) then return true end end
        return false
    end
    local gp = boot({ tomtom = true }); login(gp)
    gp.env.ClosestVendorCharDB.log.enabled = true
    gp.env.GetTrainerServiceInfo = function(i) return i == 1 and "Expert Miner" or "Smelt Iron", "", i == 1 and "unavailable" or "available" end
    gp.env.GetTrainerServiceLevelReq = function(i) return i == 1 and 20 or 0 end
    gp.env.GetTrainerServiceSkillReq = function(i) return "Mining", i == 1 and 125 or 100 end
    gp.env.GetTrainerServiceTypeFilter = function(f) return f ~= "used" end
    visit(gp, 5513, "Gelman Stonehand", { "Mining", "Mining" }, { map = 100, x = 0.6, y = 0.5 })
    eq(logged(gp, "trainer services: 2 listed; filters available=true unavailable=true used=false"), true, "probe logs the count and filters")
    eq(logged(gp, "  service: Mining | Expert Miner |  | unavailable | level 20 | needs Mining 125"), true, "probe logs a tier service")
    local gq = boot({ tomtom = true }); login(gq)
    visit(gq, 5513, "Gelman Stonehand", { "Mining" }, { map = 100, x = 0.6, y = 0.5 })
    eq(logged(gq, "trainer services"), false, "debugging off: nothing logged")
    -- Services listed late: the probe runs once, on the first TRAINER_UPDATE that can read them.
    local function times(game, text)
        local n = 0
        for _, e in ipairs(game.env.ClosestVendorCharDB.log.entries or {}) do if e.msg:find(text, 1, true) then n = n + 1 end end
        return n
    end
    local gl = boot({ tomtom = true }); login(gl)
    gl.env.ClosestVendorCharDB.log.enabled = true
    gl.env.GetTrainerServiceInfo = function() return "Smelt Iron", "", "available" end
    gl.env.GetTrainerServiceTypeFilter = function() return true end
    gl.npc = { guid = "Creature-0-4372-0-55-5513-0000A1B2C3", name = "Gelman Stonehand" }
    gl.trainer = {}
    gl.onEvent("TRAINER_SHOW")
    eq(times(gl, "trainer services: "), 0, "no services yet: no probe")
    gl.trainer = { "Mining" }
    gl.onEvent("TRAINER_UPDATE")
    eq(times(gl, "trainer services: "), 1, "services arrive on TRAINER_UPDATE: probed")
    gl.onEvent("TRAINER_UPDATE")
    eq(times(gl, "trainer services: "), 1, "a later TRAINER_UPDATE: not probed again")
    gl.onEvent("TRAINER_SHOW")
    eq(times(gl, "trainer services: "), 2, "opened again: probed again")
end

-- A trainer that refused this character (Unfriendly with its faction) is not offered.
do
    local gt = boot({ tomtom = true }); login(gt)
    visit(gt, 5513, "Gelman Stonehand", { "Mining" }, { map = 100, x = 0.6, y = 0.5 })
    gt.env.UnitReaction = function() return 3 end
    gt.npc = { guid = "Creature-0-4372-0-55-5513-0000A1B2C3", name = "Gelman Stonehand" }
    gt.onEvent("PLAYER_TARGET_CHANGED")
    eq(gt.env.ClosestVendorCharDB.standing[5513], false, "trainer standing remembered")
    gt.autoAccept = false
    gt.pos = { map = 100, x = 0.5, y = 0.5 }
    gt.skillLines = { { "Mining", 70, 75 } }; gt.onEvent("SKILL_LINES_CHANGED")
    gt.skillLines = { { "Mining", 71, 75 } }; gt.onEvent("SKILL_LINES_CHANGED")
    eq(gt.popup == nil or not has(gt.popup.text, "Gelman Stonehand"), true, "an Unfriendly trainer is not offered")
end

-- Learned trainers are saved and used after a reload.
local saved = g.env.ClosestVendorDB
local g2 = boot({ tomtom = true, db = saved, charDb = g.env.ClosestVendorCharDB }); login(g2)
g2.autoAccept = false
g2.skillLines = { { "Mining", 70, 75 } }; g2.tradeWindow = "Mining"
g2.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g2.popup ~= nil and has(g2.popup.text, "Gelman Stonehand"), true, "learned trainer survives a reload")

-- A profession first seen in a crafting window, no trainer known: told once in chat, no question.
g = boot({ tomtom = true }); login(g)
g.skillLines = { { "Tailoring", 70, 75 } }; g.tradeWindow = "Tailoring"
g.onEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eq(g.env.ClosestVendorCharDB.professions.Tailoring, true, "profession learned from the crafting window")
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
eq(g.env.ClosestVendorCharDB.cfg.tradeThreshold, 20, "/cvn trade sets it")
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
eq(g.env.ClosestVendorCharDB.professions.Mining, true, "but the profession was still seen")

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
local data = g.popup.data
d3.OnAlt(nil, data)
eq(g.tomtom[1], "Other Shop", "second button navigates to the closer target")
g = twoMaps(); g.autoAccept = false
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
d3.OnAccept(nil, g.popup.data)
eq(g.tomtom[1], "Home Shop", "first button navigates to the map target")

g = twoMaps(); g.autoAccept = false
g.env.SlashCmdList.CLOSESTVENDOR("prefer distance")
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup.which, "CLOSESTVENDOR_CONFIRM_DISTANCE", "distance preference: the closer target is the first button")

g = twoMaps()
g.env.SlashCmdList.CLOSESTVENDOR("set appearance.notification-style warning")
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
    local gg = boot({ tomtom = true, checkThat = over and over.checkThat })
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
g = mage(); g.env.ClosestVendorCharDB.cfg.reagentOff[17020] = true; g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "switched off")
g = mage(); g.env.SlashCmdList.CLOSESTVENDOR("reagents off"); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "reagents switch off")
g = mage(); g.env.SlashCmdList.CLOSESTVENDOR("ammo off"); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup ~= nil, true, "ammo switch off: the reagent question still comes")

-- Learning the spell later is noticed.
g = mage({ spells = {} }); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "not yet")
g.spells[23028] = true
g.onEvent("SPELLS_CHANGED")
eq(g.popup ~= nil, true, "asks once the spell is learned")

-- Unreadable counts are not "none".
g = mage(); breakApi(g, "GetItemCount", "throws"); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "an unreadable reagent count is not treated as none")

-- The CheckThat reagents entry says nothing, never "none", when a watched count cannot be read.
do
    local fns = {}
    local ct = { Entry = function(_, name, fn) fns[name] = fn; return true end }
    g = mage({ checkThat = ct }); g.onEvent("BAG_UPDATE_DELAYED")
    eq(fns.reagents(), "17020:3", "reagents entry: the readable count")
    breakApi(g, "GetItemCount", "throws"); g.onEvent("BAG_UPDATE_DELAYED")
    eq(select("#", fns.reagents()), 0, "reagents entry: nothing when the count cannot be read, never none")
end

-- A settings default exists and the off-list is created for old saved data.
g = boot({ tomtom = true, db = { cfg = { ammoThreshold = 100 } } }); login(g)
eq(g.env.ClosestVendorCharDB.cfg.reagentThreshold, 5, "default reagent threshold")
eq(type(g.env.ClosestVendorCharDB.cfg.reagentOff), "table", "off-list exists")
eq(g.env.ClosestVendorCharDB.cfg.ammoThreshold, 100, "saved settings kept")

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
-- A merchant list the game has not fully loaded never replaces what is known; it is read again
-- when the item data arrives.
do
    local gg = mage(); gg.autoAccept = true
    gg.npc = { guid = "Creature-0-4372-0-55-82-0000A1B2C3", name = "Reagent Shop" }
    gg.pos = { map = 100, x = 0.7, y = 0.5 }
    gg.stock = { false } -- the one item's link is not loaded yet
    gg.onEvent("MERCHANT_SHOW")
    eq(gg.env.ClosestVendorDB.learned[82], nil, "partial list: the shipped record is not replaced")
    gg.stock = { 17020 }
    gg.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    eq(gg.env.ClosestVendorDB.learned[82] and gg.env.ClosestVendorDB.learned[82][9], 1, "read again when the data arrives")
    gg.npc = { guid = "Creature-0-4372-0-55-4321-0000A1B2C3", name = "Unknown Shop" }
    gg.stock = { false, 17020 }
    gg.onEvent("MERCHANT_SHOW")
    eq(gg.env.ClosestVendorDB.learned[4321] and gg.env.ClosestVendorDB.learned[4321][9], 1, "a vendor not known yet is still learned from what could be read")
end
g.counts[17020] = 2; g.onEvent("BAG_UPDATE_DELAYED")
eq(g.shown, 1, "and is still found as a seller")
eq(has(g.popup.text, "Reagent Shop"), true, "learned record still offered: " .. g.popup.text)

-- The debug report lists the threshold, the watched reagents and the switched-off ones.
g = mage(); g.env.ClosestVendorCharDB.cfg.reagentOff[17031] = true
g.env.SlashCmdList.CLOSESTVENDOR("log")
local rwin
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then rwin = f end end
eq(has(rwin.box.text, "reagents: on, class MAGE, threshold 5, watching: Arcane Powder:3, switched off: Rune of Teleportation"), true, "report line")
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
cfg = g.env.ClosestVendorCharDB.cfg
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
-- A purchase question ends with its merchant window; ammo has a dialog of its own.
g = reagentShop()
g.env.SlashCmdList.CLOSESTVENDOR("reagentbuy on")
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
g.onEvent("MERCHANT_SHOW")
eq(g.popup and g.popup.which, "CLOSESTVENDOR_CONFIRM_REAGENTS", "purchase asked")
g.onEvent("MERCHANT_CLOSED")
eq(g.popup, nil, "closing the merchant closes the purchase question")
do
    local n, ammoLine = 0, false
    for _, e in ipairs(g.env.ClosestVendorCharDB.log.entries) do
        if e.msg == "purchase question closed with the merchant: reagents" then n = n + 1 end
        if e.msg:find("closed with the merchant: ammo", 1, true) then ammoLine = true end
    end
    eq(n, 1, "the debug log says the open purchase question closed with the merchant")
    eq(ammoLine, false, "and names only the question that was open")
    g.onEvent("MERCHANT_CLOSED")
    local again = 0
    for _, e in ipairs(g.env.ClosestVendorCharDB.log.entries) do
        if e.msg:find("purchase question closed", 1, true) then again = again + 1 end
    end
    eq(again, 1, "no question open: nothing more logged")
    g.ns.Adapter.showPopup("CLOSESTVENDOR_CONFIRM_AMMO", "Buy 200 arrows?", function() end) -- an ammo purchase question
    g.onEvent("MERCHANT_CLOSED")
    local ammo = 0
    for _, e in ipairs(g.env.ClosestVendorCharDB.log.entries) do
        if e.msg == "purchase question closed with the merchant: ammo" then ammo = ammo + 1 end
    end
    eq(ammo, 1, "the ammo purchase question closing with the merchant is logged")
    eq(g.popup, nil, "and it closes")
    -- A purchase question the game does not hide is a failure, not a closed line.
    g.ns.Adapter.showPopup("CLOSESTVENDOR_CONFIRM_REAGENTS", "Buy 17 Arcane Powder?", function() end)
    g.env.StaticPopup_Hide = function() end
    g.onEvent("MERCHANT_CLOSED")
    local failed, closed = 0, 0
    for _, e in ipairs(g.env.ClosestVendorCharDB.log.entries) do
        if e.msg == "FAILED: purchase question still shown after the merchant closed: reagents" then failed = failed + 1 end
        if e.msg == "purchase question closed with the merchant: reagents" then closed = closed + 1 end
    end
    eq(failed, 1, "a purchase question still shown after the merchant closed is logged as a failure")
    eq(closed, 1, "and no second closed line")
end
eq(g.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM_AMMO ~= nil, true, "ammo purchases have their own dialog")
g = reagentShop(); g.autoAccept = true
g.env.SlashCmdList.CLOSESTVENDOR("reagentbuy on"); g.env.SlashCmdList.CLOSESTVENDOR("reagentbuy auto")
g.ns.Ammo.OnMerchant = function() return 2, 99000 end -- an ammo purchase a moment before
g.onEvent("MERCHANT_SHOW")
eq(table.concat(g.bought, ","), "1:10", "buys at once with the money the ammo left")
eq(has(lastPrinted(g), "(all you could afford)"), true, "partial: " .. lastPrinted(g))
-- An item the game has not loaded yet: the purchase waits for GET_ITEM_INFO_RECEIVED instead of giving up.
do
    local function uncachedShop()
        local gg = reagentShop()
        gg.env.SlashCmdList.CLOSESTVENDOR("reagentbuy on")
        gg.env.GetItemInfo = function() return nil end -- not cached
        return gg
    end
    local function buyAsked(gg) return gg.popup ~= nil and gg.popup.which == "CLOSESTVENDOR_CONFIRM_REAGENTS" end
    local function loadItem(gg) gg.env.GetItemInfo = function() return "Arcane Powder", "l", 1, 1, 1, "", "", 20 end end
    local ig = uncachedShop()
    ig.onEvent("MERCHANT_SHOW")
    eq(buyAsked(ig), false, "stack size unknown: nothing asked yet")
    loadItem(ig)
    ig.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    eq(buyAsked(ig) and has(ig.popup.text, "Buy 17 Arcane Powder"), true, "the data arrived: the question is asked")
    local shown = ig.shown
    ig.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    eq(ig.shown, shown, "and only once")

    ig = uncachedShop()
    ig.onEvent("MERCHANT_SHOW")
    ig.onEvent("MERCHANT_CLOSED")
    loadItem(ig)
    ig.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    eq(buyAsked(ig), false, "merchant closed: nothing is tried")

    ig = uncachedShop()
    ig.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    eq(buyAsked(ig), false, "no merchant open: nothing is tried")

    ig = uncachedShop()
    ig.onEvent("MERCHANT_SHOW")
    for _ = 1, 5 do ig.onEvent("GET_ITEM_INFO_RECEIVED", 17020) end
    eq(buyAsked(ig), false, "data that never arrives is not retried forever")
    local reads = 0
    local realInfo = ig.env.GetItemInfo
    ig.env.GetItemInfo = function(...) reads = reads + 1; return realInfo(...) end
    ig.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    eq(reads, 0, "after three tries it stops reading")

    -- Other items loading say nothing about ours: they do not use up the tries.
    ig = uncachedShop()
    ig.onEvent("MERCHANT_SHOW")
    for i = 1, 10 do ig.onEvent("GET_ITEM_INFO_RECEIVED", 9000 + i) end
    loadItem(ig)
    ig.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    eq(buyAsked(ig), true, "ten unrelated items first: ours still gets its try")

    -- The money an ammo purchase left is only reserved while the game has not answered it; by the
    -- retry the game's own number is right, so it is not taken off twice.
    ig = uncachedShop()
    ig.env.SlashCmdList.CLOSESTVENDOR("reagentbuy auto")
    ig.ns.Ammo.OnMerchant = function() return 2, 99000 end
    ig.onEvent("MERCHANT_SHOW")
    loadItem(ig)
    ig.bought = {}
    ig.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    eq(table.concat(ig.bought, ","), "1:17", "all 17 bought: the ammo money is not subtracted a second time")

    -- A part that already asked is not run again: no second question.
    ig = reagentShop()
    ig.env.SlashCmdList.CLOSESTVENDOR("reagentbuy on")
    ig.onEvent("MERCHANT_SHOW")
    local asked = ig.shown
    ig.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    eq(ig.shown, asked, "already asked: an item arriving asks nothing more")
end

-- A later Yes plans again: reagents bought by hand meanwhile are not bought twice.
do
    local gg = reagentShop()
    gg.env.SlashCmdList.CLOSESTVENDOR("reagentbuy on")
    gg.autoAccept = false
    gg.onEvent("MERCHANT_SHOW")
    eq(gg.popup.text, "Buy 17 Arcane Powder for 17s 0c?", "asked for 17")
    gg.counts[17020] = 15 -- 12 bought by hand before Yes
    gg.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM_REAGENTS.OnAccept(nil, gg.popup.accept)
    eq(table.concat(gg.bought, ",") .. "/" .. tostring(has(lastPrinted(gg), "Bought 5 Arcane Powder for 5s 0c.")), "1:5/true", "Yes buys only the 5 still needed")
end
-- A merchant whose item kinds have not loaded does not overwrite a known arrow vendor.
do
    local gg = mage(); gg.autoAccept = true
    gg.npc = { guid = "Creature-0-4372-0-55-5555-0000A1B2C3", name = "Arrow Shop" }
    gg.pos = { map = 100, x = 0.6, y = 0.5 }
    gg.stock = { 200 }
    gg.onEvent("MERCHANT_SHOW")
    eq(gg.env.ClosestVendorDB.learned[5555][8], 1, "arrow vendor learned")
    gg.unloaded = { [200] = true }
    gg.onEvent("MERCHANT_SHOW")
    eq(gg.env.ClosestVendorDB.learned[5555][8], 1, "item kind not loaded: still sells arrows")
    gg.unloaded = nil
    gg.onEvent("GET_ITEM_INFO_RECEIVED", 200)
    eq(gg.env.ClosestVendorDB.learned[5555][8], 1, "read again once loaded")
end
-- Best usable ammo whose required level has not loaded: nothing said, bought once the data arrives.
do
    local gg = boot({ tomtom = true }); login(gg)
    local e = gg.env
    gg.npc = { guid = "Creature-0-4372-0-55-5556-0000A1B2C3", name = "Arrow Shop" }
    gg.equipped = { [18] = 100 }; gg.counts = {} -- a bow, no arrows in the ammo slot
    gg.stock, gg.bought = { 200 }, {}
    e.ClosestVendorCharDB.cfg.arrowGrade = "best"
    e.UnitLevel = function() return 30 end
    e.GetMoney = function() return 100000 end
    e.GetMerchantItemInfo = function() return "Rough Arrow", "tex", 100, 200, -1, true, false end
    e.BuyMerchantItem = function(i) gg.bought[#gg.bought + 1] = i end
    e.C_Container = { GetContainerNumFreeSlots = function(b) if b == 1 then return 1, 1 end return 0, 0 end } -- bag 1 is a quiver
    e.GetContainerNumSlots = function(b) return b == 1 and 1 or 0 end
    e.GetContainerItemInfo = function() return nil end
    e.GetItemInfo = function() return nil end
    local printed = #gg.printed
    gg.onEvent("MERCHANT_SHOW")
    eq(#gg.bought .. "/" .. (#gg.printed - printed), "0/0", "level not loaded: nothing bought, nothing said")
    e.GetItemInfo = function() return "Rough Arrow", "l", 1, 1, 5, "", "", 200 end
    gg.onEvent("GET_ITEM_INFO_RECEIVED", 200)
    eq(#gg.bought, 1, "bought once the data arrives")
end

g = boot({ db = { cfg = { reagentBuyTarget = 150 } } }); login(g)
eq(g.env.ClosestVendorCharDB.cfg.reagentBuyTarget, 100, "a saved amount above 100 is held to 100")
g = boot({ db = { cfg = { reagentBuyTarget = -3 } } }); login(g)
eq(g.env.ClosestVendorCharDB.cfg.reagentBuyTarget, 0, "and one below 0 to 0")

-- Instances. Full bags in a battleground: nothing is asked inside, and the question comes after
-- leaving (it used to be lost for good).
g = boot(); login(g); g.autoAccept = false
g.env.ClosestVendorCharDB.log.enabled = true
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
    for _, e in ipairs(game.env.ClosestVendorCharDB.log.entries or {}) do if e.msg:find(text, 1, true) then return true end end
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
local lo = g.env.ClosestVendorCharDB.lastOutside
eq(lo.continent .. ":" .. lo.map .. ":" .. lo.x .. ":" .. lo.y, "1:100:500:500", "position saved with its continent and map")
g.pos = { map = 100, x = 0.6, y = 0.5 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.env.ClosestVendorCharDB.lastOutside.x, 600, "follows the player outside")
g.instance = "party"; g.pos = { map = 100, x = 0.1, y = 0.1 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.env.ClosestVendorCharDB.lastOutside.x, 600, "not updated in a dungeon")
g.instance = nil; g.pos = nil
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.env.ClosestVendorCharDB.lastOutside.x, 600, "no position: the old one is kept")
g = boot(); login(g); g.pos = nil
g.onEvent("PLAYER_ENTERING_WORLD")
eq(g.env.ClosestVendorCharDB.lastOutside, nil, "never had a position: nothing saved")

-- The hearthstone point. The first bind name seen has no position (bound before the addon saw it);
-- a new name takes the position where the innkeeper asked, never where the player is when noticed.
g = boot(); login(g); g.bind = "Goldshire"
g.env.ClosestVendorCharDB.log.enabled = true
g.onEvent("PLAYER_ENTERING_WORLD")
local hearth = g.env.ClosestVendorCharDB.hearth
eq(hearth.name, "Goldshire", "bind name remembered")
eq(hearth.continent, nil, "but no position: it was bound earlier")
g.onEvent("ZONE_CHANGED_NEW_AREA")
eq(g.env.ClosestVendorCharDB.hearth.continent, nil, "same name: still no position")
g.bind = "Stormwind"; g.pos = { map = 100, x = 0.3, y = 0.4 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.env.ClosestVendorCharDB.hearth.name, "Goldshire", "only read on login and zone change")
g.onEvent("ZONE_CHANGED_NEW_AREA")
hearth = g.env.ClosestVendorCharDB.hearth
eq(hearth.name .. ":" .. tostring(hearth.continent), "Stormwind:nil", "a bind the addon did not see: name only, no guessed position")
eq(g.ns.frame.events.CONFIRM_BINDER, true, "listens for the innkeeper's question")
eq(g.ns.frame.events.HEARTHSTONE_BOUND, true, "and for the bind itself")
g.bind = "Goldshire"; g.pos = { map = 100, x = 0.3, y = 0.4 }
g.onEvent("CONFIRM_BINDER", "Goldshire")
g.pos = { map = 100, x = 0.9, y = 0.9 } -- walked away before the next zone change
g.onEvent("ZONE_CHANGED_NEW_AREA")
hearth = g.env.ClosestVendorCharDB.hearth
eq(hearth.name .. ":" .. hearth.continent .. ":" .. hearth.map .. ":" .. hearth.x .. ":" .. hearth.y, "Goldshire:1:100:300:400", "rebind: where the innkeeper asked becomes the point")
eq(logged(g, "hearthstone point learned: Goldshire"), true, "and it is logged")
g.onEvent("CONFIRM_BINDER", "Darkshire") -- asked, declined
g.bind = "Lakeshire"
g.onEvent("ZONE_CHANGED_NEW_AREA")
eq(tostring(g.env.ClosestVendorCharDB.hearth.continent), "nil", "a declined innkeeper question does not place another bind")
g.bind = "Stormwind"; g.pos = { map = 100, x = 0.5, y = 0.5 }
g.onEvent("CONFIRM_BINDER", "Stormwind")
g.onEvent("HEARTHSTONE_BOUND")
eq(g.env.ClosestVendorCharDB.hearth.x, 500, "the bind event learns it at once")
g.bind = "Stormwind"
g.bind = nil
g.onEvent("ZONE_CHANGED_NEW_AREA")
eq(g.env.ClosestVendorCharDB.hearth.name, "Stormwind", "an unreadable bind name keeps the point")
-- A point saved by name only gets its position when the player binds again at that same inn, from the
-- bind event or (clients without it) the next zone change.
g = boot(); login(g); g.bind = "Goldshire"
g.onEvent("PLAYER_ENTERING_WORLD")
g.pos = { map = 100, x = 0.3, y = 0.4 }
g.onEvent("CONFIRM_BINDER", "Goldshire")
g.onEvent("ZONE_CHANGED_NEW_AREA")
eq(tostring(g.env.ClosestVendorCharDB.hearth.x), "300", "same inn, next zone change: the position is learned")
-- Logout is delivered, and a new inn (not the saved one) also keeps its position.
do
    local gl = boot(); login(gl)
    eq(gl.ns.frame.events.PLAYER_LOGOUT, true, "listens for logout")
    gl.bind = "Stormwind"; gl.onEvent("PLAYER_ENTERING_WORLD")
    gl.pos = { map = 100, x = 0.3, y = 0.4 }
    gl.onEvent("CONFIRM_BINDER", "Goldshire")
    gl.bind = "Goldshire"
    gl.onEvent("PLAYER_LOGOUT")
    local hh = gl.env.ClosestVendorCharDB.hearth
    eq(hh.name .. ":" .. tostring(hh.x), "Goldshire:300", "a new inn bound just before logout: name and position")
end
-- A client with no bind event: binding and then logging out (or /reload) keeps the position.
g = boot(); login(g); g.bind = "Goldshire"
g.onEvent("PLAYER_ENTERING_WORLD")
g.pos = { map = 100, x = 0.3, y = 0.4 }
g.onEvent("CONFIRM_BINDER", "Goldshire")
g.pos = { map = 100, x = 0.9, y = 0.9 }
g.onEvent("PLAYER_LOGOUT")
eq(tostring(g.env.ClosestVendorCharDB.hearth.x), "300", "logout right after the bind: the position is saved")
g = boot(); login(g); g.bind = "Goldshire"
g.onEvent("PLAYER_ENTERING_WORLD")
g.pos = { map = 100, x = 0.3, y = 0.4 }
g.onEvent("CONFIRM_BINDER", "Goldshire")
g.pos = { map = 100, x = 0.9, y = 0.9 }
g.onEvent("HEARTHSTONE_BOUND")
hearth = g.env.ClosestVendorCharDB.hearth
eq(hearth.name .. ":" .. tostring(hearth.continent) .. ":" .. tostring(hearth.x), "Goldshire:1:300", "rebind at the same inn: where the innkeeper asked becomes the point")
g.onEvent("CONFIRM_BINDER", "Darkshire")
g.onEvent("HEARTHSTONE_BOUND")
eq(g.env.ClosestVendorCharDB.hearth.x, 300, "a bind event for another place's question keeps the point")
g.pos = { map = 100, x = 0.7, y = 0.7 }
g.onEvent("CONFIRM_BINDER") -- a question that names no place
g.onEvent("HEARTHSTONE_BOUND")
eq(g.env.ClosestVendorCharDB.hearth.x, 300, "same name, a question with no place: the point stays")
g.onEvent("CONFIRM_BINDER", "Darkshire") -- declined
g.onEvent("ZONE_CHANGED_NEW_AREA") -- still Goldshire: the Darkshire question is forgotten
g.bind = "Darkshire"
g.onEvent("ZONE_CHANGED_NEW_AREA") -- bound there later, unseen
eq(tostring(g.env.ClosestVendorCharDB.hearth.continent), "nil", "an old question for another place does not place a later bind")

-- ---- Status window, its settings and auctioneers ----

-- New saved keys get their defaults; old settings are kept.
g = boot({ db = { cfg = { hudScale = 150, hudRow = { bags = "always" } }, hud = { point = "TOP", x = 5, y = -5 } } }); login(g)
cfg = g.env.ClosestVendorCharDB.cfg
eq(cfg.hudScale, 150, "saved scale kept")
eq(cfg.hudRow.bags, "always", "saved row mode kept")
eq(g.env.ClosestVendorCharDB.hud.point, "TOP", "saved position kept")
eq(tostring(cfg.hudLocked) .. "/" .. cfg.hudAlpha .. "/" .. cfg.instanceAnchor .. "/" .. tostring(cfg.ahEnabled), "false/80/hearth/false", "defaults: unlocked, opacity 80, hearth anchor, auction house off")
-- Keys an earlier build saved per row, and modes that are not one, are dropped at login.
g = boot({ db = { cfg = { hudRow = { ["prof:Mining"] = "always", ["reagent:17020"] = "never", reagents = "always", bags = "sometimes", [3] = "never" } } } }); login(g)
local kept = {}
for k, v in pairs(g.env.ClosestVendorCharDB.cfg.hudRow) do kept[#kept + 1] = tostring(k) .. "=" .. tostring(v) end
eq(table.concat(kept, ","), "reagents=always", "only a group key with a real mode is kept")
g = boot({ db = { cfg = { hudRow = "broken" } } }); login(g)
eq(type(g.env.ClosestVendorCharDB.cfg.hudRow), "table", "a hudRow that is not a table is replaced")
g = boot(); login(g)
cfg = g.env.ClosestVendorCharDB.cfg
eq(cfg.hudScale, 100, "default scale")
eq(type(cfg.hudRow) == "table" and next(cfg.hudRow) == nil, true, "row modes start empty: every row has its default")
eq(type(g.env.ClosestVendorCharDB.hud) == "table" and next(g.env.ClosestVendorCharDB.hud) == nil, true, "no saved position yet")
eq(type(g.env.ClosestVendorDB.auctioneers), "table", "learned auctioneer table created")
local g2 = boot(); login(g2)
eq(g2.env.ClosestVendorCharDB.cfg.hudRow ~= cfg.hudRow, true, "each saved table is its own")
eq(cfg.hudAlpha .. "/" .. cfg.hudTextAlpha .. "/" .. cfg.hudColor, "80/100/000000", "defaults: background 80%, text 100%, pure black")
-- Saved window numbers outside their ranges are held to them; a colour that is not one is black again.
g = boot({ db = { cfg = { hudAlpha = -5, hudTextAlpha = 5, hudScale = 900, hudColor = "fff" } } }); login(g)
cfg = g.env.ClosestVendorCharDB.cfg
eq(cfg.hudAlpha .. "/" .. cfg.hudTextAlpha .. "/" .. cfg.hudScale .. "/" .. cfg.hudColor, "0/20/200/000000", "held to the limits, a bad colour is black")
g = boot({ db = { cfg = { hudAlpha = 150, hudTextAlpha = 400, hudColor = 7 } } }); login(g)
cfg = g.env.ClosestVendorCharDB.cfg
eq(cfg.hudAlpha .. "/" .. cfg.hudTextAlpha .. "/" .. cfg.hudColor, "100/100/000000", "held to 100")
g = boot({ db = { cfg = { hudAlpha = "dim", hudTextAlpha = false, hudColor = "1a2b3c" } } }); login(g)
cfg = g.env.ClosestVendorCharDB.cfg
eq(cfg.hudAlpha .. "/" .. cfg.hudTextAlpha .. "/" .. cfg.hudColor, "80/100/1a2b3c", "not a number: the default; a real colour is kept")
g = boot({ db = { cfg = { hudAlpha = 0 } } }); login(g)
eq(g.env.ClosestVendorCharDB.cfg.hudAlpha, 0, "background 0 is kept, not replaced by the default")

-- The window: built at login, drawn once per burst of events by one short timer.
local function window(game)
    local w = { rows = {} }
    for _, f in ipairs(game.frames) do
        if f.name == "ClosestVendorTracker" then w.frame = f
        elseif w.frame and f.parent == w.frame and f.kind == "Button" then
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
eq(shownRows(g), "Low: Bag space: 1 free", "with the bag row only")
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
-- A timer call that throws schedules nothing: the window redraws at once instead of waiting forever.
g = boot({ tomtom = true }); login(g); g.autoAccept = false; flush(g)
local timerCalls = 0
g.env.C_Timer.After = function() timerCalls = timerCalls + 1; error("timer broke") end
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(window(g).frame.shown, true, "failed timer: redrawn at once")
g.free = 20
g.onEvent("BAG_UPDATE_DELAYED")
eq(window(g).frame.shown, false, "and the next change redraws too")
eq(timerCalls >= 2, true, "each change tries the timer again")

-- Reagents and display-only items in the window; the warning switch does not hide a row.
g = boot(); login(g); g.autoAccept = false
g.spells = { [23028] = true, [5504] = true }; g.counts = { [17020] = 3, [5350] = 3, [2288] = 10 }
g.env.ClosestVendorCharDB.cfg.reagentOff[17020] = true
g.onEvent("SPELLS_CHANGED"); flush(g)
eq(shownRows(g), "Low: Arcane Powder: 3", "a low reagent shows even with its warning switched off")
eq(g.popup, nil, "and no question is asked about it")
g.env.SlashCmdList.CLOSESTVENDOR("hud row reagents always")
eq(shownRows(g), "Low: Arcane Powder: 3 | Conjured Water: 13", "Reagents always shows conjured water, summed over its ranks")

-- Clicking a row pins at once, without a question, and is logged.
g = boot({ tomtom = true }); login(g); g.autoAccept = false
g.env.ClosestVendorCharDB.log.enabled = true
g.env.SlashCmdList.CLOSESTVENDOR("hud row durability always")
w = window(g)
eq(g.env.ClosestVendorCharDB.cfg.vendorMode, "ask", "choice mode is ask")
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
eq(g.env.ClosestVendorCharDB.hud.x .. ":" .. g.env.ClosestVendorCharDB.hud.y, "40:-50", "position saved")
g.env.SlashCmdList.CLOSESTVENDOR("hud lock")
w.rows[1].scripts.OnDragStart()
eq(moved, 1, "locked: Shift-drag does nothing")
g.env.SlashCmdList.CLOSESTVENDOR("hud reset")
eq(next(g.env.ClosestVendorCharDB.hud), nil, "/cvn hud reset forgets the position")
local point
w.frame.SetPoint = function(_, p, _, _, x, y) point = p .. ":" .. x .. ":" .. y end
g.env.SlashCmdList.CLOSESTVENDOR("hud scale 150")
eq(point, "LEFT:60:60", "the window is at its default position")
eq(g.env.ClosestVendorCharDB.cfg.hudScale, 150, "scale saved")

-- The cog opens the main settings page, or says it cannot.
g = boot({ settings = true }); login(g)
window(g).cog.scripts.OnClick()
eq(g.settings.opened, 42, "cog opens the Closest Vendor page")
g = boot(); login(g)
window(g).cog.scripts.OnClick()
eq(has(lastPrinted(g), "settings page is not available"), true, "no settings page: chat says so")
-- A settings-page change redraws the window at once.
g = boot({ settings = true }); login(g)
g.env.ClosestVendorCharDB.cfg.hudRow.bags = "always"
setting(g, "hudLocked"):SetValue(true)
eq(shownRows(g), "Bag space: 20 free", "changing a setting on the page redraws the window")

-- Skills are read once and kept until they change; every row never reads nothing.
g = boot(); login(g)
local skillReads = 0
g.skillLines = { { "Mining", 70, 75 } }
g.env.GetNumSkillLines = function() skillReads = skillReads + 1 return #g.skillLines end
g.env.ClosestVendorCharDB.professions.Mining = true
g.onEvent("BAG_UPDATE_DELAYED"); flush(g)
g.onEvent("BAG_UPDATE_DELAYED"); flush(g)
eq(shownRows(g), "Low: Mining: 70/75", "a profession near its cap shows")
eq(skillReads, 1, "two redraws, skills read once")
g.skillLines = { { "Mining", 75, 150 } }
g.onEvent("BAG_UPDATE_DELAYED"); flush(g)
eq(shownRows(g), "Low: Mining: 70/75", "no skill event yet: the kept list is used")
g.onEvent("SKILL_LINES_CHANGED"); flush(g)
eq(window(g).frame.shown, false, "skill event: read again, no longer near the cap")
g.skillLines = { { "Mining", 145, 150 } }
g.onEvent("SKILL_LINES_CHANGED"); flush(g)
eq(shownRows(g), "Low: Mining: 145/150", "near the next cap")
for _, name in ipairs({ "ammo", "bags", "durability", "professions", "reagents", "supplies" }) do
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
g.env.ClosestVendorCharDB.log.enabled = true
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(#g.hudTimers, 0, "no window: no redraw timer")
eq(has(lastPrinted(g), "Ally Seller"), true, "warnings still work")
g.env.SlashCmdList.CLOSESTVENDOR("hud scale 120")
eq(g.env.ClosestVendorCharDB.cfg.hudScale, 120, "and so do the window commands")
-- No timers: the window is redrawn directly.
g = boot(); login(g); flush(g)
g.env.C_Timer = nil
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(shownRows(g), "Low: Bag space: 1 free", "no timers: redrawn at once")

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
g.env.SlashCmdList.CLOSESTVENDOR("debug on")
local function lastMsg() local e = g.env.ClosestVendorCharDB.log.entries; return e[#e] and e[#e].msg end
g.onEvent("AUCTION_HOUSE_SHOW")
local arec = g.env.ClosestVendorDB.auctioneers[50]
eq(arec[2] .. ":" .. arec[3] .. ":" .. arec[4] .. ":" .. arec[6], "Auctioneer Near:100:0.52:0", "auctioneer learned at the player's position")
eq(lastMsg(), "auctioneer learned: Auctioneer Near (npc 50), new", "the first opening is logged as new")
g.onEvent("AUCTION_HOUSE_SHOW")
eq(lastMsg(), "auctioneer learned: Auctioneer Near (npc 50), unchanged", "opening it again from the same place: unchanged, once per window")
g.pos = { map = 100, x = 0.53, y = 0.5 }
g.onEvent("AUCTION_HOUSE_SHOW")
eq(lastMsg(), "auctioneer learned: Auctioneer Near (npc 50), updated", "from another place: updated")
g.pos = { map = 100, x = 0.52, y = 0.5 }
g.onEvent("AUCTION_HOUSE_SHOW")
g.npc = { guid = "Player-0-0-0-0-0-0", name = "Someone" }
g.onEvent("AUCTION_HOUSE_SHOW")
g.npc = { guid = "Creature-0-4372-0-55-60-0000A1B2C3", name = "No Position" }; g.pos = nil
g.onEvent("AUCTION_HOUSE_SHOW")
eq(lastMsg(), "auctioneer not learned: No Position (npc 60): no map position here", "no map position: not learned, and logged")
local an = 0
for _ in pairs(g.env.ClosestVendorDB.auctioneers) do an = an + 1 end
eq(an, 1, "a non-creature or a missing position learns nothing")
g.env.SlashCmdList.CLOSESTVENDOR("log")
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then win = f end end
eq(has(win.box.text, "auctioneers: 2 shipped, 1 learned"), true, "report counts the auctioneers")
-- With auction routing on, a reagent row click goes to the learned auctioneer when it is closer than a vendor.
g = boot({ tomtom = true, db = { learned = { [90] = { 90, "Powder Seller", 100, 0.9, 0.5, 0, false, 0, 1 } } }, charDb = { standing = { [90] = true } } })
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
-- An auctioneer that refused this character (a goblin auction house while Unfriendly with its
-- cartel) is never used; seeing it trade again brings it back.
g.env.UnitReaction = function() return 3 end
g.npc = { guid = "Creature-0-4372-0-55-50-0000A1B2C3", name = "Auctioneer Near" }
g.onEvent("PLAYER_TARGET_CHANGED")
eq(g.env.ClosestVendorCharDB.standing[50], false, "auctioneer standing remembered")
window(g).rows[1].scripts.OnClick()
eq(g.tomtom[#g.tomtom], "Powder Seller", "an Unfriendly auctioneer is skipped")
g.env.UnitReaction = function() return 4 end
g.onEvent("PLAYER_TARGET_CHANGED")
window(g).rows[1].scripts.OnClick()
eq(g.tomtom[#g.tomtom], "Auctioneer Near", "Neutral again: used again")

-- Upgrade defaults differ from a genuinely fresh install; saved choices always win.
for _,case in ipairs({
    {opts={},want="toast"},
    {opts={db={cfg={autoNotice=false}}},want="warning"},
    {opts={charDb={cfg={bagThreshold=7}}},want="warning"},
    {opts={charDb={cfg={notificationStyle="toast"}}},want="toast"},
    {opts={charDb={cfg={notificationStyle="warning"}}},want="warning"},
}) do
    local upgraded=boot(case.opts);login(upgraded)
    eq(upgraded.env.ClosestVendorCharDB.cfg.notificationStyle,case.want,"upgrade/new-install notification default")
end

-- Read-only/invalid public commands do not evaluate a newly low condition.
g=boot();login(g);g.autoAccept=false;g.free=1
for _,msg in ipairs({"get bags.threshold","get bags.threshold extra","set bags.threshold 2.5","set unknown 3"}) do
    g.env.SlashCmdList.CLOSESTVENDOR(msg)
    eq(g.popup,nil,"read/invalid input cannot initiate gameplay: "..msg)
end
-- Live routes select exactly one transient renderer, without affecting the notice gate.
g=boot({tomtom=true});login(g)
eq(g.env.ClosestVendorCharDB.cfg.notificationStyle,"toast","fresh character defaults to Toast")
g.env.SlashCmdList.CLOSESTVENDOR("hud row bags always")
window(g).rows[1].scripts.OnClick()
local liveToast
for _,f in ipairs(g.frames) do if f.name=="ClosestVendorToast" then liveToast=f end end
eq(liveToast.shown,true,"route renders toast")
local warnings=0
for _,f in ipairs(g.frames) do if not f.name and f.scripts.OnUpdate and f.fontString and f.shown then warnings=warnings+1 end end
eq(warnings,0,"toast route does not duplicate warning")
liveToast:Hide();g.env.SlashCmdList.CLOSESTVENDOR("notice off")
window(g).rows[1].scripts.OnClick();eq(liveToast.shown,false,"disabled notice gate retained")
-- The newest request replaces what is on screen: a notification, a preview, a demo or a row click.
g=boot({tomtom=true});login(g);flush(g)
local function named(n) for _,f in ipairs(g.frames) do if f.name==n then return f end end end
g.env.SlashCmdList.CLOSESTVENDOR("hud row bags always")
window(g).rows[1].scripts.OnClick()
eq(named("ClosestVendorToast").shown,true,"a click shows the live toast")
g.env.SlashCmdList.CLOSESTVENDOR("preview notice")
eq(named("ClosestVendorToast").shown,false,"a preview replaces the live toast")
eq(named("ClosestVendorSampleToast").shown,true,"and shows its sample")
window(g).rows[1].scripts.OnClick()
eq(named("ClosestVendorSampleToast").shown,false,"a click replaces the sample toast")
eq(named("ClosestVendorToast").shown,true,"with the live one")
g.autoAccept=false;g.timers={}
g.env.SlashCmdList.CLOSESTVENDOR("demo")
local pinsInDemo=#g.tomtom
window(g).rows[1].scripts.OnClick()
eq(#g.timers>0 and (table.remove(g.timers,1)() or true),true,"the old demo step timer runs")
eq(#g.tomtom>pinsInDemo,true,"a click during the demo routes for real")
local afterClick=#g.tomtom
for _=1,10 do if #g.timers==0 then break end table.remove(g.timers,1)() end
eq(#g.tomtom,afterClick,"the stopped demo sets no more waypoints")
g=boot({tomtom=true});login(g);flush(g)
local function named2(n) for _,f in ipairs(g.frames) do if f.name==n then return f end end end
g.env.SlashCmdList.CLOSESTVENDOR("choice auto")
g.env.SlashCmdList.CLOSESTVENDOR("preview notice")
eq(named2("ClosestVendorSampleToast").shown,true,"a sample toast is up")
g.free=0;g.onEvent("BAG_UPDATE_DELAYED")
eq(named2("ClosestVendorToast").shown,true,"an automatic route shows its notification")
eq(named2("ClosestVendorSampleToast").shown,false,"and replaces the sample")
-- A cancelled clear request cannot clear diagnostic or gameplay data.
g=boot();login(g);g.autoAccept=false
g.env.SlashCmdList.CLOSESTVENDOR("debug on");g.onEvent("BAG_UPDATE_DELAYED")
local diagnosticCount=#g.env.ClosestVendorCharDB.log.entries
local bagThreshold=g.env.ClosestVendorCharDB.cfg.bagThreshold
g.env.SlashCmdList.CLOSESTVENDOR("log clear")
eq(#g.env.ClosestVendorCharDB.log.entries,diagnosticCount,"clear awaits acceptance")
g.env.StaticPopup_Hide("CLOSESTVENDOR_CLEAR_LOG")
eq(#g.env.ClosestVendorCharDB.log.entries,diagnosticCount,"cancel retains diagnostics")
g.env.SlashCmdList.CLOSESTVENDOR("log clear");g.popup.accept()
eq(#g.env.ClosestVendorCharDB.log.entries,0,"accept clears diagnostics")
eq(g.env.ClosestVendorCharDB.cfg.bagThreshold,bagThreshold,"clear retains configuration")

-- /cvn demo: a tour of real routes, questions and notifications, then the previous waypoint is back.
local function deep(t)
    if type(t) ~= "table" then return tostring(t) end
    local parts = {}; for k,v in pairs(t) do parts[#parts+1] = tostring(k).."="..deep(v) end
    table.sort(parts); return "{"..table.concat(parts,",").."}"
end
g = boot({tomtom=true}); login(g); flush(g)
local demoSounds={};g.env.PlaySound=function(id) demoSounds[#demoSounds+1]=id end
g.env.SlashCmdList.CLOSESTVENDOR("test sell")
local before = g.tomtom[#g.tomtom]
local pins = #g.tomtom
g.env.ClosestVendorCharDB.cfg.remindSound="ping"
g.env.ClosestVendorCharDB.cfg.autoNotice=false
local saved = deep(g.env.ClosestVendorCharDB.cfg)
g.autoAccept=false; g.timers={}; demoSounds={}
g.env.SlashCmdList.CLOSESTVENDOR("demo")
eq(window(g).frame.shown,true,"made-up status rows during the demo")
eq(#g.tomtom,pins+1,"step 1 sets a real waypoint without asking")
eq(demoSounds[1],3175,"its notification plays the chosen sound, even with On-screen notice off")
eq(#g.timers,1,"the next step is scheduled")
table.remove(g.timers,1)()
eq(g.popup and g.popup.which,"CLOSESTVENDOR_CONFIRM","step 2 asks a real question")
local steps=2
while #g.timers>0 and steps<20 do table.remove(g.timers,1)(); steps=steps+1 end
eq(steps>=6,true,"the tour has several steps: "..steps)
eq(g.tomtom[#g.tomtom],before,"the waypoint from before the demo is restored")
eq(deep(g.env.ClosestVendorCharDB.cfg),saved,"the demo changes no setting")
eq(window(g).rows[1].row ~= nil and window(g).rows[1].row.text ~= nil,true,"real rows are back")
-- The player's own game waypoint (one slot) is set again after the demo used that slot, but a new
-- one the player set during the tour is left alone.
local function nativeDemo(untracked, pre)
    local gn = boot()
    gn.slot, gn.tracked = nil, false
    gn.env.C_Map.CanSetUserWaypointOnMap = function() return true end
    gn.env.C_Map.SetUserWaypoint = function(p) gn.slot = p end
    gn.env.C_Map.GetUserWaypoint = function() return gn.slot end
    gn.env.C_Map.ClearUserWaypoint = function() gn.slot = nil end
    gn.env.C_SuperTrack = { SetSuperTrackedUserWaypoint = function(on) gn.tracked = on end,
        IsSuperTrackingUserWaypoint = function() return gn.tracked end }
    gn.env.UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { uiMapID = m, position = { x = x, y = y } } end }
    login(gn); flush(gn)
    gn.env.SlashCmdList.CLOSESTVENDOR("nav native")
    if pre then pre(gn) else gn.slot, gn.tracked = { uiMapID = 200, position = { x = 0.2, y = 0.3 } }, not untracked end
    gn.env.ClosestVendorCharDB.log.enabled = true
    gn.autoAccept = false; gn.timers = {}
    gn.env.SlashCmdList.CLOSESTVENDOR("demo")
    return gn
end
do
    local gn = nativeDemo()
    eq(gn.slot.uiMapID ~= 200, true, "the demo's first step uses the game waypoint")
    local n = 0
    while #gn.timers > 0 and n < 20 do table.remove(gn.timers, 1)(); n = n + 1 end
    eq(gn.slot and (gn.slot.uiMapID .. ":" .. gn.slot.position.x .. ":" .. tostring(gn.tracked)), "200:0.2:true",
        "the player's own game waypoint is back, still tracked")
    eq(logged(gn, "demo: your game waypoint restored, tracked"), true, "the log says it is tracked")
    -- An untracked point comes back untracked (test_nav.lua checks SetGame turns tracking off).
    gn = nativeDemo(true)
    n = 0
    while #gn.timers > 0 and n < 20 do table.remove(gn.timers, 1)(); n = n + 1 end
    eq(gn.slot and (gn.slot.uiMapID .. ":" .. tostring(gn.tracked)), "200:false",
        "the player's untracked game waypoint is back, not tracked")
    eq(logged(gn, "demo: your game waypoint restored, not tracked"), true, "the log says it is not tracked")
    -- A game waypoint that cannot be read at the end is not set over: the log says why.
    gn = nativeDemo()
    table.remove(gn.timers, 1)()
    gn.env.C_Map.GetUserWaypoint = function() error("boom") end
    n = 0
    while #gn.timers > 0 and n < 20 do table.remove(gn.timers, 1)(); n = n + 1 end
    eq(logged(gn, "demo: your game waypoint not set again: the game would not tell what is there now"), true, "unreadable slot: no restore")
    eq(logged(gn, "demo: your game waypoint restored"), false, "and nothing was set")
    -- The addon had its own game pin, the player set a point in the last step, and the slot cannot be read
    -- at the end: the old pin is not set over the player's point.
    gn = nativeDemo(nil, function(x) x.env.SlashCmdList.CLOSESTVENDOR("test sell") end)
    eq(gn.slot ~= nil, true, "the addon's own game pin is set before the demo")
    local k = 0
    while #gn.timers > 0 and not logged(gn, "demo: reminder") and k < 20 do table.remove(gn.timers, 1)(); k = k + 1 end
    gn.slot = { uiMapID = 600, position = { x = 0.6, y = 0.6 } }
    gn.env.C_Map.GetUserWaypoint = function() error("boom") end
    while #gn.timers > 0 and k < 40 do table.remove(gn.timers, 1)(); k = k + 1 end
    eq(logged(gn, "demo: over"), true, "the tour ended")
    eq(gn.slot.uiMapID, 600, "unreadable slot: the player's last point is not replaced by the old pin")
    -- A point the player sets 0.0005 from a demo pin is the player's: stopping the demo keeps it.
    gn = nativeDemo()
    local p0 = gn.slot.position
    gn.slot = { uiMapID = gn.slot.uiMapID, position = { x = p0.x + 0.0005, y = p0.y } }
    gn.env.SlashCmdList.CLOSESTVENDOR("preview notice")
    eq(gn.slot and gn.slot.position.x, p0.x + 0.0005, "a nearby player point survives a stopped demo")
    -- Set after the first step: later steps use the slot, and the player's newest point comes back.
    gn = nativeDemo()
    table.remove(gn.timers, 1)()
    gn.slot = { uiMapID = 300, position = { x = 0.6, y = 0.6 } }
    n = 0
    while #gn.timers > 0 and n < 20 do table.remove(gn.timers, 1)(); n = n + 1 end
    eq(gn.slot and gn.slot.uiMapID, 300, "a waypoint the player set during the tour stays")
    -- Set in the last step: left as it is.
    gn = nativeDemo()
    gn.env.ClosestVendorCharDB.log.enabled = true
    n = 0
    while #gn.timers > 0 and not logged(gn, "demo: reminder") and n < 20 do table.remove(gn.timers, 1)(); n = n + 1 end
    gn.slot = { uiMapID = 400, position = { x = 0.6, y = 0.6 } }
    while #gn.timers > 0 and n < 20 do table.remove(gn.timers, 1)(); n = n + 1 end
    eq(gn.slot and gn.slot.uiMapID, 400, "a waypoint set at the last step stays")
    -- The addon's own game waypoint from before the demo is not put back over the player's new one.
    gn = nativeDemo()
    gn.env.SlashCmdList.CLOSESTVENDOR("preview notice")
    gn.autoAccept = true
    gn.env.SlashCmdList.CLOSESTVENDOR("test sell") -- the addon's pin now holds the slot
    gn.autoAccept = false
    local own = gn.slot.uiMapID
    gn.timers = {}
    gn.env.SlashCmdList.CLOSESTVENDOR("demo")
    table.remove(gn.timers, 1)()
    gn.slot = { uiMapID = 500, position = { x = 0.1, y = 0.1 } }
    n = 0
    while #gn.timers > 0 and n < 20 do table.remove(gn.timers, 1)(); n = n + 1 end
    eq(gn.slot and gn.slot.uiMapID, 500, "the player's new waypoint wins over the addon's old pin")
    gn = nativeDemo()
    gn.env.SlashCmdList.CLOSESTVENDOR("preview notice")
    gn.autoAccept = true
    gn.env.SlashCmdList.CLOSESTVENDOR("test sell")
    gn.autoAccept = false
    gn.timers = {}
    gn.env.ClosestVendorCharDB.log.enabled = true
    gn.env.SlashCmdList.CLOSESTVENDOR("demo")
    n = 0
    while #gn.timers > 0 and not logged(gn, "demo: reminder") and n < 20 do table.remove(gn.timers, 1)(); n = n + 1 end
    gn.slot = { uiMapID = 600, position = { x = 0.1, y = 0.1 } }
    while #gn.timers > 0 and n < 20 do table.remove(gn.timers, 1)(); n = n + 1 end
    eq(gn.slot and gn.slot.uiMapID, 600, "set at the last step: the addon's old pin is not put over it")
    eq(logged(gn, "demo: previous waypoint not set again: the game waypoint is yours now"), true, "and the log says why")
    gn = nativeDemo()
    gn.env.SlashCmdList.CLOSESTVENDOR("preview notice")
    gn.slot = nil
    gn.autoAccept = true
    gn.env.SlashCmdList.CLOSESTVENDOR("test sell")
    gn.autoAccept = false
    own = gn.slot.uiMapID
    gn.timers = {}
    gn.env.SlashCmdList.CLOSESTVENDOR("demo")
    n = 0
    while #gn.timers > 0 and n < 20 do table.remove(gn.timers, 1)(); n = n + 1 end
    eq(gn.slot and gn.slot.uiMapID, own, "untouched by the player: the addon's own pin comes back")
    gn = nativeDemo()
    gn.env.SlashCmdList.CLOSESTVENDOR("preview notice") -- a newer request stops the demo
    eq(gn.slot and gn.slot.uiMapID, 200, "stopping the demo puts it back too")
end
-- A second demo replaces the first: the old chain stops.
g.timers={}
g.env.SlashCmdList.CLOSESTVENDOR("demo")
local old=g.timers[1]
g.env.SlashCmdList.CLOSESTVENDOR("demo")
local count=#g.timers
old();eq(#g.timers,count,"an old step timer does nothing")
g.env.C_Timer=nil;g.env.SlashCmdList.CLOSESTVENDOR("demo")
eq(has(lastPrinted(g),"working timer"),true,"missing timer explained")
g.env.SlashCmdList.CLOSESTVENDOR("preview notice")
eq(has(lastPrinted(g),"working timer"),true,"a preview without timers is explained")

-- 40. Supplies: food, water and pet food from the bags, learned from merchants, the report line and the
-- commands; a mage who can conjure and a warlock without a healthstone get a reminder instead.
local function supplyGame(class, bag, over)
    local gg = boot({ tomtom = true })
    gg.ns.ShippedVendors = {
        { 81, "Plain Shop", 100, 0.51, 0.5, 0, false, 0, 0, 0 },
        { 82, "Baker",      100, 0.70, 0.5, 0, false, 0, 0, 1 },   -- food
        { 83, "Well",       100, 0.60, 0.5, 0, false, 0, 0, 2 },   -- water
        { 84, "Butcher",    100, 0.90, 0.5, 0, false, 0, 0, 1 + 4 }, -- food, Meat
    }
    gg.ns.PetFamilies = { [1] = 4 } -- Wolf eats Meat
    gg.ns.SupplyItems = { [117] = 1 + 4, [159] = 2, [5509] = 256, [4540] = 1 + 16 }
    gg.class, gg.spells, gg.counts, gg.bag = class, {}, {}, bag
    for k, v in pairs(over or {}) do gg[k] = v end
    gg.env.GetContainerNumSlots = function(b) return b == 0 and 16 or 0 end
    gg.env.GetContainerItemInfo = function(_, s) local it = gg.bag[s]; return it and { itemID = it[1], stackCount = it[2] } or nil end
    login(gg)
    gg.autoAccept = false
    return gg
end
g = supplyGame("WARRIOR", { { 117, 2 } })
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup ~= nil, true, "low food asks")
eq(has(g.popup.text, "food") and has(g.popup.text, "2 left"), true, "names food and the count: " .. g.popup.text)
eq(has(g.popup.text, "Baker") and not has(g.popup.text, "Plain Shop"), true, "the nearest seller of food, not the nearest shop")
g.popup.accept()
eq(g.tomtom[1], "Baker", "Yes navigates to the food seller")
g.bag[2] = { 117, 30 }
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.shown, 1, "restocked: nothing more asked")

g = supplyGame("PRIEST", { { 117, 30 }, { 159, 2 } })
g.onEvent("BAG_UPDATE_DELAYED")
eq(has(g.popup.text, "water") and has(g.popup.text, "Well"), true, "a priest is asked about water: " .. g.popup.text)
g = supplyGame("ROGUE", { { 117, 30 } })
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "a rogue is not asked about water")
g = supplyGame("WARRIOR", { { 117, 1 } }); g.env.SlashCmdList.CLOSESTVENDOR("ammo off"); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup ~= nil and has(g.popup.text, "food"), true, "ammo switch off: food is still asked")
g = supplyGame("WARRIOR", { { 117, 1 } }); g.env.SlashCmdList.CLOSESTVENDOR("supplies off"); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "supplies switch off: nothing asked")
g.env.SlashCmdList.CLOSESTVENDOR("supplies on"); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup ~= nil and has(g.popup.text, "food"), true, "switched back on: asked")
g = supplyGame("WARRIOR", { { 117, 1 } }); g.env.SlashCmdList.CLOSESTVENDOR("food off"); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "food switched off")
g = supplyGame("WARRIOR", { { 117, 8 } }); g.env.SlashCmdList.CLOSESTVENDOR("food 10"); g.onEvent("BAG_UPDATE_DELAYED")
eq(g.env.ClosestVendorCharDB.cfg.foodThreshold, 10, "/cvn food sets the threshold")
eq(g.popup ~= nil, true, "and it applies at once")
g = supplyGame("WARRIOR", { { 117, 1 } }); g.env.SlashCmdList.CLOSESTVENDOR("food 99")
eq(g.env.ClosestVendorCharDB.cfg.foodThreshold, 5, "out of range: unchanged")
g = supplyGame("WARRIOR", { { 117, 1 } }); g.bag = nil
g.bag = {}
g.env.GetContainerItemInfo = function() error("unreadable") end
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "unreadable bags are not an empty bag")

-- Pet food: the pet's diet from the game picks what is counted and which vendor is offered.
g = supplyGame("HUNTER", { { 117, 2 }, { 159, 30 }, { 4540, 30 } }, nil)
g.env.UnitCreatureFamily = function() return "Wolf", 1 end
g.onEvent("UNIT_PET", "player")
eq(g.popup ~= nil and has(g.popup.text, "pet food (Meat)") and has(g.popup.text, "2 left"), true, "pet food asks: " .. tostring(g.popup and g.popup.text))
eq(has(g.popup.text, "Butcher") and not has(g.popup.text, "Baker"), true, "the Meat seller, not the nearer Baker")
g = supplyGame("HUNTER", { { 117, 2 }, { 159, 30 }, { 4540, 30 } })
g.env.UnitCreatureFamily = function() end
g.onEvent("UNIT_PET", "player")
eq(g.popup, nil, "no pet out: nothing asked")
g = supplyGame("HUNTER", { { 117, 2 }, { 159, 30 }, { 4540, 30 } })
g.env.UnitCreatureFamily = function() return "Wolf", 1 end
g.onEvent("UNIT_PET", "player")
-- Another player's pet or gear is none of our business: no evaluation, no bag scan.
do
    local gp = supplyGame("HUNTER", { { 117, 2 }, { 159, 30 }, { 4540, 30 } })
    gp.env.UnitCreatureFamily = function() return "Wolf", 1 end
    local scans = 0
    local real = gp.env.GetContainerItemInfo
    gp.env.GetContainerItemInfo = function(...) scans = scans + 1; return real(...) end
    gp.onEvent("UNIT_PET", "party1")
    gp.onEvent("UNIT_INVENTORY_CHANGED", "raid3")
    eq(scans, 0, "events for other units read no bags")
    eq(gp.popup, nil, "and ask nothing")
    gp.onEvent("UNIT_PET", "player")
    eq(scans > 0 and gp.popup ~= nil, true, "the player's own pet event does")
    -- With every supply switch off, the bags are not scanned for supplies.
    local gq = supplyGame("HUNTER", { { 117, 2 } })
    local cfg = gq.env.ClosestVendorCharDB.cfg
    cfg.foodEnabled, cfg.waterEnabled, cfg.petFoodEnabled, cfg.healthstoneRemind = false, false, false, false
    local n = 0
    local real2 = gq.env.GetContainerItemInfo
    gq.env.GetContainerItemInfo = function(...) n = n + 1; return real2(...) end
    gq.onEvent("BAG_UPDATE_DELAYED")
    eq(n, 0, "all supply warnings off: the bags are not scanned")
    cfg.foodEnabled = true
    gq.onEvent("BAG_UPDATE_DELAYED")
    eq(n > 0, true, "one switched on: they are")
    cfg.ammoEnabled = false
    n = 0
    gq.onEvent("BAG_UPDATE_DELAYED")
    eq(n > 0, true, "the ammo switch off does not stop the supply scan")
    cfg.ammoEnabled = true
    cfg.suppliesEnabled = false
    n = 0
    gq.onEvent("BAG_UPDATE_DELAYED")
    eq(n, 0, "the supplies switch off: the bags are not scanned for supplies")
end

g.env.SlashCmdList.CLOSESTVENDOR("petfood off")
eq(g.env.ClosestVendorCharDB.cfg.petFoodEnabled, false, "/cvn petfood off")

-- Reminders.
g = supplyGame("MAGE", { { 117, 1 }, { 159, 30 } }, { spells = { [587] = true } })
g.onEvent("BAG_UPDATE_DELAYED")
eq(g.popup, nil, "a mage who can conjure is not sent to a vendor")
eq(has(table.concat(g.printed, "\n"), "You are low on food (1 left). Cast Conjure Food to make more."), true, "and is reminded")
g = supplyGame("WARLOCK", { { 117, 30 }, { 159, 30 } }, { spells = { [6201] = true } })
g.onEvent("BAG_UPDATE_DELAYED")
eq(has(table.concat(g.printed, "\n"), "You have no healthstone. Cast Create Healthstone to make one."), true, "warlock reminder")
g = supplyGame("WARLOCK", { { 117, 30 }, { 159, 30 }, { 5509, 1 } }, { spells = { [6201] = true } })
g.onEvent("BAG_UPDATE_DELAYED")
eq(has(table.concat(g.printed, "\n"), "healthstone"), false, "has one: no reminder")

-- The reminder sound, end to end: the saved key becomes a game sound id, once per reminder.
do
    local function chimeGame(class, bag, spells)
        local gg = supplyGame(class, bag, { spells = spells })
        gg.played = {}
        gg.env.PlaySound = function(id) gg.played[#gg.played + 1] = id end
        return gg
    end
    g = chimeGame("MAGE", { { 117, 1 }, { 159, 30 } }, { [587] = true })
    g.onEvent("BAG_UPDATE_DELAYED")
    eq(table.concat(g.played, ","), "3081", "a reminder plays the whisper ping by default")
    g.onEvent("BAG_UPDATE_DELAYED")
    eq(#g.played, 1, "and only once")
    g = chimeGame("MAGE", { { 117, 1 }, { 159, 30 } }, { [587] = true })
    g.env.SlashCmdList.CLOSESTVENDOR("sound ping")
    eq(table.concat(g.played, ","), "3175", "/cvn sound plays the new choice as a preview")
    eq(g.env.ClosestVendorCharDB.cfg.remindSound, "ping", "and saves it")
    g.onEvent("BAG_UPDATE_DELAYED")
    eq(table.concat(g.played, ","), "3175,3175", "the reminder uses it")
    g.env.SlashCmdList.CLOSESTVENDOR("sound none")
    eq(#g.played, 2, "none previews nothing")
    g.bag = { { 117, 1 }, { 159, 30 } }
    g.onEvent("BAG_UPDATE_DELAYED")
    g = chimeGame("MAGE", { { 117, 1 }, { 159, 30 } }, { [587] = true })
    g.env.SlashCmdList.CLOSESTVENDOR("sound none")
    g.onEvent("BAG_UPDATE_DELAYED")
    eq(#g.played, 0, "none: a reminder is silent")
    g = chimeGame("MAGE", { { 117, 30 }, { 159, 30 } }, { [587] = true })
    g.env.SlashCmdList.CLOSESTVENDOR("test remind")
    eq(table.concat(g.played, ","), "3081", "/cvn test remind plays it")
    g = chimeGame("WARRIOR", { { 117, 1 } })
    g.env.PlaySound = nil
    g.env.SlashCmdList.CLOSESTVENDOR("sound ping")
    eq(g.env.ClosestVendorCharDB.cfg.remindSound, "ping", "a client without PlaySound: still saved, no error")
end
-- A sound-pack sound, end to end: Core wires LibSharedMedia into the choices and plays its file.
do
    local gg = supplyGame("MAGE", { { 117, 1 }, { 159, 30 } }, { spells = { [587] = true } })
    local files, kits = {}, {}
    local shared = { Bell = "Sound\\bell.ogg" }
    local lsm = { HashTable = function() return shared end, Fetch = function(_, _, name) return shared[name] end }
    gg.env.LibStub = function(major) if major == "LibSharedMedia-3.0" then return lsm end end
    gg.env.PlaySoundFile = function(f) files[#files + 1] = f end
    gg.env.PlaySound = function(id) kits[#kits + 1] = id end
    gg.env.SlashCmdList.CLOSESTVENDOR("sound bell")
    eq(gg.env.ClosestVendorCharDB.cfg.remindSound .. "|" .. table.concat(files, ","), "lsm:Bell|Sound\\bell.ogg", "/cvn sound picks a sound-pack sound and plays its file")
    gg.onEvent("BAG_UPDATE_DELAYED")
    eq(#files .. "/" .. #kits, "2/0", "a reminder plays the sound-pack file")
    shared.Bell = nil
    gg.bag = { { 117, 1 }, { 159, 30 } }
    gg.env.SlashCmdList.CLOSESTVENDOR("test remind")
    eq(table.concat(kits, ",") .. "|" .. gg.env.ClosestVendorCharDB.cfg.remindSound, "3081|lsm:Bell", "pack gone: the whisper ping plays and the choice stays saved")
end

-- Status window: the Supplies rows follow the bags and the pet.
do
    local gg = supplyGame("PRIEST", { { 117, 2 }, { 159, 30 } })
    flush(gg)
    eq(shownRows(gg), "Low: Food: 2", "mode low: only the low row")
    gg.env.SlashCmdList.CLOSESTVENDOR("hud row supplies always")
    flush(gg)
    eq(shownRows(gg), "Low: Food: 2 | Water: 30", "always: food and water")
    gg.bag[1] = { 117, 40 }
    gg.onEvent("BAG_UPDATE_DELAYED"); flush(gg)
    eq(shownRows(gg), "Food: 40 | Water: 30", "the bags changed: the rows follow")
    gg.env.SlashCmdList.CLOSESTVENDOR("hud row supplies never")
    flush(gg)
    eq(window(gg).frame.shown, false, "never: nothing to show, no window")
    local hh = supplyGame("HUNTER", { { 117, 30 }, { 159, 30 }, { 4540, 30 } })
    hh.env.SlashCmdList.CLOSESTVENDOR("hud row supplies always")
    flush(hh)
    eq(shownRows(hh), "Food: 60 | Water: 30", "no pet: no pet food row")
    hh.env.UnitCreatureFamily = function() return "Wolf", 1 end
    hh.onEvent("UNIT_PET", "player"); flush(hh)
    eq(shownRows(hh), "Food: 60 | Water: 30 | Pet food: 30", "a pet out: its diet's row appears at once")
end

-- Merchants: the supplies they sell are learned (food + Bread here), and a shipped vendor keeps its own.
g = supplyGame("WARRIOR", { { 117, 30 } })
g.npc = { guid = "Creature-0-4372-0-55-90-0000A1B2C3", name = "New Baker" }
g.pos = { map = 100, x = 0.2, y = 0.5 }
g.stock = { 4540 }
g.onEvent("MERCHANT_SHOW")
eq(g.env.ClosestVendorDB.learned[90][10], 17, "supply mask learned from the offered items")
g.npc = { guid = "Creature-0-4372-0-55-82-0000A1B2C3", name = "Baker" }
g.pos = { map = 100, x = 0.7, y = 0.5 }
g.stock = { 4540 }
g.onEvent("MERCHANT_SHOW")
eq(g.env.ClosestVendorDB.learned[82][10], 17, "a shipped food vendor keeps food when opened")

-- Defaults, old saved data and the report line.
g = boot({ tomtom = true, db = { cfg = { ammoThreshold = 100, foodThreshold = 9 } } }); login(g)
local c = g.env.ClosestVendorCharDB.cfg
eq(c.foodEnabled and c.waterEnabled and c.petFoodEnabled and c.healthstoneRemind, true, "new switches default on")
eq(c.waterThreshold .. "/" .. c.petFoodThreshold, "5/5", "new thresholds default to 5")
eq(c.foodThreshold, 9, "a saved value is kept")
g = supplyGame("WARRIOR", { { 117, 30 } })
g.env.SlashCmdList.CLOSESTVENDOR("water off")
g.env.SlashCmdList.CLOSESTVENDOR("log")
local swin
for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then swin = f end end
eq(has(swin.box.text, "supplies: on; food on (5), water off (5), pet food on (5), healthstone reminder on"), true, "report line")
g.env.SlashCmdList.CLOSESTVENDOR("status")
eq(has(table.concat(g.printed, "\n"), "Supplies: food on (5), water off (5), pet food on (5), healthstone reminder on"), true, "settings line")
eq(has(table.concat(g.printed, "\n"), "Notification sound: Whisper ping"), true, "sound line")
eq(has(swin.box.text, "notification sound whisper"), true, "sound in the report header")

-- 32. NorgannonDB (optional): its vendors on the Forever-only maps join the pool; nothing changes without it.
local function fakeNG()
    local npcs = { [9001] = { name = "Hyjal Seller", flags = 4, reaction = "AH", spawns = { [616] = { { 52, 50 } } }, sells = {} } }
    return {
        schema = { major = 1, minor = 5 },
        zones = { [616] = { uiMapId = 2482 } },
        index = { zones = { [616] = { npcs = { 9001 } } } },
        categories = { vendor = { npcs = { [9001] = "AH" } } },
        RequireSchema = function() return true end,
        Peek = function(_, _, id) return npcs[id] end,
    }
end
local function reportOf(gg)
    gg.env.SlashCmdList.CLOSESTVENDOR("log")
    local w
    for _, f in ipairs(gg.frames) do if f.name == "ClosestVendorReport" then w = f end end
    return w and w.box.text or ""
end
g = boot(); login(g)
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(lastPrinted(g):find("Ally Seller", 1, true) ~= nil, true, "no NorgannonDB: the usual nearest vendor")
eq(has(reportOf(g), "NorgannonDB: not found"), true, "report says it is not found")
local oldNG = fakeNG(); oldNG.schema = { major = 1, minor = 3 }; oldNG.RequireSchema = function() return false end
g = boot({ ng = oldNG }); login(g)
eq(has(reportOf(g), "NorgannonDB: installed, but its data is not a supported schema"), true, "report says the schema is not supported")
g = boot({ ng = fakeNG() }); login(g)
g.pos = { map = 2482, x = 0.5, y = 0.5 } -- the player is in Mount Hyjal
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(lastPrinted(g):find("Hyjal Seller", 1, true) ~= nil, true, "NorgannonDB vendor is the nearest: " .. lastPrinted(g))
eq(has(reportOf(g), "NorgannonDB: found, schema 1.5, 1 vendors added, 0 skipped"), true, "report line")
-- The question line names where its target came from (covers: Question lines name the source and the distance).
do
    local function questionOf(gg)
        for line in logText(gg):gmatch("[^\n]+") do if line:find("question shown:", 1, true) then return line end end
    end
    local function lowBags(gg)
        gg.env.SlashCmdList.CLOSESTVENDOR("debug on")
        gg.free = 1
        gg.onEvent("BAG_UPDATE_DELAYED")
        return questionOf(gg)
    end
    local gn = boot({ ng = fakeNG() }); login(gn)
    gn.pos = { map = 2482, x = 0.5, y = 0.5 }
    eq(lowBags(gn):match("^question shown: sell, Hyjal Seller %(npc 9001%), NorgannonDB, %d+ yd$") ~= nil, true, "a vendor only NorgannonDB gave: " .. tostring(questionOf(gn)))
    local gs = boot(); login(gs)
    eq(lowBags(gs):match("^question shown: sell, Ally Seller %(npc 4%), shipped, %d+ yd$") ~= nil, true, "a shipped vendor: " .. tostring(questionOf(gs)))
    local gl = boot({ db = { learned = { [777] = { 777, "Learned Seller", 100, 0.76, 0.5, 1, false, 0, 0, 0 } } } }); login(gl)
    gl.pos = { map = 100, x = 0.76, y = 0.5 }
    eq(lowBags(gl):match("^question shown: sell, Learned Seller %(npc 777%), learned, %d+ yd$") ~= nil, true, "a vendor this account learned: " .. tostring(questionOf(gl)))
    -- /cvn test trainer end to end (covers: Trainer test command): a character with no profession, a learned trainer.
    local gt = boot({ db = { trainers = { [30] = { 30, "Near Smith", 100, 0.76, 0.5, 1, { Blacksmithing = true } } } } }); login(gt)
    gt.pos = { map = 100, x = 0.76, y = 0.5 }
    gt.autoAccept = false
    gt.env.SlashCmdList.CLOSESTVENDOR("debug on")
    gt.env.SlashCmdList.CLOSESTVENDOR("test trainer")
    eq(questionOf(gt), "question shown: trainer for Blacksmithing, Near Smith (npc 30), learned, 0 yd", "test trainer names the learned trainer: " .. tostring(questionOf(gt)))
    eq(gt.popup ~= nil and gt.popup.text:find("Near Smith", 1, true) ~= nil, true, "and the dialog names the trainer")
    local gn2 = boot(); login(gn2)
    gn2.env.SlashCmdList.CLOSESTVENDOR("test trainer")
    eq(has(lastPrinted(gn2), "No known profession trainer"), true, "no trainer known: chat says so: " .. tostring(lastPrinted(gn2)))
end
-- A trainer only NorgannonDB knows: an Unfriendly reaction is remembered, so it is not offered.
do
    local ng = fakeNG()
    local peekVendor = ng.Peek
    local tnpcs = { [9100] = { name = "Master Smith", subName = "Master Blacksmith", reaction = "AH", spawns = { [700] = { { 90, 50 } } } } }
    ng.Peek = function(self, kind, id) return tnpcs[id] or peekVendor(self, kind, id) end
    ng.zones[700] = { uiMapId = 100 }
    ng.categories.trainer = { npcs = { [9100] = "AH" } }
    ng.recipes = { [1] = { skill = 164, trainers = { [9100] = 1 } } }
    ng.L = function(_, kind, id) if kind == "professions" and id == 164 then return "Blacksmithing" end end
    local gs = boot({ tomtom = true, ng = ng }); login(gs)
    gs.npc = { guid = "Creature-0-4372-0-55-9100-0000A1B2C3", name = "Master Smith" }
    gs.env.UnitReaction = function() return 3 end
    gs.onEvent("PLAYER_TARGET_CHANGED")
    eq(gs.env.ClosestVendorCharDB.standing[9100], false, "an Unfriendly trainer only NorgannonDB knows is remembered")
end

-- Trainers with a tier from NorgannonDB: Artisan is routed, only to a trainer whose title teaches it;
-- a learned trainer of unknown tier is not used for Artisan, and its position wins when NorgannonDB has it.
do
    local ng = fakeNG()
    local tnpcs = {
        [9100] = { name = "Master Smith", subName = "Master Blacksmith", reaction = "AH", spawns = { [700] = { { 90, 50 } } } },
        [9101] = { name = "Expert Smith", subName = "Expert Blacksmith", reaction = "AH", spawns = { [700] = { { 51, 50 } } } },
    }
    local peekVendor = ng.Peek
    ng.Peek = function(self, kind, id) return tnpcs[id] or peekVendor(self, kind, id) end
    ng.zones[700] = { uiMapId = 100 }
    ng.categories.trainer = { npcs = { [9100] = "AH", [9101] = "AH" } }
    ng.recipes = { [1] = { skill = 164, trainers = { [9100] = 1, [9101] = 1 } } }
    ng.L = function(_, kind, id) if kind == "professions" and id == 164 then return "Blacksmithing" end end
    local gt = boot({ tomtom = true, ng = ng, db = { trainers = { [9102] = { 9102, "Learned Smith", 100, 0.5, 0.5, 0, { Blacksmithing = true } } } },
        charDb = { professions = { Blacksmithing = true } } })
    login(gt)
    gt.env.UnitLevel = function() return 40 end
    gt.pos = { map = 100, x = 0.5, y = 0.5 }
    gt.autoAccept = false
    gt.skillLines = { { "Blacksmithing", 219, 225 } }; gt.onEvent("SKILL_LINES_CHANGED")
    gt.skillLines = { { "Blacksmithing", 220, 225 } }; gt.onEvent("SKILL_LINES_CHANGED")
    eq(gt.popup and gt.popup.text:find("Master Smith", 1, true) ~= nil, true, "Artisan next: the Master Blacksmith, not the nearer ones: " .. tostring(gt.popup and gt.popup.text))
    eq(has(reportOf(gt), "1 vendors added, 0 skipped, 2 trainers with a tier"), true, "report counts the trainers")
    gt.env.ClosestVendorCharDB.cfg.hudRow = { professions = "always" }
    gt.onEvent("BAG_UPDATE_DELAYED"); flush(gt)
    local lowRow = false
    for _, r in ipairs(window(gt).rows) do if r.text and r.text.text and r.text.text:find("Low: Blacksmithing", 1, true) then lowRow = true end end
    eq(lowRow, true, "the status window marks the Artisan row low")
    -- A learned trainer NorgannonDB also has keeps its learned name and position, and gains the tier.
    local gm = boot({ tomtom = true, ng = ng, db = { trainers = { [9100] = { 9100, "Learned Master", 100, 0.52, 0.5, 0, { Blacksmithing = true } } } },
        charDb = { professions = { Blacksmithing = true } } })
    login(gm)
    gm.env.UnitLevel = function() return 40 end
    gm.pos = { map = 100, x = 0.5, y = 0.5 }
    gm.autoAccept = false
    gm.skillLines = { { "Blacksmithing", 219, 225 } }; gm.onEvent("SKILL_LINES_CHANGED")
    gm.skillLines = { { "Blacksmithing", 220, 225 } }; gm.onEvent("SKILL_LINES_CHANGED")
    eq(gm.popup and gm.popup.text:find("Learned Master", 1, true) ~= nil, true, "learned record with NorgannonDB's tier: " .. tostring(gm.popup and gm.popup.text))
    -- NorgannonDB loading after login: its trainers are read too.
    local gl = boot({ tomtom = true, charDb = { professions = { Blacksmithing = true } } })
    login(gl)
    gl.env.UnitLevel = function() return 40 end
    gl.pos = { map = 100, x = 0.5, y = 0.5 }
    gl.autoAccept = false
    gl.env.NorgannonDB = ng
    gl.onEvent("ADDON_LOADED", "NorgannonDB")
    gl.skillLines = { { "Blacksmithing", 219, 225 } }; gl.onEvent("SKILL_LINES_CHANGED")
    gl.skillLines = { { "Blacksmithing", 220, 225 } }; gl.onEvent("SKILL_LINES_CHANGED")
    eq(gl.popup and gl.popup.text:find("Master Smith", 1, true) ~= nil, true, "a late load adds the trainers")
end
-- Not installed at login, loaded later: read once more, no reload needed.
g = boot(); login(g)
g.env.NorgannonDB = fakeNG()
g.pos = { map = 2482, x = 0.5, y = 0.5 }
g.free = 1
g.onEvent("ADDON_LOADED", "NorgannonDB") -- no other event needed: it is evaluated again at once
eq(lastPrinted(g):find("Hyjal Seller", 1, true) ~= nil, true, "a late load adds the vendors")
-- Another addon loading, or NorgannonDB loading before our login, does not read it.
local reads = 0
local ng = fakeNG()
ng.RequireSchema = function() reads = reads + 1 return true end
g = boot({ ng = ng })
g.onEvent("ADDON_LOADED", "ClosestVendor")
g.onEvent("ADDON_LOADED", "NorgannonDB")
eq(reads, 0, "before login: not read")
g.onEvent("PLAYER_LOGIN")
eq(reads, 1, "read once after login")
g.onEvent("ADDON_LOADED", "SomeOtherAddon")
for _ = 1, 3 do g.onEvent("BAG_UPDATE_DELAYED"); g.onEvent("MERCHANT_SHOW"); g.onEvent("ZONE_CHANGED_NEW_AREA") end
eq(reads, 1, "never on bag, merchant or movement events")
-- A learned vendor that has moved keeps its own position; one that agrees keeps NorgannonDB's.
g = boot({ ng = fakeNG(), db = { learned = { [9001] = { 9001, "Hyjal Seller", 2482, 0.90, 0.5, 0, true, 0, 0, 0 } } } }); login(g)
g.pos = { map = 2482, x = 0.5, y = 0.5 }
g.free = 1
g.onEvent("BAG_UPDATE_DELAYED")
eq(lastPrinted(g):find("(90.0, 50.0)", 1, true) ~= nil, true, "a vendor that moved: the learned position: " .. lastPrinted(g))

-- Reagents have their own switch; a character saved before that keeps what the ammo switch said.
do
    local old = boot({ charDb = { cfg = { ammoEnabled = false } } }); login(old)
    eq(old.env.ClosestVendorCharDB.cfg.reagentsEnabled, false, "ammo was off: reagents start off")
    local on = boot({ charDb = { cfg = { ammoEnabled = true } } }); login(on)
    eq(on.env.ClosestVendorCharDB.cfg.reagentsEnabled, true, "ammo was on: reagents start on")
    local own = boot({ charDb = { cfg = { ammoEnabled = false, reagentsEnabled = true } } }); login(own)
    eq(own.env.ClosestVendorCharDB.cfg.reagentsEnabled, true, "an own choice is kept")
    local fresh = boot(); login(fresh)
    eq(fresh.env.ClosestVendorCharDB.cfg.reagentsEnabled, true, "new: on")
end

-- Settings are per character; vendors learned are shared by the account.
do
    local legacy = { cfg = { bagThreshold = 7, reagentOff = { [1] = true } }, hud = { point = "TOP" }, learned = {} }
    local a = boot({ db = legacy }); login(a)
    eq(a.env.ClosestVendorCharDB.cfg.bagThreshold, 7, "a first character starts from the settings the account had")
    eq(a.env.ClosestVendorCharDB.hud.point, "TOP", "and the window position")
    a.env.ClosestVendorCharDB.cfg.bagThreshold = 30
    a.env.ClosestVendorCharDB.cfg.reagentOff[2] = true
    eq(legacy.cfg.bagThreshold, 7, "changing one character leaves the account copy alone")
    eq(legacy.cfg.reagentOff[2], nil, "nested tables are copied, not shared")
    local b = boot({ db = legacy }); login(b)
    eq(b.env.ClosestVendorCharDB.cfg.bagThreshold, 7, "the next character starts from it too, not from the other character")
    local c = boot({ db = legacy, charDb = a.env.ClosestVendorCharDB }); login(c)
    eq(c.env.ClosestVendorCharDB.cfg.bagThreshold, 30, "a known character keeps its own settings")
    local d = boot(); login(d)
    eq(d.env.ClosestVendorCharDB.cfg.bagThreshold, 2, "no earlier settings: defaults")
    eq(d.env.ClosestVendorDB.cfg, nil, "and nothing is written to the account table")
end

-- The row's arrow lists other sellers in the game's menu; picking one pins it. No menu control: no arrow.
do
    local function arrow(game, row)
        for _, f in ipairs(game.frames) do
            if f.parent == row and f.kind == "Button" then return f end
        end
    end
    local g = boot({ tomtom = true }); login(g); g.autoAccept = false
    local menu
    g.env.MenuUtil = { CreateContextMenu = function(anchor, build)
        menu = { anchor = anchor, items = {} }
        build(anchor, {
            CreateTitle = function(_, t) menu.title = t end,
            CreateRadio = function(_, text, isSelected, pick) menu.items[#menu.items + 1] = { text = text, checked = isSelected(), pick = pick } end,
            CreateButton = function(_, text, pick) menu.items[#menu.items + 1] = { text = text, pick = pick } end,
        })
    end }
    g.env.SlashCmdList.CLOSESTVENDOR("hud row bags always"); flush(g)
    local row = window(g).rows[1]
    local more = arrow(g, row)
    eq(more ~= nil and more.shown, true, "the bag row has an arrow: several vendors buy items")
    more.scripts.OnClick()
    eq(menu and menu.anchor, more, "the menu opens at the arrow")
    eq(menu.title, "Other vendors to sell to", "with the row's title")
    eq(#menu.items >= 2 and #menu.items <= 4, true, "the default and up to three others: " .. #menu.items)
    eq(menu.items[1].checked, true, "the default is marked")
    eq(#g.tomtom, 0, "opening the menu sets no waypoint")
    local second = menu.items[2].text
    menu.items[2].pick()
    local name = second:match("^(.-) %(")
    eq(g.tomtom[#g.tomtom], name, "picking the second entry pins it")
    eq(has(lastPrinted(g), "Navigating to " .. name), true, "and chat names it: " .. lastPrinted(g))

    -- Only one friendly repair vendor: no arrow on the durability row.
    g.env.SlashCmdList.CLOSESTVENDOR("hud row bags never")
    g.env.SlashCmdList.CLOSESTVENDOR("hud row durability always"); flush(g)
    eq(arrow(g, window(g).rows[1]).shown, false, "a row with one seller has no arrow")

    -- No menu control on this client: no arrow, and the row click still routes.
    local n = boot({ tomtom = true }); login(n); n.autoAccept = false
    n.env.SlashCmdList.CLOSESTVENDOR("hud row bags always"); flush(n)
    local r = window(n).rows[1]
    local a = arrow(n, r)
    eq(a == nil or not a.shown, true, "no menu control: no arrow")
    r.scripts.OnClick()
    eq(#n.tomtom, 1, "and the row click still pins a vendor")
end

-- Debug log lines and CheckThat entries the in-game plans assert or keep as diagnostics (docs/contracts.md): exact text.
do
    local function msgs(gg) local t = {} for _, e in ipairs(gg.env.ClosestVendorCharDB.log.entries) do t[#t + 1] = e.msg end return t end
    local function times(gg, line) local n = 0 for _, m in ipairs(msgs(gg)) do if m == line then n = n + 1 end end return n end
    local function all(gg) return table.concat(msgs(gg), " / ") end
    local fns = {}
    local reads = 0
    local opts = { checkThat = { Entry = function(_, name, fn) fns[name] = fn; return true end } }
    local gl = boot(opts); login(gl)
    local isLoaded = gl.env.C_AddOns.IsAddOnLoaded
    gl.env.C_AddOns.IsAddOnLoaded = function(...) reads = reads + 1; return isLoaded(...) end
    gl.env.SlashCmdList.CLOSESTVENDOR("debug on")
    gl.autoAccept = false

    -- A vendor's window: new, unchanged, updated; a later read of the same window logs nothing again.
    eq(fns.learned("vendors"), 0, "learned: no vendor yet")
    gl.npc = { guid = "Creature-0-4372-0-55-1234-0000A1B2C3", name = "New Seller" }
    gl.onEvent("MERCHANT_SHOW")
    eq(times(gl, "vendor learned: New Seller (npc 1234), new; it was not in the search pool"), 1, "a vendor unknown to the addon: " .. all(gl))
    eq(fns.learned("vendors"), 1, "learned: one vendor")
    eq(fns.learned("vendors", 1234), true, "learned: that vendor")
    gl.onEvent("MERCHANT_SHOW")
    eq(times(gl, "vendor learned: New Seller (npc 1234), unchanged"), 1, "the same vendor again: unchanged")
    gl.repairable = true
    gl.onEvent("MERCHANT_SHOW")
    eq(times(gl, "vendor learned: New Seller (npc 1234), updated"), 1, "now known to repair: updated")
    -- A shipped vendor opened for the first time is new to the learned table, not to the search.
    gl.npc = { guid = "Creature-0-4372-0-55-2-0000A1B2C3", name = "Far Repairer" }
    gl.onEvent("MERCHANT_SHOW")
    eq(times(gl, "vendor learned: Far Repairer (npc 2), new"), 1, "a shipped vendor: new, in the search pool")
    gl.stock = { false }
    gl.npc = { guid = "Creature-0-4372-0-55-4321-0000A1B2C3", name = "Slow Shop" }
    gl.onEvent("MERCHANT_SHOW")
    gl.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    gl.onEvent("GET_ITEM_INFO_RECEIVED", 17020)
    eq(times(gl, "vendor learned: Slow Shop (npc 4321), new; it was not in the search pool"), 1, "a partial list read again: logged once")
    eq(times(gl, "vendor learned: Slow Shop (npc 4321), unchanged"), 0, "and the rereads of the same window log nothing")
    gl.stock = nil

    -- A trainer's window: learned once per window; a class trainer says why nothing was learned.
    gl.npc = { guid = "Creature-0-4372-0-55-5513-0000A1B2C3", name = "Gelman Stonehand" }
    gl.trainer = { "Mining", "Engineering" }
    gl.onEvent("TRAINER_SHOW")
    gl.onEvent("TRAINER_UPDATE")
    eq(times(gl, "trainer learned: Gelman Stonehand (npc 5513), new, teaches Mining, Engineering"), 1, "a new trainer, once: " .. all(gl))
    eq(fns.learned("trainers", 5513), true, "learned: that trainer")
    gl.onEvent("TRAINER_SHOW")
    eq(times(gl, "trainer learned: Gelman Stonehand (npc 5513), unchanged, teaches Mining, Engineering"), 1, "opened again: unchanged")
    gl.npc, gl.trainer = { guid = "Creature-0-4372-0-55-777-0000A1B2C3", name = "Class Trainer" }, nil
    gl.onEvent("TRAINER_SHOW")
    gl.onEvent("TRAINER_UPDATE")
    eq(times(gl, "trainer window: nothing learned: not a profession trainer"), 1, "a class trainer: why, once")
    gl.trainer = {}
    gl.onEvent("TRAINER_SHOW")
    eq(times(gl, "trainer window: nothing learned: no profession services listed yet"), 1, "services not listed yet: why")
    -- The services arrive late (TRAINER_UPDATE): the first readable read writes the line, once.
    gl.npc = { guid = "Creature-0-4372-0-55-5513-0000A1B2C3", name = "Gelman Stonehand" }
    gl.trainer = {}
    gl.onEvent("TRAINER_SHOW")
    gl.trainer = { "Mining", "Engineering" }
    gl.onEvent("TRAINER_UPDATE")
    gl.onEvent("TRAINER_UPDATE")
    eq(times(gl, "trainer learned: Gelman Stonehand (npc 5513), unchanged, teaches Mining, Engineering"), 2, "services listed late: the line once for this window: " .. all(gl))
    -- No map position: says so, once per window.
    local pos = gl.pos
    gl.pos = nil
    gl.onEvent("TRAINER_SHOW")
    gl.onEvent("TRAINER_UPDATE")
    eq(times(gl, "trainer not learned: Gelman Stonehand (npc 5513): no map position here"), 1, "a trainer with no map position: " .. all(gl))
    gl.npc = { guid = "Creature-0-4372-0-55-1234-0000A1B2C3", name = "New Seller" }
    gl.onEvent("MERCHANT_SHOW")
    eq(times(gl, "vendor not learned: New Seller (npc 1234): no map position here"), 1, "a vendor with no map position")
    gl.pos = pos
    gl.trainer = nil

    -- Standing: a change is logged; targeting one already known to refuse says so again.
    local reaction = 3
    gl.env.UnitReaction = function() return reaction end
    gl.npc = { guid = "Creature-0-4372-0-55-1234-0000A1B2C3", name = "New Seller" }
    eq(fns.standing(1234), true, "standing: its window opened")
    gl.onEvent("PLAYER_TARGET_CHANGED")
    eq(times(gl, "standing: npc 1234 will not trade (Unfriendly or Hostile)"), 1, "changed to Unfriendly: logged")
    eq(fns.standing("1234"), false, "standing: will not trade")
    gl.onEvent("PLAYER_TARGET_CHANGED")
    eq(times(gl, "standing: npc 1234 will not trade (Unfriendly or Hostile), already known"), 1, "targeted again: already known")
    gl.onEvent("UPDATE_MOUSEOVER_UNIT")
    eq(times(gl, "standing: npc 1234 will not trade (Unfriendly or Hostile), already known"), 1, "a mouseover of a known one logs nothing")
    gl.env.ClosestVendorCharDB.log.entries = {} -- the log keeps 300 lines: count from here
    local t0 = (gl.time or 0) + 100
    gl.time = t0
    gl.onEvent("PLAYER_TARGET_CHANGED")
    gl.time = t0 + 29
    gl.onEvent("PLAYER_TARGET_CHANGED")
    eq(times(gl, "standing: npc 1234 will not trade (Unfriendly or Hostile), already known"), 1, "targeted again and again: once in 30 seconds: " .. all(gl))
    gl.time = t0 + 30
    gl.onEvent("PLAYER_TARGET_CHANGED")
    eq(times(gl, "standing: npc 1234 will not trade (Unfriendly or Hostile), already known"), 2, "and again after 30 seconds")
    reaction = 4
    gl.onEvent("PLAYER_TARGET_CHANGED")
    eq(times(gl, "standing: npc 1234 will trade"), 1, "back to Neutral: logged")
    eq(select("#", fns.standing(4242)), 0, "standing: never seen, nothing")

    -- nav: the method Core keeps; the entry itself never reaches the game.
    eq(fns.nav(), "chat", "nav: nothing installed, the chat line")
    reads = 0
    fns.nav(); fns.nav()
    eq(reads, 0, "nav: an entry call reads nothing from the game")
    opts.tomtom = true
    gl.env.TomTom = { AddWaypoint = function() return {} end, RemoveWaypoint = function() end }
    eq(fns.nav(), "chat", "nav: kept until something can change it")
    gl.onEvent("ADDON_LOADED", "TomTom")
    eq(fns.nav(), "tomtom", "nav: read again when another addon loads")
    gl.env.SlashCmdList.CLOSESTVENDOR("nav native")
    eq(fns.nav(), "tomtom", "nav: native is not available here, so the usual order")
    opts.tomtom = false
    gl.env.SlashCmdList.CLOSESTVENDOR("nav auto")
    eq(fns.nav(), "chat", "nav: read again after a slash command")

    -- external: what NorgannonDB gave, as the report says it; the same line is logged at login.
    eq(fns.external(), "not found", "external: not found")
    gl.env.SlashCmdList.CLOSESTVENDOR("debug on")
    gl.onEvent("PLAYER_LOGIN")
    eq(times(gl, "NorgannonDB: not found"), 1, "login: the NorgannonDB line")
    local gn = boot({ ng = fakeNG(), checkThat = { Entry = function(_, name, fn) fns[name] = fn; return true end } }); login(gn)
    eq(fns.external(), "found, schema 1.5, 1 vendors added, 0 skipped, 0 trainers with a tier", "external: found")
    -- A NorgannonDB vendor's window: whether its learned position replaces NorgannonDB's.
    gn.env.SlashCmdList.CLOSESTVENDOR("debug on")
    gn.autoAccept = false
    gn.npc = { guid = "Creature-0-4372-0-55-9001-0000A1B2C3", name = "Hyjal Seller" }
    gn.pos = { map = 2482, x = 0.53, y = 0.50 }
    gn.onEvent("MERCHANT_SHOW")
    eq(times(gn, "vendor learned: Hyjal Seller (npc 9001), new; the NorgannonDB position is kept"), 1, "a NorgannonDB vendor is in the search pool; within 0.03: kept: " .. all(gn))
    gn.pos = { map = 2482, x = 0.60, y = 0.50 }
    gn.onEvent("MERCHANT_SHOW")
    eq(times(gn, "vendor learned: Hyjal Seller (npc 9001), updated; replaces the NorgannonDB position"), 1, "moved: replaces")
    -- A NorgannonDB vendor whose window stored nothing: no error, still one line.
    local record = gn.ns.Discovery.Record
    gn.ns.Discovery.Record = function() return false end
    gn.env.ClosestVendorDB.learned[9001] = nil
    eq(pcall(gn.onEvent, "MERCHANT_SHOW"), true, "nothing learned for a NorgannonDB vendor: no error")
    eq(times(gn, "vendor learned: Hyjal Seller (npc 9001), new"), 1, "and its line, without the position note: " .. all(gn))
    gn.ns.Discovery.Record = record

    -- The row's arrow: the menu opening is logged, and it picks nothing by itself.
    do
        local gm = boot({ tomtom = true }); login(gm); gm.autoAccept = false
        gm.env.SlashCmdList.CLOSESTVENDOR("debug on")
        gm.env.MenuUtil = { CreateContextMenu = function(anchor, build)
            build(anchor, { CreateTitle = function() end, CreateRadio = function() end, CreateButton = function() end })
        end }
        gm.env.SlashCmdList.CLOSESTVENDOR("hud row bags always"); flush(gm)
        local row, more = window(gm).rows[1]
        for _, f in ipairs(gm.frames) do if f.parent == row and f.kind == "Button" then more = f end end
        more.scripts.OnClick()
        local shown, picked = 0, 0
        for _, e in ipairs(gm.env.ClosestVendorCharDB.log.entries) do
            if e.msg:find("^choice menu shown: bags, %d+ entries$") then shown = shown + 1 end
            if e.msg:find("^chosen pin: ") or e.msg:find("^accepted: ") then picked = picked + 1 end
        end
        eq(shown, 1, "the menu opening is logged once")
        eq(picked, 0, "and nothing is picked or pinned")
    end

    -- The settings page's Waypoint choice is read again at once (the nav entry).
    local fs = {}
    local gs = boot({ settings = true, tomtom = true, checkThat = { Entry = function(_, name, fn) fs[name] = fn; return true end } })
    gs.env.C_Map.CanSetUserWaypointOnMap = function() return true end
    gs.env.C_Map.SetUserWaypoint = function() end
    gs.env.C_SuperTrack = { SetSuperTrackedUserWaypoint = function() end }
    gs.env.UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { uiMapID = m, position = { x = x, y = y } } end }
    login(gs)
    eq(fs.nav(), "tomtom", "nav: TomTom first")
    setting(gs, "navProvider"):SetValue("native")
    eq(fs.nav(), "native", "nav: the settings page choice, at once")
end

-- Phase 4 evidence (#61): the status window, the purchase questions and settings changes in the debug log.
do
    local function lines(game, part)
        local n = 0
        for _, e in ipairs(game.env.ClosestVendorCharDB.log.entries or {}) do if e.msg:find(part, 1, true) then n = n + 1 end end
        return n
    end
    local function last(game) local t = game.env.ClosestVendorCharDB.log.entries; return t[#t] and t[#t].msg end
    local fs = {}
    local gw = boot({ checkThat = { Entry = function(_, name, fn) fs[name] = fn; return true end } })
    login(gw); gw.autoAccept = false
    gw.env.SlashCmdList.CLOSESTVENDOR("debug on")
    flush(gw)
    eq(fs.window(), "hidden", "window entry: hidden with nothing low")
    gw.free = 1; gw.onEvent("BAG_UPDATE_DELAYED"); flush(gw)
    eq(lines(gw, "status window: shown, rows: bags low"), 1, "the window showing is logged with its rows")
    eq(fs.window(), "shown: bags low", "window entry: shown, with the low row")
    gw.free = 0; gw.onEvent("BAG_UPDATE_DELAYED"); flush(gw)
    eq(lines(gw, "status window: shown, rows: bags low"), 1, "a count change alone writes nothing")
    gw.free = 20; gw.onEvent("BAG_UPDATE_DELAYED"); flush(gw)
    eq(last(gw), "status window: hidden", "the window hiding is logged")
    gw.env.SlashCmdList.CLOSESTVENDOR("hud row bags always")
    eq(lines(gw, "status window: shown, rows: bags"), 2, "a row set change is logged at once: " .. tostring(last(gw)))
    eq(fs.window(), "shown: bags", "window entry: shown, the row not low")
    eq(fs.window("bags"), "bags", "window entry: one group's rows")
    eq(fs.window("supplies"), "none", "window entry: a group with no row shows none")
    -- The frame does not show: a failure, and the entry knows nothing.
    gw.env.SlashCmdList.CLOSESTVENDOR("hud row bags low")
    local w = window(gw)
    local show = w.frame.Show
    w.frame.Show = function() end
    gw.env.SlashCmdList.CLOSESTVENDOR("hud row bags always")
    eq(last(gw), "status window: FAILED: not shown, rows: bags", "rows the frame does not show: FAILED")
    eq(select("#", fs.window()), 0, "window entry: nothing after a failed draw")
    eq(select("#", fs.window("bags")), 0, "window entry: no group rows after a failed draw")
    w.frame.Show = show
    gw.onEvent("BAG_UPDATE_DELAYED"); flush(gw)
    eq(fs.window("bags"), "bags", "window entry: group rows again after a good draw")
    -- A preview draws made-up rows: nothing is logged and the entry says demo.
    local before = #gw.env.ClosestVendorCharDB.log.entries
    gw.env.SlashCmdList.CLOSESTVENDOR("preview hud")
    eq(fs.window(), "demo", "window entry: demo while made-up rows show")
    eq(select("#", fs.window("bags")), 0, "window entry: no group rows while made-up rows show")
    gw.free = 1; gw.onEvent("BAG_UPDATE_DELAYED"); flush(gw)
    local wrote = false
    for i = before + 1, #gw.env.ClosestVendorCharDB.log.entries do
        if gw.env.ClosestVendorCharDB.log.entries[i].msg:find("status window: ", 1, true) then wrote = true end
    end
    eq(wrote, false, "no status window line while made-up rows show")

    -- Settings changes: one line per key, at once for a command.
    gw.env.SlashCmdList.CLOSESTVENDOR("bags 5")
    eq(lines(gw, "setting changed: bagThreshold 2 -> 5"), 1, "a command's change is logged")
    eq(lines(gw, "setting changed: hudRow.bags low -> always"), 2, "each row mode change is logged with its group (typed twice above)")
    gw.env.SlashCmdList.CLOSESTVENDOR("bags 5")
    eq(lines(gw, "setting changed: bagThreshold"), 1, "the same value again writes nothing")
    gw.env.SlashCmdList.CLOSESTVENDOR("reagent off arcane powder")
    eq(lines(gw, "setting changed: reagentOff.17020 none -> true"), 1, "a reagent switched off is logged by its id")
    gw.env.SlashCmdList.CLOSESTVENDOR("bags 2")

    -- Purchase questions: asked once the dialog shows, declined on No.
    local gr = reagentShop()
    gr.env.SlashCmdList.CLOSESTVENDOR("debug on")
    gr.autoAccept = false
    gr.env.SlashCmdList.CLOSESTVENDOR("reagentbuy on")
    gr.onEvent("MERCHANT_SHOW")
    eq(last(gr), "reagent buy: asked", "the reagent question is logged once it shows")
    gr.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM_REAGENTS.OnCancel(nil, gr.popup.data, "override")
    eq(lines(gr, "reagent buy: declined"), 0, "a question replaced by another (override) is no answer: no declined line")
    gr.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM_REAGENTS.OnCancel(nil, gr.popup.data, "clicked")
    eq(last(gr), "reagent buy: declined", "No is logged")
    eq(#gr.bought, 0, "and buys nothing")
    gr.onEvent("MERCHANT_CLOSED")
    gr.env.StaticPopup_Show = function() end
    gr.onEvent("MERCHANT_SHOW")
    eq(last(gr), "reagent buy: FAILED: the question did not show", "a question that does not show: FAILED")
    -- The ammo question the same way, through the ammo purchase's confirm.
    local ga = reagentShop()
    ga.env.SlashCmdList.CLOSESTVENDOR("debug on")
    ga.autoAccept = false
    ga.ns.Ammo.OnMerchant = function(_, env) env.confirm("Buy 200 Sharp Arrow for 1s 0c?", function() end) return 0 end
    ga.onEvent("MERCHANT_SHOW")
    eq(lines(ga, "ammo buy: asked"), 1, "the ammo question is logged once it shows")
    ga.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM_AMMO.OnCancel(nil, ga.popup.data, "clicked")
    eq(last(ga), "ammo buy: declined", "No on the ammo question is logged")

    -- The settings page: noted once, a second after the last change.
    local gs = boot({ settings = true })
    login(gs)
    gs.env.SlashCmdList.CLOSESTVENDOR("debug on")
    setting(gs, "bagThreshold"):SetValue(7)
    setting(gs, "bagThreshold"):SetValue(8)
    eq(lines(gs, "setting changed: bagThreshold"), 0, "a slider move is not logged at once")
    local t = gs.timers; gs.timers = {}
    t[1]()
    eq(lines(gs, "setting changed: bagThreshold"), 0, "the wait restarts with each change: the first timer writes nothing")
    for i = 2, #t do t[i]() end
    eq(lines(gs, "setting changed: bagThreshold 2 -> 8"), 1, "the settings page change is logged once, a second after the last change, from the start value")
    eq(lines(gs, "setting changed: bagThreshold"), 1, "and only once")
    -- A page change still waiting for its timer is written before the next command's own change.
    setting(gs, "bagThreshold"):SetValue(7)
    gs.env.SlashCmdList.CLOSESTVENDOR("bags 9")
    eq(lines(gs, "setting changed: bagThreshold 8 -> 7"), 1, "the pending page change is written first, with its own values")
    eq(lines(gs, "setting changed: bagThreshold 7 -> 9"), 1, "then the command's change")
    t = gs.timers; gs.timers = {}
    for i = 1, #t do t[i]() end
    eq(lines(gs, "setting changed: bagThreshold"), 3, "the page timer then writes nothing")
    -- The migration at load (notificationStyle for an existing user) is in the starting values: the
    -- next command does not report it.
    local gmg = boot({ charDb = { cfg = { bagThreshold = 2 } } })
    login(gmg)
    gmg.env.SlashCmdList.CLOSESTVENDOR("debug on")
    gmg.env.SlashCmdList.CLOSESTVENDOR("bags 5")
    eq(gmg.env.ClosestVendorCharDB.cfg.notificationStyle, "warning", "an existing user without the setting is migrated to warning")
    eq(lines(gmg, "setting changed: notificationStyle"), 0, "the migration is not logged as a command's change")
    eq(lines(gmg, "setting changed: bagThreshold 2 -> 5"), 1, "the command's own change is")

    -- Move draws a placeholder: changes meanwhile are logged once Move ends (Done).
    local fm = {}
    local gmv = boot({ checkThat = { Entry = function(_, name, fn) fm[name] = fn; return true end } })
    login(gmv); gmv.autoAccept = false
    gmv.env.SlashCmdList.CLOSESTVENDOR("debug on")
    flush(gmv)
    eq(fm.window(), "hidden", "move: hidden before")
    gmv.ns.Options.Move("hud")
    eq(fm.window(), "demo", "move: the placeholder is made-up rows")
    gmv.free = 1; gmv.onEvent("BAG_UPDATE_DELAYED"); flush(gmv)
    eq(lines(gmv, "status window: shown"), 0, "nothing logged while Move shows its placeholder")
    local done
    for _, f in ipairs(gmv.frames) do if f.kind == "Button" and f.text == "Done" and f.parent and f.parent.parent and f.parent.parent.name == "ClosestVendorTracker" then done = f end end
    done.scripts.OnClick()
    flush(gmv)
    eq(fm.window(), "shown: bags low", "after Done the entry has the real rows")
    eq(lines(gmv, "status window: shown, rows: bags low"), 1, "and the real rows are logged")

    -- A fault while noting the window's state loses the note only, never the window.
    local gn = boot(); login(gn); gn.autoAccept = false
    gn.env.SlashCmdList.CLOSESTVENDOR("debug on")
    flush(gn)
    local sig = gn.ns.Status.Signature
    gn.ns.Status.Signature = function() error("boom", 0) end
    gn.free = 1; gn.onEvent("BAG_UPDATE_DELAYED"); flush(gn)
    eq(lines(gn, "status window: FAILED: not logged: boom"), 1, "the fault is logged")
    eq(lines(gn, "switched off"), 0, "the window is not switched off")
    gn.ns.Status.Signature = sig
    gn.free = 0; gn.onEvent("BAG_UPDATE_DELAYED"); flush(gn)
    eq(lines(gn, "status window: shown, rows: bags low"), 1, "the next redraw logs the window again")

    -- A window the frame does not hide: a failure line, not "hidden".
    local gh = boot(); login(gh); gh.autoAccept = false
    gh.env.SlashCmdList.CLOSESTVENDOR("debug on")
    gh.env.SlashCmdList.CLOSESTVENDOR("hud row bags always")
    eq(lines(gh, "status window: shown, rows: bags"), 1, "shown with the bag row")
    local wh = window(gh)
    wh.frame.Hide = function() end
    gh.env.SlashCmdList.CLOSESTVENDOR("hud row bags low")
    eq(last(gh), "status window: FAILED: still shown with no rows", "no rows but the frame stays: FAILED")
    -- The frame cannot say whether it is on screen: unknown, never "hidden", and the entry answers nothing.
    local fu = {}
    local gu = boot({ checkThat = { Entry = function(_, name, fn) fu[name] = fn; return true end } })
    login(gu); gu.autoAccept = false
    gu.env.SlashCmdList.CLOSESTVENDOR("debug on")
    flush(gu)
    eq(fu.window(), "hidden", "unknown visibility: hidden before")
    window(gu).frame.IsShown = function() error("no read", 0) end
    gu.env.SlashCmdList.CLOSESTVENDOR("hud row bags always")
    eq(last(gu), "status window: visibility unknown, rows: bags", "an unread frame is logged as unknown")
    eq(select("#", fu.window()), 0, "window entry: nothing while the frame cannot be read")
    eq(select("#", fu.window("bags")), 0, "window entry: no group rows while the frame cannot be read")
    gu.env.SlashCmdList.CLOSESTVENDOR("hud row bags low")
    eq(last(gu), "status window: visibility unknown, rows: none", "no rows and an unread frame: unknown, not hidden")
    eq(lines(gu, "status window: hidden"), 1, "only the hidden line from before the fault")

    -- The ammo question that does not show: a failure line.
    local gf = reagentShop()
    gf.env.SlashCmdList.CLOSESTVENDOR("debug on")
    gf.autoAccept = false
    gf.ns.Ammo.OnMerchant = function(_, env) env.confirm("Buy 200 Sharp Arrow for 1s 0c?", function() end) return 0 end
    gf.env.StaticPopup_Show = function() end
    gf.onEvent("MERCHANT_SHOW")
    eq(lines(gf, "ammo buy: FAILED: the question did not show"), 1, "an ammo question that does not show: FAILED")

    -- Switching a warning off and on clears its handled latch, so the plan can ask again at once.
    local gm = mage()
    gm.env.SlashCmdList.CLOSESTVENDOR("debug on")
    gm.onEvent("BAG_UPDATE_DELAYED")
    eq(lines(gm, "question shown: reagent Arcane Powder"), 1, "low reagent: asked")
    gm.env.StaticPopupDialogs.CLOSESTVENDOR_CONFIRM.OnCancel(nil, gm.popup.data, "clicked")
    gm.onEvent("BAG_UPDATE_DELAYED")
    eq(lines(gm, "question shown: reagent Arcane Powder"), 1, "after No: not asked again while low")
    gm.env.SlashCmdList.CLOSESTVENDOR("reagents off")
    gm.env.SlashCmdList.CLOSESTVENDOR("reagents on")
    eq(lines(gm, "question shown: reagent Arcane Powder"), 2, "reagents off then on: asked again at once")
end

-- Test settings mode (spec saved-settings, diagnostics): the player's own settings, status window and toast
-- positions are put aside and the defaults are used; off brings them back exactly. The three tables are
-- refilled in place, a switch is not a setting change, and what was begun under one set ends.
do
    local real = { bagThreshold = 4, vendorMode = "auto", reagentOff = { [17020] = true }, hudRow = { bags = "always" }, hudColor = "ff0000" }
    local g = boot({ charDb = { cfg = real, hud = { point = "TOP", relPoint = "TOP", x = 5, y = 6 }, toast = { point = "CENTER", x = 9 } } })
    g.env.ColorPickerFrame = { SetupColorPickerAndShow = function(_, t) g.pick = t end, GetColorRGB = function() return 0, 1, 0 end }
    login(g)
    local S = g.env.SlashCmdList.CLOSESTVENDOR
    local char = g.env.ClosestVendorCharDB
    local cfgRef, hudRef, toastRef = char.cfg, char.hud, char.toast
    local function header()
        S("log")
        for _, f in ipairs(g.frames) do if f.name == "ClosestVendorReport" then return f.box.text end end
        return ""
    end
    S("debug on")
    eq(has(header(), "test settings: off"), true, "report: test settings off")
    S("testsettings off")
    eq(has(logText(g), "test settings: not on"), true, "off while off: refused and logged")
    eq(char.cfg.bagThreshold, 4, "off while off changes nothing")

    -- A colour pick and a route question begun under the player's own settings.
    S("hud color")
    eq(g.pick ~= nil, true, "the colour picker is open")
    g.autoAccept = false
    S("testsettings on")
    eq(has(logText(g), "test settings: on (own settings put aside)"), true, "on is logged")
    eq(rawequal(char.cfg, cfgRef) and rawequal(char.hud, hudRef) and rawequal(char.toast, toastRef), true, "the three tables are the same ones, refilled in place")
    eq(char.cfg.bagThreshold, 2, "test settings: default bag threshold")
    eq(char.cfg.vendorMode, "ask", "test settings: default vendor mode")
    eq(char.cfg.hudColor, "000000", "test settings: default colour")
    eq(next(char.hud), nil, "test settings: status window at its default place")
    eq(next(char.toast), nil, "test settings: toast at its default place")
    eq(char.cfg.notificationStyle, "toast", "test settings: the style a new character gets")
    eq(char.realSettings.cfg.bagThreshold, 4, "the player's own settings are put aside")
    eq(has(header(), "test settings: on"), true, "report: test settings on")
    g.pick.swatchFunc()
    eq(char.cfg.hudColor, "000000", "a colour pick begun before the switch changes nothing")
    S("dur 100")
    local log = logText(g)
    eq(has(log, "setting changed: durThreshold 20 -> 100"), true, "a change under test settings is logged")
    eq(has(log, "setting changed: bagThreshold"), false, "the switch itself is not a setting change")

    -- on while on: a clean test set, the stash untouched.
    S("bags 99")
    S("testsettings on")
    eq(has(logText(g), "test settings: reset to defaults"), true, "on while on: logged as a reset")
    eq(char.cfg.bagThreshold, 2, "on while on: defaults again")
    eq(char.realSettings.cfg.bagThreshold, 4, "on while on: the stash is kept")

    -- A route question open at the switch is withdrawn and nothing is bought.
    g.free = 1; g.onEvent("BAG_UPDATE_DELAYED")
    eq(g.popup ~= nil, true, "a question is open under the test set")
    local before = logText(g)
    char.realSettings.cfg.durThreshold = nil -- a default added since the stash
    S("testsettings off")
    eq(char.cfg.durThreshold, 20, "a default added since the stash is filled at the restore")
    eq(g.popup, nil, "the open question closes at the switch")
    eq(has(logText(g), "question withdrawn: test settings switched"), true, "the withdrawal is logged")
    eq(has(logText(g), "test settings: off (own settings restored)"), true, "off is logged")
    eq(rawequal(char.cfg, cfgRef) and rawequal(char.hud, hudRef) and rawequal(char.toast, toastRef), true, "off refills the same tables")
    eq(char.cfg.bagThreshold, 4, "own bag threshold is back")
    eq(char.cfg.vendorMode, "auto", "own vendor mode is back")
    eq(char.cfg.reagentOff[17020], true, "own nested values are back")
    eq(char.cfg.hudRow.bags, "always", "own row mode is back")
    eq(char.cfg.hudColor, "ff0000", "own colour is back")
    eq(char.hud.x, 5, "own status window position is back")
    eq(char.toast.x, 9, "own toast position is back")
    eq(char.realSettings, nil, "nothing is put aside any more")
    eq(has(header(), "test settings: off"), true, "report: test settings off again")
    eq(has(logText(g):sub(#before + 1), "setting changed"), false, "the restore is not a setting change either")
end

-- The mode lasts across a reload: login says so in the log and in chat.
do
    local g = boot({ charDb = { cfg = { bagThreshold = 4 } } })
    login(g)
    local S = g.env.SlashCmdList.CLOSESTVENDOR
    S("debug on"); S("testsettings on")
    local g2 = boot({ charDb = g.env.ClosestVendorCharDB }); login(g2)
    local e = g2.env.ClosestVendorCharDB.log.entries
    local n = #e
    eq(e[n - 1] and e[n - 1].msg ~= nil, true, "the log is kept")
    local text = logText(g2)
    eq(text:find("---- login ----\ntest settings: on at login", 1, true) ~= nil, true, "login marker, then the test settings line: " .. text)
    local said = false
    for _, p in ipairs(g2.printed) do if p:find("/cvn testsettings off", 1, true) then said = true end end
    eq(said, true, "chat at login names /cvn testsettings off")
    eq(g2.env.ClosestVendorCharDB.cfg.bagThreshold, 2, "the test set is still in use after the reload")
    g2.env.SlashCmdList.CLOSESTVENDOR("testsettings off")
    eq(g2.env.ClosestVendorCharDB.cfg.bagThreshold, 4, "off after a reload restores the own settings")
end

-- Test settings follow the CheckThat run (spec checkthat-integration): a run start turns them on once, a run end
-- turns them off, a login with no run open restores what a run left on, and a CheckThat without the
-- callback changes nothing.
do
    local function runGame(charDb, open, noHook)
        local f = { open = open }
        function f.Entry() return true end
        if not noHook then
            function f.OnRun(_, fn) f.run = fn; return true end
            function f.ActiveRun() return f.open end
        end
        local gg = boot({ charDb = charDb, checkThat = f }); login(gg)
        gg.env.SlashCmdList.CLOSESTVENDOR("debug on")
        return gg, f
    end
    local function bags(gg) return gg.env.ClosestVendorCharDB.cfg.bagThreshold end

    -- Start turns them on, end brings the own settings back.
    local g, f = runGame({ cfg = { bagThreshold = 4 } }, "plan")
    f.run("start", { runId = "r1" })
    eq(bags(g), 2, "run start: the test set is in use")
    eq(g.env.ClosestVendorCharDB.realSettings.cfg.bagThreshold, 4, "run start: the own settings are put aside")
    eq(has(logText(g), "test settings: run started"), true, "run start: logged")
    f.run("end", { runId = "r1", reason = "replaced" })
    eq(bags(g), 4, "run end: the own settings are back")
    eq(has(logText(g), "test settings: run ended: replaced"), true, "run end: logged with the reason")
    eq(g.env.ClosestVendorCharDB.realSettings, nil, "run end: nothing put aside")
    eq(g.env.ClosestVendorCharDB.testRun, nil, "run end: no run kept")

    -- The plan's last step turned them off; a start for the same run after a reload keeps them off.
    g, f = runGame({ cfg = { bagThreshold = 4 } }, "plan")
    f.run("start", { runId = "r1" })
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings off")
    f.run("start", { runId = "r1" })
    eq(bags(g), 4, "run seen: still off after a repeated start")
    eq(has(logText(g), "test settings: run already seen"), true, "run seen: logged")
    f.run("start", { runId = "r2" })
    eq(bags(g), 2, "a new run turns them on again")

    -- Start while already on keeps the test set as it is.
    g, f = runGame({ cfg = { bagThreshold = 4 } }, "plan")
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    g.env.SlashCmdList.CLOSESTVENDOR("bags 9")
    f.run("start", { runId = "r1" })
    eq(bags(g), 9, "start while on: no reset")
    eq(has(logText(g), "test settings: already on (run started)"), true, "start while on: logged")
    f.run("end", { reason = "ended" })
    eq(bags(g), 4, "the run owns the mode once it started")

    -- End while off changes nothing.
    g, f = runGame({ cfg = { bagThreshold = 4 } }, "plan")
    f.run("end", { reason = "deleted" })
    eq(bags(g), 4, "end while off: settings unchanged")
    eq(has(logText(g), "test settings: run ended: deleted"), true, "end while off: logged")

    -- Login: a run left test settings on and no run is open any more.
    g, f = runGame({ cfg = { bagThreshold = 4 } }, "plan")
    f.run("start", { runId = "r1" })
    local saved = g.env.ClosestVendorCharDB
    local g2 = boot({ charDb = saved, checkThat = { Entry = function() return true end, OnRun = function() return true end, ActiveRun = function() return nil end } })
    login(g2)
    eq(bags(g2), 4, "login without a run: the own settings are back")
    eq(has(logText(g2), "test settings: no run open at login"), true, "login without a run: logged")
    eq(saved.testRun, nil, "login without a run: no run kept")

    -- Login with the run still open: they stay on, and the catch-up start for the same run changes nothing.
    g, f = runGame({ cfg = { bagThreshold = 4 } }, "plan")
    f.run("start", { runId = "r1" })
    local reg
    g2 = boot({ charDb = g.env.ClosestVendorCharDB, checkThat = { Entry = function() return true end, ActiveRun = function() return "plan" end,
        OnRun = function(_, fn) reg = fn; return true end } })
    login(g2)
    reg("start", { runId = "r1" })
    eq(bags(g2), 2, "login with the run open: still the test set")
    eq(g2.env.ClosestVendorCharDB.realSettings.cfg.bagThreshold, 4, "login with the run open: the own settings stay put aside")

    -- Test settings typed by hand are not turned off at login.
    g, f = runGame({ cfg = { bagThreshold = 4 } }, "plan")
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    g2 = boot({ charDb = g.env.ClosestVendorCharDB, checkThat = { Entry = function() return true end, OnRun = function() return true end, ActiveRun = function() return nil end } })
    login(g2)
    eq(bags(g2), 2, "typed on, no run: still on at login")

    -- Like CheckThat: an open run sends its start inside OnRun, during login.
    local function liveCT(open, runId)
        return { Entry = function() return true end, ActiveRun = function() return open end,
                 OnRun = function(_, fn) if open then fn("start", { runId = runId, plan = open }) end return true end }
    end
    g2 = boot({ charDb = { cfg = { bagThreshold = 4 } }, checkThat = liveCT("plan", 1700000000) }); login(g2)
    eq(bags(g2), 2, "catch-up start at login turns test settings on")
    eq(g2.env.ClosestVendorCharDB.testRun, "1700000000", "a number run id is kept as text")
    local g3 = boot({ charDb = g2.env.ClosestVendorCharDB, checkThat = liveCT("plan", 1700000000) }); login(g3)
    eq(bags(g3), 2, "the same number id after a reload: still on, no reset")

    -- Run r1 ended while the addon was not loaded and r2 is open at login: r2 starts from fresh defaults.
    g, f = runGame({ cfg = { bagThreshold = 4 } }, "plan")
    f.run("start", { runId = "r1" })
    g.env.SlashCmdList.CLOSESTVENDOR("bags 9")
    g2 = boot({ charDb = g.env.ClosestVendorCharDB, checkThat = liveCT("plan", "r2") }); login(g2)
    eq(bags(g2), 2, "another run: the test set is reset to the defaults")
    eq(g2.env.ClosestVendorCharDB.realSettings.cfg.bagThreshold, 4, "another run: the own settings stay put aside")
    eq(has(logText(g2), "test settings: another run started"), true, "another run: logged")
    g2.env.SlashCmdList.CLOSESTVENDOR("testsettings off")
    eq(bags(g2), 4, "another run: off still brings the own settings back")

    -- A start without a run id is ignored.
    g, f = runGame({ cfg = { bagThreshold = 4 } }, "plan")
    f.run("start", {})
    eq(bags(g), 4, "no run id: nothing turned on")
    eq(g.env.ClosestVendorCharDB.testRun, nil, "no run id: nothing kept")
    eq(has(logText(g), "test settings: run start without an id"), true, "no run id: logged")

    -- A CheckThat without the callback: only the commands change test settings.
    g, f = runGame({ cfg = { bagThreshold = 4 } }, nil, true)
    eq(f.run, nil, "no callback: nothing registered")
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    eq(bags(g), 2, "no callback: the command still works")
end

-- Test settings: what holds the old settings ends at the switch (review findings): a pending purchase retry,
-- purchase questions and their stale answers, an ordinary drag, Move, colour picks from the page, a demo, a
-- preview and the confirmations of /cvn log clear.
do
    local function named3(g, n) for _, f in ipairs(g.frames) do if f.name == n then return f end end end
    local function count(g, text) local n = 0 for _, e in ipairs(g.env.ClosestVendorCharDB.log.entries) do if e.msg == text then n = n + 1 end end return n end
    local function arrowShop()
        local gg = boot({ tomtom = true }); login(gg)
        local e = gg.env
        gg.npc = { guid = "Creature-0-4372-0-55-5557-0000A1B2C3", name = "Arrow Shop" }
        gg.pos = { map = 100, x = 0.6, y = 0.5 }
        gg.equipped = { [18] = 100 }; gg.counts = {}
        gg.stock, gg.bought = { 200 }, {}
        e.ClosestVendorCharDB.cfg.arrowGrade = "best"
        e.UnitLevel = function() return 30 end
        e.GetMoney = function() return 100000 end
        e.GetMerchantItemInfo = function() return "Rough Arrow", "tex", 100, 200, -1, true, false end
        e.BuyMerchantItem = function(i) gg.bought[#gg.bought + 1] = i end
        e.C_Container = { GetContainerNumFreeSlots = function(b) if b == 1 then return 1, 1 end return 0, 0 end }
        e.GetContainerNumSlots = function(b) return b == 1 and 1 or 0 end
        e.GetContainerItemInfo = function() return nil end
        gg.loaded = function() e.GetItemInfo = function() return "Rough Arrow", "l", 1, 1, 5, "", "", 200 end end
        e.GetItemInfo = function() return nil end
        gg.env.SlashCmdList.CLOSESTVENDOR("debug on")
        return gg
    end

    -- A merchant purchase waiting for item data does not run under the other set.
    local g = arrowShop()
    g.onEvent("MERCHANT_SHOW")
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    g.loaded()
    g.onEvent("GET_ITEM_INFO_RECEIVED", 200)
    eq(count(g, "item data arrived: trying the merchant purchase again"), 0, "a pending purchase retry is dropped at the switch")
    eq(#g.bought, 0, "and nothing is bought")

    -- The ammo question closes at the switch, and answering it later buys nothing.
    g = arrowShop(); g.loaded(); g.autoAccept = false
    g.env.ClosestVendorCharDB.cfg.ammoBuyPrompt = true
    g.onEvent("MERCHANT_SHOW")
    eq(g.popup and g.popup.which, "CLOSESTVENDOR_CONFIRM_AMMO", "an ammo question is open")
    local stale = g.popup.accept
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    eq(g.popup == nil or g.popup.which ~= "CLOSESTVENDOR_CONFIRM_AMMO", true, "the ammo question closes at the switch")
    stale()
    eq(#g.bought, 0, "answering the ammo question later buys nothing")

    -- Same for the reagent question.
    g = reagentShop(); g.env.SlashCmdList.CLOSESTVENDOR("reagentbuy on")
    g.onEvent("MERCHANT_SHOW")
    eq(g.popup and g.popup.which, "CLOSESTVENDOR_CONFIRM_REAGENTS", "a reagent question is open")
    stale = g.popup.accept
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    eq(g.popup == nil or g.popup.which ~= "CLOSESTVENDOR_CONFIRM_REAGENTS", true, "the reagent question closes at the switch")
    stale()
    eq(#g.bought, 0, "answering the reagent question later buys nothing")

    -- An ordinary Shift-drag in progress does not write into the other set.
    g = boot(); login(g)
    g.env.SlashCmdList.CLOSESTVENDOR("hud row bags always")
    local w = window(g)
    w.frame.StartMoving = function() end
    w.frame.GetPoint = function() return "TOPLEFT", nil, "TOPLEFT", 40, -50 end
    g.env.IsShiftKeyDown = function() return true end
    w.rows[1].scripts.OnDragStart()
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    w.rows[1].scripts.OnDragStop()
    eq(next(g.env.ClosestVendorCharDB.hud), nil, "a drag begun before the switch saves no position into the test set")
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings off")
    eq(next(g.env.ClosestVendorCharDB.hud), nil, "and none into the restored one")

    -- Move ends at the switch; its Done does nothing after.
    g = boot(); login(g)
    g.ns.Options.Move("hud")
    local done
    for _, f in ipairs(g.frames) do if f.kind == "Button" and f.text == "Done" and f.parent and f.parent.parent and f.parent.parent.name == "ClosestVendorTracker" then done = f end end
    eq(g.ns.Options.Move ~= nil and done ~= nil, true, "Move is on")
    g.env.SlashCmdList.CLOSESTVENDOR("debug on")
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    eq(g.ns.Options.Move ~= nil and window(g).frame.shown, false, "Move's placeholder is gone")
    done.scripts.OnClick()
    eq(next(g.env.ClosestVendorCharDB.hud), nil, "Done after the switch saves no position")

    -- A colour picked on the settings page after the switch changes nothing.
    local gc = boot({ settings = true })
    gc.env.ColorPickerFrame = { SetupColorPickerAndShow = function(_, t) gc.pick = t end, GetColorRGB = function() return 0, 1, 0 end }
    login(gc)
    local function find(node, name)
        if type(node) ~= "table" then return end
        if node.name == name and node.func then return node end
        for _, v in pairs(node) do local r = type(v) == "table" and find(v, name); if r then return r end end
    end
    local button = find(gc.settings.tree, "Background color")
    eq(button ~= nil, true, "the page has the Background color button")
    button.func()
    eq(gc.pick ~= nil, true, "the page opened the picker")
    gc.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    gc.pick.swatchFunc()
    eq(gc.env.ClosestVendorCharDB.cfg.hudColor, "000000", "a page colour pick begun before the switch changes nothing")

    -- A demo and a preview end at the switch.
    g = boot({ tomtom = true }); login(g); flush(g)
    g.env.SlashCmdList.CLOSESTVENDOR("set appearance.notification-style toast")
    g.env.SlashCmdList.CLOSESTVENDOR("preview notice")
    eq(named3(g, "ClosestVendorSampleToast").shown, true, "a preview is showing")
    g.autoAccept = false; g.timers = {}
    g.env.SlashCmdList.CLOSESTVENDOR("demo")
    local pins = #g.tomtom
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    eq(named3(g, "ClosestVendorSampleToast").shown, false, "the preview ends at the switch")
    for _ = 1, 10 do if #g.timers == 0 then break end table.remove(g.timers, 1)() end
    eq(#g.tomtom, pins, "the demo sets no more waypoints after the switch")

    -- The clear-log confirmation closes at the switch.
    g = boot(); login(g); g.autoAccept = false
    g.env.SlashCmdList.CLOSESTVENDOR("log clear")
    eq(g.popup and g.popup.which, "CLOSESTVENDOR_CLEAR_LOG", "the clear confirmation is open")
    g.env.SlashCmdList.CLOSESTVENDOR("testsettings on")
    eq(g.popup, nil, "the clear confirmation closes at the switch")
end

H.done()
