-- Glue between the game and the pure modules. Game state is read only through ns.Adapter;
-- this file owns events, saved settings, the question dialog and the slash command.
local ADDON, ns = ...
local A = ns.Adapter
local L = ns.L

local DEFAULTS = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, tradeThreshold = 10,
    bagEnabled = true, durEnabled = true, ammoEnabled = true, tradeEnabled = true, suppliesEnabled = true, reagentsEnabled = true,
    ammoBuyEnabled = true, ammoBuyPrompt = false, arrowGrade = "equipped", bulletGrade = "equipped",
    vendorMode = "ask", vendorPrefer = "map", autoNotice = true, reagentThreshold = 5,
    -- Reagent buying: off until the player turns it on, asks first, stocks up to 20 of each.
    reagentBuyEnabled = false, reagentBuyPrompt = true, reagentBuyTarget = 20,
    -- Status window: scale, background opacity (0 draws no background) and text and icon opacity are
    -- percentages; the background colour is "rrggbb", pure black unless the player chooses another.
    -- Row group modes are in cfg.hudRow (see init).
    hudLocked = false, hudScale = 100, hudAlpha = 80, hudTextAlpha = 100, hudColor = "000000",
    instanceAnchor = "hearth", ahEnabled = false,
    -- Supplies: each switch is on, each threshold 5 (see Supplies.lua). suppliesEnabled is their master switch (the ammo switch does not affect them); each also has its own.
    foodEnabled = true, waterEnabled = true, petFoodEnabled = true, healthstoneRemind = true,
    foodThreshold = 5, waterThreshold = 5, petFoodThreshold = 5, remindSound = "whisper", navProvider = "auto" }
local POLL_SECONDS = 5
local WINDOW_DELAY = 0.25 -- one redraw of the status window this long after the first change

