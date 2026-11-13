-- The adapter must turn every missing or throwing game function into "no data", never an error.
package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

-- Load Triggers + Adapter with a fake game. `game` holds the fake globals.
local function boot(game)
    local errors = {}
    local env = setmetatable(game or {}, { __index = _G })
    local ns = {}
    require("harness").locale(ns)
    for _, f in ipairs({ "Triggers", "Ammo", "Reagents", "Supplies", "Adapter" }) do
        local chunk = assert(loadfile("ClosestVendor/" .. f .. ".lua"))
        setfenv(chunk, env)
        chunk("ClosestVendor", ns)
    end
    ns.PetFamilies = { [1] = 4, [2] = 12, [4] = 252, [21] = 200 } -- Wolf Meat, Cat Meat+Fish, Bear all, Turtle Fish+Fungus+Fruit
    ns.SupplyItems = { [300] = 1 + 16, [200] = 2, [17020] = 1 } -- food + Bread, drink, food (fixture ids)
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
eq(mer.supplies, 19, "supply mask: item 300 is food and Bread, item 200 is drink")
eq(boot(merchantGame({ GetMerchantNumItems = boom })).merchant().supplies, 0, "stock unreadable: sells no supplies")
eq(boot(merchantGame({ GetMerchantNumItems = function() return 1 end,
    GetMerchantItemLink = function() return "item:4242:0" end,
    GetItemInfoInstant = function(id) return id, "", "", "", 0, 0, 0 end })).merchant().supplies, 0, "not a supply item")
-- auctioneer.
local ah = boot(merchantGame()).auctioneer()
eq(ah.id, 1234, "auctioneer id from the GUID")
eq(ah.name, "Fresh Vendor", "auctioneer name")
eq(ah.faction, 2, "auctioneer faction")
eq(boot(merchantGame({ UnitGUID = function() return "Player-0-0-0-0-0-0" end })).auctioneer(), nil, "not a creature")
eq(boot(merchantGame({ UnitGUID = boom })).auctioneer(), nil, "GUID throws")
eq(boot({}).auctioneer(), nil, "functions missing")
eq(boot(merchantGame({ UnitFactionGroup = function() return nil end })).auctioneer().faction, 0, "neutral auctioneer")

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

-- Reagents sold: the mask covers the class reagents offered, whatever their item class.
eq(mer.reagents, 0, "no reagents offered")
local rg = boot(merchantGame({
    GetMerchantNumItems = function() return 4 end,
    GetMerchantItemLink = function(i) return "item:" .. ({ 17020, 17032, 300, 17020 })[i] .. ":0" end,
    GetItemInfoInstant = function(id) return id, "", "", "", 0, 0, 0 end,
})).merchant()
eq(rg.reagents, 1 + 4, "arcane powder (bit 0) and portals (bit 2), a duplicate counted once")
eq(rg.ammo, 0, "reagents are not ammo")
eq(boot(merchantGame({ GetMerchantNumItems = boom })).merchant().reagents, 0, "stock unreadable: no reagents")
eq(boot(merchantGame({ GetMerchantNumItems = function() return 2 end,
    GetMerchantItemLink = function(i) if i == 1 then error("x") end return "item:17031:0" end,
    GetItemInfoInstant = function(id) return id, "", "", "", 0, 0, 0 end })).merchant().reagents, 2, "one unreadable item skipped")

-- Class, spells, counts and names.
eq(boot({ UnitClass = function() return "Mage", "MAGE", 8 end }).classToken(), "MAGE", "class token")
eq(boot({ UnitClass = function() return "Mage", nil end }).classToken(), nil, "no token")
eq(boot({ UnitClass = boom }).classToken(), nil, "class throws")
eq(boot({}).classToken(), nil, "class missing")
eq(boot({ IsPlayerSpell = function(id) return id == 10059 end }).knowsSpell(10059), true, "IsPlayerSpell true")
eq(boot({ IsPlayerSpell = function(id) return id == 10059 end }).knowsSpell(1), false, "IsPlayerSpell false")
eq(boot({ IsSpellKnown = function(id) return id == 7 end }).knowsSpell(7), true, "falls back to IsSpellKnown")
eq(boot({ IsPlayerSpell = boom }).knowsSpell(7), nil, "spell check throws: unknown, not false")
eq(boot({}).knowsSpell(7), nil, "no spell API: unknown")
eq(boot({ C_Item = { GetItemCount = function(id) return id == 17020 and 12 or 0 end } }).itemCount(17020), 12, "item count")
eq(boot({ GetItemCount = boom }).itemCount(17020), nil, "count throws: unknown")
eq(boot({}).itemCount(17020), nil, "no count API: unknown")
eq(boot({ GetItemInfo = function() return "Arcane Powder" end }).itemName(17020), "Arcane Powder", "item name")
eq(boot({ GetItemInfo = function() return nil end }).itemName(17020), nil, "name not cached")
eq(boot({}).itemName(17020), nil, "no item API")

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

