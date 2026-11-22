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

-- Dead or a ghost: the game shows no questions then (whileDead = false).
function A.isDead()
    return call("UnitIsDeadOrGhost", UnitIsDeadOrGhost, "player") and true or false
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

-- The icon (file id or path) of an item from its id; nil when unknown.
function A.itemIcon(id)
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local _, _, _, _, icon = call("GetItemInfoInstant", f, id)
    return icon
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

-- Where the player is: "none" (open world), "party" (dungeon), "raid" or "pvp" (battleground or
-- arena); nil when the game cannot say. Any other kind of instance counts as a dungeon.
function A.instanceType()
    local inside, kind = call("IsInInstance", IsInInstance)
    if inside == nil and kind == nil then return nil end
    if not inside or kind == "none" then return "none" end
    if kind == "pvp" or kind == "arena" then return "pvp" end
    if kind == "raid" then return "raid" end
    return "party"
end

-- The name of the place the hearthstone is bound to, or nil. The game gives no position for it.
function A.bindLocation()
    local name = call("GetBindLocation", GetBindLocation)
    if type(name) == "string" and name ~= "" then return name end
end

-- True or false whether a Shift key is held; nil when the game cannot say.
function A.shiftDown()
    local down = call("IsShiftKeyDown", IsShiftKeyDown)
    if down == nil then return nil end
    return down and true or false
end

-- True when the game has a colour picker window; nil when it has none.
function A.hasColorPicker()
    if type(ColorPickerFrame) == "table" then return true end
end

-- True when the game's colour picker takes the calls the game's own settings colour swatch makes
-- (ColorPickerFrame:SetupColorPickerAndShow and :GetPreviousValues); nil when not.
function A.hasSwatchPicker()
    local frame = ColorPickerFrame
    if type(frame) == "table" and type(frame.SetupColorPickerAndShow) == "function"
            and type(frame.GetPreviousValues) == "function" then
        return true
    end
end

-- True when the settings page can hold a button (the game's CreateSettingsButtonInitializer); nil when not.
function A.hasSettingsButton()
    if type(CreateSettingsButtonInitializer) == "function" then return true end
end

-- Open the game's colour picker at r, g, b (0 to 1, no opacity). onPick(r, g, b) is called for every
-- colour tried, and with the starting colour when the player cancels. True when the picker opened;
-- nothing, and one failure reported, when it is missing or differs. Newer clients take one table,
-- older ones are set up field by field.
function A.pickColor(r, g, b, onPick)
    local frame = ColorPickerFrame
    if type(frame) ~= "table" then fail("ColorPickerFrame", "missing") return end
    local function picked()
        local ok, nr, ng, nb = pcall(frame.GetColorRGB, frame)
        if ok and type(nr) == "number" and type(ng) == "number" and type(nb) == "number" then onPick(nr, ng, nb) end
    end
    local function cancelled() onPick(r, g, b) end
    local ok, err
    if type(frame.SetupColorPickerAndShow) == "function" then
        ok, err = pcall(frame.SetupColorPickerAndShow, frame,
            { r = r, g = g, b = b, hasOpacity = false, swatchFunc = picked, cancelFunc = cancelled })
    else
        ok, err = pcall(function()
            frame.hasOpacity = false
            frame.func, frame.cancelFunc = picked, cancelled
            frame:SetColorRGB(r, g, b)
            frame:Show()
        end)
    end
    if not ok then fail("ColorPickerFrame", err) return end
    return true
end

-- Show text on screen for about NOTICE_SECONDS, silently, in a frame of our own (the game's error
-- frame fades too soon and is shared with real errors). A newer message replaces the one showing and
-- restarts the time. Nothing happens, and one failure is reported, where the client has no frames.
local NOTICE_SECONDS = 5
local notice, sampleNotice

local function buildNotice()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(800, 40)
    f:SetPoint("TOP", 0, -200)
    f:SetFrameStrata("HIGH")
    f:EnableMouse(false)
    f.text = ns.Presentation and ns.Presentation.Font(f, "GameFontHighlight") or f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.text:SetPoint("CENTER")
    f.text:SetWidth(760)
    f.text:SetTextColor(.867, .867, .867)
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
        notice:SetHeight(math.max(40, (notice.text:GetStringHeight() or 24) + 16))
        notice.left = NOTICE_SECONDS
        notice:Show()
    end)