local POPUP = "CLOSESTVENDOR_CONFIRM"
-- The ammo and reagent purchase questions have dialogs of their own, so they show side by side at
-- the same merchant, never replace a route question, and close with the merchant window.
local POPUP_AMMO, POPUP_REAGENTS = "CLOSESTVENDOR_CONFIRM_AMMO", "CLOSESTVENDOR_CONFIRM_REAGENTS"
-- The question text is passed whole as the first argument, so "%" in vendor names is safe.
if StaticPopupDialogs then
    for _, which in ipairs({ POPUP, POPUP_AMMO, POPUP_REAGENTS, "CLOSESTVENDOR_SAMPLE", "CLOSESTVENDOR_CLEAR_LOG" }) do
        StaticPopupDialogs[which] = {
            text = "%s",
            button1 = YES or "Yes",
            button2 = NO or "No",
            -- data is the Yes function, or { accept, decline } for a route question.
            OnAccept = function(_, data)
                local accept = type(data) == "table" and data.accept or data
                if type(accept) == "function" then accept() end
            end,
            -- No or Escape (not a question replaced or withdrawn) is an answer.
            OnCancel = function(_, data, reason)
                if reason == "clicked" and type(data) == "table" and data.decline then data.decline() end
            end,
            timeout = which == "CLOSESTVENDOR_SAMPLE" and 10 or 0,
            whileDead = false,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
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
            OnCancel = function(_, data, reason)
                if reason == "clicked" and data and data.decline then data.decline() end
            end,
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

local DB, CHAR, controller, timerArmed, panel, log, runMerchantParts
local colorNote = "not registered" -- what Options said about the background colour control
local buckets, trainerBuckets, auctionBuckets = {}, {}, {}
local tracker, toast, sampleToast, windowDirty, skillCache, playerClass
local sampleToken, sampleKind = 0, nil

-- Print to chat. "|" starts an escape code in chat, so it is doubled in the text.
local function say(text)
    print("|cff33ffccClosestVendor|r " .. (text:gsub("|", "||")))
end

-- A merchant visit reads item data the game may not have loaded yet. A part (ammo, reagents) that
-- stopped for that, and asked and bought nothing, is run again when the game says the data arrived
-- (GET_ITEM_INFO_RECEIVED for one of the missing items), a few times at most; closing the merchant
-- window drops them.
local merchantActed, retryParts, retryItems, retries = false, {}, {}, 0
local MAX_RETRIES = 3

-- What ns.Ammo needs when a merchant opens: all game reads and the purchase go through the Adapter.
local AMMO_ENV = {
    kind = function() return (A.ammoStatus()) end,
    equippedID = A.equippedAmmoID,
    level = A.level,
    offers = A.merchantAmmo,
    money = A.money,
    space = A.ammoSpace,
    buy = function(...) merchantActed = true; return A.buyMerchantItem(...) end,
    say = say,
    log = function(text) if log then log.Add(text) end end,
    confirm = function(text, accept) merchantActed = true; A.showPopup(POPUP_AMMO, text, accept) end,
    sells = A.merchantItemId,
}

-- Failures of guarded game calls go to the debug log (once per kind of failure).
A.onError = function(name, err)
    if log then log.Add("game call failed: " .. name .. ": " .. err) end
end

-- The optional NorgannonDB addon, read for vendors on the maps that are only in WoW Forever (Mount
-- Hyjal, Riverglades, Shen'dralas, Zephras Isle and the Darkspear Islands), and for profession
-- trainers whose title tells which tier they teach, on every map. Read after login, and again if
-- NorgannonDB finishes loading later; never on bag, merchant or movement events.
local EXTERNAL_MAPS = { [2482] = true, [2548] = true, [2652] = true, [2521] = true, [2665] = true, [2524] = true }
local external = { list = {}, skipped = 0, trainers = {}, trainerIds = {} }
local started = false

local function readExternal()
    local list, skipped, schema = A.externalVendors(EXTERNAL_MAPS)
    external = { list = list or {}, skipped = list and skipped or 0, schema = schema, unsupported = skipped == "unsupported",
                 trainers = list and A.externalTrainers() or {}, trainerIds = {} }
    for _, e in ipairs(external.trainers) do external.trainerIds[e[1]] = true end
end

-- Trainer tiers are known (NorgannonDB gave trainers with titles), so Artisan is routed too.
local function trainerTiers() return #external.trainers > 0 end

-- Shipped, NorgannonDB and learned vendors, converted to world coordinates once and bucketed by continent.
local vendorIds = {} -- every npc id in the search pool, before the trade filter
local function rebuildBuckets()
    for k in pairs(buckets) do buckets[k] = nil end
    local known = {}
    for _, v in ipairs(ns.ShippedVendors or {}) do known[v[1]] = true end
    for _, v in ipairs(external.list) do known[v[1]] = true end
    local pool = ns.Discovery.Pool(ns.ShippedVendors or {}, external.list, DB.learned)
    vendorIds = {}
    for _, r in ipairs(pool) do vendorIds[r[1]] = true end
    local list = ns.Discovery.Tradable(pool, known, CHAR.standing)
    for _, r in ipairs(list) do
        local continent, wx, wy = A.toWorld(r[3], r[4], r[5])
        if continent then
            local b = buckets[continent]
            if not b then b = {}; buckets[continent] = b end
            b[#b + 1] = { r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8] or 0, wx, wy, r[9] or 0, r[10] or 0 }
        end
    end
end

-- Learned profession trainers, converted to world coordinates and bucketed by continent.
-- Learned trainers (where the player stood, each profession's tier not known) and NorgannonDB's
-- (with the tier its title gives). For a trainer in both, the learned position and professions are
-- kept and NorgannonDB's tiers fill them in.
local function rebuildTrainers()
    for k in pairs(trainerBuckets) do trainerBuckets[k] = nil end
    local all = {}
    for id, t in pairs(DB.trainers) do all[id] = t end
    for _, e in ipairs(external.trainers) do
        local t = all[e[1]]
        if t then
            local trades = {}
            for name, v in pairs(t[7]) do trades[name] = v end
            for name, tier in pairs(e[7]) do trades[name] = tier end
            all[e[1]] = { t[1], t[2], t[3], t[4], t[5], t[6], trades }
        else
            all[e[1]] = e
        end
    end
    for _, t in pairs(all) do
        local continent, wx, wy = A.toWorld(t[3], t[4], t[5])
        if continent and CHAR.standing[t[1]] ~= false then -- not one seen refusing this character
            local b = trainerBuckets[continent]
            if not b then b = {}; trainerBuckets[continent] = b end
            b[#b + 1] = { t[1], t[2], t[3], t[4], t[5], t[6], t[7], wx, wy }
        end
    end
end

-- Shipped + learned auctioneers, in the vendor record shape (no repair, no ammo), bucketed by continent.
local auctionIds = {}
local function rebuildAuctioneers()
    for k in pairs(auctionBuckets) do auctionBuckets[k] = nil end
    auctionIds = {}
    for _, r in ipairs(ns.Discovery.Merge(ns.ShippedAuctioneers or {}, DB.auctioneers)) do
        auctionIds[r[1]] = true
        local continent, wx, wy = A.toWorld(r[3], r[4], r[5])
        if continent and CHAR.standing[r[1]] ~= false then -- not one seen refusing this character
            local b = auctionBuckets[continent]
            if not b then b = {}; auctionBuckets[continent] = b end
            b[#b + 1] = { r[1], r[2], r[3], r[4], r[5], r[6], nil, 0, wx, wy }
        end
    end
end

-- Notes where the player is: logs a change of instance, and while in the open world with a position
-- keeps it as CHAR.lastOutside { continent, map, x, y } (world x,y). Never updated inside an instance.
local lastInstance = "none"
local function trackPlace()
    local inst = A.instanceType() or "none" -- unknown is treated as the open world
    if inst ~= lastInstance then
        log.Add("instance: " .. lastInstance .. " -> " .. inst)
        lastInstance = inst
    end
    if inst ~= "none" then return end
    local continent, x, y, map = A.playerWorldPos()
    if not continent then return end
    local o = CHAR.lastOutside
    if not o then o = {}; CHAR.lastOutside = o end
    o.continent, o.map, o.x, o.y = continent, map, x, y
end

-- The hearthstone point, CHAR.hearth { name, continent, map, x, y }: the game gives only the name of
-- the bind location, so when that name changes the player's position is taken as the point. The
-- first name seen is kept without a position: that hearthstone was bound somewhere else, earlier.
-- Where the player stood when an innkeeper asked to bind the hearthstone (CONFIRM_BINDER): the
-- position of the new point once the bind name changes. A bind the addon did not see keeps the name
-- with no position, never the place the player happens to be when it notices.
local pendingBind
local function noteBinder(area)
    local continent, x, y, map = A.playerWorldPos()
    pendingBind = continent and { area = area, continent = continent, map = map, x = x, y = y } or nil
end
-- An innkeeper question at the inn already saved (same name) gives that inn's position, so a point
-- saved by name only gets one. Not every client fires HEARTHSTONE_BOUND, so a zone change counts too;
-- a question closed without binding there still names the inn the player is bound to.
local function learnHearth()
    local name = A.bindLocation()
    if not name then return end
    local h = CHAR.hearth
    local p = pendingBind
    -- The innkeeper names the place it binds to; a question declined there says nothing about this bind.
    -- A question that named another place is forgotten, so it cannot place a later bind.
    if p and type(p.area) == "string" and p.area ~= name then p, pendingBind = nil, nil end
    if h and h.name == name then
        -- Same name: only a question that named this inn says where it is.
        if not (p and p.area == name) then return end
        pendingBind = nil
        CHAR.hearth = { name = name, continent = p.continent, map = p.map, x = p.x, y = p.y }
        log.Add("hearthstone point learned: " .. name)
        return
    end
    pendingBind = nil
    if h and p then
        CHAR.hearth = { name = name, continent = p.continent, map = p.map, x = p.x, y = p.y }
        log.Add("hearthstone point learned: " .. name)
    else
        CHAR.hearth = { name = name }
        if h then log.Add("hearthstone point changed to " .. name .. "; its position is unknown until you bind at an innkeeper") end
    end
end

-- A saved place for the controller: "hearth" or "last", nil while its position is not known.
local function anchor(which)
    local p
    if which == "hearth" then p = CHAR.hearth else p = CHAR.lastOutside end
    if p and p.continent then return p end
end

local evaluate
local function evaluateNow()
    if not controller then return end
    trackPlace()
    controller.Evaluate()
    -- Re-check later only while a request is waiting for a map position.
    if controller.pending and not timerArmed then
        if A.after(POLL_SECONDS, function() timerArmed = false; evaluate() end) then timerArmed = true end
    end
end
evaluate = evaluateNow

-- Remember the merchant that just opened (position is the player's, within interaction range).
-- A vendor this character can see (target, mouseover, nameplate): remember whether it will trade
-- with this character, and search again when that changed.
local function learnStanding(unit)
    local id = A.npc(unit)
    -- Vendors, trainers and auctioneers: a goblin auction house or a neutral trainer refuses a
    -- character Unfriendly with its faction, like a vendor does.
    local trainer, auctioneer = DB.trainers[id] ~= nil or external.trainerIds[id] == true, auctionIds[id]
    if not id or not (vendorIds[id] or trainer or auctioneer) then return end
    local can = A.canTrade(unit)
    if can == nil or CHAR.standing[id] == can then return end
    CHAR.standing[id] = can
    log.Add(("standing: npc %d %s"):format(id, can and "will trade" or "will not trade (Unfriendly or Hostile)"))
    if vendorIds[id] then rebuildBuckets() end
    if trainer then rebuildTrainers() end
    if auctioneer then rebuildAuctioneers() end
end
-- A merchant list read before the game loaded every item is read again when item data arrives;
-- until then it never replaces what is already known about that vendor.
local relearnMerchant = false
local function learnMerchant()
    local m = A.merchant()
    if not m then return end
    local changed = CHAR.standing[m.id] ~= true
    CHAR.standing[m.id] = true -- its window opened: it trades with this character
    relearnMerchant = m.partial
    if m.partial and vendorIds[m.id] then
        log.Add("merchant list not fully loaded: kept what is known about " .. tostring(m.name))
        if changed then rebuildBuckets() end
        return
    end
    local map, x, y = A.mapPosition()
    if not map then return end
    if ns.Discovery.Record(DB.learned, { m.id, m.name, map, x, y, m.faction, m.repair, m.ammo, m.reagents, m.supplies }) or changed then
        rebuildBuckets()
    end
end

-- Remember the profession trainer whose window just opened, and the professions it teaches.
-- Returns the set of those professions, or nil if this is not a profession trainer.
local function learnTrainer()
    local t = A.trainer()
    if not t then return end
    local set = {}
    for _, name in ipairs(t.trades) do CHAR.professions[name] = true; set[name] = true end
    local changed = CHAR.standing[t.id] ~= true
    CHAR.standing[t.id] = true -- its window opened: it trains this character
    local map, x, y = A.mapPosition()
    if (map and ns.Discovery.RecordTrainer(DB.trainers, { t.id, t.name, map, x, y, t.faction }, t.trades)) or changed then
        rebuildTrainers()
    end
    return set
end

-- Remember the auctioneer whose window just opened (position is the player's).
local function learnAuctioneer()
    local a = A.auctioneer()
    if not a then return end
    local changed = CHAR.standing[a.id] ~= true
    CHAR.standing[a.id] = true -- its window opened: it trades with this character
    local map, x, y = A.mapPosition()
    if (map and ns.Discovery.RecordAuctioneer(DB.auctioneers, { a.id, a.name, map, x, y, a.faction })) or changed then
        rebuildAuctioneers()
    end
end

local function init()
    local existingUser = type(ClosestVendorDB) == "table" or type(ClosestVendorCharDB) == "table"
    ClosestVendorDB = ClosestVendorDB or {}
    DB = ClosestVendorDB -- shared by the account: the vendors, trainers and auctioneers learned
    -- Everything the player sets, and what is true of this character only, is saved per character. A
    -- character met for the first time starts from the settings the account had before they were per
    -- character (left in DB for the next one), or from the defaults.
    local first = ClosestVendorCharDB == nil
    ClosestVendorCharDB = ClosestVendorCharDB or {}
    CHAR = ClosestVendorCharDB
    if first then
        local function copy(v)
            if type(v) ~= "table" then return v end
            local t = {}
            for k, x in pairs(v) do t[k] = copy(x) end
            return t
        end
        if type(DB.cfg) == "table" then CHAR.cfg = copy(DB.cfg) end
        if type(DB.hud) == "table" then CHAR.hud = copy(DB.hud) end
    end
    CHAR.cfg = CHAR.cfg or {}
    -- Reagents once shared the ammo switch; a character saved before they had their own keeps that choice.
    if CHAR.cfg.reagentsEnabled == nil and CHAR.cfg.ammoEnabled ~= nil then CHAR.cfg.reagentsEnabled = CHAR.cfg.ammoEnabled end
    for k, v in pairs(DEFAULTS) do if CHAR.cfg[k] == nil then CHAR.cfg[k] = v end end
    CHAR.cfg.reagentOff = CHAR.cfg.reagentOff or {} -- item ids the player switched off; all others are on
    -- A saved window number outside its range, or a colour that is not one, is put right.
    for _, key in ipairs({ "hudScale", "hudAlpha", "hudTextAlpha", "reagentBuyTarget" }) do
        local v, limits = tonumber(CHAR.cfg[key]), ns.Commands.LIMITS[key]
        CHAR.cfg[key] = v and math.max(limits[1], math.min(limits[2], v)) or DEFAULTS[key]
    end
    if not ns.Status.Color(CHAR.cfg.hudColor) then CHAR.cfg.hudColor = DEFAULTS.hudColor end
    -- Status window group key -> mode, only for groups the player changed. Anything else in it (a key
    -- that is not a group, a mode that is not one) is dropped: it would mean the default anyway.
    if type(CHAR.cfg.hudRow) ~= "table" then CHAR.cfg.hudRow = {} end
    for key, mode in pairs(CHAR.cfg.hudRow) do
        if ns.Status.Group(key) ~= key or not ns.Status.MODES[mode] then CHAR.cfg.hudRow[key] = nil end
    end
    if ns.Presentation then ns.Presentation.Migrate(CHAR.cfg, existingUser) end
    CHAR.toast = type(CHAR.toast) == "table" and CHAR.toast or {}
    CHAR.hud = CHAR.hud or {} -- where the status window was dragged to; empty means its default place
    DB.learned = DB.learned or {}
    DB.auctioneers = DB.auctioneers or {}
    DB.trainers = DB.trainers or {}
    CHAR.professions = CHAR.professions or {}
    CHAR.standing = CHAR.standing or {} -- [npcId] = true (trades) / false (Unfriendly or Hostile), as seen by this character
    CHAR.log = CHAR.log or {}
    -- Account-level copies from before settings and places moved per character; nothing reads them
    -- (cfg and hud stay as the seed for a new character). toastLocked was retired from the settings.
    DB.hearth, DB.lastOutside, DB.professions, DB.log = nil, nil, nil, nil
    CHAR.cfg.toastLocked = nil
    log = ns.Log.New(CHAR.log, A.now)
end

-- The class reagents being watched, with their counts: { { item, count, name } }, or nil when the
-- class is unknown. A reagent is watched when the player knows a spell that uses it and has not
-- switched it off; one whose count cannot be read is left out.
local function reagentList()
    local class = A.classToken()
    if not class then return end
    local out = {}
    for _, item in ipairs(ns.Reagents.Watched(class, A.knowsSpell, CHAR.cfg.reagentOff)) do
        local count = A.itemCount(item.id)
        if count then out[#out + 1] = { item = item, count = count, name = A.itemName(item.id) or item.name } end
    end
    return out
end

-- What the controller needs for food, water, pet food and the reminders: the class, the bag totals
-- (nil when the bags cannot be read), the spell test and the active pet's diets (hunters only, nil
-- without a pet), or nil when the class is unknown.
local function supplyState()
    local class = A.classToken()
    if not class then return end
    local diets = class == "HUNTER" and A.petDiet() or nil
    return { class = class, totals = ns.Supplies.Totals(A.supplyCounts(), diets), knows = A.knowsSpell, diets = diets }
end

-- One report line: each supply switch with its threshold.
local function supplyLine()
    local c = CHAR.cfg
    return ("supplies: %s; food %s (%d), water %s (%d), pet food %s (%d), healthstone reminder %s, notification sound %s"):format(
        c.suppliesEnabled and "on" or "off", c.foodEnabled and "on" or "off", c.foodThreshold, c.waterEnabled and "on" or "off", c.waterThreshold,
        c.petFoodEnabled and "on" or "off", c.petFoodThreshold, c.healthstoneRemind and "on" or "off",
        tostring(c.remindSound))
end

-- What ns.Reagents.OnMerchant needs when a merchant opens: the reagents the warning watches, with
-- the same counts, and the game reads and the purchase through the Adapter. Money is what is left
-- after an ammo purchase made a moment before (the game updates it only when the server answers).
local ammoSpent = 0
local REAGENT_ENV = {
    watched = function() return reagentList() end,
    offers = A.merchantReagents,
    slots = A.bagSlots,
    stack = A.stackSize,
    money = function()
        local m = A.money()
        return m and math.max(0, m - ammoSpent) or nil
    end,
    buy = function(...) merchantActed = true; return A.buyMerchantItem(...) end,
    say = say,
    log = function(text) if log then log.Add(text) end end,
    confirm = function(text, accept) merchantActed = true; A.showPopup(POPUP_REAGENTS, text, accept) end,
    sells = A.merchantItemId,
}

-- Status window ---------------------------------------------------------------------------------

-- What Status.Snapshot reads. Skills are kept until SKILL_LINES_CHANGED says they changed.
local STATUS_SRC = {
    freeSlots = A.freeSlots, lowestDurability = A.lowestDurability, ammo = A.ammoStatus,
    knows = A.knowsSpell, itemCount = A.itemCount, itemName = A.itemName,
    supplies = supplyState,
    trainerTiers = function() return trainerTiers() end,
    level = A.level,
    skills = function()
        if not skillCache then skillCache = A.skills() end
        return skillCache
    end,
}

-- Redraw the status window now. Nothing is read from the game for a row set to "never".
local function refreshWindow()
    if not tracker then return end
    playerClass = playerClass or A.classToken()
    local cfg = CHAR.cfg
    STATUS_SRC.known = CHAR.professions
    local rows = ns.Status.Visible(ns.Status.Rows(ns.Status.Snapshot(STATUS_SRC, cfg, playerClass), cfg, playerClass), cfg)
    local ok, err = pcall(tracker.Show, rows)
    if not ok then
        log.Add("status window failed and is switched off: " .. tostring(err))
        tracker = nil
    end
end

-- The newest thing the player asked for replaces whatever is on screen. clearNotices hides every
-- notification, live or sample, Toast or Warning. endShows also stops a running demo (its previous
-- waypoint comes back) or preview, cancels Move and brings back the real status window rows.
local function clearNotices()
    if toast then pcall(toast.Hide) end
    if sampleToast then pcall(sampleToast.Hide) end
    if A.hideNotice then A.hideNotice() end
    if A.hideSamples then A.hideSamples() end
end
local function endShows()
    sampleToken = sampleToken + 1 -- a running preview's timer now does nothing
    if controller and controller.StopDemo then controller.StopDemo() end
    if tracker and tracker.Move then tracker.Move.Cancel() end
    if toast then toast.Move.Cancel() end
    clearNotices()
    if sampleKind then
        sampleKind = nil
        if tracker then pcall(tracker.Demo, nil) end
        refreshWindow()
    end
end

-- Something the window shows may have changed: one redraw shortly, however many events arrive.
local function touchWindow()
    if not tracker or windowDirty then return end
    if A.after(WINDOW_DELAY, function() windowDirty = false; refreshWindow() end) then
        windowDirty = true
    else
        refreshWindow() -- no timers on this client
    end
end

-- Worn-gear events come in bursts (a durability tick every few seconds, many inventory changes at
-- once): one check shortly after, however many arrive. The window redraw batches the same way.
local EVAL_DELAY = 0.2
local burst, burstQueued = 0, false
local function flushBurst()
    burstQueued = false
    if log then log.Add(("gear events: %d folded into one check"):format(burst)) end
    burst = 0
    evaluate()
    touchWindow()
end
local function evaluateSoon()
    burst = burst + 1
    if burstQueued then return end
    if A.after(EVAL_DELAY, function() if burstQueued then flushBurst() end end) then burstQueued = true else flushBurst() end
end

-- A window setting changed (scale, opacity, text opacity, colour, lock, a row mode): apply it and redraw at once.
local function applyWindow()
    if toast then pcall(toast.Apply) end
    if sampleToast then pcall(sampleToast.Apply) end
    if not tracker then return end
    pcall(tracker.Apply)
    refreshWindow()
end

-- Open the settings page (the main one); false when it cannot be opened.
local function openSettings(page)
    if not panel then return false end
    local ok, result = pcall(ns.Options.Open, panel, page)
    return ok and result ~= false
end

local function buildWindow()
    local ok, t = pcall(ns.Tracker.New, {
        cfg = CHAR.cfg,
        pos = CHAR.hud,
        shiftDown = A.shiftDown,
        escape = A.escape,
        go = function(row)
            log.Add("row click: " .. row.key .. " (" .. row.text .. ")")
            endShows() -- a click replaces any demo, preview or notification on screen
            if controller and not controller.Go(row.kind, row.id) then log.Add("row click: nothing pinned") end
            touchWindow()
        end,
        -- The row's arrow: shown with this tooltip title when there is another seller to choose.
        choiceTitle = function(row)
            if not (controller and A.hasMenu()) then return nil end
            return controller.ChoiceTitle(row.kind, row.id)
        end,
        choose = function(row, anchor)
            local c = controller and controller.Choices(row.kind, row.id)
            if not c then return end
            local items = {}
            for i, e in ipairs(c.entries) do
                items[i] = { text = e.label, checked = e.default, func = function()
                    log.Add("choice: " .. row.key .. " -> " .. tostring(e.v[2]))
                    endShows()
                    if not controller.Pick(row.kind, row.id, e) then log.Add("choice: nothing pinned") end
                    touchWindow()
                end }
            end
            if not A.menu(anchor, c.title, items) then log.Add("choice: no menu control") end
        end,
        openSettings = function()
            if not openSettings() then say(L["The settings page is not available here: %s. Use /cvn help."]:format(ns.Options.failure or colorNote)) end
        end,
    })
    if ok then tracker = t else log.Add("status window not available: " .. tostring(t)) end
end

-- One report line: the status window settings; only group modes that are not the default are listed.
local function windowLine()
    local c, rows = CHAR.cfg, {}
    for _, group in ipairs(ns.Status.GROUPS) do
        local mode = ns.Status.Mode(c, group)
        if mode ~= ns.Status.DEFAULT_MODE then rows[#rows + 1] = group .. "=" .. mode end
    end
    return ("status window: %s, scale %s%%, opacity %s%%, color #%s, text opacity %s%%, %s, rows: %s"):format(c.hudLocked and "locked" or "unlocked",
        tostring(c.hudScale), tostring(c.hudAlpha), tostring(c.hudColor), tostring(c.hudTextAlpha), tracker and "built" or "not built", #rows > 0 and table.concat(rows, ", ") or "all default")
end

-- One report line: the reagent threshold, what is being watched now and what the player switched off.
local function reagentLine()
    local watching, off = {}, {}
    for _, r in ipairs(reagentList() or {}) do watching[#watching + 1] = r.item.name .. ":" .. r.count end
    for id, v in pairs(CHAR.cfg.reagentOff) do
        local item = v and ns.Reagents.ById(id)
        if item then off[#off + 1] = item.name end
    end
    table.sort(off)
    return ("reagents: %s, class %s, threshold %d, watching: %s, switched off: %s"):format(CHAR.cfg.reagentsEnabled and "on" or "off",
        tostring(A.classToken()), CHAR.cfg.reagentThreshold, #watching > 0 and table.concat(watching, ", ") or "none", #off > 0 and table.concat(off, ", ") or "none")
end

-- The report: facts about this client and addon, then the debug log.
local function reportText()
    local info = A.clientInfo()
    local learned, continents, auctioneers = 0, {}, 0
    for _ in pairs(DB.auctioneers) do auctioneers = auctioneers + 1 end
    local trainers, professions = 0, {}
    for _ in pairs(DB.learned) do learned = learned + 1 end
    for _ in pairs(DB.trainers) do trainers = trainers + 1 end
    for name in pairs(CHAR.professions) do professions[#professions + 1] = name end
    table.sort(professions)
    for id, b in pairs(buckets) do continents[#continents + 1] = id .. ":" .. #b end
    table.sort(continents)
    local c = CHAR.cfg
    local header = {
        "addon version: " .. tostring(info.addon),
        "game: " .. tostring(info.gameVersion) .. " build " .. tostring(info.build) .. ", interface " .. tostring(info.interface),
        "locale: " .. tostring(info.locale),
        "navigation: " .. tostring(ns.Nav.Select(A.navApi(say), c.navProvider)) .. " (preference " .. tostring(c.navProvider) .. ")",
        ("vendors: %d shipped, %d learned, per continent: %s"):format(#(ns.ShippedVendors or {}), learned, table.concat(continents, " ")),
        (function()
            local yes, no = 0, 0
            for _, v in pairs(CHAR.standing or {}) do if v then yes = yes + 1 else no = no + 1 end end
            return ("standing (this character): %d vendors trade, %d will not (Unfriendly or Hostile)"):format(yes, no)
        end)(),
        external.schema and ("NorgannonDB: found, schema %s, %d vendors added, %d skipped, %d trainers with a tier"):format(external.schema, #external.list, external.skipped, #external.trainers)
            or (external.unsupported and "NorgannonDB: installed, but its data is not a supported schema" or "NorgannonDB: not found"),
        ("settings: bags %s/%d, durability %s/%d, ammo %s/%d, professions %s/%d"):format(c.bagEnabled and "on" or "off", c.bagThreshold,
            c.durEnabled and "on" or "off", c.durThreshold, c.ammoEnabled and "on" or "off", c.ammoThreshold,
            c.tradeEnabled and "on" or "off", c.tradeThreshold),
        ("ammo buying: %s, %s, arrows %s, bullets %s"):format(c.ammoBuyEnabled and "on" or "off",
            c.ammoBuyPrompt and "asks first" or "buys at once", tostring(c.arrowGrade), tostring(c.bulletGrade)),
        reagentLine(),
        supplyLine(),
        ("reagent buying: %s, %s, up to %s of each"):format(c.reagentBuyEnabled and "on" or "off",
            c.reagentBuyPrompt and "asks first" or "buys at once", tostring(c.reagentBuyTarget)),
        ("target choice: %s, prefers %s, on-screen notice %s"):format(tostring(c.vendorMode), tostring(c.vendorPrefer), c.autoNotice and "on" or "off"),
        ("trainers: %d learned, professions seen: %s"):format(trainers, table.concat(professions, ", ")),
        windowLine(),
        ("color picker: %s, settings button: %s, %s"):format(A.hasColorPicker() and "available" or "missing",
            A.hasSettingsButton() and "available" or "missing", colorNote),
        ("instance anchor: %s, auction house routing: %s, auctioneers: %d shipped, %d learned"):format(tostring(c.instanceAnchor),
            c.ahEnabled and "on" or "off", #(ns.ShippedAuctioneers or {}), auctioneers),
    }
    header[#header + 1] = "presentation scope: This character; style " .. tostring(c.notificationStyle) .. "; sample " .. tostring(sampleKind or "off")
    header[#header + 1] = ("toast: background %s%%, text/icons %s%%, scale %s%%, position %s/%s/%s/%s"):format(tostring(c.toastAlpha),tostring(c.toastTextAlpha),tostring(c.toastScale),tostring(CHAR.toast.point),tostring(CHAR.toast.relPoint),tostring(CHAR.toast.x),tostring(CHAR.toast.y))
    header[#header + 1] = "CheckThat: " .. (ns.CheckThat and ns.CheckThat.Status() or "not detected")
    header[#header + 1] = "Move: hud " .. tostring(tracker and tracker.Move and tracker.Move.active or false) .. ", toast " .. tostring(toast and toast.Move.active or false)
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
    readExternal()
    started = true
    rebuildBuckets()
    rebuildTrainers()
    rebuildAuctioneers()
    local nav = { Set = function(v) return ns.Nav.Set(A.navApi(say), v, CHAR.cfg.navProvider) end,
                  Clear = function(h) ns.Nav.Clear(A.navApi(say), h) end,
                  ReadGame = function() return ns.Nav.ReadGame(A.navApi(say)) end,
                  SetGame = function(p) return ns.Nav.SetGame(A.navApi(say), p) end }
    controller = ns.Controller.New({
        cfg = CHAR.cfg,
        log = function(msg) log.Add(msg) end,
        freeSlots = A.freeSlots,
        lowestDurability = A.lowestDurability,
        inCombat = A.inCombat,
        dead = A.isDead,
        playerPos = A.playerWorldPos,
        playerFaction = A.factionId("player"),
        buckets = buckets,
        nav = nav,
        ammo = A.ammoStatus,
        reagents = reagentList,
        supplies = supplyState,
        confirm = function(kind, v, accept, count, trade, two, decline)
            closeQuestions() -- one question is open at a time, whichever kind it is
            if not two then
                A.showPopup(POPUP, ns.Controller.PromptText(kind, v, A.mapName(v[3]), count, trade), { accept = accept, decline = decline })
                return
            end
            local text = ns.Controller.PromptText(kind, v, A.mapName(v[3]), count, trade, two, A.mapName(two.other[3]))
            A.showPopup(two.mapFirst and POPUP_MAP or POPUP_DIST, text, { accept = accept, alt = two.acceptOther, decline = decline })
        end,
        cancelConfirm = closeQuestions,
        questionOpen = function() return A.popupShown(POPUP) or A.popupShown(POPUP_MAP) or A.popupShown(POPUP_DIST) end,
        skills = A.skills,
        level = A.level,
        known = CHAR.professions,
        trainerBuckets = trainerBuckets,
        trainerTiers = trainerTiers,
        auctionBuckets = auctionBuckets,
        say = say,
        notify = function(text)
            clearNotices() -- one notification at a time: the newest replaces any other, live or sample
            if CHAR.cfg.notificationStyle == "toast" then
                if toast then pcall(toast.Show, text, 5) end
            else
                A.screenMessage(text)
            end
        end,
        playSound = function(key) A.playSound(ns.Supplies.SoundId(key)) end,
        zoneName = A.mapName,
        itemName = A.itemName,
        itemIcon = A.itemIcon,
        menu = function(title, items) return A.hasMenu() and A.menu("cursor", title, items) end,
        instanceType = A.instanceType,
        anchor = anchor,
        after = A.after,
        evaluate = evaluate, -- the controller's own re-checks also arm the position retry
    })
    -- The settings page is optional: if the client's settings API differs, only the page is lost.
    local ok, category = pcall(ns.Options.Register, CHAR.cfg, DEFAULTS, function() evaluate(); applyWindow() end, A.classToken(),
        A.hasColorPicker() and A.pickColor or nil,
        function(text) colorNote = text; log.Add(text) end, A.hasSwatchPicker())
    if not ok then colorNote = "settings page failed: " .. tostring(category) end
    panel = ok and category or nil
    -- So is the status window: a client whose frames differ only loses the window.
    buildWindow()
    if A.createToast then
        toast = A.createToast({ cfg = CHAR.cfg, pos = CHAR.toast, name = "ClosestVendorToast", escape = A.escape })
        sampleToast = A.createToast({ cfg = CHAR.cfg, pos = CHAR.toast, name = "ClosestVendorSampleToast" })
    end
    ns.Options.Run = function(cmd) SlashCmdList["CLOSESTVENDOR"](cmd) end
    ns.Options.DebugEnabled = log.Enabled
    ns.Options.Version = function() return A.clientInfo().addon end
    ns.Options.itemName = A.itemName -- reagent labels in the player's language
    ns.Supplies.media = { list = A.mediaSounds, fetch = A.mediaSound } -- sound-pack sounds, when shared
    ns.Options.Move = function(kind)
        sampleToken = sampleToken + 1; sampleKind = nil
        if A.hideSamples then A.hideSamples() end
        if sampleToast then pcall(sampleToast.Hide) end
        if tracker then pcall(tracker.Demo, nil) end
        local target = kind == "toast" and toast or tracker
        if tracker and tracker.Move then tracker.Move.Cancel() end
        if toast then toast.Move.Cancel() end
        if not (target and target.Move and target.Move.Begin()) then say(kind == "hud" and L["Unlock the position before moving; the surface must be available."] or L["The toast surface is not available on this client."]) end
    end
    ns.Options.Reset = function(kind)
        local target = kind == "toast" and toast or tracker
        if target and target.Move then target.Move.Cancel() end
        if target then pcall(target.Reset) end
    end
    touchWindow()
    -- Last, and guarded: a fault in the test-runner integration never stops the addon from starting.
    local CT = ns.CheckThat
    if CT then
        local ok, err = pcall(CT.Start, { cfg = function() return CHAR.cfg end, version = A.addonVersion,
            log = function(msg) log.Add(msg) end,
            active = function() if controller then return controller.Active() end end })
        if not ok then pcall(CT.Fail, "Start: " .. tostring(err)) end
    end
end

SLASH_CLOSESTVENDOR1 = "/cvn"
SLASH_CLOSESTVENDOR2 = "/closestvendor"
SlashCmdList["CLOSESTVENDOR"] = function(msg)
    if not DB then return end
    local lines, action = ns.Commands.Run(CHAR.cfg, msg, A.classToken(), A.itemName)
    for _, line in ipairs(lines) do say(line) end
    if action and action[1] == "read" then return end
    if action and action[1] == "open" then
        if openSettings(action[2]) then return end
        say(L["The settings page is not available here: %s. Use /cvn help."]:format(ns.Options.failure or colorNote))
        return
    end
    if action and action[1] == "debug" then
        -- The off line is written before the log stops, so both directions are recorded.
        if not action[2] then log.Add("debug log turned off") end
        log.SetEnabled(action[2])
        if action[2] then log.Add("debug log turned on") end
        return
    end
    if action and action[1] == "log" then
        if action[2] == "clear" then
            A.showPopup("CLOSESTVENDOR_CLEAR_LOG", L["Clear recorded diagnostic entries? Learned places, settings and gameplay data are kept."], function() log.Clear() end)
        else showReport() end
        return
    end
    if action and action[1] == "sound" then
        A.playSound(ns.Supplies.SoundId(CHAR.cfg.remindSound))
        return
    end
    if action and action[1] == "find" then
        if controller then controller.Find(action[2]) end
        return
    end
    if action and action[1] == "test" then
        local problem = controller and controller.Test(action[2])
        if problem then say(problem) end
        return
    end
    if action and action[1] == "hud" and action[2] == "pick" then
        -- The picker works wherever the game has one, settings page or not.
        local r, g, b = ns.Status.Color(CHAR.cfg.hudColor)
        local opened = A.hasColorPicker() and A.pickColor(r or 0, g or 0, b or 0, function(nr, ng, nb)
            CHAR.cfg.hudColor = ns.Status.Hex(nr, ng, nb)
            applyWindow()
        end)
        if not opened then
            say(L["This game has no color picker; use /cvn hud color #rrggbb, or black or reset."])
        end
        return
    end
    if action and action[1] == "demo" then
        -- A tour of real routes, questions and notifications (Controller.Demo), with made-up status
        -- window rows while it runs. The waypoint the player had before comes back at the end.
        if not controller then return end
        endShows() -- a new demo replaces the old one, any preview and any notification
        local snap, fake = ns.Status.Demo(ns.Status.Roller(A.now()), CHAR.cfg)
        local started = controller.Demo(function()
            sampleKind = nil
            if tracker then pcall(tracker.Demo, nil) end
            refreshWindow()
        end)
        if not started then say(L["The demo needs a working timer API."]) return end
        sampleKind = "demo"
        say(L["Demo: real routes, questions and notifications, one every five seconds. Your previous waypoint comes back at the end."])
        if tracker then pcall(tracker.Demo, ns.Status.Visible(ns.Status.Rows(snap, fake), fake)) end
        return
    end
    if action and action[1] == "preview" then
        local kind = action[2]
        local token = sampleToken + 1
        local function finish()
            if token ~= sampleToken then return end
            sampleKind = nil
            if tracker then pcall(tracker.Demo, nil) end
            if sampleToast then pcall(sampleToast.Hide) end
            if A.hideSamples then A.hideSamples() end
            refreshWindow()
        end
        if not A.after(10, finish) then say(L["Visual previews need a working timer API."]); return end
        endShows() -- a new preview replaces any demo, preview or notification
        sampleToken = token
        sampleKind = kind
        if kind == "hud" then
            local snap, fake = ns.Status.Demo(ns.Status.Roller(A.now()), CHAR.cfg)
            if tracker then pcall(tracker.Demo, ns.Status.Visible(ns.Status.Rows(snap, fake), fake)) end
        end
        if kind == "notice" then
            -- The sample renderer of the chosen style and the notification sound, even while notices are off.
            local text = L["Preview — Supply vendor (Elwynn Forest), 120 yards. Low food. Alternative: Repair vendor (Westfall), 240 yards."]
            if CHAR.cfg.notificationStyle == "warning" then
                if A.sampleWarning then A.sampleWarning(text, 10) end
            elseif sampleToast then pcall(sampleToast.Show, text, 10) end
            A.playSound(ns.Supplies.SoundId(CHAR.cfg.remindSound))
        end
        if kind == "prompt" then
            A.showPopup("CLOSESTVENDOR_SAMPLE", L["Preview — Navigate to the sample vendor? These buttons perform no gameplay action."], function() end)
        end
        return
    end
    if action and action[1] == "hud" and action[2] == "reset" then
        if tracker and tracker.Move then tracker.Move.Cancel() end
        for k in pairs(CHAR.hud) do CHAR.hud[k] = nil end
        log.Add("status window position reset")
    end
    if ns.Options.Refresh then ns.Options.Refresh() end
    evaluate() -- a changed threshold may apply right away
    applyWindow() -- and so may a window setting or a row mode
end

-- Run the ammo and reagent purchase parts named in order. A part that stopped because an item was not
-- loaded, and asked and bought nothing, is kept to run again.
local MERCHANT_PARTS = {
    ammo = function()
        local _, spent = ns.Ammo.OnMerchant(CHAR.cfg, AMMO_ENV)
        ammoSpent = spent or 0
    end,
    reagents = function() ns.Reagents.OnMerchant(CHAR.cfg, REAGENT_ENV) end,
}
runMerchantParts = function(names)
    for _, name in ipairs(names) do
        A.resetItemData()
        merchantActed = false
        MERCHANT_PARTS[name]()
        local missing = A.missingItems()
        if missing and not merchantActed then
            retryParts[#retryParts + 1] = name
            for id in pairs(missing) do retryItems[id] = true end
        end
    end
end

ns.frame = CreateFrame("Frame")
ns.frame:SetScript("OnEvent", function(_, event, arg1)
    -- Fires for every item the game loads, so it is handled before anything is logged.
    if event == "GET_ITEM_INFO_RECEIVED" and relearnMerchant and DB then learnMerchant() end
    if event == "GET_ITEM_INFO_RECEIVED" then
        if #retryParts > 0 and retryItems[arg1] and retries < MAX_RETRIES and DB then
            retries = retries + 1
            local names = retryParts
            retryParts, retryItems = {}, {}
            ammoSpent = 0 -- the game has answered the earlier purchase by now; money is what it says
            if log then log.Add("item data arrived: trying the merchant purchase again") end
            runMerchantParts(names)
        end
        return
    end
    if event == "CONFIRM_BINDER" then
        if DB then noteBinder(arg1) end
        return
    end
    if event == "HEARTHSTONE_BOUND" or event == "PLAYER_LOGOUT" then
        -- Logout and reload also apply a bind the client did not announce, before the question is lost.
        if DB then learnHearth() end
        return
    end
    if event == "MERCHANT_CLOSED" then
        retryParts, retryItems, relearnMerchant = {}, {}, false
        -- A purchase question ends with its merchant, unanswered: nothing is bought.
        -- Logged only after the hide, once the question is confirmed gone; still shown is a failure.
        local function close(which, closed, failed)
            local was = A.popupShown(which)
            A.hidePopup(which)
            if log and was then log.Add(A.popupShown(which) and failed or closed) end
        end
        close(POPUP_AMMO, "purchase question closed with the merchant: ammo",
            "FAILED: purchase question still shown after the merchant closed: ammo")
        close(POPUP_REAGENTS, "purchase question closed with the merchant: reagents",
            "FAILED: purchase question still shown after the merchant closed: reagents")
        return
    end
    if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" or event == "NAME_PLATE_UNIT_ADDED" then
        local unit = event == "PLAYER_TARGET_CHANGED" and "target" or event == "UPDATE_MOUSEOVER_UNIT" and "mouseover" or arg1
        if DB and type(unit) == "string" then learnStanding(unit) end
        return
    end
    -- Only the player's own gear, casts and pet matter; party and raid members fire these too.
    if (event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_PET") and arg1 ~= "player" then return end
    if event == "UPDATE_INVENTORY_DURABILITY" or event == "UNIT_INVENTORY_CHANGED" then
        evaluateSoon() -- not logged one by one: the burst gets one line
        return
    end
    if log and (event ~= "ADDON_LOADED" or arg1 == ADDON) then
        log.Add("event " .. event .. (arg1 ~= nil and (" " .. tostring(arg1)) or ""))
    end
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            init()
        elseif arg1 == "NorgannonDB" and started then
            readExternal()
            rebuildBuckets()
            rebuildTrainers()
            evaluate()
            touchWindow()
        end
    elseif event == "PLAYER_LOGIN" then
        start()
    elseif event == "MERCHANT_SHOW" then
        -- A gear check still waiting runs first, so a repair question it makes is the one the merchant answers.
        if burstQueued then flushBurst() end
        if DB then learnMerchant() end
        if controller then controller.OnMerchantShow() end
        if DB then
            retryParts, retryItems, retries = {}, {}, 0
            runMerchantParts({ "ammo", "reagents" })
        end
    elseif event == "TRAINER_SHOW" or event == "TRAINER_UPDATE" then
        local trades = DB and learnTrainer()
        -- Probe for trainer tiers (which trainer teaches which rank): with debugging on, log every
        -- service the window lists, with its level and skill requirements and the filter states.
        if trades and event == "TRAINER_SHOW" and log and log.Enabled() then
            local services, filters = A.trainerServices()
            log.Add(("trainer services: %d listed; filters available=%s unavailable=%s used=%s"):format(#services,
                tostring(filters.available), tostring(filters.unavailable), tostring(filters.used)))
            for _, s in ipairs(services) do
                log.Add(("  service: %s | %s | %s | %s | level %s | needs %s %s"):format(tostring(s.skill), tostring(s.name),
                    tostring(s.sub), tostring(s.kind), tostring(s.level), tostring(s.reqSkill), tostring(s.reqRank)))
            end
        end
        if trades and controller then controller.OnTrainerShow(trades) end
    elseif event == "AUCTION_HOUSE_SHOW" then
        if DB then learnAuctioneer() end
    elseif event == "SKILL_LINES_CHANGED" then
        skillCache = nil
        if controller then controller.OnSkillChange() end
        touchWindow()
    elseif event == "TRADE_SKILL_SHOW" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- A craft is a successful cast while a tradeskill or craft window is open.
        local name = DB and A.craftProfession()
        if name then
            CHAR.professions[name] = true
            if event == "UNIT_SPELLCAST_SUCCEEDED" and controller then controller.OnCraft() end
        end
    else
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            if DB then learnHearth() end
            if controller then controller.OnPlaceChange() end
        end
        evaluate()
        touchWindow()
    end
end)
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA",
        "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED",
        "PLAYER_REGEN_ENABLED", "MERCHANT_SHOW", "TRAINER_SHOW", "TRAINER_UPDATE", "SKILL_LINES_CHANGED",
        "TRADE_SKILL_SHOW", "UNIT_SPELLCAST_SUCCEEDED", "SPELLS_CHANGED", "PLAYER_LOGOUT" }) do
    ns.frame:RegisterEvent(e)
end
-- Registering an event the client does not have is an error, and this one's name is unverified.
pcall(ns.frame.RegisterEvent, ns.frame, "AUCTION_HOUSE_SHOW")
pcall(ns.frame.RegisterEvent, ns.frame, "GET_ITEM_INFO_RECEIVED")
pcall(ns.frame.RegisterEvent, ns.frame, "MERCHANT_CLOSED")
-- The innkeeper's bind question, and (newer clients) the bind itself: the hearthstone point's position.
pcall(ns.frame.RegisterEvent, ns.frame, "CONFIRM_BINDER")
pcall(ns.frame.RegisterEvent, ns.frame, "HEARTHSTONE_BOUND")
-- Warnings wait while dead or a ghost; coming back to life checks again.
pcall(ns.frame.RegisterEvent, ns.frame, "PLAYER_ALIVE")
pcall(ns.frame.RegisterEvent, ns.frame, "PLAYER_UNGHOST")
-- Seeing an NPC tells whether it will trade with this character (reputation).
for _, e in ipairs({ "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED" }) do
    pcall(ns.frame.RegisterEvent, ns.frame, e)
end
pcall(ns.frame.RegisterEvent, ns.frame, "UNIT_PET") -- the active pet, so its diet follows pet changes