-- Reagent buying on both API shapes: the merchant's class reagents (never display-only items or
-- items paid with more than gold), the general bag slots and the stack size.
local reagentLines = { { "Arcane Powder", 100, 1, -1, false, 17020 }, { "Soul Shard", 1, 1, -1, false, 6265 },
    { "Rune of Portals", 5, 1, -1, true, 17032 }, { "Rough Arrow", 100, 200, -1, false, ARROW }, { "Rune of Teleportation", 1000, 1, 5, false, 17031 } }
local function reagentGame(modern, over)
    local g = ammoGame(modern)
    g.GetMerchantNumItems = function() return #reagentLines end
    g.GetMerchantItemLink = function(i) return "|cff|Hitem:" .. reagentLines[i][6] .. "::|h[x]|h|r" end
    g.GetMerchantItemMaxStack = function() return 20 end
    local function info(i)
        local m = reagentLines[i]
        return m[1], m[2], m[3], m[4], m[5]
    end
    if modern then
        g.C_MerchantFrame = { GetItemInfo = function(i)
            local n, p, b, s, x = info(i)
            return { name = n, price = p, stackCount = b, numAvailable = s, hasExtendedCost = x }
        end }
    else
        g.GetMerchantItemInfo = function(i) local n, p, b, s, x = info(i); return n, "tex", p, b, s, true, x end
    end
    -- Backpack (bag 0): general, slots { AP x5, empty }; bag 1 a quiver (left out); bag 2 general, { empty }.
    local bags = { [0] = { { 17020, 5 }, false }, [2] = { false } }
    local function numSlots(b) if b == 1 then return 3 end return bags[b] and #bags[b] or 0 end
    local function free(b) if b == 1 then return 1, 1 end return 1, 0 end
    local function slot(b, s) local x = bags[b] and bags[b][s]; return x or nil end
    if modern then
        g.C_Container = { GetContainerNumSlots = numSlots, GetContainerNumFreeSlots = free,
            GetContainerItemInfo = function(b, s) local x = slot(b, s); return x and { itemID = x[1], stackCount = x[2] } end }
    else
        g.GetContainerNumSlots, g.GetContainerNumFreeSlots = numSlots, free
        g.GetContainerItemInfo = function(b, s) local x = slot(b, s); if x then return "tex", x[2] end end
        g.GetContainerItemID = function(b, s) local x = slot(b, s); return x and x[1] end
    end
    for k, v in pairs(over or {}) do g[k] = v end
    return g
