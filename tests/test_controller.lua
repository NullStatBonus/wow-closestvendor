package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
H.locale(ns)
for _, f in ipairs({ "Triggers", "Professions", "Reagents", "Supplies", "Search", "Controller" }) do
    loadfile("ClosestVendor/" .. f .. ".lua")("ClosestVendor", ns)
end


-- { npcId, name, uiMapID, mx, my, faction, repair, ammo, wx, wy }
local VENDORS = {
    { 1, "Near Seller",  100, 0.1, 0.1, 0, false, 0, 10, 0 },
    { 2, "Far Repairer", 100, 0.9, 0.1, 0, true,  0, 90, 0 },
    { 3, "Arrow Man",    100, 0.5, 0.1, 0, false, 1, 50, 0 },
    { 4, "Gun Shop",     100, 0.7, 0.1, 0, false, 2, 70, 0 },
}

local function world(over)
    local w = { free = 10, dur = nil, combat = false, pos = { 1, 0, 0 }, calls = {}, setCount = 0, clearCount = 0,
                prompts = {}, notes = {}, cancelCount = 0, ammoKind = nil, ammoCount = 0, logs = {}, says = {}, sounds = {}, known = {}, open = false }
    for k, v in pairs(over or {}) do w[k] = v end
    local env = {
        cfg = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, bagEnabled = true, durEnabled = true, ammoEnabled = true, suppliesEnabled = true, reagentsEnabled = true,
                 tradeThreshold = 10, tradeEnabled = true, reagentThreshold = 5 },
        reagents = function() return w.reagents end,
        supplies = function() return w.supplies end,
        playSound = function(key) w.sounds[#w.sounds + 1] = key or "unset" end,
        skills = function() return w.skills end,
        known = w.known,
        level = w.level and function() return w.level end,
        trainerBuckets = w.trainers or {},
        auctionBuckets = w.auction,
        say = function(t) w.says[#w.says + 1] = t end,
        notify = (not w.noNotify) and function(t) w.notes[#w.notes + 1] = t end or nil,
        zoneName = function(id) return w.zones and w.zones[id] end,
        questionOpen = function() return w.open end,
        freeSlots = function() return w.free end,
        lowestDurability = function() return w.dur end,
        inCombat = function() return w.combat end,
        instanceType = function() return w.instance end,
        anchor = function(which) return w.anchors and w.anchors[which] end,
        after = (not w.noAfter) and function(s, fn)
            if w.noTimers then return false end
            w.timers = w.timers or {}
            w.timers[#w.timers + 1] = { s = s, fn = fn }
            return true
        end or nil,
        playerPos = function() if w.pos then return w.pos[1], w.pos[2], w.pos[3], w.pos[4] end end,
        playerFaction = 1,
        buckets = w.buckets or { [1] = VENDORS },
        log = (not w.noLog) and function(m) w.logs[#w.logs + 1] = m end or nil,
        ammo = function() return w.ammoKind, w.ammoCount end,
        confirm = function(kind, v, accept, count, trade, two)
            w.prompts[#w.prompts + 1] = { kind = kind, vendor = v, accept = accept, count = count, trade = trade, two = two }
            if w.autoAccept ~= false then (w.pickOther and two and two.acceptOther or accept)() else w.open = true end -- tests say autoAccept = false to hold the question open
        end,
        cancelConfirm = function() w.cancelCount = w.cancelCount + 1; w.open = false end,
        nav = {
            Set = function(v) w.setCount = w.setCount + 1; w.last = v; if not w.nilNav then return { kind = "x" } end end,
            Clear = function() w.clearCount = w.clearCount + 1 end,
        },
    }
    for k, v in pairs(w.cfg or {}) do env.cfg[k] = v end
    w.c = ns.Controller.New(env)
    w.liveCfg = env.cfg
    return w
end

-- Bags full -> nearest vendor of any kind; freeing bags clears.
local w = world({ free = 1 })
w.c.Evaluate()
eq(w.setCount, 1, "navigation set")
eq(w.last[2], "Near Seller", "nearest vendor chosen")
w.c.Evaluate()
eq(w.setCount, 1, "no repeat while condition holds")
w.free = 20
w.c.Evaluate()
eq(w.clearCount, 1, "cleared when bags freed")

-- Durability low -> must be a repair vendor, even though a seller is nearer.
w = world({ dur = 10 })
w.c.Evaluate()
eq(w.last[2], "Far Repairer", "repair vendor chosen")

-- No map position: nothing set, no error, retried once position appears.
w = world({ free = 1, pos = false })
w.c.Evaluate()
eq(w.setCount, 0, "no position -> nothing set")
eq(w.c.pending, "sell", "request kept pending")
w.c.Evaluate()
eq(w.setCount, 0, "still no position")
w.pos = { 1, 0, 0 }
w.c.Evaluate()
eq(w.setCount, 1, "placed once position available")
eq(w.c.pending, nil, "pending cleared")

-- Pending request dropped if the condition clears before a position appears.
w = world({ free = 1, pos = false })
w.c.Evaluate()
w.free = 20
w.c.Evaluate()
eq(w.c.pending, nil, "pending dropped when condition clears")
w.pos = { 1, 0, 0 }
w.c.Evaluate()
eq(w.setCount, 0, "nothing set after condition cleared")

-- No vendor on this continent: silent, nothing pending.
w = world({ free = 1, pos = { 7, 0, 0 } })
w.c.Evaluate()
eq(w.setCount, 0, "no vendor on continent")
eq(w.c.pending, nil, "not retried")

-- Combat defers; fires after combat.
w = world({ free = 1, combat = true })
w.c.Evaluate()
eq(w.setCount, 0, "deferred in combat")
w.combat = false
w.c.Evaluate()
eq(w.setCount, 1, "fires after combat")

-- Pending retry does not run in combat.
w = world({ free = 1, pos = false })
w.c.Evaluate()
w.pos = { 1, 0, 0 }; w.combat = true
w.c.Evaluate()
eq(w.setCount, 0, "pending not placed in combat")
w.combat = false
w.c.Evaluate()
eq(w.setCount, 1, "pending placed after combat")

-- Merchant window clears navigation and does not re-request while the condition holds.
w = world({ free = 1 })
w.c.Evaluate()
w.c.OnMerchantShow()
eq(w.clearCount, 1, "merchant clears")
w.c.Evaluate()
eq(w.setCount, 1, "no re-request after merchant dismissal")
w.c.OnMerchantShow()
eq(w.clearCount, 1, "merchant with nothing active")

-- Merchant window while a request is still waiting for a position drops that request.
w = world({ free = 1, pos = false })
w.c.Evaluate()
eq(w.c.pending, "sell", "pending before merchant")
w.c.OnMerchantShow()
eq(w.c.pending, nil, "merchant drops pending request")
w.pos = { 1, 0, 0 }
w.c.Evaluate()
eq(w.setCount, 0, "dropped request is not placed later")

-- A new target replaces the active one: sell first, then durability drops -> repair vendor.
w = world({ free = 1 })
w.c.Evaluate()
eq(w.last[2], "Near Seller", "sell target first")
w.dur = 10
w.c.Evaluate()
eq(w.clearCount, 1, "previous navigation cleared before replacing")
eq(w.setCount, 2, "replaced")
eq(w.last[2], "Far Repairer", "now the repair vendor")

-- The question names the right kind and vendor.
w = world({ free = 1, autoAccept = false })
w.c.Evaluate()
eq(#w.prompts, 1, "one question asked")
eq(w.prompts[1].kind, "sell", "sell question")
eq(w.prompts[1].vendor[2], "Near Seller", "about the nearest vendor")
eq(w.setCount, 0, "nothing navigates before Yes")
w.prompts[1].accept()
eq(w.setCount, 1, "Yes navigates")
w = world({ dur = 10, autoAccept = false })
w.c.Evaluate()
eq(w.prompts[1].kind, "repair", "repair question")
eq(w.prompts[1].vendor[2], "Far Repairer", "about the repair vendor")

-- Declining: nothing navigates, no nagging, asks again only after the condition clears and recurs.
w = world({ free = 1, autoAccept = false })
w.c.Evaluate()
w.c.Evaluate()
w.c.Evaluate()
eq(#w.prompts, 1, "not asked again while the condition holds")
eq(w.setCount, 0, "declined: no navigation")
w.free = 20
w.c.Evaluate()
eq(w.cancelCount >= 1, true, "question closed when the condition clears")
w.free = 1
w.c.Evaluate()
eq(#w.prompts, 2, "asked again after clearing and recurring")

-- A late Yes after the condition cleared does nothing.
w = world({ free = 1, autoAccept = false })
w.c.Evaluate()
w.free = 20
w.c.Evaluate()
w.prompts[1].accept()
eq(w.setCount, 0, "stale Yes ignored after the condition cleared")

-- A merchant window cancels the question; a late Yes does nothing.
w = world({ free = 1, autoAccept = false })
w.c.Evaluate()
local before = w.cancelCount
w.c.OnMerchantShow()
eq(w.cancelCount > before, true, "merchant closes the question")
w.prompts[1].accept()
eq(w.setCount, 0, "stale Yes ignored after a merchant opened")

-- An active target is replaced only if the player accepts the new question.
w = world({ free = 1 })
w.c.Evaluate()
eq(w.setCount, 1, "sell target active")
w.autoAccept = false
w.dur = 10
w.c.Evaluate()
eq(w.clearCount, 0, "old target kept while the question is open")
eq(w.setCount, 1, "no new target yet")
w.prompts[#w.prompts].accept()
eq(w.clearCount, 1, "old target cleared on Yes")
eq(w.setCount, 2, "new target set on Yes")
eq(w.last[2], "Far Repairer", "the repair vendor")

-- Test(): asks the usual question whatever the bags/gear/combat, and Yes sets the pin.
w = world({ free = 20, dur = 100, combat = true, autoAccept = false })
eq(w.c.Test("sell"), nil, "test sell: nothing to complain about")
eq(#w.prompts, 1, "test sell asks even with plenty of space, full durability and in combat")
eq(w.prompts[1].kind, "sell", "test sell kind")
eq(w.prompts[1].vendor[2], "Near Seller", "test sell picks the nearest vendor")
eq(w.setCount, 0, "no pin before Yes")
w.prompts[1].accept()
eq(w.setCount, 1, "Yes sets the pin")
w.c.Test("repair")
eq(w.prompts[2].kind, "repair", "test repair kind")
eq(w.prompts[2].vendor[2], "Far Repairer", "test repair picks a repair vendor")
w.prompts[2].accept()
eq(w.clearCount, 1, "previous pin replaced on Yes")
eq(w.setCount, 2, "repair pin set")
w.c.OnMerchantShow()
eq(w.clearCount, 2, "any merchant window clears a test pin")

-- Test(): says why instead of asking when there is nothing to show.
w = world({ pos = false })
eq(w.c.Test("sell"):find("No map position", 1, true) ~= nil, true, "no position message")
eq(#w.prompts, 0, "no question without a position")
eq(w.c.pending, nil, "test never leaves a pending request")
w = world({ pos = { 7, 0, 0 } })
eq(w.c.Test("repair"):find("No known repair vendor", 1, true) ~= nil, true, "no vendor message")
eq(#w.prompts, 0, "no question without a vendor")

-- Test() does not disturb the real triggers.
w = world({ free = 1, autoAccept = false })
w.c.Test("sell")
w.c.Evaluate()
eq(#w.prompts, 2, "the real trigger still asks after a test")

-- Ammo: asks for the right kind, with the count, only when low.
w = world({ ammoKind = "arrow", ammoCount = 500, autoAccept = false })
w.c.Evaluate()
eq(#w.prompts, 0, "plenty of arrows: silent")
w.ammoCount = 150
w.c.Evaluate()
eq(#w.prompts, 1, "low arrows: asked")
eq(w.prompts[1].kind, "arrow", "kind is arrow")
eq(w.prompts[1].vendor[2], "Arrow Man", "nearest arrow seller, not a nearer non-seller")
eq(w.prompts[1].count, 150, "count passed for the text")
w.c.Evaluate()
eq(#w.prompts, 1, "not asked again")
w.prompts[1].accept()
eq(w.setCount, 1, "Yes sets the pin")
w.ammoCount = 900
w.c.Evaluate()
eq(w.clearCount, 1, "restocked: pin cleared")

w = world({ ammoKind = "bullet", ammoCount = 10, autoAccept = false })
w.c.Evaluate()
eq(w.prompts[1].kind, "bullet", "bullets for a gun")
eq(w.prompts[1].vendor[2], "Gun Shop", "bullet seller")

w = world({ ammoKind = nil, ammoCount = 0, autoAccept = false })
w.c.Evaluate()
eq(#w.prompts, 0, "no ranged weapon: not monitored")

-- Ammo with no position waits; if the weapon is swapped meanwhile, the request is dropped.
w = world({ ammoKind = "arrow", ammoCount = 10, pos = false, autoAccept = false })
w.c.Evaluate()
eq(w.c.pending, "ammo", "ammo request waiting for a position")
w.ammoKind = nil
w.pos = { 1, 0, 0 }
w.c.Evaluate()
eq(#w.prompts, 0, "weapon changed: nothing to buy")
eq(w.c.pending, nil, "pending dropped")

-- Repair is asked before ammo; ammo only after repair resolves.
w = world({ ammoKind = "arrow", ammoCount = 10, dur = 5, autoAccept = false })
w.c.Evaluate()
eq(#w.prompts, 1, "one question at a time")
eq(w.prompts[1].kind, "repair", "repair first")
w.c.Evaluate()
eq(#w.prompts, 1, "ammo waits")
w.dur = 100
w.c.Evaluate()
w.c.Evaluate()
eq(#w.prompts, 2, "ammo asked once repair resolved")
eq(w.prompts[2].kind, "arrow", "then arrows")

-- Auto notice says what to buy for ammo (also from /cvn test).
w = world({ ammoKind = "arrow", ammoCount = 10, cfg = { vendorMode = "auto" } })
w.c.Evaluate()
eq(w.says[1] and w.says[1]:find(" to buy ammo.", 1, true) ~= nil, true, "auto notice names ammo")
w = world({ cfg = { vendorMode = "auto" } })
w.c.Test("bullet")
eq(w.says[1] and w.says[1]:find(" to buy ammo.", 1, true) ~= nil, true, "test bullets: notice names ammo")
w = world({ dur = 5, cfg = { vendorMode = "auto" } })
w.c.Evaluate()
eq(w.says[1] and w.says[1]:find(" to repair your gear.", 1, true) ~= nil, true, "auto notice says repair")
-- Test(): ammo kinds ask for that ammo regardless of weapon or count.
w = world({ ammoKind = nil, autoAccept = false })
eq(w.c.Test("arrow"), nil, "test arrows")
eq(w.prompts[1].kind, "arrow", "arrow question")
eq(w.prompts[1].vendor[2], "Arrow Man", "arrow seller")
eq(w.prompts[1].count, nil, "no count for a test")
w.c.Test("bullet")
eq(w.prompts[2].vendor[2], "Gun Shop", "bullet seller")
w = world({ pos = { 7, 0, 0 } })
eq(w.c.Test("arrow"):find("vendor selling arrows", 1, true) ~= nil, true, "no arrow vendor message")

-- Dialog text.
local sell = ns.Controller.PromptText("sell", { 1, "Near Seller" }, "Elwynn Forest")
eq(sell, "Your bags are almost full.\n\nNavigate to the closest vendor, Near Seller (Elwynn Forest)?", "sell text")
local rep = ns.Controller.PromptText("repair", { 2, "Far Repairer" }, nil)
eq(rep, "Your gear needs repair.\n\nNavigate to the closest repair vendor, Far Repairer?", "repair text without zone")

local a1 = ns.Controller.PromptText("arrow", { 3, "Arrow Man" }, "Elwynn Forest", 150)
eq(a1, "You are low on arrows (150 left).\n\nNavigate to the closest vendor that sells arrows, Arrow Man (Elwynn Forest)?", "arrow text")
local a2 = ns.Controller.PromptText("bullet", { 4, "Gun Shop" }, nil, nil)
eq(a2, "You are low on bullets.\n\nNavigate to the closest vendor that sells bullets, Gun Shop?", "bullet text without count or zone")

-- Debug log lines: what was seen, what was decided, and why.
local function has(w, text) return table.concat(w.logs, "\n"):find(text, 1, true) ~= nil end
w = world({ free = 1, dur = 55, ammoKind = "arrow", ammoCount = 900, autoAccept = false })
w.c.Evaluate()
eq(has(w, "trigger go sell (bags=1 durability=55% ammo=arrow:900 combat=false)"), true, "decision with the values behind it: " .. table.concat(w.logs, " / "))
eq(has(w, "question shown: sell, Near Seller (npc 1)"), true, "question shown")
w.prompts[1].accept()
eq(has(w, "accepted: Near Seller via "), true, "acceptance")
w.free = 20
w.c.Evaluate()
eq(has(w, "trigger clear"), true, "clear decision")

w = world({ free = 1, autoAccept = false })
w.c.Evaluate()
w.free = 20
w.c.Evaluate()
w.prompts[1].accept()
eq(has(w, "answer ignored: the question was withdrawn"), true, "stale answer noted")

w = world({ free = 1, pos = false })
w.c.Evaluate()
eq(has(w, "no map position yet: sell request kept for a retry"), true, "waiting for a position")
w.pos = { 1, 0, 0 }
w.c.Evaluate()
eq(has(w, "retrying the sell request"), true, "retry noted")

w = world({ free = 1, pos = { 7, 0, 0 } })
w.c.Evaluate()
eq(has(w, "no known vendor for sell on this continent"), true, "no vendor noted")

w = world({ ammoKind = "arrow", ammoCount = 10, combat = true })
w.c.Evaluate()
eq(has(w, "trigger"), false, "nothing decided in combat, nothing logged")

w = world({})
w.c.OnMerchantShow()
w.c.Test("repair")
eq(has(w, "merchant window opened"), true, "merchant noted")
eq(has(w, "test command: repair"), true, "test command noted")

-- The logger is optional.
w = world({ free = 1, noLog = true })
w.c.Evaluate(); w.c.OnMerchantShow(); w.c.Test("sell")
eq(#w.prompts >= 1, true, "works without a logger")

-- Profession trainers ---------------------------------------------------------------------------------------
-- { npcId, name, uiMapID, mx, my, faction, trades, wx, wy }
local TRAINERS = {
    { 20, "Near Miner", 100, 0.1, 0.1, 0, { Mining = true }, 10, 0 },
    { 21, "Far Miner",  100, 0.9, 0.1, 0, { Mining = true }, 90, 0 },
    { 22, "Herb Lady",  100, 0.2, 0.1, 0, { Herbalism = true }, 20, 0 },
}
local function mining(rank, max) return { { name = "Mining", rank = rank, max = max or 75 } } end
local function trade(over)
    local o = { known = { Mining = true, Herbalism = true }, skills = mining(70), trainers = { [1] = TRAINERS } }
    for k, v in pairs(over or {}) do o[k] = v end
    return world(o)
end

-- Near the cap: ask about the nearest trainer for that profession; Yes sets the pin.
w = trade()
w.c.OnCraft()
eq(#w.prompts, 1, "trainer question asked")
eq(w.prompts[1].kind, "trainer", "kind")
eq(w.prompts[1].vendor[2], "Near Miner", "nearest trainer for the profession")
eq(w.prompts[1].count, 5, "points left passed on")
eq(w.prompts[1].trade, "Mining", "profession passed on")
eq(w.setCount, 1, "accepted: pin set")
eq(w.last[2], "Near Miner", "pin is the trainer")

-- The other profession's trainer is never chosen, however near.
w = trade({ skills = { { name = "Herbalism", rank = 70, max = 75 } } })
w.c.OnCraft()
eq(w.prompts[1].vendor[2], "Herb Lady", "herbalism trainer")

-- Far from the cap, the final tier, an unknown skill and a missing skill list: no question.
w = trade({ skills = mining(50) }); w.c.OnCraft()
eq(#w.prompts, 0, "far from the cap")
w = trade({ skills = mining(300, 300) }); w.c.OnCraft()
eq(#w.prompts, 0, "final tier")
w = trade({ known = {} }); w.c.OnCraft()
eq(#w.prompts, 0, "profession not known")
w = trade({ skills = false }); w.c.OnCraft()
eq(#w.prompts, 0, "skills unreadable")
w = trade({ skills = mining(150, 150), level = 15 }); w.c.OnCraft()
eq(#w.prompts, 0, "150/150 at level 15: the trainer would refuse Expert, no question")
w = trade({ skills = mining(150, 150), level = 20 }); w.c.OnCraft()
eq(#w.prompts, 1, "150/150 at level 20: ask")

-- Declined: asked again on the next craft (no latch). Open question: not asked twice.
w = trade({ autoAccept = false })
w.c.OnCraft()
eq(#w.prompts, 1, "asked")
w.c.OnCraft()
eq(#w.prompts, 1, "question still open: not asked again")
w.open = false -- the player said No
w.c.OnCraft()
eq(#w.prompts, 2, "asked again after a No")
eq(w.setCount, 0, "nothing navigated")

-- An active trainer waypoint suppresses new questions.
w = trade()
w.c.OnCraft(); w.c.OnCraft(); w.c.OnCraft()
eq(#w.prompts, 1, "one trip at a time")

-- Combat: the check is skipped, the next event after combat asks.
w = trade({ combat = true })
w.c.OnCraft()
eq(#w.prompts, 0, "no question in combat")
w.combat = false
w.c.OnCraft()
eq(#w.prompts, 1, "asked after combat")

-- Switched off, and a custom threshold.
w = trade({ cfg = { tradeEnabled = false } })
w.c.OnCraft()
eq(#w.prompts, 0, "switched off")
w = trade({ cfg = { tradeThreshold = 2 } })
w.c.OnCraft()
eq(#w.prompts, 0, "5 away with threshold 2")
w = trade({ cfg = { tradeThreshold = 5 } })
w.c.OnCraft()
eq(#w.prompts, 1, "5 away with threshold 5")

-- Position unknown: nothing, and no notice either.
w = trade({ pos = false })
w.c.OnCraft()
eq(#w.prompts, 0, "no position: no question")
eq(#w.says, 0, "no position: no notice")

-- No trainer known: a notice once per profession, no question.
w = trade({ trainers = {} })
w.c.OnCraft()
eq(#w.prompts, 0, "no trainer: no question")
eq(#w.says, 1, "no trainer: notice")
eq(w.says[1]:find("Mining", 1, true) ~= nil, true, "notice names the profession")
w.c.OnCraft()
eq(#w.says, 1, "notice not repeated")
w.skills = { { name = "Mining", rank = 70, max = 75 }, { name = "Herbalism", rank = 70, max = 75 } }
w.c.OnCraft()
eq(#w.says, 2, "a second profession gets its own notice")

-- Trainers on another continent, or of the other faction, do not count.
w = trade({ trainers = { [2] = TRAINERS } })
w.c.OnCraft()
eq(#w.prompts, 0, "other continent")
eq(#w.says, 1, "other continent: notice")
w = trade({ trainers = { [1] = { { 30, "Horde Miner", 100, 0.1, 0.1, 2, { Mining = true }, 10, 0 } } } })
w.c.OnCraft()
eq(#w.prompts, 0, "hostile faction trainer skipped")

-- Order: nearest the cap first; a profession without a trainer does not hide the next one.
w = trade({ skills = { { name = "Mining", rank = 70, max = 75 }, { name = "Herbalism", rank = 73, max = 75 } } })
w.c.OnCraft()
eq(w.prompts[1].trade, "Herbalism", "closest to the cap first")
w = trade({ skills = { { name = "Mining", rank = 70, max = 75 }, { name = "Herbalism", rank = 73, max = 75 } },
            trainers = { [1] = { TRAINERS[1] } } })
w.c.OnCraft()
eq(w.prompts[1].trade, "Mining", "falls through to a profession that has a trainer")
eq(#w.says, 1, "and tells about the one that has none")

-- Skill changes: the first read only stores; a rise asks; unchanged values do not.
w = trade({ skills = mining(70) })
w.c.OnSkillChange()
eq(#w.prompts, 0, "first read only stores")
w.skills = mining(71)
w.c.OnSkillChange()
eq(#w.prompts, 1, "a skill-up asks")
w = trade({ skills = mining(70), autoAccept = false })
w.c.OnSkillChange()
w.c.OnSkillChange()
eq(#w.prompts, 0, "unchanged skills do not ask")

-- Priority: trainer is lowest.
w = trade({ free = 1, autoAccept = false })
w.c.Evaluate()
eq(w.prompts[1].kind, "sell", "sell question open")
w.c.OnCraft()
eq(#w.prompts, 1, "trainer does not replace an open sell question")
w = trade({ free = 1 })
w.c.Evaluate()
w.c.OnCraft()
eq(#w.prompts, 1, "trainer waits while a sell request is active")
w = trade({ autoAccept = false })
w.c.OnCraft()
eq(w.prompts[1].kind, "trainer", "trainer question open")
w.free = 1
w.c.Evaluate()
eq(w.prompts[2].kind, "sell", "sell replaces an open trainer question")
w = trade()
w.c.OnCraft()
w.free = 1
w.c.Evaluate()
eq(w.last[2], "Near Seller", "a sell trip replaces a trainer pin")

-- A merchant window leaves a trainer pin and a trainer question alone.
w = trade()
w.c.OnCraft()
w.c.OnMerchantShow()
eq(w.clearCount, 0, "merchant leaves the trainer pin")
w.c.OnTrainerShow({ Mining = true })
eq(w.clearCount, 1, "so the pin was still there for the trainer window to clear")
w = world({ free = 1 }); w.c.Evaluate(); w.c.OnMerchantShow()
eq(w.clearCount, 1, "control: a merchant still clears a vendor pin")
w = trade({ autoAccept = false })
w.c.OnCraft()
local cancels = w.cancelCount
w.c.OnMerchantShow()
eq(w.cancelCount, cancels, "merchant keeps an open trainer question")

-- A trainer window for the profession ends the trip; another profession's does not.
w = trade()
w.c.OnCraft()
local before = w.clearCount
w.c.OnTrainerShow({ Herbalism = true })
eq(w.clearCount, before, "other profession's trainer: pin stays")
w.c.OnTrainerShow({ Mining = true })
eq(w.clearCount, before + 1, "its own trainer: pin cleared")
w.c.OnCraft()
eq(#w.prompts, 2, "asks again once the pin is gone")
w = trade({ autoAccept = false })
w.c.OnCraft()
w.c.OnTrainerShow({ Herbalism = true })
eq(w.cancelCount, 0, "other profession's trainer: question stays")
w.c.OnTrainerShow({ Mining = true })
eq(w.cancelCount, 1, "its own trainer: question closed")

-- The pin ends when the profession is no longer near its cap (a higher tier was learned).
w = trade()
w.c.OnCraft()
before = w.clearCount
w.skills = mining(70, 150)
w.c.OnCraft()
eq(w.clearCount, before + 1, "pin cleared after the cap rose")
w.skills = mining(70)
w.c.OnCraft()
eq(#w.prompts, 2, "and a later approach asks again")

-- Prompt text.
local text = ns.Controller.PromptText("trainer", TRAINERS[1], "Ironforge", 5, "Mining")
eq(text:find("Mining", 1, true) ~= nil and text:find("5", 1, true) ~= nil, true, "text names profession and points")
eq(text:find("Near Miner (Ironforge)", 1, true) ~= nil, true, "text names the trainer and zone")
text = ns.Controller.PromptText("trainer", TRAINERS[1], nil, 0, "Mining")
eq(text:find("reached", 1, true) ~= nil, true, "at the cap reads differently")
eq(text:find("0 point", 1, true) == nil, true, "no zero points")
eq(text:find("(", 1, true) == nil, true, "no zone: no parentheses")

-- Edge cases found by mutation testing.
-- Navigation unavailable: Yes sets nothing, so no trip is in progress and the next event asks again.
w = world({ known = { Mining = true }, skills = mining(70), trainers = { [1] = TRAINERS }, nilNav = true })
w.c.OnCraft(); w.c.OnCraft()
eq(#w.prompts, 2, "no pin was set, so the next craft asks again")

-- The pin ends only when its own profession leaves the threshold, not when another one is near.
w = trade({ skills = { { name = "Mining", rank = 70, max = 75 } } })
w.c.OnCraft()
before = w.clearCount
w.skills = { { name = "Mining", rank = 70, max = 150 }, { name = "Herbalism", rank = 72, max = 75 } }
w.c.OnCraft()
eq(w.clearCount, before + 1, "pin cleared although another profession is near its cap")

-- Faction: an Alliance trainer is fine for an Alliance player; a trainer on the player's continent only.
w = trade({ trainers = { [1] = { { 31, "Ally Miner", 100, 0.1, 0.1, 1, { Mining = true }, 10, 0 } } } })
w.c.OnCraft()
eq(#w.prompts, 1, "same-faction trainer is eligible")
w = trade({ pos = { 2, 0, 0 }, trainers = { [1] = TRAINERS, [2] = { { 32, "Other Continent", 100, 0.1, 0.1, 0, { Mining = true }, 10, 0 } } } })
w.c.OnCraft()
eq(w.prompts[1].vendor[2], "Other Continent", "the player's own continent is searched")

-- A vendor request ending (bags freed) does not take a trainer pin away.
w = trade({ autoAccept = false })
w.c.OnCraft()
w.prompts[1].accept()
w.open = false
w.free = 1
w.c.Evaluate()
eq(w.prompts[2].kind, "sell", "sell question while the trainer trip is on")
w.open = false -- the player said No
before = w.clearCount
w.free = 20
w.c.Evaluate()
eq(w.clearCount, before, "bags freed: the trainer pin stays")

-- Map-aware choice -----------------------------------------------------------------------------------------
-- Other (map 200) is nearest; Home (map 100) is farther but on the player's map.
local MAPV = {
    { 31, "Other Seller", 200, 0.1, 0.1, 0, false, 0, 10, 0 },
    { 32, "Home Seller",  100, 0.5, 0.1, 0, false, 0, 50, 0 },
}
local function mapped(over)
    local o = { free = 1, buckets = { [1] = MAPV }, pos = { 1, 0, 0, 100 } }
    for k, v in pairs(over or {}) do o[k] = v end
    return world(o)
end

-- Ask mode, prefer map (the defaults when unset): current-map vendor first, the closer one second.
w = mapped({ autoAccept = false })
w.c.Evaluate()
eq(#w.prompts, 1, "one question")
eq(w.prompts[1].vendor[2], "Home Seller", "map preference: current-map vendor is first")
eq(w.prompts[1].two.other[2], "Other Seller", "the closer vendor is offered second")
eq(w.prompts[1].two.mapFirst, true, "first is the map one")
eq(w.prompts[1].two.dist, 50, "distance of the first")
eq(w.prompts[1].two.otherDist, 10, "distance of the second")
eq(w.setCount, 0, "nothing pinned before an answer")
w.prompts[1].accept()
eq(w.last[2], "Home Seller", "first button pins the first")
w = mapped({ pickOther = true })
w.c.Evaluate()
eq(w.last[2], "Other Seller", "second button pins the other vendor")
eq(w.setCount, 1, "exactly one pin")

-- Prefer distance: the closer vendor is first.
w = mapped({ autoAccept = false, cfg = { vendorPrefer = "distance" } })
w.c.Evaluate()
eq(w.prompts[1].vendor[2], "Other Seller", "distance preference: closer vendor first")
eq(w.prompts[1].two.mapFirst, false, "first is not the map one")
eq(w.prompts[1].two.other[2], "Home Seller", "the map vendor is second")

-- Cancel: no pin; a late answer after the question is withdrawn is ignored.
w = mapped({ autoAccept = false })
w.c.Evaluate()
w.c.OnMerchantShow()
w.prompts[1].two.acceptOther()
eq(w.setCount, 0, "a withdrawn question cannot navigate (second button)")
w.prompts[1].accept()
eq(w.setCount, 0, "a withdrawn question cannot navigate (first button)")

-- One candidate: the nearest is on the player's map, there is no map, or nothing is on the map.
w = mapped({ autoAccept = false, pos = { 1, 60, 0, 100 } })
w.c.Evaluate()
eq(w.prompts[1].vendor[2], "Home Seller", "nearest is on the map")
eq(w.prompts[1].two, nil, "plain question")
w = mapped({ autoAccept = false, pos = { 1, 0, 0 } })
w.c.Evaluate()
eq(w.prompts[1].vendor[2], "Other Seller", "no map id: the nearest")
eq(w.prompts[1].two, nil, "no map id: plain question")
w = mapped({ autoAccept = false, pos = { 1, 0, 0, 300 } })
w.c.Evaluate()
eq(w.prompts[1].vendor[2], "Other Seller", "nothing on the map: the nearest")
eq(w.prompts[1].two, nil, "nothing on the map: plain question")

-- Auto mode: no question; map preference pins the current-map vendor, distance the closer one.
w = mapped({ cfg = { vendorMode = "auto" } })
w.c.Evaluate()
eq(#w.prompts, 0, "auto: no question")
eq(w.setCount, 1, "auto: pinned")
eq(w.last[2], "Home Seller", "auto, prefer map")
eq(#w.says, 1, "auto: one chat line")
eq(w.says[1], "Navigating to Home Seller (50 yards) to sell items and free bag space. The other choice was Other Seller (10 yards).", "auto: names both targets, no zones known")
eq(w.notes[1], w.says[1], "auto: the on-screen message is the same text")
w = mapped({ cfg = { vendorMode = "auto", vendorPrefer = "distance" } })
w.c.Evaluate()
eq(w.last[2], "Other Seller", "auto, prefer distance")
w = mapped({ pos = { 1, 60, 0, 100 }, cfg = { vendorMode = "auto" } })
w.c.Evaluate()
eq(#w.prompts, 0, "auto with one candidate: no question")
eq(w.last[2], "Home Seller", "auto with one candidate pins it")

-- Auto still waits for the usual gates.
w = mapped({ combat = true, cfg = { vendorMode = "auto" } })
w.c.Evaluate()
eq(w.setCount, 0, "auto: nothing pinned in combat")

-- /cvn test goes through the same choice.
w = mapped({ free = 20, autoAccept = false })
w.c.Test("sell")
eq(w.prompts[1].two.other[2], "Other Seller", "test command offers both")

-- Trainers follow the same rule.
local MTR = {
    { 40, "Other Miner", 200, 0.1, 0.1, 0, { Mining = true }, 10, 0 },
    { 41, "Home Miner",  100, 0.5, 0.1, 0, { Mining = true }, 50, 0 },
}
local function mtrade(over)
    local o = { known = { Mining = true }, skills = mining(70), trainers = { [1] = MTR }, pos = { 1, 0, 0, 100 } }
    for k, v in pairs(over or {}) do o[k] = v end
    return world(o)
end
w = mtrade({ autoAccept = false })
w.c.OnCraft()
eq(w.prompts[1].kind, "trainer", "trainer question")
eq(w.prompts[1].vendor[2], "Home Miner", "trainer: map one first")
eq(w.prompts[1].two.other[2], "Other Miner", "trainer: closer one second")
eq(w.prompts[1].count, 5, "trainer: points left passed on")
w = mtrade({ cfg = { vendorMode = "auto" } })
w.c.OnCraft()
eq(#w.prompts, 0, "trainer auto: no question")
eq(w.last[2], "Home Miner", "trainer auto: pinned")
w.free = 20
w.c.Evaluate()
eq(w.clearCount, 0, "trainer auto: the pin is a trainer pin, vendor events leave it")
w = mtrade({ cfg = { vendorMode = "auto", vendorPrefer = "distance" }, combat = true })
w.c.OnCraft()
eq(w.setCount, 0, "trainer auto: combat blocks")

-- PromptText with two targets.
local T = ns.Controller.PromptText
local txt = T("repair", MAPV[2], "Elwynn", nil, nil, { other = MAPV[1], dist = 50, otherDist = 10 }, "Westfall")
eq(txt:find("Home Seller (Elwynn, 50 yards)", 1, true) ~= nil, true, "first target has zone and distance")
eq(txt:find("Other Seller (Westfall, 10 yards)", 1, true) ~= nil, true, "second target has zone and distance")
txt = T("sell", MAPV[2], nil, nil, nil, { other = MAPV[1], dist = 50, otherDist = 10 }, nil)
eq(txt:find("Home Seller (50 yards)", 1, true) ~= nil, true, "no zone: name and distance")
eq(T("trainer", MTR[2], "A", 5, "Mining", { other = MTR[1], dist = 1, otherDist = 2 }, "B"):find("Mining", 1, true) ~= nil, true, "trainer text names the profession")

-- Auto notice: zones, one candidate, the other candidate, the switch, no notify function, trainers.
w = mapped({ cfg = { vendorMode = "auto" }, zones = { [100] = "Elwynn", [200] = "Westfall" } })
w.c.Evaluate()
eq(w.says[1], "Navigating to Home Seller (Elwynn, 50 yards) to sell items and free bag space. The other choice was Other Seller (Westfall, 10 yards).", "notice has zones and distances for both")
eq(#w.notes, 1, "one on-screen message")
w = mapped({ cfg = { vendorMode = "auto", vendorPrefer = "distance" }, zones = { [100] = "Elwynn", [200] = "Westfall" } })
w.c.Evaluate()
eq(w.says[1], "Navigating to Other Seller (Westfall, 10 yards) to sell items and free bag space. The other choice was Home Seller (Elwynn, 50 yards).", "distance preference names the pinned one first")
w = mapped({ pos = { 1, 60, 0, 100 }, cfg = { vendorMode = "auto" }, zones = { [100] = "Elwynn" } })
w.c.Evaluate()
eq(w.says[1], "Navigating to Home Seller (Elwynn, 10 yards) to sell items and free bag space.", "single candidate: no other choice")
w = mapped({ cfg = { vendorMode = "auto", autoNotice = false } })
w.c.Evaluate()
eq(#w.notes, 0, "notice off: no on-screen message")
eq(#w.says, 1, "notice off: the chat line still prints")
eq(w.setCount, 1, "notice off: still pinned")
w = mapped({ cfg = { vendorMode = "auto" }, noNotify = true })
w.c.Evaluate()
eq(#w.says, 1, "no notify function: chat only, no error")
w = mtrade({ cfg = { vendorMode = "auto" }, zones = { [100] = "Elwynn", [200] = "Westfall" } })
w.c.OnCraft()
eq(w.says[1], "Navigating to Home Miner (Elwynn, 50 yards) to train Mining. The other choice was Other Miner (Westfall, 10 yards).", "trainer notice")
eq(w.notes[1], w.says[1], "trainer on-screen message")
w = mapped({ autoAccept = false })
w.c.Evaluate()
eq(#w.notes, 0, "ask mode: no on-screen message")

-- Reagents ---------------------------------------------------------------------------------------------------
local POWDER, PORTALS = ns.Reagents.ById(17020), ns.Reagents.ById(17032)
-- { npcId, name, uiMapID, mx, my, faction, repair, ammo, wx, wy, reagents }
local RV = {
    { 1, "Plain Seller",  100, 0.1, 0.1, 0, false, 0, 5, 0, 0 },
    { 2, "Powder Seller", 100, 0.3, 0.1, 0, false, 0, 30, 0, 1 },
    { 3, "Rune Seller",   100, 0.6, 0.1, 0, false, 0, 60, 0, 4 },
}
local function reagent(over)
    local o = { buckets = { [1] = RV }, reagents = { { item = POWDER, count = 3, name = "Arcane Powder" } } }
    for k, v in pairs(over or {}) do o[k] = v end
    return world(o)
end

-- A low reagent asks about the nearest vendor that sells it; Yes sets the pin.
w = reagent()
w.c.Evaluate()
eq(#w.prompts, 1, "reagent question asked")
eq(w.prompts[1].kind, "reagent", "kind")
eq(w.prompts[1].vendor[2], "Powder Seller", "nearest seller of that reagent, not the nearest vendor")
eq(w.prompts[1].count, 3, "count passed")
eq(w.prompts[1].trade, "Arcane Powder", "reagent name passed")
eq(w.setCount, 1, "Yes sets the pin")
eq(w.last[2], "Powder Seller", "pin is the seller")
w.c.Evaluate()
eq(#w.prompts, 1, "not asked again while low")

-- The threshold is inclusive; above it nothing is asked; combat holds it back.
w = reagent({ reagents = { { item = POWDER, count = 5, name = "Arcane Powder" } } })
w.c.Evaluate()
eq(#w.prompts, 1, "at the threshold: asks")
w = reagent({ reagents = { { item = POWDER, count = 6, name = "Arcane Powder" } } })
w.c.Evaluate()
eq(#w.prompts, 0, "above the threshold: nothing")
w = reagent({ cfg = { reagentThreshold = 10 }, reagents = { { item = POWDER, count = 10, name = "Arcane Powder" } } })
w.c.Evaluate()
eq(#w.prompts, 1, "a higher reagent threshold applies")
w = reagent({ combat = true })
w.c.Evaluate()
eq(#w.prompts, 0, "no question in combat")
w.combat = false
w.c.Evaluate()
eq(#w.prompts, 1, "asked after combat")

-- The reagents switch turns reagent questions off; the ammo switch does not.
w = reagent({ cfg = { reagentsEnabled = false } })
w.c.Evaluate()
eq(#w.prompts, 0, "reagents switch off")
w = reagent({ cfg = { ammoEnabled = false } })
w.c.Evaluate()
eq(#w.prompts, 1, "ammo switch off: reagents still asked")

-- Recovering withdraws the pin and the question.
w = reagent()
w.c.Evaluate()
w.reagents[1].count = 40
w.c.Evaluate()
eq(w.clearCount, 1, "pin cleared when the reagent is restocked")

-- Two reagents low: one question, the second after the first resolves.
w = reagent({ autoAccept = false, reagents = { { item = POWDER, count = 1, name = "Arcane Powder" }, { item = PORTALS, count = 2, name = "Rune of Portals" } } })
w.c.Evaluate()
eq(#w.prompts, 1, "one question")
eq(w.prompts[1].trade, "Arcane Powder", "first in list order")
w.c.Evaluate()
eq(#w.prompts, 1, "second waits")
w.c.OnMerchantShow()
w.c.Evaluate()
eq(#w.prompts, 2, "second asked after the merchant")
eq(w.prompts[2].trade, "Rune of Portals", "second reagent")
eq(w.prompts[2].vendor[2], "Rune Seller", "its own seller")

-- No known seller: one chat line, never a dialog, not repeated.
w = reagent({ buckets = { [1] = { RV[1] } } })
w.c.Evaluate()
eq(#w.prompts, 0, "no seller: no question")
eq(#w.says, 1, "one chat line")
eq(w.says[1]:find("Arcane Powder", 1, true) ~= nil, true, "names the reagent")
w.reagents[1].count = 40
w.c.Evaluate()
w.reagents[1].count = 2
w.c.Evaluate()
eq(#w.says, 1, "told once per reagent")

-- No map position: kept and retried; if the reagent recovers meanwhile, dropped.
w = reagent({ pos = false })
w.c.Evaluate()
eq(w.c.pending, "reagent", "kept pending")
w.pos = { 1, 0, 0 }
w.c.Evaluate()
eq(#w.prompts, 1, "placed once there is a position")
w = reagent({ pos = false })
w.c.Evaluate()
w.reagents[1].count = 40
w.c.Evaluate()
eq(w.c.pending, nil, "dropped when restocked")

-- Another map: both targets offered, like any vendor question.
local RM = {
    { 1, "Other Map Seller", 200, 0.1, 0.1, 0, false, 0, 20, 0, 1 },
    { 2, "Home Seller",      100, 0.5, 0.1, 0, false, 0, 60, 0, 1 },
}
w = reagent({ buckets = { [1] = RM }, pos = { 1, 0, 0, 100 }, zones = { [100] = "Home", [200] = "Away" } })
w.c.Evaluate()
eq(w.prompts[1].vendor[2], "Home Seller", "the one on the player's map first")
eq(w.prompts[1].two.other[2], "Other Map Seller", "the closer one second")
eq(w.setCount, 1, "first choice taken")

-- Auto mode: pinned at once, with the notice.
w = reagent({ cfg = { vendorMode = "auto" } })
w.c.Evaluate()
eq(#w.prompts, 0, "auto: no question")
eq(w.setCount, 1, "auto: pinned")
eq(#w.notes, 1, "auto: on-screen notice")
eq(w.notes[1], "Navigating to Powder Seller (30 yards) to buy Arcane Powder.", "auto: the notice says what to buy")
eq(w.says[1], w.notes[1], "auto: and so does the chat line")
w = reagent({ cfg = { vendorMode = "auto" }, buckets = { [1] = RM }, pos = { 1, 0, 0, 100 }, zones = { [100] = "Home", [200] = "Away" } })
w.c.Evaluate()
eq(w.notes[1], "Navigating to Home Seller (Home, 60 yards) to buy Arcane Powder. The other choice was Other Map Seller (Away, 20 yards).", "auto, two candidates: what to buy and the other choice")

-- Reagent questions never override a vendor request that is open (repair first).
w = reagent({ dur = 5, autoAccept = false, buckets = { [1] = { RV[2], { 4, "Repairer", 100, 0.5, 0.1, 0, true, 0, 40, 0, 0 } } } })
w.c.Evaluate()
eq(w.prompts[1].kind, "repair", "repair first")
w.c.Evaluate()
eq(#w.prompts, 1, "reagent waits for the repair question")

-- Text.
eq(ns.Controller.PromptText("reagent", RV[2], nil, 3, "Arcane Powder"):find("low on Arcane Powder (3 left)", 1, true) ~= nil, true, "single text")
eq(ns.Controller.PromptText("reagent", RV[2], "Home", 3, "Arcane Powder", { other = RV[3], dist = 5, otherDist = 9 }, "Away"):find("Which vendor that sells Arcane Powder", 1, true) ~= nil, true, "two-target text names what to buy")
eq(ns.Controller.PromptText("reagent", RV[2], nil, 3, "Arcane Powder"):find("closest vendor that sells Arcane Powder, Powder Seller?", 1, true) ~= nil, true, "single text names what to buy")

-- /cvn test reagent.
w = reagent({ reagents = { { item = POWDER, count = 80, name = "Arcane Powder" } } })
eq(w.c.Test("reagent"), nil, "test asks even when plentiful")
eq(w.prompts[1].vendor[2], "Powder Seller", "test question")
w = reagent({ reagents = {} })
eq(w.c.Test("reagent") ~= nil, true, "nothing watched: a message")
eq(#w.prompts, 0, "and no dialog")
w = reagent({ buckets = { [1] = { RV[1] } } })
eq(w.c.Test("reagent"):find("Arcane Powder", 1, true) ~= nil, true, "no seller: says so")
w = reagent({ pos = false })
eq(w.c.Test("reagent"):find("No map position", 1, true) ~= nil, true, "no position")

-- Reagents: the controller decides "low" with Reagents.Low, the test the status window also uses.
local realLow = ns.Reagents.Low
local lowCalls = {}
ns.Reagents.Low = function(items, count, threshold)
    lowCalls[#lowCalls + 1] = { n = #items, count = count(items[1].id), threshold = threshold }
    return {}
end
w = reagent({ reagents = { { item = POWDER, count = 1, name = "Arcane Powder" } } })
w.c.Evaluate()
ns.Reagents.Low = realLow
eq(#lowCalls, 1, "Evaluate asks Reagents.Low")
eq(lowCalls[1].n .. ":" .. lowCalls[1].count .. ":" .. lowCalls[1].threshold, "1:1:5", "with the watched items, their counts and the threshold")
eq(w.setCount, 0, "and follows its answer: nothing low, nothing asked")

-- Instances -----------------------------------------------------------------------------------------------
-- Triggers wait inside and keep their latch: the question comes after leaving.
w = world({ free = 1, instance = "pvp", pos = { 7, 0, 0 } }) -- a battleground has a position but no vendors
w.c.Evaluate()
eq(w.setCount, 0, "battleground: nothing pinned")
eq(#w.prompts, 0, "battleground: nothing asked")
w.instance, w.pos = "none", { 1, 0, 0 }
w.c.Evaluate()
eq(w.setCount, 1, "asked after leaving with full bags")
w = world({ dur = 5, instance = "party" })
w.c.Evaluate()
eq(#w.prompts, 0, "dungeon: nothing asked")
w.instance = nil
w.c.Evaluate()
eq(w.prompts[1].kind, "repair", "asked outside (unknown instance state is the open world)")
w = world({ free = 1, instance = "raid" })
w.c.Evaluate()
w.free = 20; w.instance = "none"
w.c.Evaluate()
eq(#w.prompts, 0, "resolved before leaving: never asked")
-- A request waiting for a position is not retried inside.
w = world({ free = 1, pos = false })
w.c.Evaluate()
w.instance, w.pos = "pvp", { 7, 0, 0 }
w.c.Evaluate()
eq(w.c.pending, "sell", "the waiting request is kept inside")
w.instance, w.pos = "none", { 1, 0, 0 }
w.c.Evaluate()
eq(w.setCount, 1, "and placed after leaving")
-- Professions wait too.
w = trade({ instance = "party" })
w.c.OnCraft()
eq(#w.prompts, 0, "profession question waits in a dungeon")
w.instance = "none"
w.c.OnCraft()
eq(#w.prompts, 1, "and is asked outside")

-- Pin kinds --------------------------------------------------------------------------------------------------
w = world({ free = 1 })
eq(w.c.PinKind(), nil, "no waypoint: no kind")
w.c.Evaluate()
eq(w.c.PinKind(), "sell", "a sell pin knows what it is for")
w.c.OnMerchantShow()
eq(w.c.PinKind(), nil, "cleared with the waypoint")
w = world({ ammoKind = "arrow", ammoCount = 10 })
w.c.Evaluate()
eq(w.c.PinKind(), "ammo", "arrows and bullets are an ammo pin")
w = reagent()
w.c.Evaluate()
local pk, pid = w.c.PinKind()
eq(pk .. ":" .. pid, "reagent:17020", "a reagent pin knows its item")
w = trade(); w.c.OnCraft()
eq(w.c.PinKind(), "trainer", "a trainer pin")
w = world({ free = 1, nilNav = true })
w.c.Evaluate()
eq(w.c.PinKind(), nil, "no waypoint could be set: no kind")

-- A trigger that ends removes only a pin of its own kind. Sell declined, ammo pinned by a click,
-- then the bags are emptied: the ammo pin stays.
w = world({ free = 1, ammoKind = "arrow", ammoCount = 900, autoAccept = false })
w.c.Evaluate()
eq(w.prompts[1].kind, "sell", "sell asked")
w.open = false -- the player said No
eq(w.c.Go("ammo"), true, "ammo pinned by a click")
eq(w.last[2], "Arrow Man", "the arrow vendor")
w.free = 20
w.c.Evaluate()
eq(w.clearCount, 0, "sell ended: the ammo pin stays")
eq(w.c.PinKind(), "ammo", "still the ammo pin")
w.c.OnMerchantShow()
eq(w.clearCount, 1, "a merchant window clears every vendor pin")
-- Its own kind still clears.
w = world({ free = 1 })
w.c.Evaluate()
w.free = 20
w.c.Evaluate()
eq(w.clearCount, 1, "sell ended: the sell pin is cleared")
-- One reagent ending does not remove another reagent's pin.
w = reagent({ autoAccept = false, reagents = { { item = POWDER, count = 1, name = "Arcane Powder" }, { item = PORTALS, count = 9, name = "Rune of Portals" } } })
w.c.Evaluate()
w.open = false
eq(w.c.Go("reagent", 17032), true, "the other reagent pinned by a click")
w.reagents[1].count = 50
w.c.Evaluate()
eq(w.clearCount, 0, "powder restocked: the rune pin stays")

-- Direct pin (Go) --------------------------------------------------------------------------------------------
-- Ask mode: pinned at once, no question, and the usual notice says why.
w = world({ dur = 100, zones = { [100] = "Elwynn" } })
eq(w.c.Go("repair"), true, "pinned")
eq(#w.prompts, 0, "ask mode: no question")
eq(w.last[2], "Far Repairer", "the nearest repair vendor")
eq(w.says[1], "Navigating to Far Repairer (Elwynn, 90 yards) to repair your gear.", "chat says why")
eq(w.notes[1], w.says[1], "and so does the on-screen notice")
eq(#w.says, 1, "nothing about anchors in the open world")
eq(w.c.PinKind(), "repair", "the pin knows its kind")
w = world({ cfg = { autoNotice = false } })
w.c.Go("sell")
eq(#w.notes, 0, "notice switched off: chat only")
eq(#w.says, 1, "chat line still printed")
-- Combat does not hold it back.
w = world({ combat = true })
eq(w.c.Go("sell"), true, "pinned in combat")
eq(w.last[2], "Near Seller", "nearest vendor")
-- The map preference chooses between the two candidates.
w = mapped({ free = 20 })
w.c.Go("sell")
eq(w.last[2], "Home Seller", "prefers the player's map by default")
eq(w.says[1]:find("The other choice was Other Seller", 1, true) ~= nil, true, "names the other choice")
w = mapped({ free = 20, cfg = { vendorPrefer = "distance" } })
w.c.Go("sell")
eq(w.last[2], "Other Seller", "distance preference: the closest")
-- Ammo follows the weapon; no weapon, nothing.
w = world({ ammoKind = "bullet", ammoCount = 900 })
w.c.Go("ammo")
eq(w.last[2], "Gun Shop", "bullets for a gun")
eq(w.says[1]:find(" to buy ammo.", 1, true) ~= nil, true, "reason is ammo")
w = world({ ammoKind = nil })
eq(w.c.Go("ammo"), false, "no ranged weapon: nothing")
eq(w.setCount + #w.says, 0, "silently")
-- Reagents by item id, named in the notice.
w = reagent({ reagents = { { item = POWDER, count = 80, name = "Arkanpulver" } } })
eq(w.c.Go("reagent", 17020), true, "reagent pinned")
eq(w.last[2], "Powder Seller", "a vendor that sells it")
eq(w.says[1]:find(" to buy Arkanpulver.", 1, true) ~= nil, true, "the game's name for it")
w = reagent({ reagents = {} })
w.c.Go("reagent", 17032)
eq(w.says[1]:find(" to buy Rune of Portals.", 1, true) ~= nil, true, "falls back to the table's name")
eq(w.c.Go("reagent", 1), false, "not a reagent: nothing")
eq(w.c.Go("nonsense"), false, "unknown kind: nothing")
-- A display-only item cannot be routed to.
local shard = { id = 6265, class = "WARLOCK", name = "Soul Shard", vendor = false }
local realById = ns.Reagents.ById
ns.Reagents.ById = function(id) if id == 6265 then return shard end return realById(id) end
w = reagent()
eq(w.c.Go("reagent", 6265), false, "display-only item: nothing pinned")
eq(w.setCount + #w.says + #w.prompts, 0, "and nothing said or asked")
ns.Reagents.ById = realById
-- No vendor and no position say so.
w = world({ pos = { 7, 0, 0 } })
eq(w.c.Go("repair"), false, "no vendor: nothing pinned")
eq(w.says[1], "No known repair vendor on this continent for your faction.", "chat says so")
w = reagent({ buckets = { [1] = { RV[1] } } })
w.c.Go("reagent", 17020)
eq(w.says[1], "No known vendor selling Arcane Powder on this continent for your faction.", "names the reagent")
w = world({ pos = false })
eq(w.c.Go("sell"), false, "no position: nothing pinned")
eq(w.says[1], "No map position here (dungeons and some areas have none). Try again outside.", "chat says so")
-- An open question about something else is closed, and its late Yes does nothing.
w = world({ free = 1, autoAccept = false })
w.c.Evaluate()
local cancelsBefore = w.cancelCount
w.c.Go("repair")
eq(w.cancelCount, cancelsBefore + 1, "the open question is closed")
eq(w.open, false, "question gone")
w.prompts[1].accept()
eq(w.last[2], "Far Repairer", "a late Yes on the old question does not move the pin")
w = world({ free = 1, autoAccept = false, pos = { 7, 0, 0 } })
w.c.Evaluate()
cancelsBefore = w.cancelCount
w.c.Go("repair")
eq(w.cancelCount, cancelsBefore, "nothing found: the question stays")
-- A low condition counts as handled: not asked again, and the pin ends when it resolves.
w = world({ free = 1, combat = true, autoAccept = false })
w.c.Evaluate()
w.c.Go("sell")
w.combat = false
w.c.Evaluate()
eq(#w.prompts, 0, "clicked while low: not asked about afterwards")
w.free = 20
w.c.Evaluate()
eq(w.clearCount, 1, "resolved: the clicked pin is cleared")
-- Not low: the pin stays until a merchant window.
w = world({ free = 20 })
w.c.Go("sell")
w.c.Evaluate()
eq(w.clearCount, 0, "not low: nothing clears it")
w.c.OnMerchantShow()
eq(w.clearCount, 1, "until a merchant window opens")
-- A request waiting for a position is dropped once the click handles it.
w = world({ free = 1, pos = false, autoAccept = false })
w.c.Evaluate()
eq(w.c.pending, "sell", "waiting for a position")
w.pos = { 1, 0, 0 }
w.c.Go("sell")
eq(w.c.pending, nil, "the click took it over")
-- Profession rows: only while within the threshold.
w = trade({ autoAccept = false })
eq(w.c.Go("trainer", "Mining"), true, "near the cap: pinned")
eq(#w.prompts, 0, "no question")
eq(w.last[2], "Near Miner", "nearest trainer for it")
eq(w.says[1]:find(" to train Mining.", 1, true) ~= nil, true, "reason is training")
eq(w.c.PinKind(), "trainer", "a trainer pin")
w.c.OnCraft()
eq(w.clearCount, 0, "the next skill check keeps it")
w = trade({ skills = mining(50) })
eq(w.c.Go("trainer", "Mining"), false, "far from the cap: nothing")
eq(w.setCount + #w.says, 0, "silently")
w = trade({ trainers = {} })
eq(w.c.Go("trainer", "Mining"), false, "no trainer known")
eq(w.says[1]:find("No known trainer for Mining", 1, true) ~= nil, true, "chat says so")

-- Direct pin inside an instance: the search starts from an anchor, and chat says which.
local HEARTH, LAST = { continent = 1, x = 95, y = 0, map = 100 }, { continent = 1, x = 48, y = 0, map = 100 }
w = world({ instance = "party", pos = false, anchors = { hearth = HEARTH, last = LAST } })
eq(w.c.Go("sell"), true, "dungeon: pinned although there is no position")
eq(w.last[2], "Far Repairer", "default anchor: closest to the hearthstone point")
eq(w.says[1]:find("(5 yards)", 1, true) ~= nil, true, "distance is from the anchor: " .. w.says[1])
eq(w.says[2], "You are in an instance, so the search started from your hearthstone point.", "chat names the anchor")
w = world({ instance = "raid", cfg = { instanceAnchor = "last" }, anchors = { hearth = HEARTH, last = LAST } })
w.c.Go("sell")
eq(w.last[2], "Arrow Man", "anchor setting last: closest to the last position outside")
eq(w.says[2], "You are in an instance, so the search started from your last position outside.", "chat names the anchor")
w = world({ instance = "party", anchors = { last = LAST } })
w.c.Go("sell")
eq(w.last[2], "Arrow Man", "hearthstone point unknown: falls back to the last position")
w = world({ instance = "party", cfg = { instanceAnchor = "last" }, anchors = { hearth = HEARTH } })
w.c.Go("sell")
eq(w.last[2], "Far Repairer", "last position unknown: falls back to the hearthstone point")
w = world({ instance = "pvp", pos = { 7, 0, 0 }, cfg = { instanceAnchor = "hearth" }, anchors = { hearth = HEARTH, last = LAST } })
w.c.Go("sell")
eq(w.last[2], "Arrow Man", "battleground: always the last position outside")
w = world({ instance = "party", anchors = {} })
eq(w.c.Go("sell"), false, "no anchor known: nothing pinned")
eq(w.says[1], "No target is known yet: the addon has not seen your hearthstone point or a position outside an instance.", "chat says so")
eq(w.setCount, 0, "no waypoint")
w = world({ instance = "party", anchors = { hearth = { continent = 7, x = 0, y = 0 } } })
eq(w.c.Go("repair"), false, "no vendor near the anchor")
eq(w.says[1], "No known repair vendor on this continent for your faction.", "chat says so")
w = trade({ instance = "party", pos = false, anchors = { hearth = HEARTH } })
w.c.Go("trainer", "Mining")
eq(w.last[2], "Far Miner", "trainers are searched from the anchor too")

-- Auction house routing (Go only) --------------------------------------------------------------------------
-- { npcId, name, uiMapID, mx, my, faction, nil, 0, wx, wy }
local function auction(over)
    local o = { buckets = { [1] = RV }, auction = { [1] = { { 90, "Auctioneer Near", 100, 0.2, 0.1, 0, nil, 0, 20, 0 } } },
                cfg = { ahEnabled = true }, reagents = { { item = POWDER, count = 3, name = "Arcane Powder" } } }
    for k, v in pairs(over or {}) do o[k] = v end
    return world(o)
end
w = auction({ pos = { 1, 20, 0 } })
eq(w.c.Go("reagent", 17020), true, "pinned")
eq(w.last[2], "Auctioneer Near", "auctioneer closer than the powder seller")
eq(w.says[1]:find("at the auction house", 1, true) ~= nil, true, "notice says to buy at the auction house: " .. w.says[1])
eq(w.c.PinKind(), "reagent", "still a reagent pin")
w = auction({ pos = { 1, 25, 0 } })
w.c.Go("reagent", 17020)
eq(w.last[2], "Powder Seller", "vendor closer: the vendor")
w = auction({ pos = { 1, 20, 0 }, cfg = { ahEnabled = false } })
w.c.Go("reagent", 17020)
eq(w.last[2], "Powder Seller", "setting off: vendors only")
w = auction({ pos = { 1, 20, 0 }, cfg = {} })
w.c.Go("reagent", 17020)
eq(w.last[2], "Powder Seller", "setting unset: vendors only")
w = auction({ pos = { 1, 20, 0 }, buckets = { [1] = {} } })
eq(w.c.Go("reagent", 17020), true, "no vendor known but an auctioneer is")
eq(w.last[2], "Auctioneer Near", "the auctioneer is pinned")
w = auction({ instance = "party", anchors = { last = { continent = 1, x = 20, y = 0 } } })
w.c.Go("reagent", 17020)
eq(w.last[2], "Powder Seller", "in an instance the setting has no effect")
POWDER.soulbound = true
w = auction({ pos = { 1, 20, 0 } })
w.c.Go("reagent", 17020)
POWDER.soulbound = nil
eq(w.last[2], "Powder Seller", "a soulbound item never goes to an auctioneer")
w = auction({ pos = { 1, 20, 0 }, ammoKind = "arrow", ammoCount = 5, buckets = { [1] = VENDORS } })
w.c.Go("ammo")
eq(w.last[2], "Auctioneer Near", "ammo can go to an auctioneer")
w = auction({ pos = { 1, 20, 0 }, dur = 50, buckets = { [1] = VENDORS } })
w.c.Go("repair")
eq(w.last[2], "Far Repairer", "repair never goes to an auctioneer")
-- Automatic triggers stay vendor-only.
w = auction({ pos = { 1, 20, 0 } })
w.c.Evaluate()
eq(w.prompts[1].vendor[2], "Powder Seller", "the question offers vendors only")
w = auction({ pos = { 1, 20, 0 }, auction = { [1] = {} } })
w.c.Go("reagent", 17020)
eq(w.last[2], "Powder Seller", "no auctioneer known: the vendor")

-- Demo -------------------------------------------------------------------------------------------------------
-- rolls: a fixed list of rolls in place of the random ones. First the warning (1 pin without asking,
-- 2 question, 3 direct pin), then the kind (1 sell, 2 repair, 3 arrows, 4 bullets).
local function rolls(...)
    local list, i = { ... }, 0
    return function(n) i = i + 1; assert(list[i] and list[i] <= n, "roll out of range"); return list[i] end
end
local function flat(t)
    local out = {}
    for k, v in pairs(t) do out[#out + 1] = tostring(k) .. "=" .. tostring(v) end
    table.sort(out)
    return table.concat(out, ",")
end
-- Pin without asking, in ask mode: the usual notice, and the pin goes after 10 seconds.
w = world({ autoAccept = false })
local saved = flat(w.liveCfg)
local dones = 0
eq(w.c.Demo(rolls(1, 2), function() dones = dones + 1 end), true, "demo started")
eq(#w.prompts, 0, "pin without asking: no question")
eq(w.last[2], "Far Repairer", "the rolled kind (repair) is pinned through the usual search")
eq(w.says[1], "Navigating to Far Repairer (90 yards) to repair your gear.", "the usual chat line")
eq(w.notes[1], w.says[1], "and the usual on-screen notice")
eq(#w.timers .. "/" .. w.timers[1].s, "1/10", "one timer, 10 seconds")
eq(w.clearCount .. "/" .. dones, "0/0", "nothing is taken back before the timer")
w.timers[1].fn()
eq(w.clearCount, 1, "time up: the demo's pin is cleared")
eq(w.c.PinKind(), nil, "no waypoint left")
eq(dones, 1, "and the caller is told")
eq(flat(w.liveCfg), saved, "pin without asking: settings exactly as before")
-- Question: shown through the usual dialog, closed after 10 seconds, a late Yes does nothing.
w = world({ autoAccept = false, cfg = { vendorMode = "auto" } })
saved = flat(w.liveCfg)
w.c.Demo(rolls(2, 3))
eq(#w.prompts .. "/" .. w.prompts[1].kind .. "/" .. w.prompts[1].vendor[2], "1/arrow/Arrow Man", "question asked even in auto mode")
eq(w.setCount, 0, "nothing pinned until it is answered")
local cancels = w.cancelCount
w.timers[1].fn()
eq(w.cancelCount, cancels + 1, "time up: the demo's question is closed")
w.prompts[1].accept()
eq(w.setCount, 0, "a Yes after the demo does nothing")
eq(flat(w.liveCfg), saved, "question: settings exactly as before")
-- Question answered Yes: that pin is the demo's and goes with it.
w = world({ autoAccept = false })
w.c.Demo(rolls(2, 1))
w.prompts[1].accept()
eq(w.setCount .. "/" .. w.clearCount, "1/0", "answered: pinned")
w.timers[1].fn()
eq(w.clearCount, 1, "time up: the pin from the demo's question is cleared")
-- Direct pin: the row-click path. Bags that really are low are still asked about afterwards.
w = world({ autoAccept = false, free = 1, combat = true })
saved = flat(w.liveCfg)
w.c.Evaluate() -- in combat: the low bags are seen but not asked about yet
w.c.Demo(rolls(3, 1))
eq(w.last[2], "Near Seller", "direct pin, in combat like any row click")
eq(#w.prompts, 0, "no question")
w.timers[1].fn()
eq(w.clearCount, 1, "time up: cleared")
w.combat = false
w.c.Evaluate()
eq(#w.prompts, 1, "the demo did not use up the real warning")
eq(flat(w.liveCfg), saved, "direct pin: settings exactly as before")
-- A second demo ends the first and restarts the 10 seconds: the first timer no longer does anything.
w = world({ autoAccept = false })
dones = 0
w.c.Demo(rolls(1, 1), function() dones = dones + 1 end)
w.c.Demo(rolls(2, 2), function() dones = dones + 10 end)
eq(w.clearCount, 1, "the first demo's pin is cleared when the second starts")
eq(#w.prompts .. "/" .. tostring(w.open), "1/true", "the second demo's question is open")
cancels = w.cancelCount
w.timers[1].fn()
eq(w.cancelCount .. "/" .. tostring(w.open) .. "/" .. dones, cancels .. "/true/0", "the first timer does not cut the second demo short")
w.timers[2].fn()
eq(tostring(w.open) .. "/" .. dones, "false/10", "the second timer ends it")
-- A waypoint set by something else during the demo is not the demo's to clear; nor is a newer question.
w = world({ autoAccept = false })
w.c.Demo(rolls(1, 1))
w.c.Go("repair")
local clears = w.clearCount
w.timers[1].fn()
eq(w.clearCount .. "/" .. tostring(w.c.PinKind()), clears .. "/repair", "a real pin made during the demo stays")
w = world({ autoAccept = false })
w.c.Demo(rolls(2, 1))
w.c.Test("repair")
cancels = w.cancelCount
w.timers[1].fn()
eq(w.cancelCount .. "/" .. tostring(w.open), cancels .. "/true", "a newer question stays open")
-- Nowhere to go: chat says so, the demo still runs its time.
w = world({ pos = false })
eq(w.c.Demo(rolls(1, 1)), true, "no position: still a demo")
eq(w.says[1], "No map position here (dungeons and some areas have none). Try again outside.", "chat says why there is no warning")
w = world({ pos = { 7, 0, 0 } })
w.c.Demo(rolls(2, 2))
eq(w.says[1], "No known repair vendor on this continent for your faction.", "no vendor: chat says so")
w.timers[1].fn()
eq(w.clearCount .. "/" .. w.setCount, "0/0", "nothing to take back")
-- No timers: no demo at all, since nothing could take it back.
w = world({ noTimers = true })
eq(w.c.Demo(rolls(1, 1)), false, "timers refuse: no demo")
eq(w.setCount, 0, "nothing pinned")
w = world({ noAfter = true })
eq(w.c.Demo(rolls(1, 1)), false, "no timer function: no demo")

-- Supplies: food, water and pet food, and the notice-only reminders -------------------------------------------
-- { npcId, name, uiMapID, mx, my, faction, repair, ammo, wx, wy, reagents, supplies }
local SV = {
    { 1, "Plain Seller", 100, 0.1, 0.1, 0, false, 0, 5, 0, 0, 0 },
    { 2, "Baker",        100, 0.3, 0.1, 0, false, 0, 30, 0, 0, 1 + 16 },  -- food, Bread
    { 3, "Well",         100, 0.6, 0.1, 0, false, 0, 60, 0, 0, 2 },       -- water
    { 4, "Butcher",      100, 0.8, 0.1, 0, false, 0, 80, 0, 0, 1 + 4 },   -- food, Meat
}
local SUPCFG = { foodEnabled = true, waterEnabled = true, petFoodEnabled = true, healthstoneRemind = true,
                 foodThreshold = 5, waterThreshold = 5, petFoodThreshold = 5, remindSound = "whisper" }
-- class token, bag totals, optional pet diets and known spells; over adds world fields.
local function supply(class, totals, diets, knows, over)
    local o = { buckets = { [1] = SV }, cfg = {}, supplies = { class = class, totals = totals, diets = diets,
        knows = function(id) return (knows or {})[id] == true end } }
    for k, v in pairs(SUPCFG) do o.cfg[k] = v end
    for k, v in pairs(over or {}) do
        if k == "cfg" then for ck, cv in pairs(v) do o.cfg[ck] = cv end else o[k] = v end
    end
    return world(o)
end

-- Food: nearest vendor that sells food, not the nearest vendor; the question names food and the count.
w = supply("WARRIOR", { food = 3, water = 0, healthstone = 0 })
w.c.Evaluate()
eq(#w.prompts, 1, "food question asked")
eq(w.prompts[1].kind, "supply", "supply kind")
eq(w.prompts[1].vendor[2], "Baker", "nearest food seller")
eq(w.prompts[1].count, 3, "count passed")
eq(w.prompts[1].trade, "food", "named food")
eq(w.setCount, 1, "Yes sets the pin")
w.c.Evaluate()
eq(#w.prompts, 1, "not asked again while low")
eq(ns.Controller.PromptText("supply", SV[2], nil, 3, "food"), "You are low on food (3 left).\n\nNavigate to the closest vendor that sells food, Baker?", "question text")
w.supplies.totals = { food = 30, water = 0, healthstone = 0 }
w.c.Evaluate()
eq(w.clearCount >= 1, true, "restocked: the pin is withdrawn")

-- Water is for mana classes; food comes first, water after the food question resolves.
w = supply("PRIEST", { food = 30, water = 2, healthstone = 0 })
w.c.Evaluate()
eq(w.prompts[1].trade, "water", "water asked for a priest")
eq(w.prompts[1].vendor[2], "Well", "nearest water seller")
w = supply("ROGUE", { food = 30, water = 0, healthstone = 0 })
w.c.Evaluate()
eq(#w.prompts, 0, "a rogue is never asked about water")
w = supply("PRIEST", { food = 1, water = 1, healthstone = 0 }, nil, nil, { autoAccept = false })
w.c.Evaluate()
eq(#w.prompts, 1, "one question at a time")
eq(w.prompts[1].trade, "food", "food first")

-- Pet food: the pet's diet picks the vendor; no diet means nothing is asked.
w = supply("HUNTER", { food = 30, water = 30, healthstone = 0, pet = 2 }, { Meat = true })
w.c.Evaluate()
eq(w.prompts[1].trade, "pet food (Meat)", "named with the diet")
eq(w.prompts[1].vendor[2], "Butcher", "the Meat seller, not the nearer Baker")
w = supply("HUNTER", { food = 30, water = 30, healthstone = 0 }, nil)
w.c.Evaluate()
eq(#w.prompts, 0, "no pet: nothing asked")
w = supply("HUNTER", { food = 30, water = 30, healthstone = 0, pet = 1 }, { Bread = true, Cheese = true })
w.c.Evaluate()
eq(w.prompts[1].trade, "pet food (Bread, Cheese)", "several diets in table order")
eq(w.prompts[1].vendor[2], "Baker", "any of the diets")

-- No known seller: one chat line, no question; once per supply.
w = supply("HUNTER", { food = 30, water = 30, healthstone = 0, pet = 1 }, { Fruit = true })
w.c.Evaluate()
eq(#w.prompts, 0, "no fruit seller: no dialog")
eq(#w.says, 1, "one chat line")
eq(w.says[1], "No known vendor sells food your pet eats on this continent yet. Open a vendor that sells it once and the addon will remember it.", "pet line")
w.c.Evaluate()
eq(#w.says, 1, "said once")
w = supply("WARRIOR", { food = 1, water = 0, healthstone = 0 }, nil, nil, { buckets = { [1] = { SV[1], SV[3] } } })
w.c.Evaluate()
eq(w.says[1], "No known vendor sells food on this continent yet. Open a vendor that sells it once and the addon will remember it.", "food line")

-- Switches. The ammo switch is not one of them: supplies have their own.
w = supply("PRIEST", { food = 1, water = 1, healthstone = 0 }, nil, nil, { cfg = { foodEnabled = false } })
w.c.Evaluate()
eq(w.prompts[1].trade, "water", "food switched off")
w = supply("PRIEST", { food = 1, water = 1, healthstone = 0 }, nil, nil, { cfg = { ammoEnabled = false } })
w.c.Evaluate()
eq(w.prompts[1] and w.prompts[1].trade, "food", "ammo switch off: supplies are still asked")
w = supply("PRIEST", { food = 1, water = 1, healthstone = 0 }, nil, nil, { cfg = { suppliesEnabled = false } })
w.c.Evaluate()
eq(#w.prompts, 0, "supplies switch off: nothing asked")
w = supply("WARRIOR", { food = 1, water = 0, healthstone = 0 }, nil, nil, { combat = true })
w.c.Evaluate()
eq(#w.prompts, 0, "combat holds it back")
w = supply("WARRIOR", { food = nil, water = 0, healthstone = 0 })
w.c.Evaluate()
eq(#w.prompts, 0, "unknown count is never low")
w = supply("WARRIOR", nil)
w.c.Evaluate()
eq(#w.prompts, 0, "unreadable bags: nothing asked")

-- Auto mode pins and says what to buy.
w = supply("WARRIOR", { food = 1, water = 0, healthstone = 0 }, nil, nil, { cfg = { vendorMode = "auto" } })
w.c.Evaluate()
eq(#w.prompts, 0, "auto: no question")
eq(w.last[2], "Baker", "auto pin")
eq(w.says[1], "Navigating to Baker (30 yards) to buy food.", "auto says what to buy")

-- A reagent is asked before food.
w = supply("MAGE", { food = 1, water = 30, healthstone = 0 }, nil, nil, { reagents = { { item = POWDER, count = 3, name = "Arcane Powder" } },
    buckets = { [1] = { SV[2], RV[2] } }, autoAccept = false })
w.c.Evaluate()
eq(w.prompts[1].kind, "reagent", "reagent before food")

-- Reminders: a mage who can conjure is reminded, never sent; a warlock is reminded to make a healthstone.
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, { [587] = true })
w.c.Evaluate()
eq(#w.prompts, 0, "mage who can conjure: no vendor question")
eq(w.setCount, 0, "and no pin")
eq(w.says[1], "You are low on food (2 left). Cast Conjure Food to make more.", "conjure reminder")
eq(w.notes[1], w.says[1], "also on screen")
w.c.Evaluate()
eq(#w.says, 1, "once")
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, {})
w.c.Evaluate()
eq(#w.prompts, 1, "mage without the spell is sent to a vendor")
eq(#w.says, 0, "and not reminded")
w = supply("WARLOCK", { food = 30, water = 30, healthstone = 0 }, nil, { [6201] = true })
w.c.Evaluate()
eq(w.says[1], "You have no healthstone. Cast Create Healthstone to make one.", "healthstone reminder")
eq(#w.prompts, 0, "no question")
w = supply("WARLOCK", { food = 30, water = 30, healthstone = 1 }, nil, { [6201] = true })
w.c.Evaluate()
eq(#w.says, 0, "has a healthstone")
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, { [587] = true }, { combat = true })
w.c.Evaluate()
eq(#w.says, 0, "combat: not shown")
w.combat = false
w.c.Evaluate()
eq(#w.says, 1, "shown after combat")
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, { [587] = true }, { noNotify = true })
w.c.Evaluate()
eq(#w.says, 1, "chat line without an on-screen notice function")
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, { [587] = true }, { cfg = { autoNotice = false } })
w.c.Evaluate()
eq(#w.notes, 0, "on-screen notice switched off")

-- The reminder sound: the saved key goes to the game side once per batch; a vendor question makes none.
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, { [587] = true })
w.c.Evaluate()
eq(table.concat(w.sounds, ","), "whisper", "a reminder plays the chosen sound")
w.c.Evaluate()
eq(#w.sounds, 1, "once, not on every check")
local WATER_SPELL = ns.Reagents.DisplayOnly("MAGE")[1].id == 5349 and ns.Reagents.DisplayOnly("MAGE")[2].spells[1] or ns.Reagents.DisplayOnly("MAGE")[1].spells[1]
w = supply("MAGE", { food = 2, water = 2, healthstone = 0 }, nil, { [587] = true, [WATER_SPELL] = true })
w.c.Evaluate()
eq(#w.says .. "/" .. #w.sounds, "2/1", "food and water together: two lines, one sound")
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, {})
w.c.Evaluate()
eq(#w.sounds, 0, "a vendor question is silent here (the pin has its own sound)")
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, { [587] = true }, { combat = true })
w.c.Evaluate()
eq(#w.sounds, 0, "combat: no sound until the reminder shows")
w.combat = false
w.c.Evaluate()
eq(#w.sounds, 1, "after combat")
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, { [587] = true }, { cfg = { remindSound = "none" } })
w.c.Evaluate()
eq(table.concat(w.sounds, ","), "none", "none is passed on; the game side plays nothing for it")
w = supply("WARLOCK", { food = 30, water = 30, healthstone = 0 }, nil, { [6201] = true })
w.c.Evaluate()
eq(#w.sounds, 1, "the healthstone reminder too")
w = supply("MAGE", { food = 7, water = 1, healthstone = 0 })
w.c.Test("remind")
eq(#w.sounds, 1, "/cvn test remind plays it")
w = supply("WARRIOR", { food = 7, water = 0, healthstone = 0 })
w.c.Test("remind")
eq(#w.sounds .. "/" .. #w.says .. "/" .. #w.notes, "1/1/1", "any other class: a test line, on screen, and the sound")
w = supply("MAGE", { food = 7, water = 1, healthstone = 0 }, nil, nil, { combat = true, instance = "party" })
w.c.Test("remind")
eq(#w.says .. "/" .. #w.sounds, "1/1", "works in combat and in an instance")
w = supply("MAGE", { food = 7, water = 1, healthstone = 0 }, nil, nil, { cfg = { ammoEnabled = false, foodEnabled = false } })
w.c.Test("remind")
eq(#w.says .. "/" .. #w.sounds, "1/1", "works with the warnings switched off")
w = world({})
eq(w.c.Test("remind"), nil, "no supply source: still no error")
eq(#w.says .. "/" .. #w.sounds, "1/1", "and still a line and a sound")

-- A click on a supply row pins the nearest seller at once.
w = supply("WARRIOR", { food = 3, water = 0, healthstone = 0 }, nil, nil, { autoAccept = false })
eq(w.c.Go("supply", "food"), true, "food row clicked")
eq(w.last[2], "Baker", "the nearest food seller, not the nearest vendor")
eq(#w.prompts, 0, "no question")
w = supply("PRIEST", { food = 30, water = 3, healthstone = 0 })
eq(w.c.Go("supply", "water"), true, "water row clicked")
eq(w.last[2], "Well", "the water seller")
w = supply("HUNTER", { food = 30, water = 30, pet = 2, healthstone = 0 }, { Meat = true })
eq(w.c.Go("supply", "pet"), true, "pet food row clicked")
eq(w.last[2], "Butcher", "a seller of the pet's diet")
w = supply("HUNTER", { food = 30, water = 30, healthstone = 0 })
eq(w.c.Go("supply", "pet"), false, "no pet diet: nothing to look for")
w = supply("WARRIOR", { food = 3, water = 0, healthstone = 0 }, nil, nil, { buckets = { [1] = { SV[3] } } })
eq(w.c.Go("supply", "food"), false, "no food seller known")
eq(w.says[#w.says], "No known vendor selling food on this continent for your faction.", "chat says so")
w = supply("WARRIOR", { food = 3, water = 0, healthstone = 0 }, nil, nil, { autoAccept = false, combat = true })
w.c.Evaluate()
eq(#w.prompts, 0, "in combat the question waits")
eq(w.c.Go("supply", "food"), true, "a click pins in combat")
w.combat = false
w.c.Evaluate()
eq(#w.prompts, 0, "the click counted as the answer: the food question is not asked afterwards")

-- /cvn test.
w = supply("WARRIOR", { food = 30, water = 0, healthstone = 0 })
eq(w.c.Test("food"), nil, "test food asks regardless of count")
eq(w.prompts[1].vendor[2], "Baker", "test food target")
eq(supply("ROGUE", { food = 1, water = 0, healthstone = 0 }).c.Test("water"), "Your class does not use water.", "test water for a rogue")
eq(supply("HUNTER", { food = 1, water = 1, healthstone = 0 }).c.Test("petfood"), "There is no pet to feed.", "test petfood without a pet")
eq(supply("MAGE", { food = 1, water = 1, healthstone = 0 }).c.Test("petfood"), "There is no pet to feed.", "test petfood for another class")
w = supply("HUNTER", { food = 1, water = 1, healthstone = 0, pet = 0 }, { Meat = true })
eq(w.c.Test("petfood"), nil, "test petfood with a pet")
eq(w.prompts[1].vendor[2], "Butcher", "test petfood target")
w = supply("MAGE", { food = 7, water = 1, healthstone = 0 })
eq(w.c.Test("remind"), nil, "test remind for a mage")
eq(w.says[1], "You are low on food (7 left). Cast Conjure Food to make more.", "test reminder text")
w = supply("WARLOCK", { food = 7, water = 1, healthstone = 3 })
w.c.Test("remind")
eq(w.says[1], "You have no healthstone. Cast Create Healthstone to make one.", "test remind for a warlock")
w = supply("WARRIOR", { food = 7, water = 0, healthstone = 0 })
eq(w.c.Test("remind"), nil, "test remind for a warrior")
eq(w.says[1], "This is a test reminder. Only mages and warlocks get real ones.", "a plain test line")
eq(world({ buckets = { [1] = { SV[3] } }, supplies = { class = "WARRIOR", totals = { food = 1 }, knows = function() return false end } }).c.Test("food"),
    "No known vendor selling food on this continent for your faction.", "test food with no seller")
eq(world().c.Test("food"), "Your bags cannot be read right now.", "no supply source")

-- /cvn demo with supplies: a made-up count and diet, a reminder, and a direct pin; nothing real is changed.
w = supply("WARRIOR", { food = 30, water = 0, healthstone = 0 }, nil, nil, { autoAccept = false })
w.c.Demo(rolls(2, 5, 3))
eq(w.prompts[1].kind .. "/" .. tostring(w.prompts[1].trade) .. "/" .. w.prompts[1].count .. "/" .. w.prompts[1].vendor[2], "supply/food/2/Baker", "demo question about food, made-up count")
w.timers[#w.timers].fn()
eq(w.cancelCount >= 1, true, "and taken back after the demo")
w = supply("WARRIOR", { food = 30, water = 0, healthstone = 0 }, nil, nil, { autoAccept = false })
w.c.Demo(rolls(2, 6, 1))
eq(w.prompts[1].trade, "food", "water for a class without mana is shown as food")
w = supply("PRIEST", { food = 30, water = 30, healthstone = 0 }, nil, nil, { autoAccept = false })
w.c.Demo(rolls(2, 6, 1))
eq(w.prompts[1].trade .. "/" .. w.prompts[1].vendor[2], "water/Well", "water for a priest")
w = supply("HUNTER", { food = 30, water = 30, healthstone = 0 }, nil, nil, { autoAccept = false })
w.c.Demo(rolls(2, 7, 1, 4))
eq(w.prompts[1].trade .. "/" .. w.prompts[1].vendor[2], "pet food (Meat)/Butcher", "no pet out: a made-up diet")
w = supply("HUNTER", { food = 30, water = 30, pet = 20, healthstone = 0 }, { Bread = true }, nil, { autoAccept = false })
w.c.Demo(rolls(2, 7, 2))
eq(w.prompts[1].trade .. "/" .. w.prompts[1].vendor[2], "pet food (Bread)/Baker", "a pet out: its own diet, no diet roll")
w = supply("WARRIOR", { food = 30, water = 0, healthstone = 0 })
w.c.Demo(rolls(1, 5, 1))
eq(w.setCount .. "/" .. w.last[2], "1/Baker", "pin without asking for a supply")
w = supply("MAGE", { food = 30, water = 30, healthstone = 0 })
w.c.Demo(rolls(1, 8))
eq(#w.says .. "/" .. #w.sounds .. "/" .. #w.prompts .. "/" .. w.setCount, "1/1/0/0", "a demo reminder: a line and the sound, no question, no pin")
eq(w.says[1], "You are low on food (30 left). Cast Conjure Food to make more.", "the mage reminder text")
w = supply("WARRIOR", { food = 30, water = 0, healthstone = 0 })
w.c.Demo(rolls(3, 3))
eq(w.setCount .. "/" .. w.last[2] .. "/" .. #w.prompts, "1/Baker/0", "direct pin for food")
w = supply("WARRIOR", { food = 30, water = 0, healthstone = 0 }, nil, nil, { buckets = { [1] = { SV[1] } } })
w.c.Demo(rolls(2, 5, 1))
eq(w.says[#w.says], "No known vendor selling food on this continent for your faction.", "no seller: says so, no question")

H.done()