end


-- Samples use the same warning renderer, with a separate lifetime and no live state.
function A.hideNotice()
    if notice then call("notice hide", notice.Hide, notice) end
end
function A.sampleWarning(text, seconds)
    if not sampleNotice then sampleNotice = call("sample warning", buildNotice) end
    if not sampleNotice then return end
    call("sample warning show", function()
        sampleNotice.text:SetText((text:gsub("|", "||")))
        sampleNotice:SetHeight(math.max(40, (sampleNotice.text:GetStringHeight() or 24) + 16))
        sampleNotice.left = seconds or 10; sampleNotice:Show()
    end)
end
function A.hideSamples()
    if sampleNotice then call("sample warning hide", sampleNotice.Hide, sampleNotice) end
    A.hidePopup("CLOSESTVENDOR_SAMPLE")
end
function A.escape(frame, cancel)
    local name = call("move frame name", frame.GetName, frame)
    if not name or type(UISpecialFrames) ~= "table" then return end
    call("move hide handler", frame.SetScript, frame, "OnHide", cancel)
    return function(active)
        call("move Escape registration", function()
            for i = #UISpecialFrames, 1, -1 do
                if UISpecialFrames[i] == name then table.remove(UISpecialFrames, i) end
            end
            if active then UISpecialFrames[#UISpecialFrames + 1] = name end
        end)
    end
end
function A.createToast(env)
    return call("toast frame", ns.Toast and ns.Toast.New, env)
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

-- What the open trainer window lists, as its filters show it, for the debug log: a list of
-- { skill, name, sub, kind, level, reqSkill, reqRank }, and the filter states { available, unavailable,
-- used }. Read only: the player's filters are never changed. Any value the client lacks is nil.
function A.trainerServices()
    local out = {}
    local count = call("GetNumTrainerServices", GetNumTrainerServices) or 0
    for i = 1, count do
        local name, sub, kind = call("GetTrainerServiceInfo", GetTrainerServiceInfo, i)
        local reqSkill, reqRank = call("GetTrainerServiceSkillReq", GetTrainerServiceSkillReq, i)
        out[#out + 1] = { skill = call("GetTrainerServiceSkillLine", GetTrainerServiceSkillLine, i), name = name, sub = sub,
            kind = kind, level = call("GetTrainerServiceLevelReq", GetTrainerServiceLevelReq, i), reqSkill = reqSkill, reqRank = reqRank }
    end
    local filters = {}
    for _, f in ipairs({ "available", "unavailable", "used" }) do
        filters[f] = call("GetTrainerServiceTypeFilter", GetTrainerServiceTypeFilter, f)
    end
    return out, filters
end

-- Units and merchants ----------------------------------------------------------------------------

-- 1 Alliance, 2 Horde, 0 neutral or unknown.
function A.factionId(unit)
    local token = call("UnitFactionGroup", UnitFactionGroup, unit)
    if token == "Alliance" then return 1 elseif token == "Horde" then return 2 end
    return 0
end

-- NPC id and name of the creature the player is talking to (or of unit, such as "target"), or nil
-- if it is not a creature.
function A.npc(unit)
    unit = unit or "npc"
    local guid = call("UnitGUID", UnitGUID, unit)
    local name = call("UnitName", UnitName, unit)
    local kind, id = (type(guid) == "string" and guid or ""):match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    id = tonumber(id)
    if kind ~= "Creature" or not id or not name then return end
    return id, name
end

-- The auctioneer whose window just opened: { id, name, faction }, or nil when the open window's NPC
-- cannot be identified as a creature.
function A.auctioneer()
    local id, name = A.npc()
    if not id then return end
    return { id = id, name = name, faction = A.factionId("npc") }
end

-- What the open merchant window sells: an ammo code (0 none, 1 arrows, 2 bullets, 3 both), a
-- reagent mask (bits of the Reagents table) and a supply mask (bits 0-7 of Supplies.lua), and
-- whether the list was only partly readable (the game had not loaded every item yet). One pass over
-- the offered items.
local function merchantScan()
    local arrows, bullets, reagents, supplies, partial = 0, 0, {}, {}, false
    local count = call("GetMerchantNumItems", GetMerchantNumItems)
    if type(count) ~= "number" then count, partial = 0, true end
    for i = 1, count do
        local link = call("GetMerchantItemLink", GetMerchantItemLink, i)
        local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
        if id then
            if ns.Reagents.ById(id) then reagents[id] = true end
            if ns.Supplies.ItemMask(id) ~= 0 then supplies[id] = true end
            local c, sc = A.itemClass(id)
            if c == 6 and sc == 2 then arrows = 1 elseif c == 6 and sc == 3 then bullets = 2 end
            -- Its kind cannot be read yet: the list is only partly read, as for a missing link.
            if c == nil then partial = true end
        else
            partial = true
        end
    end
    return arrows + bullets, ns.Reagents.Mask(reagents), ns.Supplies.VendorMask(supplies), partial
end

-- Vendors from the NorgannonDB addon (optional) on the maps in `mapIds` (a set of UiMap ids), in the
-- vendor record shape. Returns list, skipped, schema ("1.5"); or nil when the addon is missing; or
-- nil, "unsupported" when it is installed but too old or unreadable. `skipped` counts vendors listed
-- under a zone with its own map that have no usable position; sub-zones are not read. Reads
-- NorgannonDB's records with Peek and keeps nothing.
local NPC_REPAIR_FLAG = 16384
local REACTION_FACTION = { A = 1, H = 2 }

local function hasFlag(mask, flag) return type(mask) == "number" and mask % (2 * flag) >= flag end

local function externalRecord(DB, id, area, map)
    local r = DB:Peek("npcs", id)
    if type(r) ~= "table" or type(r.name) ~= "string" or type(r.spawns) ~= "table" then return end
    local spawn = type(r.spawns[area]) == "table" and r.spawns[area][1]
    local x, y = type(spawn) == "table" and spawn[1], type(spawn) == "table" and spawn[2]
    if type(x) ~= "number" or type(y) ~= "number" or x < 0 or y < 0 or x > 100 or y > 100 or (x == 0 and y == 0) then return end
    local arrows, bullets, reagents, supplies = 0, 0, {}, {}
    for item in pairs(type(r.sells) == "table" and r.sells or {}) do
        if type(item) == "number" then
            if ns.Reagents.ById(item) then reagents[item] = true end
            if ns.Supplies.ItemMask(item) ~= 0 then supplies[item] = true end
            local c, sc = A.itemClass(item)
            if c == 6 and sc == 2 then arrows = 1 elseif c == 6 and sc == 3 then bullets = 2 end
        end
    end
    return { id, r.name, map, x / 100, y / 100, REACTION_FACTION[r.reaction] or 0, hasFlag(r.flags, NPC_REPAIR_FLAG),
        arrows + bullets, ns.Reagents.Mask(reagents), ns.Supplies.VendorMask(supplies) }
end

local function scanExternal(DB, mapIds)
    local list, done, tried = {}, {}, {}
    local vendors = type(DB.categories) == "table" and type(DB.categories.vendor) == "table" and DB.categories.vendor.npcs
    local byZone = type(DB.index) == "table" and DB.index.zones
    for area, zone in pairs(DB.zones) do
        local map = type(zone) == "table" and zone.uiMapId
        local npcs = map and mapIds[map] and type(byZone[area]) == "table" and byZone[area].npcs
        for _, id in ipairs(npcs or {}) do
            if vendors[id] and not done[id] then
                tried[id] = true
                local ok, rec = pcall(externalRecord, DB, id, area, map)
                if ok and rec then
                    done[id] = true
                    list[#list + 1] = rec
                end
            end
        end
    end
    local skipped = 0
    for id in pairs(tried) do if not done[id] then skipped = skipped + 1 end end
    return list, skipped
end

function A.externalVendors(mapIds)
    local DB = NorgannonDB
    if type(DB) ~= "table" then return end
    if type(DB.RequireSchema) ~= "function" then return nil, "unsupported" end
    if not call("NorgannonDB.RequireSchema", DB.RequireSchema, DB, 1, 4) then return nil, "unsupported" end
    local ok, list, skipped = pcall(scanExternal, DB, mapIds)
    if not ok or not list then return nil, "unsupported" end
    local v = type(DB.schema) == "table" and DB.schema
    return list, skipped, v and (tostring(v.major) .. "." .. tostring(v.minor)) or "?"
end

-- Profession trainers from NorgannonDB (optional) whose title tells the highest tier they teach
-- (Professions.TitleTier). Their professions come from the recipes each one teaches (skill line ids),
-- named with NorgannonDB's profession names in the player's language. A list of trainer records
-- { id, name, uiMapID, x, y, faction, trades = { [profession] = tier } }, or nil when NorgannonDB is
-- missing, too old or unreadable. Reads with Peek and keeps nothing of NorgannonDB's own tables.
local function scanTrainers(DB)
    local trainers = type(DB.categories) == "table" and type(DB.categories.trainer) == "table" and DB.categories.trainer.npcs
    if type(trainers) ~= "table" or type(DB.recipes) ~= "table" then return end
    local skills = {}
    for _, r in pairs(DB.recipes) do
        if type(r) == "table" and type(r.trainers) == "table" and type(r.skill) == "number" then
            for npc in pairs(r.trainers) do
                if trainers[npc] then skills[npc] = skills[npc] or {}; skills[npc][r.skill] = true end
            end
        end
    end
    local list = {}
    for id, set in pairs(skills) do
        local r = DB:Peek("npcs", id)
        local tier = type(r) == "table" and ns.Professions.TitleTier(r.subName)
        if tier and type(r.spawns) == "table" then
            for area, spots in pairs(r.spawns) do
                local zone = type(DB.zones) == "table" and DB.zones[area]
                local map = type(zone) == "table" and zone.uiMapId
                local s = type(spots) == "table" and spots[1]
                local x, y = type(s) == "table" and s[1], type(s) == "table" and s[2]
                if map and type(x) == "number" and type(y) == "number" and x > 0 and y > 0 and x <= 100 and y <= 100 then
                    local trades = {}
                    for skill in pairs(set) do
                        local name = DB:L("professions", skill)
                        if type(name) == "string" then trades[name] = tier end
                    end
                    local name = DB:L("npcs", id, "name")
                    list[#list + 1] = { id, type(name) == "string" and name or r.name, map, x / 100, y / 100, REACTION_FACTION[r.reaction] or 0, trades }
                    break
                end
            end
        end
    end
    return list
end

function A.externalTrainers()
    local DB = NorgannonDB
    if type(DB) ~= "table" or type(DB.RequireSchema) ~= "function" or type(DB.L) ~= "function" then return end
    if not call("NorgannonDB.RequireSchema", DB.RequireSchema, DB, 1, 4) then return end
    local ok, list = pcall(scanTrainers, DB)
    return ok and list or nil
end

-- Whether the player can trade with unit: true at Neutral or better, false at Unfriendly or Hostile,
-- nil when the game does not say.
function A.canTrade(unit)
    local reaction = call("UnitReaction", UnitReaction, unit, "player")
    if type(reaction) ~= "number" then return nil end
    return reaction >= 4
end

-- The merchant window that just opened: { id, name, faction, repair, ammo, reagents, supplies, partial }, or nil if
-- the merchant cannot be identified as a creature.
function A.merchant()
    local id, name = A.npc()
    if not id then return end
    local ammo, reagents, supplies, partial = merchantScan()
    return { id = id, name = name, faction = A.factionId("npc"),
             repair = call("CanMerchantRepair", CanMerchantRepair) and true or false, ammo = ammo, reagents = reagents,
             supplies = supplies, partial = partial }
end

-- Class reagents -------------------------------------------------------------------------------

-- The player's class token ("MAGE"), or nil.
function A.classToken()
    local _, token = call("UnitClass", UnitClass, "player")
    return type(token) == "string" and token or nil
end

-- True or false whether the player knows the spell; nil when the game cannot say.
function A.knowsSpell(id)
    local f = IsPlayerSpell or IsSpellKnown
    local known = call("IsPlayerSpell", f, id)
    if known == nil then return nil end
    return known and true or false
end

-- How many of the item the player carries (bags included); nil when unknown.
function A.itemCount(id) return itemCount(id) end

-- The game's name for an item, or nil when it is not cached yet.
function A.itemName(id)
    local name = call("GetItemInfo", (C_Item and C_Item.GetItemInfo) or GetItemInfo, id)
    return type(name) == "string" and name or nil
end

-- Buying ammo -----------------------------------------------------------------------------------

local AMMO_FAMILY = { arrow = 1, bullet = 2 } -- bag family bits of a quiver and an ammo pouch

local uncached = {} -- item ids read since A.resetItemData that the game had not loaded; see A.missingItems

local function itemInfo(item)
    return call("GetItemInfo", (C_Item and C_Item.GetItemInfo) or GetItemInfo, item)
end

-- One merchant line: name, price per purchase, items per purchase, stock (-1 unlimited), paid with
-- more than gold. Newer clients return a table from C_MerchantFrame.GetItemInfo, Classic Era
-- returns values from GetMerchantItemInfo: name, texture, price, quantity, numAvailable, then either
-- isUsable, extendedCost (7 values) or isPurchasable, isUsable, extendedCost, ... (8 or more), so the
-- extended cost is found by the number of values.
local function merchantItem(i)
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local t = call("C_MerchantFrame.GetItemInfo", C_MerchantFrame.GetItemInfo, i)
        if type(t) == "table" then
            return t.name, t.price, t.stackCount, t.numAvailable, t.hasExtendedCost
        end
    end
    local r = { n = 0 }
    local function pack(...) r = { n = select("#", ...), ... } end
    pack(call("GetMerchantItemInfo", GetMerchantItemInfo, i))
    return r[1], r[3], r[4], r[5], r[r.n >= 8 and 8 or 7]
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
                if type(minLevel) ~= "number" then minLevel = nil; uncached[id] = true end
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
    -- Called directly so a missing or failing function (unknown) is not taken for an empty slot.
    if type(f) ~= "function" then fail("GetContainerItemInfo", "missing") return end
    local ok, a, b = pcall(f, bag, slot)
    if not ok then fail("GetContainerItemInfo", a) return end
    if type(a) == "table" then return a.itemID and { a.itemID, a.stackCount or 1 } or false end
    if a == nil then return false end
    local id = call("GetContainerItemID", (C_Container and C_Container.GetContainerItemID) or GetContainerItemID, bag, slot)
    return id and { id, b or 1 } or nil
end

-- Room, in items, in the carried quivers or ammo pouches of this kind for item `id`; nil if unknown.
function A.ammoSpace(id, kind)
    local stack = select(8, itemInfo(id))
    if type(stack) ~= "number" then uncached[id] = true end
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

-- Buy one purchase (one batch) of merchant item `index`, or `quantity` single items of it.
-- The item id at a slot of the open merchant window, or nil (no merchant open, or no data).
function A.merchantItemId(index)
    local link = call("GetMerchantItemLink", GetMerchantItemLink, index)
    return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

function A.buyMerchantItem(index, quantity)
    if quantity then call("BuyMerchantItem", BuyMerchantItem, index, quantity)
    else call("BuyMerchantItem", BuyMerchantItem, index) end
end

-- Buying reagents -------------------------------------------------------------------------------

-- The open merchant's class reagents (vendor-sold reagents of the Reagents table, never display-only
-- items): list of { index, id, name, price, batch, stock, maxBuy }. maxBuy is how many single items one
-- purchase may take (GetMerchantItemMaxStack), nil when unknown. Items paid with more than gold are
-- left out. nil when the merchant list cannot be read.
function A.merchantReagents()
    local count = call("GetMerchantNumItems", GetMerchantNumItems)
    if not count then return end
    local list = {}
    for i = 1, count do
        local link = call("GetMerchantItemLink", GetMerchantItemLink, i)
        local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
        if id and ns.Reagents.ById(id) then
            local name, price, batch, stock, extended = merchantItem(i)
            if price and not extended then
                local maxBuy = GetMerchantItemMaxStack and call("GetMerchantItemMaxStack", GetMerchantItemMaxStack, i)
                list[#list + 1] = { index = i, id = id, name = name or tostring(id), price = price, batch = batch or 1,
                    stock = stock, maxBuy = type(maxBuy) == "number" and maxBuy or nil }
            end
        end
    end
    return list
end

-- Every slot of the general-purpose bags, backpack included (quivers, ammo pouches and other special
-- bags cannot hold class reagents and are left out): false if empty, { id, count } if filled. A bag
-- whose kind cannot be read is left out (less room, never more); nil when the backpack or any slot of
-- a general bag cannot be read.
function A.bagSlots()
    local slots = {}
    for bag = 0, NUM_BAG_SLOTS or 4 do
        local _, family = bagFree(bag)
        if family == nil and bag == 0 then return end
        if family == 0 then
            local n = call("GetContainerNumSlots", (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots, bag)
            if not n then return end
            for slot = 1, n do
                local s = bagSlot(bag, slot)
                if s == nil then return end
                slots[#slots + 1] = s
            end
        end
    end
    return slots
end

-- The active pet's diets as a set ({ Meat = true, Fish = true }), or nil when there is no pet, the call is
-- missing or fails, or the family is unknown. The pet is identified by the creature family id that
-- UnitCreatureFamily returns after the name, so no localized text is read; Supplies maps the id to diets.
function A.petDiet()
    if type(UnitCreatureFamily) ~= "function" then fail("UnitCreatureFamily", "missing") return end
    local ok, name, id = pcall(UnitCreatureFamily, "pet")
    if not ok then fail("UnitCreatureFamily", name) return end
    if type(id) ~= "number" then return end
    return ns.Supplies.FamilyDiets(id)
end

-- Play a game sound by id (PlaySound), or, when file is true, a sound file by path or file id
-- (PlaySoundFile). A missing or failing call is reported once and skipped.
function A.playSound(id, file)
    if file then
        if type(id) == "string" or type(id) == "number" then call("PlaySoundFile", PlaySoundFile, id) end
    elseif type(id) == "number" then call("PlaySound", PlaySound, id) end
end

-- LibSharedMedia-3.0 when another addon provides it (Closest Vendor does not ship it), else nil.
local function sharedMedia()
    if LibStub == nil then return end
    local ok, lib = pcall(LibStub, "LibSharedMedia-3.0", true)
    if ok and type(lib) == "table" then return lib end
end

-- Sorted names of the sounds other addons share (case ignored, "None" left out), or nil.
function A.mediaSounds()
    local lib = sharedMedia()
    if not lib then return end
    local ok, hash = pcall(lib.HashTable, lib, "sound")
    if not ok or type(hash) ~= "table" then return end
    local names = {}
    for name in pairs(hash) do
        if type(name) == "string" and name ~= "None" then names[#names + 1] = name end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

-- The file of a shared sound by name, or nil when it is not shared now.
function A.mediaSound(name)
    local lib = sharedMedia()
    if not lib then return end
    local ok, path = pcall(lib.Fetch, lib, "sound", name, true)
    if ok and (type(path) == "string" or type(path) == "number") then return path end
end

-- How many of each supply item (food, drink, healthstone, pet food) the general bags hold:
-- { [itemId] = count }, only for ids in the supply table; nil when any bag slot cannot be read.
function A.supplyCounts()
    local slots = A.bagSlots()
    if not slots then return end
    local counts = {}
    for _, s in ipairs(slots) do
        if s and ns.Supplies.ItemMask(s[1]) ~= 0 then counts[s[1]] = (counts[s[1]] or 0) + s[2] end
    end
    return counts
end

-- How many of the item fit in one bag slot, or nil when unknown (item not cached).
function A.stackSize(id)
    local stack = select(8, itemInfo(id))
    if type(stack) == "number" then return stack end
    uncached[id] = true
    return nil
end

-- The item ids a read since A.resetItemData found not loaded yet (a set), or nil when there were none.
-- The game loads them in the background and then fires GET_ITEM_INFO_RECEIVED with the item id.
function A.missingItems() return next(uncached) ~= nil and uncached or nil end
function A.resetItemData() uncached = {} end

-- Misc -------------------------------------------------------------------------------------------

-- Seconds since the game started, for timestamping log entries.
function A.now()
    return call("GetTime", GetTime) or 0
end

-- Run fn after seconds; returns false if timers are unavailable or the call failed (then fn never runs).
function A.after(seconds, fn)
    if not (C_Timer and C_Timer.After) then return false end
    return call("C_Timer.After", function() C_Timer.After(seconds, fn) return true end) == true
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

-- Choice menu ------------------------------------------------------------------------------

function A.hasMenu()
    if MenuUtil and type(MenuUtil.CreateContextMenu) == "function" then return true end
    return type(UIDropDownMenu_Initialize) == "function" and type(UIDropDownMenu_CreateInfo) == "function"
        and type(UIDropDownMenu_AddButton) == "function" and type(ToggleDropDownMenu) == "function"
        and type(CreateFrame) == "function"
end

local menuFrame
-- An item's menu text: its icon in front when it has one.
local function menuText(item)
    return item.icon and ("|T%s:16|t %s"):format(tostring(item.icon), item.text) or item.text
end

-- Shows a menu at anchor: a title, then items { text, checked, func, icon }. Choosing one runs its
-- func. anchor "cursor" opens it at the mouse pointer. Tries MenuUtil, then the classic dropdown;
-- true when one was shown.
function A.menu(anchor, title, items)
    if MenuUtil and type(MenuUtil.CreateContextMenu) == "function" then
        local owner = anchor == "cursor" and UIParent or anchor
        local ok = pcall(MenuUtil.CreateContextMenu, owner, function(_, root)
            root:CreateTitle(title)
            for _, item in ipairs(items) do
                root:CreateRadio(menuText(item), function() return item.checked end, function() item.func() end)
            end
        end)
        if ok then return true end
    end
    if not A.hasMenu() or type(UIDropDownMenu_Initialize) ~= "function" then return false end
    return (pcall(function()
        menuFrame = menuFrame or CreateFrame("Frame", "ClosestVendorChoiceMenu", UIParent, "UIDropDownMenuTemplate")
        UIDropDownMenu_Initialize(menuFrame, function(_, level)
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.isTitle, info.notCheckable = title, true, true
            UIDropDownMenu_AddButton(info, level)
            for _, item in ipairs(items) do
                info = UIDropDownMenu_CreateInfo()
                info.text, info.checked, info.func, info.notCheckable = menuText(item), item.checked, item.func, false
                UIDropDownMenu_AddButton(info, level)
            end
        end, "MENU")
        ToggleDropDownMenu(1, nil, menuFrame, anchor, 0, 0)
    end))
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