end
for _, modern in ipairs({ false, true }) do
    local label = modern and "newer client: " or "Classic Era: "
    local A = boot(reagentGame(modern))
    local offers = A.merchantReagents()
    local ids = {}
    for _, o in ipairs(offers) do ids[#ids + 1] = o.id end
    eq(table.concat(ids, ","), "17020,17031", label .. "class reagents only: no display-only item, no extended cost, no ammo")
    local o = offers[2]
    eq(o.index .. "/" .. o.name .. "/" .. o.price .. "/" .. o.batch .. "/" .. o.stock .. "/" .. o.maxBuy, "5/Rune of Teleportation/1000/1/5/20", label .. "offer fields")
    local s = A.bagSlots()
    eq(#s, 3, label .. "backpack and the general bag, not the quiver")
    eq(s[1][1] .. "x" .. s[1][2] .. "," .. tostring(s[2]) .. "," .. tostring(s[3]), "17020x5,false,false", label .. "slot contents")
    eq(A.stackSize(17020), 200, label .. "stack size from item info")
end
eq(boot({}).merchantReagents(), nil, "no merchant API: unknown")
eq(boot(reagentGame(false, { GetMerchantItemMaxStack = false })).merchantReagents()[1].maxBuy, nil, "no max-stack function: maxBuy unknown")
eq(boot(reagentGame(false, { GetMerchantItemMaxStack = boom })).merchantReagents()[1].maxBuy, nil, "max stack throws: unknown")
eq(boot({}).bagSlots(), nil, "no bag API: unknown")
eq(boot(reagentGame(false, { GetContainerNumFreeSlots = function(b) if b == 0 then error("x") end return 1, 0 end })).bagSlots(), nil, "backpack unreadable: unknown")
eq(#boot(reagentGame(false, { GetContainerNumFreeSlots = function(b) if b == 2 then error("x") end return 1, b == 1 and 1 or 0 end })).bagSlots(), 2, "a bag of unknown kind is left out")
eq(boot(reagentGame(false, { GetContainerItemInfo = boom, GetContainerItemID = boom })).bagSlots(), nil, "a slot unreadable: unknown")
-- petDiet: the family id (second value of UnitCreatureFamily) maps to diets; no text is read.
local function dietNames(d) local n = {} for k in pairs(d or {}) do n[#n + 1] = k end table.sort(n) return table.concat(n, ",") end
eq(dietNames(boot({ UnitCreatureFamily = function() return "Cat", 2 end }).petDiet()), "Fish,Meat", "Cat: Meat and Fish")
eq(dietNames(boot({ UnitCreatureFamily = function() return "Bär", 4 end }).petDiet()), "Bread,Cheese,Fish,Fruit,Fungus,Meat", "a localized name changes nothing")
eq(boot({ UnitCreatureFamily = function() end }).petDiet(), nil, "no pet: nothing returned")
eq(boot({ UnitCreatureFamily = function() return "Cat" end }).petDiet(), nil, "no id: no diet")
eq(boot({ UnitCreatureFamily = function() return "Dragonkin", 99999 end }).petDiet(), nil, "unknown family: no diet")
eq(boot({ UnitCreatureFamily = function() return "Moth", 10 end }).petDiet(), nil, "family that eats nothing: no diet")
eq(boot({ UnitCreatureFamily = boom }).petDiet(), nil, "throws: no diet")
eq(boot({}).petDiet(), nil, "missing: no diet")
-- playSound: one guarded call; a bad id, a missing call and a throwing call are all quiet.
do
    local played = {}
    local a = boot({ PlaySound = function(id) played[#played + 1] = id end })
    a.playSound(3081)
    a.playSound(nil)
    a.playSound("3081")
    eq(table.concat(played, ","), "3081", "only a number is played")
    local b, be = boot({})
    b.playSound(3081)
    b.playSound(3081)
    eq(#be, 1, "a missing PlaySound is reported once")
    local c, ce = boot({ PlaySound = boom })
    c.playSound(3081)
    eq(#ce, 1, "a throwing PlaySound is reported and skipped")
end
local pd, pe = boot({})
pd.petDiet()
eq(#pe, 1, "a missing call is reported once")

local sc = boot(reagentGame(false)).supplyCounts()
eq(sc[17020], 5, "supply counts: the 17020 stack in the backpack")
eq(sc[99999], nil, "only supply ids are counted")
eq(boot({}).supplyCounts(), nil, "no bag API: unknown, never zero")
eq(boot(reagentGame(false, { GetContainerItemInfo = boom, GetContainerItemID = boom })).supplyCounts(), nil, "a slot unreadable: unknown")
eq(boot({}).stackSize(17020), nil, "no item info: stack unknown")
eq(boot({ GetItemInfo = function() return "n" end }).stackSize(17020), nil, "item info without a stack: unknown")
local calls = {}
local Ab = boot({ BuyMerchantItem = function(...) calls[#calls + 1] = select("#", ...) .. ":" .. table.concat({ ... }, ",") end })
Ab.buyMerchantItem(3); Ab.buyMerchantItem(4, 17)
eq(table.concat(calls, " "), "1:3 2:4,17", "one batch, or a quantity of single items")
eq(boot({ BuyMerchantItem = boom }).buyMerchantItem(1, 5), nil, "buying throws: no error")
eq(boot(ammoGame(false)).level(), nil, "no UnitLevel: unknown")

-- screenMessage: silent text in a frame of our own, about five seconds, replaced by a newer message.
local function noticeGame()
    local made = { frames = 0 }
    local function frame()
        local f = { shown = false, strata = nil }
        function f:SetSize() end
        function f:SetPoint() end
        function f:SetFrameStrata(s) self.strata = s end
        function f:EnableMouse(on) self.mouse = on end
        function f:CreateFontString() self.fontString = frame(); return self.fontString end
        function f:SetText(t) self.shownText = t end
        function f:SetScript(ev, fn) self.scripts = self.scripts or {}; self.scripts[ev] = fn end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        return f
    end
    made.game = { UIParent = {}, CreateFrame = function() made.frames = made.frames + 1; made.frame = frame(); return made.frame end }
    return made
end
local function tick(f, seconds) if f.shown then f.scripts.OnUpdate(f, seconds) end end

local m = noticeGame()
local aS, eS = boot(m.game)
aS.screenMessage("Go to Old|Name")
eq(m.frame.fontString.shownText, "Go to Old||Name", "text drawn with the pipe doubled")
eq(m.frame.shown, true, "visible")
eq(m.frame.mouse, false, "never takes the mouse")
tick(m.frame, 4.9)
eq(m.frame.shown, true, "still visible just under five seconds")
tick(m.frame, 0.2)
eq(m.frame.shown, false, "gone after about five seconds")
aS.screenMessage("again")
eq(m.frame.shown, true, "a later message shows again")
eq(m.frames, 1, "one frame, reused")
tick(m.frame, 3)
aS.screenMessage("newer")
eq(m.frame.fontString.shownText, "newer", "a newer message replaces the text")
tick(m.frame, 3)
eq(m.frame.shown, true, "the newer message has its own full time")
tick(m.frame, 2.1)
eq(m.frame.shown, false, "and then goes")
eq(#eS, 0, "no error reported")

local aU, eU = boot({ UIErrorsFrame = { AddMessage = function() error("not this frame") end }, UIParent = m.game.UIParent, CreateFrame = m.game.CreateFrame })
aU.screenMessage("x")
eq(#eU, 0, "the game's error frame is never used")

local aN, eN = boot({})
eq(aN.screenMessage("x"), nil, "no CreateFrame: nothing, no error raised")
eq(#eN, 1, "the missing frame is reported once")
aN.screenMessage("y")
eq(#eN, 1, "and not again")
local aT, eT = boot({ UIParent = {}, CreateFrame = boom })
eq(aT.screenMessage("x"), nil, "throwing CreateFrame: nothing, no error raised")
eq(#eT, 1, "the failure is reported")

-- instanceType: none, party, raid or pvp; unknown is nil, never "none".
local function inst(inside, kind) return boot({ IsInInstance = function() return inside, kind end }).instanceType() end
eq(inst(false, "none"), "none", "open world")
eq(inst(true, "party"), "party", "dungeon")
eq(inst(true, "raid"), "raid", "raid")
eq(inst(true, "pvp"), "pvp", "battleground")
eq(inst(true, "arena"), "pvp", "an arena counts as pvp")
eq(inst(true, "scenario"), "party", "another kind of instance counts as a dungeon")
eq(inst(false, nil), "none", "not inside and no kind given: open world")
eq(inst(nil, nil), nil, "the game says nothing: unknown")
local aI, eI = boot({})
eq(aI.instanceType(), nil, "missing IsInInstance: unknown")
eq(#eI, 1, "missing reported once")
eq(boot({ IsInInstance = boom }).instanceType(), nil, "throwing: unknown")

-- bindLocation: the name, or nil.
eq(boot({ GetBindLocation = function() return "Goldshire" end }).bindLocation(), "Goldshire", "bind name")
eq(boot({ GetBindLocation = function() return "" end }).bindLocation(), nil, "empty name: unknown")
eq(boot({ GetBindLocation = function() return nil end }).bindLocation(), nil, "no name: unknown")
eq(boot({ GetBindLocation = boom }).bindLocation(), nil, "throwing: unknown")
eq(boot({}).bindLocation(), nil, "missing: unknown")

-- shiftDown.
eq(boot({ IsShiftKeyDown = function() return true end }).shiftDown(), true, "shift held")
eq(boot({ IsShiftKeyDown = function() return 1 end }).shiftDown(), true, "numeric true")
eq(boot({ IsShiftKeyDown = function() return false end }).shiftDown(), false, "shift not held")
eq(boot({ IsShiftKeyDown = boom }).shiftDown(), nil, "throwing: unknown")
eq(boot({}).shiftDown(), nil, "missing: unknown")

-- Colour picker: newer clients take one table, older ones are set up field by field. Missing or
-- throwing: nothing opens, nil, one report.
local function picker(newStyle, throws)
    local f = { shown = false, rgb = { 0, 0, 0 } }
    function f:GetColorRGB() return self.rgb[1], self.rgb[2], self.rgb[3] end
    if newStyle then
        function f:SetupColorPickerAndShow(info)
            if throws then error("kaboom", 0) end
            self.info, self.shown = info, true
            self.rgb = { info.r, info.g, info.b }
        end
    else
        function f:SetColorRGB(r, g, b) if throws then error("kaboom", 0) end self.rgb = { r, g, b } end
        function f:Show() self.shown = true end
    end
    return f
end
eq(boot({ ColorPickerFrame = picker(true) }).hasColorPicker(), true, "colour picker present")
eq(boot({}).hasColorPicker(), nil, "no colour picker: nil")
eq(boot({ CreateSettingsButtonInitializer = function() end }).hasSettingsButton(), true, "settings button maker present")
eq(boot({}).hasSettingsButton(), nil, "no settings button maker: nil")
eq(boot({ ColorPickerFrame = { SetupColorPickerAndShow = function() end, GetPreviousValues = function() end } }).hasSwatchPicker(), true, "picker takes the settings swatch's calls")
eq(boot({ ColorPickerFrame = { SetupColorPickerAndShow = function() end } }).hasSwatchPicker(), nil, "no GetPreviousValues: nil")
eq(boot({ ColorPickerFrame = { GetPreviousValues = function() end } }).hasSwatchPicker(), nil, "no SetupColorPickerAndShow: nil")
eq(boot({}).hasSwatchPicker(), nil, "no picker: nil")
for _, newStyle in ipairs({ true, false }) do
    local frame = picker(newStyle)
    local Ap = boot({ ColorPickerFrame = frame })
    local got = {}
    eq(Ap.pickColor(0.2, 0.4, 0.6, function(r, g, b) got[#got + 1] = r .. "," .. g .. "," .. b end), true, "picker opened: " .. tostring(newStyle))
    eq(frame.shown, true, "and shown")
    eq(table.concat(frame.rgb, ","), "0.2,0.4,0.6", "at the colour given")
    local swatch = newStyle and frame.info.swatchFunc or frame.func
    local cancel = newStyle and frame.info.cancelFunc or frame.cancelFunc
    local hasOpacity; if newStyle then hasOpacity = frame.info.hasOpacity else hasOpacity = frame.hasOpacity end
    eq(hasOpacity, false, "no opacity in the picker: that is its own setting")
    frame.rgb = { 1, 0, 0.5 }; swatch()
    eq(got[1], "1,0,0.5", "a colour tried is passed on")
    cancel()
    eq(got[2], "0.2,0.4,0.6", "cancel goes back to the starting colour")
    frame.GetColorRGB = boom; swatch()
    eq(#got, 2, "a picker that cannot say its colour changes nothing")
end
local Am, errm = boot({})
eq(Am.pickColor(0, 0, 0, function() end), nil, "no picker: nil")
eq(errm[1], "ColorPickerFrame: missing", "and reported")
for _, newStyle in ipairs({ true, false }) do
    local At, errt = boot({ ColorPickerFrame = picker(newStyle, true) })
    eq(At.pickColor(0, 0, 0, function() end), nil, "throwing picker: nil")
    eq(errt[1], "ColorPickerFrame: kaboom", "and reported")
end

H.done()
