-- Glue between the game and the pure modules. Game state is read only through ns.Adapter;
-- this file owns events, saved settings, the question dialog and the slash command.
local ADDON, ns = ...
local A = ns.Adapter
local L = ns.L

local DEFAULTS = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10,
    bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true,
    ammoBuyEnabled = true, ammoBuyPrompt = false, arrowGrade = "equipped", bulletGrade = "equipped",
    vendorMode = "ask", vendorPrefer = "map" }
local POLL_SECONDS = 5

local POPUP = "CLOSESTVENDOR_CONFIRM"
-- The question text is passed whole as the first argument, so "%" in vendor names is safe.
if StaticPopupDialogs then
    StaticPopupDialogs[POPUP] = {
        text = "%s",
        button1 = YES or "Yes",
        button2 = NO or "No",
        OnAccept = function(_, accept) if accept then accept() end end,
        timeout = 0,
        whileDead = false,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- The two-target question: Cancel plus one button per target. Two copies so the preferred target
-- is always the first button.
local POPUP_MAP, POPUP_DIST = "CLOSESTVENDOR_CONFIRM_MAP", "CLOSESTVENDOR_CONFIRM_DISTANCE"
if StaticPopupDialogs then
    local function threeWay(first, second)
        return {
            text = "%s",
            button1 = first,
            button3 = second,
            button2 = CANCEL or "Cancel",
            OnAccept = function(_, data) if data and data.accept then data.accept() end end,
            OnAlt = function(_, data) if data and data.alt then data.alt() end end,
            timeout = 0,
            whileDead = false,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopupDialogs[POPUP_MAP] = threeWay(L["This map"], L["Closest"])
    StaticPopupDialogs[POPUP_DIST] = threeWay(L["Closest"], L["This map"])
end

local function closeQuestions()
    A.hidePopup(POPUP); A.hidePopup(POPUP_MAP); A.hidePopup(POPUP_DIST)
end

local DB, controller, timerArmed, panel, log
local buckets, trainerBuckets = {}, {}

-- Print to chat. "|" starts an escape code in chat, so it is doubled in the text.
local function say(text)
    print("|cff33ffccClosestVendor|r " .. (text:gsub("|", "||")))
end

-- What ns.Ammo needs when a merchant opens: all game reads and the purchase go through the Adapter.
local AMMO_ENV = {
    kind = function() return (A.ammoStatus()) end,
    equippedID = A.equippedAmmoID,
    level = A.level,
    offers = A.merchantAmmo,
    money = A.money,
    space = A.ammoSpace,
    buy = A.buyMerchantItem,
    say = say,
    log = function(text) if log then log.Add(text) end end,
    confirm = function(text, accept) A.showPopup(POPUP, text, accept) end,
}

-- Failures of guarded game calls go to the debug log (once per kind of failure).
A.onError = function(name, err)
    if log then log.Add("game call failed: " .. name .. ": " .. err) end
end

-- Shipped + learned vendors, converted to world coordinates once and bucketed by continent.
local function rebuildBuckets()
    for k in pairs(buckets) do buckets[k] = nil end
    local list = ns.Discovery.Merge(ns.ShippedVendors or {}, DB.learned)
    for _, r in ipairs(list) do
        local continent, wx, wy = A.toWorld(r[3], r[4], r[5])
        if continent then
            local b = buckets[continent]
            if not b then b = {}; buckets[continent] = b end
            b[#b + 1] = { r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8] or 0, wx, wy }
        end
    end
end

-- Learned profession trainers, converted to world coordinates and bucketed by continent.
local function rebuildTrainers()
    for k in pairs(trainerBuckets) do trainerBuckets[k] = nil end
    for _, t in pairs(DB.trainers) do
        local continent, wx, wy = A.toWorld(t[3], t[4], t[5])
        if continent then
            local b = trainerBuckets[continent]
            if not b then b = {}; trainerBuckets[continent] = b end
            b[#b + 1] = { t[1], t[2], t[3], t[4], t[5], t[6], t[7], wx, wy }
        end
    end
end

local function evaluate()
    if not controller then return end
    controller.Evaluate()
    -- Re-check later only while a request is waiting for a map position.
    if controller.pending and not timerArmed then
        if A.after(POLL_SECONDS, function() timerArmed = false; evaluate() end) then timerArmed = true end
    end
end

-- Remember the merchant that just opened (position is the player's, within interaction range).
local function learnMerchant()
    local m = A.merchant()
    if not m then return end
    local map, x, y = A.mapPosition()
    if not map then return end
    if ns.Discovery.Record(DB.learned, { m.id, m.name, map, x, y, m.faction, m.repair, m.ammo }) then
        rebuildBuckets()
    end
end

-- Remember the profession trainer whose window just opened, and the professions it teaches.
-- Returns the set of those professions, or nil if this is not a profession trainer.
local function learnTrainer()
    local t = A.trainer()
    if not t then return end
    local set = {}
    for _, name in ipairs(t.trades) do DB.professions[name] = true; set[name] = true end
    local map, x, y = A.mapPosition()
    if map and ns.Discovery.RecordTrainer(DB.trainers, { t.id, t.name, map, x, y, t.faction }, t.trades) then
        rebuildTrainers()
    end
    return set
end

local function init()
    ClosestVendorDB = ClosestVendorDB or {}
    DB = ClosestVendorDB
    DB.cfg = DB.cfg or {}
    for k, v in pairs(DEFAULTS) do if DB.cfg[k] == nil then DB.cfg[k] = v end end
    DB.learned = DB.learned or {}
    DB.trainers = DB.trainers or {}
    DB.professions = DB.professions or {}
    DB.log = DB.log or {}
    log = ns.Log.New(DB.log, A.now)
end

-- The report: facts about this client and addon, then the debug log.
local function reportText()
    local info = A.clientInfo()
    local learned, continents = 0, {}
    local trainers, professions = 0, {}
    for _ in pairs(DB.learned) do learned = learned + 1 end
    for _ in pairs(DB.trainers) do trainers = trainers + 1 end
    for name in pairs(DB.professions) do professions[#professions + 1] = name end
    table.sort(professions)
    for id, b in pairs(buckets) do continents[#continents + 1] = id .. ":" .. #b end
    table.sort(continents)
    local c = DB.cfg
    local header = {
        "addon version: " .. tostring(info.addon),
        "game: " .. tostring(info.gameVersion) .. " build " .. tostring(info.build) .. ", interface " .. tostring(info.interface),
        "locale: " .. tostring(info.locale),
        "navigation: " .. tostring(ns.Nav.Select(A.navApi(say))),
        ("vendors: %d shipped, %d learned, per continent: %s"):format(#(ns.ShippedVendors or {}), learned, table.concat(continents, " ")),
        ("settings: bags %s/%d, durability %s/%d, ammo %s/%d, professions %s/%d"):format(c.bagEnabled and "on" or "off", c.bagThreshold,
            c.durEnabled and "on" or "off", c.durThreshold, c.ammoEnabled and "on" or "off", c.ammoThreshold,
            c.tradeEnabled and "on" or "off", c.tradeThreshold),
        ("ammo buying: %s, %s, arrows %s, bullets %s"):format(c.ammoBuyEnabled and "on" or "off",
            c.ammoBuyPrompt and "asks first" or "buys at once", tostring(c.arrowGrade), tostring(c.bulletGrade)),
        ("target choice: %s, prefers %s"):format(tostring(c.vendorMode), tostring(c.vendorPrefer)),
        ("trainers: %d learned, professions seen: %s"):format(trainers, table.concat(professions, ", ")),
    }
    return ns.Log.Report(header, log.Entries(), log.Enabled()), header
end

local function showReport()
    local text, header = reportText()
    if pcall(ns.Report.Show, text) then return end
    -- No window: the header and the newest entries go to chat instead.
    for _, line in ipairs(header) do say(line) end
    for _, line in ipairs(ns.Log.Format(log.Entries(), 20)) do say(line) end
end

local function start()
    log.Add("---- login ----")
    rebuildBuckets()
    rebuildTrainers()
    local nav = { Set = function(v) return ns.Nav.Set(A.navApi(say), v) end,
                  Clear = function(h) ns.Nav.Clear(A.navApi(say), h) end }
    controller = ns.Controller.New({
        cfg = DB.cfg,
        log = function(msg) log.Add(msg) end,
        freeSlots = A.freeSlots,
        lowestDurability = A.lowestDurability,
        inCombat = A.inCombat,
        playerPos = A.playerWorldPos,
        playerFaction = A.factionId("player"),
        buckets = buckets,
        nav = nav,
        ammo = A.ammoStatus,
        confirm = function(kind, v, accept, count, trade, two)
            closeQuestions() -- one question is open at a time, whichever kind it is
            if not two then
                A.showPopup(POPUP, ns.Controller.PromptText(kind, v, A.mapName(v[3]), count, trade), accept)
                return
            end
            local text = ns.Controller.PromptText(kind, v, A.mapName(v[3]), count, trade, two, A.mapName(two.other[3]))
            A.showPopup(two.mapFirst and POPUP_MAP or POPUP_DIST, text, { accept = accept, alt = two.acceptOther })
        end,
        cancelConfirm = closeQuestions,
        questionOpen = function() return A.popupShown(POPUP) or A.popupShown(POPUP_MAP) or A.popupShown(POPUP_DIST) end,
        skills = A.skills,
        known = DB.professions,
        trainerBuckets = trainerBuckets,
        say = say,
    })
    -- The settings page is optional: if the client's settings API differs, only the page is lost.
    local ok, category = pcall(ns.Options.Register, DB.cfg, DEFAULTS, evaluate)
    panel = ok and category or nil
end

SLASH_CLOSESTVENDOR1 = "/cvn"
SLASH_CLOSESTVENDOR2 = "/closestvendor"
SlashCmdList["CLOSESTVENDOR"] = function(msg)
    if not DB then return end
    local lines, action = ns.Commands.Run(DB.cfg, msg)
    for _, line in ipairs(lines) do say(line) end
    if action and action[1] == "open" then
        if panel and pcall(ns.Options.Open, panel) then return end
        say(L["The settings page is not available here; use the commands above."])
        return
    end
    if action and action[1] == "debug" then
        log.SetEnabled(action[2])
        log.Add(action[2] and "debug log turned on" or "debug log turned off")
        return
    end
    if action and action[1] == "log" then
        if action[2] == "clear" then log.Clear() else showReport() end
        return
    end
    if action and action[1] == "test" then
        local problem = controller and controller.Test(action[2])
        if problem then say(problem) end
        return
    end
    evaluate() -- a changed threshold may apply right away
end

ns.frame = CreateFrame("Frame")
ns.frame:SetScript("OnEvent", function(_, event, arg1)
    if (event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_SPELLCAST_SUCCEEDED") and arg1 ~= "player" then return end
    if log and (event ~= "ADDON_LOADED" or arg1 == ADDON) then
        log.Add("event " .. event .. (arg1 ~= nil and (" " .. tostring(arg1)) or ""))
    end
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then init() end
    elseif event == "PLAYER_LOGIN" then
        start()
    elseif event == "MERCHANT_SHOW" then
        if DB then learnMerchant() end
        if controller then controller.OnMerchantShow() end
        if DB then ns.Ammo.OnMerchant(DB.cfg, AMMO_ENV) end
    elseif event == "TRAINER_SHOW" or event == "TRAINER_UPDATE" then
        local trades = DB and learnTrainer()
        if trades and controller then controller.OnTrainerShow(trades) end
    elseif event == "SKILL_LINES_CHANGED" then
        if controller then controller.OnSkillChange() end
    elseif event == "TRADE_SKILL_SHOW" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- A craft is a successful cast while a tradeskill or craft window is open.
        local name = DB and A.craftProfession()
        if name then
            DB.professions[name] = true
            if event == "UNIT_SPELLCAST_SUCCEEDED" and controller then controller.OnCraft() end
        end
    else
        evaluate()
    end
end)
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA",
        "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED",
        "PLAYER_REGEN_ENABLED", "MERCHANT_SHOW", "TRAINER_SHOW", "TRAINER_UPDATE", "SKILL_LINES_CHANGED",
        "TRADE_SKILL_SHOW", "UNIT_SPELLCAST_SUCCEEDED" }) do
    ns.frame:RegisterEvent(e)
end
