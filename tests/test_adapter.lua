-- The adapter must turn every missing or throwing game function into "no data", never an error.
package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

-- Load Triggers + Adapter with a fake game. `game` holds the fake globals.
local function boot(game)
    local errors = {}
    local env = setmetatable(game or {}, { __index = _G })
    local ns = {}
    for _, f in ipairs({ "Triggers", "Ammo", "Adapter" }) do
        local chunk = assert(loadfile("ClosestVendor/" .. f .. ".lua"))
        setfenv(chunk, env)
        chunk("ClosestVendor", ns)
    end
    ns.Adapter.onError = function(name, err) errors[#errors + 1] = name .. ": " .. err end
    return ns.Adapter, errors
end

local function boom() error("kaboom", 0) end

-- isAddOnLoaded: new API, old API, missing, throwing.
local A, errs = boot({ C_AddOns = { IsAddOnLoaded = function(n) return n == "TomTom" end } })
eq(A.isAddOnLoaded("TomTom"), true, "C_AddOns.IsAddOnLoaded")
eq(A.isAddOnLoaded("Other"), false, "not loaded")
A = boot({ IsAddOnLoaded = function(n) return n == "TomTom" end })
eq(A.isAddOnLoaded("TomTom"), true, "falls back to the global IsAddOnLoaded")
A, errs = boot({})
eq(A.isAddOnLoaded("TomTom"), false, "missing: false")
eq(#errs, 1, "missing reported")
A, errs = boot({ C_AddOns = { IsAddOnLoaded = boom } })
eq(A.isAddOnLoaded("TomTom"), false, "throwing: false")
eq(errs[1], "IsAddOnLoaded: kaboom", "failure text kept")

-- Reported once per kind, not per call.
A, errs = boot({ C_AddOns = { IsAddOnLoaded = boom } })
for _ = 1, 5 do A.isAddOnLoaded("x") end
eq(#errs, 1, "five failures, one report")
A, errs = boot({ C_AddOns = { IsAddOnLoaded = boom }, InCombatLockdown = boom })
A.isAddOnLoaded("x"); A.inCombat()
eq(#errs, 2, "each kind reported once")

-- inCombat.
eq(boot({ InCombatLockdown = function() return true end }).inCombat(), true, "in combat")
eq(boot({ InCombatLockdown = function() return false end }).inCombat(), false, "not in combat")
eq(boot({ InCombatLockdown = function() return 1 end }).inCombat(), true, "numeric true")
eq(boot({ InCombatLockdown = boom }).inCombat(), false, "throwing: not in combat")
eq(boot({}).inCombat(), false, "missing: not in combat")

-- freeSlots: sums bags 0..NUM_BAG_SLOTS, falls back to the old global, unknown when unreadable.
local bags = { [0] = 3, [1] = 4, [2] = 0, [3] = 5, [4] = 1 }
eq(boot({ C_Container = { GetContainerNumFreeSlots = function(b) return bags[b], 0 end } }).freeSlots(), 13, "all five bags, default NUM_BAG_SLOTS")
eq(boot({ NUM_BAG_SLOTS = 2, C_Container = { GetContainerNumFreeSlots = function(b) return bags[b], 0 end } }).freeSlots(), 7, "respects NUM_BAG_SLOTS")
eq(boot({ GetContainerNumFreeSlots = function(b) return bags[b], 0 end }).freeSlots(), 13, "old global fallback")
A, errs = boot({})
eq(A.freeSlots(), nil, "no bag API: unknown, not zero")
eq(#errs, 1, "missing bag API reported once")
eq(boot({ C_Container = { GetContainerNumFreeSlots = boom } }).freeSlots(), nil, "bag API throws: unknown")
eq(boot({ C_Container = { GetContainerNumFreeSlots = function(b) if b == 1 then error("x") end return 2, 0 end } }).freeSlots(), 8, "one unreadable bag: the others count")

-- lowestDurability.
local dur = { [1] = { 90, 100 }, [5] = { 30, 100 }, [8] = { 80, 100 } }
eq(boot({ GetInventoryItemDurability = function(s) if dur[s] then return dur[s][1], dur[s][2] end end }).lowestDurability(), 30, "lowest over readable slots")
eq(boot({ GetInventoryItemDurability = function(s) if s == 5 then error("x") end if dur[s] then return dur[s][1], dur[s][2] end end }).lowestDurability(), 80, "an unreadable slot is ignored")
eq(boot({ GetInventoryItemDurability = boom }).lowestDurability(), nil, "all slots throw: unknown")
eq(boot({}).lowestDurability(), nil, "missing: unknown")

-- itemClass.
local info = function(id) return id, "t", "s", "", 0, 2, 3 end
local a1, a2 = boot({ GetItemInfoInstant = info }).itemClass(100)
eq(a1 .. "/" .. a2, "2/3", "class and subclass from the 7 returns")
a1, a2 = boot({ C_Item = { GetItemInfoInstant = info } }).itemClass(100)
eq(a1, 2, "C_Item.GetItemInfoInstant preferred")
a1, a2 = boot({}).itemClass(100)
eq(a1, nil, "missing: nil")
a1 = boot({ GetItemInfoInstant = boom }).itemClass(100)
eq(a1, nil, "throwing: nil")

-- ammoStatus.
local function ammoGame(over)
    local g = {
        GetInventoryItemID = function(_, slot) return ({ [18] = 100, [0] = 200 })[slot] end,
        GetItemInfoInstant = function(id) local c = ({ [100] = { 2, 2 }, [200] = { 6, 2 } })[id]; return id, "", "", "", 0, c[1], c[2] end,
        GetItemCount = function() return 150 end,
    }
    for k, v in pairs(over or {}) do g[k] = v end
    return g
end
local kind, count = boot(ammoGame()).ammoStatus()
eq(kind .. ":" .. count, "arrow:150", "bow with arrows")
kind, count = boot(ammoGame({ GetInventoryItemID = function(_, slot) return ({ [18] = 100 })[slot] end })).ammoStatus()
eq(kind .. ":" .. count, "arrow:0", "bow and nothing in the ammo slot: 0")
eq(boot(ammoGame({ GetInventoryItemID = function() return nil end })).ammoStatus(), nil, "no ranged weapon")
eq(boot(ammoGame({ GetItemInfoInstant = false })).ammoStatus(), nil, "item info missing: not monitored")
eq(boot(ammoGame({ GetItemCount = boom })).ammoStatus(), nil, "count unreadable: unknown, not 0")
eq(boot(ammoGame({ GetItemCount = false })).ammoStatus(), nil, "count missing: unknown, not 0")
eq(boot(ammoGame({ GetInventoryItemID = boom })).ammoStatus(), nil, "slot lookup throws: nothing")
eq(boot(ammoGame({ GetItemInfoInstant = function(id) if id == 200 then error("x") end return id, "", "", "", 0, 2, 2 end })).ammoStatus(), nil, "ammo item unreadable: unknown")

-- mapPosition / toWorld / playerWorldPos.
local function mapGame(over)
    local g = {
        CreateVector2D = function(x, y) return { x = x, y = y } end,
        C_Map = {
            GetBestMapForUnit = function() return 1429 end,
            GetPlayerMapPosition = function() return { x = 0.4, y = 0.6 } end,
            GetWorldPosFromMapPos = function(_, v) return 0, { x = v.x * 100, y = v.y * 100 } end,
            GetMapInfo = function() return { name = "Elwynn Forest" } end,
        },
    }
    for k, v in pairs(over or {}) do g[k] = v end
    return g
end
local m, x, y = boot(mapGame()).mapPosition()
eq(m .. "/" .. x .. "/" .. y, "1429/0.4/0.6", "map position")
local c, wx, wy = boot(mapGame()).toWorld(1429, 0.4, 0.6)
eq(c .. "/" .. wx .. "/" .. wy, "0/40/60", "world position")
local pm
c, wx, _, pm = boot(mapGame()).playerWorldPos()
eq(c .. "/" .. wx .. "/" .. pm, "0/40/1429", "player world position and map id")
local function withMap(field, fn) local g = mapGame(); g.C_Map[field] = fn; return boot(g) end
eq(withMap("GetBestMapForUnit", function() end).mapPosition(), nil, "no map for the unit")
eq(withMap("GetPlayerMapPosition", function() end).mapPosition(), nil, "no position (instance)")
eq(withMap("GetPlayerMapPosition", function() return { x = 0, y = 0 } end).mapPosition(), nil, "(0,0) is no position")
eq(withMap("GetPlayerMapPosition", boom).mapPosition(), nil, "position throws")
eq(withMap("GetBestMapForUnit", boom).playerWorldPos(), nil, "unit map throws: no world position")
eq(boot(mapGame({ C_Map = false })).mapPosition(), nil, "C_Map missing")
local aV, eV = boot(mapGame({ CreateVector2D = false }))
eq(aV.toWorld(1, 0.5, 0.5), nil, "CreateVector2D missing")
eq(#eV, 1, "one clear report, not a second one from the conversion call")
eq(boot(mapGame({ CreateVector2D = boom })).toWorld(1, 0.5, 0.5), nil, "CreateVector2D throws")
eq(withMap("GetWorldPosFromMapPos", boom).toWorld(1, 0.5, 0.5), nil, "world conversion throws")
eq(withMap("GetWorldPosFromMapPos", function() return nil end).toWorld(1, 0.5, 0.5), nil, "world conversion returns nothing")
eq(boot(mapGame()).mapName(1429), "Elwynn Forest", "map name")
eq(withMap("GetMapInfo", boom).mapName(1), nil, "map name throws")
eq(boot({}).mapName(1), nil, "map name: no C_Map")

-- factionId.
eq(boot({ UnitFactionGroup = function() return "Alliance" end }).factionId("player"), 1, "Alliance")
eq(boot({ UnitFactionGroup = function() return "Horde" end }).factionId("player"), 2, "Horde")
eq(boot({ UnitFactionGroup = function() return nil end }).factionId("npc"), 0, "neutral")
eq(boot({ UnitFactionGroup = boom }).factionId("npc"), 0, "throws: neutral")
eq(boot({}).factionId("player"), 0, "missing: neutral")

-- merchant.
local function merchantGame(over)
    local g = {
        UnitGUID = function() return "Creature-0-4372-0-55-1234-0000A1B2C3" end,
        UnitName = function() return "Fresh Vendor" end,
        UnitFactionGroup = function() return "Horde" end,
        CanMerchantRepair = function() return true end,
        GetMerchantNumItems = function() return 3 end,
        GetMerchantItemLink = function(i) return "|cff|Hitem:" .. ({ 300, 200, 201 })[i] .. ":0|h[x]|h|r" end,
        GetItemInfoInstant = function(id) local c = ({ [300] = { 0, 0 }, [200] = { 6, 2 }, [201] = { 6, 3 }, [400] = { 4, 2 }, [401] = { 4, 3 } })[id]; return id, "", "", "", 0, c[1], c[2] end,
    }
    for k, v in pairs(over or {}) do g[k] = v end
    return g
end
local mer = boot(merchantGame()).merchant()
eq(mer.id, 1234, "npc id from the GUID")
eq(mer.name, "Fresh Vendor", "name")
eq(mer.faction, 2, "faction")
eq(mer.repair, true, "repair")
eq(mer.ammo, 3, "sells arrows and bullets")
eq(boot(merchantGame({ GetMerchantNumItems = function() return 2 end,
    GetMerchantItemLink = function(i) return "item:" .. ({ 400, 401 })[i] .. ":0" end })).merchant().ammo, 0, "other item classes with an ammo subclass number are not ammo")
eq(boot(merchantGame({ UnitGUID = function() return nil end })).merchant(), nil, "no GUID")
eq(boot(merchantGame({ UnitGUID = function() return "Player-0-0-0-0-0-0" end })).merchant(), nil, "not a creature")
eq(boot(merchantGame({ UnitGUID = function() return 42 end })).merchant(), nil, "GUID of the wrong type")
eq(boot(merchantGame({ UnitName = function() return nil end })).merchant(), nil, "no name")
eq(boot(merchantGame({ UnitGUID = boom })).merchant(), nil, "GUID throws")
eq(boot(merchantGame({ GetMerchantNumItems = boom })).merchant().ammo, 0, "stock unreadable: sells no ammo")
eq(boot(merchantGame({ CanMerchantRepair = boom })).merchant().repair, false, "repair check throws: false")
eq(boot(merchantGame({ GetMerchantItemLink = function(i) if i == 2 then error("x") end return "item:300:0" end })).merchant().ammo, 0, "one unreadable item skipped")
eq(boot({}).merchant(), nil, "nothing available")

-- now.
eq(boot({ GetTime = function() return 123.5 end }).now(), 123.5, "game time")
eq(boot({}).now(), 0, "no clock: 0")
eq(boot({ GetTime = boom }).now(), 0, "clock throws: 0")

-- after / popups.
local scheduled
eq(boot({ C_Timer = { After = function(s, fn) scheduled = { s, fn } end } }).after(5, print), true, "timer scheduled")
eq(scheduled[1], 5, "delay passed")
eq(boot({}).after(5, print), false, "no timer API")
eq(boot({ C_Timer = { After = boom } }).after(5, print), true, "timer throws: no error")
local log = {}
A = boot({ StaticPopup_Hide = function(w) log[#log + 1] = "hide " .. w end, StaticPopup_Show = function(w, t, _, d) log[#log + 1] = "show " .. w .. " " .. t .. " " .. d end })
A.showPopup("W", "text", "data")
eq(table.concat(log, "|"), "hide W|show W text data", "hides the old question, shows the new")
A.hidePopup("W")
eq(log[#log], "hide W", "hide")
A = boot({})
A.showPopup("W", "text", "data"); A.hidePopup("W")
A = boot({ StaticPopup_Show = boom, StaticPopup_Hide = boom })
A.showPopup("W", "text", "data"); A.hidePopup("W")

-- navApi / clientInfo.
local api = boot({ TomTom = "tt", WaypointUIAPI = "wui", C_Map = "cm", C_SuperTrack = "cs", UiMapPoint = "up" }).navApi(print)
eq(api.TomTom .. api.WaypointUIAPI .. api.C_Map .. api.C_SuperTrack .. api.UiMapPoint, "ttwuicmcsup", "other addons' globals passed through")
eq(api.print, print, "print passed through")
eq(type(api.isAddOnLoaded), "function", "isAddOnLoaded")
eq(boot({}).navApi(print).TomTom, nil, "absent addons are nil")
local ci = boot({ GetBuildInfo = function() return "1.60.1", "70790", "Nov 4 2026", 16001 end, GetLocale = function() return "enUS" end,
                  GetAddOnMetadata = function(_, k) return k == "Version" and "0.1.0" or nil end }).clientInfo()
eq(ci.addon .. "|" .. ci.gameVersion .. "|" .. ci.build .. "|" .. ci.interface .. "|" .. ci.locale, "0.1.0|1.60.1|70790|16001|enUS", "client info")
ci = boot({}).clientInfo()
eq(ci.addon, nil, "missing client info: nils, no error")

-- skills: Forever gives tables, Era gives values; headers and sub-lines are left out.
local function names(list) local t = {} for k, v in ipairs(list or {}) do t[k] = v.name .. ":" .. v.rank .. "/" .. v.max end return list and table.concat(t, ",") or "nil" end
local forever = {
    { name = "Professions", isHeader = true, rank = 0, maxRank = 0, parentSkillLineID = 0 },
    { name = "Mining", isHeader = false, rank = 290, maxRank = 300, parentSkillLineID = 0 },
    { name = "Mining Sub", isHeader = false, rank = 5, maxRank = 10, parentSkillLineID = 164 },
    { name = "Swords", isHeader = false, rank = 40, maxRank = 75, parentSkillLineID = 0 },
}
eq(names(boot({ C_SkillInfo = { GetNumSkillLines = function() return #forever end, GetSkillLineInfo = function(i) return forever[i] end } }).skills()),
    "Mining:290/300,Swords:40/75", "Forever: tables, no headers, no sub-lines")
local era = { { "Professions", true }, { "Mining", false, true, 225, 0, 0, 300 }, { "Swords", false, true, 40, 0, 0, 75 } }
eq(names(boot({ GetNumSkillLines = function() return #era end, GetSkillLineInfo = function(i) return unpack(era[i]) end }).skills()),
    "Mining:225/300,Swords:40/75", "Era: values, no headers")
eq(names(boot({ C_SkillInfo = {}, GetNumSkillLines = function() return #era end, GetSkillLineInfo = function(i) return unpack(era[i]) end }).skills()),
    "Mining:225/300,Swords:40/75", "an empty C_SkillInfo falls back to the globals")
A, errs = boot({})
eq(A.skills(), nil, "no skill API: unknown")
eq(#errs, 1, "missing skill API reported once")
eq(boot({ GetNumSkillLines = boom }).skills(), nil, "count throws: unknown")
eq(names(boot({ GetNumSkillLines = function() return 2 end, GetSkillLineInfo = boom }).skills()), "", "lines throw: nothing readable, not an error")
eq(names(boot({ GetNumSkillLines = function() return 3 end, GetSkillLineInfo = function(i) if i == 1 then error("x") end return unpack(era[i]) end }).skills()),
    "Mining:225/300,Swords:40/75", "one unreadable line skipped")
eq(names(boot({ GetNumSkillLines = function() return 1 end, GetSkillLineInfo = function() return "Odd", false, true, "x", 0, 0, 300 end }).skills()), "", "non-numeric rank skipped")
eq(names(boot({ C_SkillInfo = { GetNumSkillLines = function() return 1 end, GetSkillLineInfo = function() return "string" end } }).skills()), "", "non-table result skipped")

-- craftProfession: the profession whose window is open.
local function frame(shownNow) return { IsShown = function() return shownNow end } end
eq(boot({ ProfessionsFrame = frame(true), C_TradeSkillUI = { GetBaseProfessionInfo = function() return { professionName = "Tailoring" } end } }).craftProfession(), "Tailoring", "Forever window")
eq(boot({ TradeSkillFrame = frame(true), GetTradeSkillLine = function() return "Mining", 1, 300 end }).craftProfession(), "Mining", "Era tradeskill window")
eq(boot({ CraftFrame = frame(true), GetCraftDisplaySkillLine = function() return "Enchanting", 1, 300 end }).craftProfession(), "Enchanting", "Era craft window")
eq(boot({ CraftFrame = frame(false), GetCraftDisplaySkillLine = function() return "Enchanting" end }).craftProfession(), nil, "craft window closed")
eq(boot({ TradeSkillFrame = frame(false), GetTradeSkillLine = function() return "Mining" end }).craftProfession(), nil, "window closed")
eq(boot({ ProfessionsFrame = frame(false), C_TradeSkillUI = { GetBaseProfessionInfo = function() return { professionName = "Tailoring" } end } }).craftProfession(), nil, "Forever window closed")
eq(boot({ TradeSkillFrame = frame(true), GetTradeSkillLine = function() return "" end }).craftProfession(), nil, "empty name")
eq(boot({ TradeSkillFrame = frame(true), GetTradeSkillLine = boom }).craftProfession(), nil, "name throws")
eq(boot({ TradeSkillFrame = { IsShown = boom }, GetTradeSkillLine = function() return "Mining" end }).craftProfession(), nil, "IsShown throws")
eq(boot({ ProfessionsFrame = frame(true), C_TradeSkillUI = { GetBaseProfessionInfo = function() return {} end } }).craftProfession(), nil, "Forever window without a name")
eq(boot({}).craftProfession(), nil, "nothing available")

-- trainer: only profession trainers, with the professions they teach.
local function trainerGame(over)
    local g = {
        IsTradeskillTrainer = function() return true end,
        UnitGUID = function() return "Creature-0-4372-0-55-5513-0000A1B2C3" end,
        UnitName = function() return "Gelman Stonehand" end,
        UnitFactionGroup = function() return "Alliance" end,
        GetNumTrainerServices = function() return 4 end,
        GetTrainerServiceSkillLine = function(i) return ({ "Mining", "Mining", "Engineering", false })[i] end,
    }
    for k, v in pairs(over or {}) do g[k] = v end
    return g
end
local tr = boot(trainerGame()).trainer()
eq(tr.id, 5513, "trainer npc id")
eq(tr.name, "Gelman Stonehand", "trainer name")
eq(tr.faction, 1, "trainer faction")
eq(table.concat(tr.trades, ","), "Mining,Engineering", "each profession once, in order")
eq(boot(trainerGame({ IsTradeskillTrainer = function() return false end })).trainer(), nil, "class trainer")
eq(boot(trainerGame({ IsTradeskillTrainer = boom })).trainer(), nil, "trainer check throws")
eq(boot(trainerGame({ GetNumTrainerServices = function() return 0 end })).trainer(), nil, "services not loaded yet")
eq(boot(trainerGame({ GetTrainerServiceSkillLine = function() return nil end })).trainer(), nil, "no profession lines")
eq(boot(trainerGame({ GetTrainerServiceSkillLine = function() return "" end })).trainer(), nil, "empty profession names")
eq(boot(trainerGame({ GetNumTrainerServices = boom })).trainer(), nil, "service count throws")
eq(table.concat(boot(trainerGame({ GetTrainerServiceSkillLine = function(i) if i == 1 then error("x") end return "Mining" end })).trainer().trades, ","), "Mining", "one unreadable service skipped")
eq(boot(trainerGame({ UnitGUID = function() return "Player-0-0-0-0-0-0" end })).trainer(), nil, "not a creature")
eq(boot({}).trainer(), nil, "nothing available")

-- popupShown.
eq(boot({ StaticPopup_Visible = function(w) return w == "W" and "StaticPopup1" or nil end }).popupShown("W"), true, "shown")
eq(boot({ StaticPopup_Visible = function() return nil end }).popupShown("W"), false, "not shown")
eq(boot({ StaticPopup_Visible = boom }).popupShown("W"), false, "throws: not shown")
eq(boot({}).popupShown("W"), false, "missing: not shown")

-- Ammo buying on both API shapes: Classic Era (global functions, positional returns) and the newer
-- client (C_Container / C_MerchantFrame tables).
local ARROW, OTHER = 2515, 3030 -- item ids; class 6, subclass 2
local merchantLines = { { "Rough Arrow", 100, 200, -1, false, ARROW }, { "Gold Thing", 5, 1, -1, true, 9 } }
local function ammoGame(modern)
    local g = {
        NUM_BAG_SLOTS = 4,
        GetMerchantNumItems = function() return #merchantLines end,
        GetMerchantItemLink = function(i) return "|cff|Hitem:" .. merchantLines[i][6] .. "::|h[x]|h|r" end,
        GetItemInfoInstant = function(id) return id, "", "", "", "", id == 9 and 2 or 6, 2 end,
        BuyMerchantItem = function() end,
    }
    local bag1 = { { ARROW, 50 }, nil, { OTHER, 10 } } -- slot 2 empty
    local function numSlots(b) return b == 1 and 3 or 0 end
    local function free(b) if b == 1 then return 1, 1 end return 0, 0 end -- bag 1 is a quiver
    local function info(b, slot) local x = b == 1 and bag1[slot]; return x end
    local function itemInfo() return "n", "l", 1, 1, 5, "", "", 200 end -- min level 5, stack 200
    if modern then
        g.C_Container = { GetContainerNumSlots = numSlots, GetContainerNumFreeSlots = free,
            GetContainerItemInfo = function(b, slot) local x = info(b, slot); return x and { itemID = x[1], stackCount = x[2] } end }
        g.C_Item = { GetItemInfo = itemInfo }
        g.C_MerchantFrame = { GetItemInfo = function(i)
            local m = merchantLines[i]
            return { name = m[1], price = m[2], stackCount = m[3], numAvailable = m[4], hasExtendedCost = m[5] }
        end }
    else
        g.GetContainerNumSlots, g.GetContainerNumFreeSlots, g.GetItemInfo = numSlots, free, itemInfo
        g.GetContainerItemInfo = function(b, slot) local x = info(b, slot); if x then return "tex", x[2] end end
        g.GetContainerItemID = function(b, slot) local x = info(b, slot); return x and x[1] end
        g.GetMerchantItemInfo = function(i)
            local m = merchantLines[i]
            return m[1], "tex", m[2], m[3], m[4], true, m[5]
        end
    end
    return g
end
for _, modern in ipairs({ false, true }) do
    local label = modern and "newer client: " or "Classic Era: "
    local A = boot(ammoGame(modern))
    local offers = A.merchantAmmo()
    eq(#offers, 1, label .. "gold-only ammo listed, extended-cost line skipped")
    local o = offers[1]
    eq(o.id .. "/" .. o.price .. "/" .. o.batch .. "/" .. o.minLevel .. "/" .. o.kind .. "/" .. o.index, ARROW .. "/100/200/5/arrow/1", label .. "offer fields")
    -- slots: 50 of the arrow (150 room), one empty (200), one other ammo (0)
    eq(A.ammoSpace(ARROW, "arrow"), 350, label .. "room in the quiver")
    eq(A.ammoSpace(ARROW, "bullet"), 0, label .. "bags readable but no pouch: no room")
end
eq(boot({}).merchantAmmo(), nil, "no merchant API: unknown")
eq(boot(ammoGame(false)).level(), nil, "no UnitLevel: unknown")

-- screenMessage: silent on-screen text through the error frame; "|" doubled; missing or throwing frames are harmless.
local shown = {}
local aS, eS = boot({ UIErrorsFrame = { AddMessage = function(_, t, r, g, b) shown[#shown + 1] = { t, r, g, b } end } })
aS.screenMessage("Go to Old|Name")
eq(shown[1][1], "Go to Old||Name", "text drawn with the pipe doubled")
eq(type(shown[1][2]), "number", "a colour is given")
eq(#eS, 0, "no error reported")
local aN, eN = boot({})
eq(aN.screenMessage("x"), nil, "no error frame: nothing, no error raised")
eq(#eN, 1, "the missing frame is reported once")
local aT, eT = boot({ UIErrorsFrame = { AddMessage = boom } })
eq(aT.screenMessage("x"), nil, "throwing frame: nothing, no error raised")
eq(#eT, 1, "the failure is reported")

H.done()
