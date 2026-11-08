-- The only file that reads game state. Every call is checked and run in pcall, so a missing or
-- changed function means "no data" (nil) instead of an error. A failure is reported once per
-- kind through A.onError(name, text) so it can be logged without flooding.
local _, ns = ...

local A = {}
ns.Adapter = A

A.onError = function() end -- replaced by Core (the debug log)

local reported = {}
local function fail(name, err)
    if reported[name] then return end
    reported[name] = true
    A.onError(name, tostring(err))
end

local function finish(name, ok, ...)
    if not ok then fail(name, (...)) return end
    return ...
end

-- Run fn(...) guarded; returns its results, or nothing if fn is missing or throws.
local function call(name, fn, ...)
    if type(fn) ~= "function" then fail(name, "missing") return end
    return finish(name, pcall(fn, ...))
end

local RANGED_SLOT, AMMO_SLOT = 18, 0
local EQUIP_SLOTS = {}
for i = 1, 18 do EQUIP_SLOTS[i] = i end

function A.isAddOnLoaded(name)
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return call("IsAddOnLoaded", f, name) and true or false
end

function A.inCombat()
    return call("InCombatLockdown", InCombatLockdown) and true or false
end

-- Bags -------------------------------------------------------------------------------------

local function bagFree(bag)
    local f = (C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
    return call("GetContainerNumFreeSlots", f, bag)
end

-- Free slots in general bags, or nil if no bag could be read.
function A.freeSlots()
    return ns.Triggers.FreeSlots(bagFree, 0, NUM_BAG_SLOTS or 4)
end

-- Gear ---------------------------------------------------------------------------------------

local function durability(slot)
    return call("GetInventoryItemDurability", GetInventoryItemDurability, slot)
end

-- Lowest durability percent over equipped items; nil if none could be read.
function A.lowestDurability()
    return ns.Triggers.LowestDurability(durability, EQUIP_SLOTS)
end

-- Items and ammo -------------------------------------------------------------------------------

local function inventoryItemID(slot)
    return call("GetInventoryItemID", GetInventoryItemID, "player", slot)
end

-- Item class and subclass from an item id (weapons are class 2, ammo class 6).
function A.itemClass(id)
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local _, _, _, _, _, classID, subClassID = call("GetItemInfoInstant", f, id)
    return classID, subClassID
end

local function itemCount(id)
    local f = (C_Item and C_Item.GetItemCount) or GetItemCount
    return call("GetItemCount", f, id)
end

-- Ammo the equipped ranged weapon needs ("arrow"/"bullet") and how much of the equipped ammo the
-- player has (bags included); nil when there is nothing to monitor or the data is unavailable.
-- With no ammo equipped the count is 0.
function A.ammoStatus()
    local weapon = inventoryItemID(RANGED_SLOT)
    if not weapon then return end
    local needed = ns.Triggers.AmmoNeeded(A.itemClass(weapon))
    if not needed then return end
    local ammo = inventoryItemID(AMMO_SLOT)
    local c, sc, total
    if ammo then
        c, sc = A.itemClass(ammo)
        total = itemCount(ammo)
        -- Equipped ammo we cannot read is unknown, not "none".
        if c == nil or total == nil then return end
    end
    return needed, ns.Triggers.AmmoCount(needed, c, sc, total)
end

-- Position -------------------------------------------------------------------------------------

-- Player position as a map id and 0-1 coordinates; nil where the game gives none (instances).
function A.mapPosition()
    local map = call("GetBestMapForUnit", C_Map and C_Map.GetBestMapForUnit, "player")
    if not map then return end
    local pos = call("GetPlayerMapPosition", C_Map and C_Map.GetPlayerMapPosition, map, "player")
    if not pos then return end
    local x, y = pos.x, pos.y
    if not x or (x == 0 and y == 0) then return end
    return map, x, y
end

-- Continent id plus world x,y for a map position; nil if the client cannot convert it.
function A.toWorld(map, x, y)
    local v = call("CreateVector2D", CreateVector2D, x, y)
    if not v then return end
    local continent, w = call("GetWorldPosFromMapPos", C_Map and C_Map.GetWorldPosFromMapPos, map, v)
    if continent and w then return continent, w.x, w.y end
end

-- Continent id, world x,y and map id of the player, or nil.
function A.playerWorldPos()
    local map, x, y = A.mapPosition()
    if not map then return end
    local continent, wx, wy = A.toWorld(map, x, y)
    if continent then return continent, wx, wy, map end
end

-- Show text on screen for about NOTICE_SECONDS, silently, in a frame of our own (the game's error
-- frame fades too soon and is shared with real errors). A newer message replaces the one showing and
-- restarts the time. Nothing happens, and one failure is reported, where the client has no frames.
local NOTICE_SECONDS = 5
local notice

local function buildNotice()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(800, 40)
    f:SetPoint("TOP", 0, -200)
    f:SetFrameStrata("HIGH")
    f:EnableMouse(false)
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.text:SetPoint("CENTER")
    -- A hidden frame gets no OnUpdate, so this costs nothing while no message shows.
    f:SetScript("OnUpdate", function(self, elapsed)
        self.left = (self.left or 0) - elapsed
        if self.left <= 0 then self:Hide() end
    end)
    return f
end

-- "|" starts an escape code, so it is doubled.
function A.screenMessage(text)
    if not notice then notice = call("screenMessage frame", buildNotice) end
    if not notice then return end
    call("screenMessage show", function()
        notice.text:SetText((text:gsub("|", "||")))
        notice.left = NOTICE_SECONDS
        notice:Show()
    end)
end

function A.mapName(id)
    local info = call("GetMapInfo", C_Map and C_Map.GetMapInfo, id)
    return info and info.name
end

-- Skills and trainers ---------------------------------------------------------------------------------

-- One skill line as { name, header, rank, max }: Forever returns a table from C_SkillInfo, Era the
-- old multiple values from the global function.
local function skillLine(i)
    if C_SkillInfo and type(C_SkillInfo.GetSkillLineInfo) == "function" then
        local info = call("C_SkillInfo.GetSkillLineInfo", C_SkillInfo.GetSkillLineInfo, i)
        if type(info) ~= "table" then return end
        if info.parentSkillLineID and info.parentSkillLineID ~= 0 then return end -- sub-lines of a skill
        return info.name, info.isHeader, info.rank, info.maxRank
    end
    local name, header, _, rank, _, _, max = call("GetSkillLineInfo", GetSkillLineInfo, i)
    return name, header, rank, max
end

-- The player's skills as a list of { name, rank, max } (headers left out); nil if unreadable.
function A.skills()
    local count = call("GetNumSkillLines", (C_SkillInfo and C_SkillInfo.GetNumSkillLines) or GetNumSkillLines)
    if type(count) ~= "number" then return end
    local out = {}
    for i = 1, count do
        local name, header, rank, max = skillLine(i)
        if name and not header and type(rank) == "number" and type(max) == "number" then
            out[#out + 1] = { name = name, rank = rank, max = max }
        end
    end
    return out
end

-- Name of the profession whose tradeskill or craft window is open, or nil.
local function shown(frame)
    return type(frame) == "table" and call("IsShown", frame.IsShown, frame) and true or false
end

function A.craftProfession()
    if shown(ProfessionsFrame) and C_TradeSkillUI then
        local info = call("GetBaseProfessionInfo", C_TradeSkillUI.GetBaseProfessionInfo)
        if type(info) == "table" and info.professionName then return info.professionName end
    end
    if shown(TradeSkillFrame) then
        local name = call("GetTradeSkillLine", GetTradeSkillLine)
        if type(name) == "string" and name ~= "" then return name end
    end
    if shown(CraftFrame) then
        local name = call("GetCraftDisplaySkillLine", GetCraftDisplaySkillLine)
        if type(name) == "string" and name ~= "" then return name end
    end
end

-- The profession trainer window that just opened: { id, name, faction, trades = { names } }, or
-- nil if it is not a profession trainer, cannot be identified, or has not loaded its services yet.
function A.trainer()
    if not call("IsTradeskillTrainer", IsTradeskillTrainer) then return end
    local id, name = A.npc()
    if not id then return end
    local trades, seen = {}, {}
    local count = call("GetNumTrainerServices", GetNumTrainerServices) or 0
    for i = 1, count do
        local skill = call("GetTrainerServiceSkillLine", GetTrainerServiceSkillLine, i)
        if type(skill) == "string" and skill ~= "" and not seen[skill] then
            seen[skill] = true
            trades[#trades + 1] = skill
        end
    end
    if #trades == 0 then return end
    return { id = id, name = name, faction = A.factionId("npc"), trades = trades }
end

-- Units and merchants ----------------------------------------------------------------------------

-- 1 Alliance, 2 Horde, 0 neutral or unknown.
function A.factionId(unit)
    local token = call("UnitFactionGroup", UnitFactionGroup, unit)
    if token == "Alliance" then return 1 elseif token == "Horde" then return 2 end
    return 0
end

-- NPC id and name of the creature the player is talking to, or nil if it is not a creature.
function A.npc()
    local guid = call("UnitGUID", UnitGUID, "npc")
    local name = call("UnitName", UnitName, "npc")
    local kind, id = (type(guid) == "string" and guid or ""):match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    id = tonumber(id)
    if kind ~= "Creature" or not id or not name then return end
    return id, name
end

-- 0 none, 1 arrows, 2 bullets, 3 both: what the open merchant window sells.
local function merchantAmmoCode()
    local arrows, bullets = 0, 0
    local count = call("GetMerchantNumItems", GetMerchantNumItems) or 0
    for i = 1, count do
        local link = call("GetMerchantItemLink", GetMerchantItemLink, i)
        local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
        if id then
            local c, sc = A.itemClass(id)
            if c == 6 and sc == 2 then arrows = 1 elseif c == 6 and sc == 3 then bullets = 2 end
        end
    end
    return arrows + bullets
end

-- The merchant window that just opened: { id, name, faction, repair, ammo }, or nil if the
-- merchant cannot be identified as a creature.
function A.merchant()
    local id, name = A.npc()
    if not id then return end
    return { id = id, name = name, faction = A.factionId("npc"),
             repair = call("CanMerchantRepair", CanMerchantRepair) and true or false, ammo = merchantAmmoCode() }
end

-- Buying ammo -----------------------------------------------------------------------------------

local AMMO_FAMILY = { arrow = 1, bullet = 2 } -- bag family bits of a quiver and an ammo pouch

local function itemInfo(item)
    return call("GetItemInfo", (C_Item and C_Item.GetItemInfo) or GetItemInfo, item)
end

-- One merchant line: name, price per purchase, items per purchase, stock (-1 unlimited), paid with
-- more than gold. Newer clients return a table from C_MerchantFrame.GetItemInfo, Classic Era
-- returns values from GetMerchantItemInfo.
local function merchantItem(i)
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local t = call("C_MerchantFrame.GetItemInfo", C_MerchantFrame.GetItemInfo, i)
        if type(t) == "table" then
            return t.name, t.price, t.stackCount, t.numAvailable, t.hasExtendedCost
        end
    end
    local name, _, price, batch, stock, _, extended = call("GetMerchantItemInfo", GetMerchantItemInfo, i)
    return name, price, batch, stock, extended
end

-- The open merchant's arrows and bullets: list of { index, id, name, price, batch, minLevel, kind, stock }.
-- Price is per purchase of `batch` items. Items paid for with anything but gold are left out.
function A.merchantAmmo()
    local count = call("GetMerchantNumItems", GetMerchantNumItems)
    if not count then return end
    local list = {}
    for i = 1, count do
        local name, price, batch, stock, extended = merchantItem(i)
        local link = call("GetMerchantItemLink", GetMerchantItemLink, i)
        local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
        if id and price and not extended then
            local c, sc = A.itemClass(id)
            if c == 6 and (sc == 2 or sc == 3) then
                local _, _, _, _, minLevel = itemInfo(link)
                list[#list + 1] = { index = i, id = id, name = name or tostring(id), price = price, batch = batch or 1,
                    minLevel = minLevel, kind = sc == 2 and "arrow" or "bullet", stock = stock }
            end
        end
    end
    return list
end

function A.equippedAmmoID() return inventoryItemID(AMMO_SLOT) end

function A.level() return call("UnitLevel", UnitLevel, "player") end

function A.money() return call("GetMoney", GetMoney) end

-- One slot of a bag: false if empty, { id, count } if filled; nil if it cannot be read.
local function bagSlot(bag, slot)
    local f = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo
    local a, b = call("GetContainerItemInfo", f, bag, slot)
    if type(a) == "table" then return a.itemID and { a.itemID, a.stackCount or 1 } or false end
    if a == nil then return false end
    local id = call("GetContainerItemID", (C_Container and C_Container.GetContainerItemID) or GetContainerItemID, bag, slot)
    return id and { id, b or 1 } or nil
end

-- Room, in items, in the carried quivers or ammo pouches of this kind for item `id`; nil if unknown.
function A.ammoSpace(id, kind)
    local stack = select(8, itemInfo(id))
    local slots, readable = {}, false
    for bag = 1, NUM_BAG_SLOTS or 4 do
        local _, family = bagFree(bag)
        if family and family == AMMO_FAMILY[kind] then
            local n = call("GetContainerNumSlots", (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots, bag)
            if not n then return end
            for slot = 1, n do
                local s = bagSlot(bag, slot)
                if s == nil then return end
                slots[#slots + 1] = s
            end
        end
        if family then readable = true end
    end
    if readable then return ns.Ammo.Space(slots, stack, id) end
end

-- Buy one purchase (one batch) of merchant item `index`.
function A.buyMerchantItem(index)
    call("BuyMerchantItem", BuyMerchantItem, index)
end

-- Misc -------------------------------------------------------------------------------------------

-- Seconds since the game started, for timestamping log entries.
function A.now()
    return call("GetTime", GetTime) or 0
end

-- Run fn after seconds; returns false if timers are unavailable.
function A.after(seconds, fn)
    if not (C_Timer and C_Timer.After) then return false end
    call("C_Timer.After", C_Timer.After, seconds, fn)
    return true
end

function A.showPopup(which, text, data)
    call("StaticPopup_Hide", StaticPopup_Hide, which) -- replace a question that is still open
    call("StaticPopup_Show", StaticPopup_Show, which, text, nil, data)
end

function A.hidePopup(which)
    call("StaticPopup_Hide", StaticPopup_Hide, which)
end

function A.popupShown(which)
    return call("StaticPopup_Visible", StaticPopup_Visible, which) and true or false
end

-- What the navigation adapters need from the game (late-loaded addons are looked up at use).
function A.navApi(print)
    return {
        isAddOnLoaded = A.isAddOnLoaded,
        TomTom = TomTom, WaypointUIAPI = WaypointUIAPI,
        C_Map = C_Map, C_SuperTrack = C_SuperTrack, UiMapPoint = UiMapPoint,
        print = print,
        mapName = A.mapName,
    }
end

-- Version, client and locale for the diagnostic report.
function A.clientInfo()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version, build, date, interface = call("GetBuildInfo", GetBuildInfo)
    return {
        addon = call("GetAddOnMetadata", meta, "ClosestVendor", "Version"),
        gameVersion = version, build = build, interface = interface,
        locale = call("GetLocale", GetLocale),
    }
end
