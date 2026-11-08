package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
H.locale(ns)
for _, f in ipairs({ "Triggers", "Professions", "Search", "Controller" }) do
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
                prompts = {}, notes = {}, cancelCount = 0, ammoKind = nil, ammoCount = 0, logs = {}, says = {}, known = {}, open = false }
    for k, v in pairs(over or {}) do w[k] = v end
    local env = {
        cfg = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, bagEnabled = true, durEnabled = true, ammoEnabled = true,
                 tradeThreshold = 10, tradeEnabled = true },
        skills = function() return w.skills end,
        known = w.known,
        trainerBuckets = w.trainers or {},
        say = function(t) w.says[#w.says + 1] = t end,
        notify = (not w.noNotify) and function(t) w.notes[#w.notes + 1] = t end or nil,
        zoneName = function(id) return w.zones and w.zones[id] end,
        questionOpen = function() return w.open end,
        freeSlots = function() return w.free end,
        lowestDurability = function() return w.dur end,
        inCombat = function() return w.combat end,
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
eq(w.says[1], "Navigating to Home Seller (50 yards). The other choice was Other Seller (10 yards).", "auto: names both targets, no zones known")
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
eq(w.says[1], "Navigating to Home Seller (Elwynn, 50 yards). The other choice was Other Seller (Westfall, 10 yards).", "notice has zones and distances for both")
eq(#w.notes, 1, "one on-screen message")
w = mapped({ cfg = { vendorMode = "auto", vendorPrefer = "distance" }, zones = { [100] = "Elwynn", [200] = "Westfall" } })
w.c.Evaluate()
eq(w.says[1], "Navigating to Other Seller (Westfall, 10 yards). The other choice was Home Seller (Elwynn, 50 yards).", "distance preference names the pinned one first")
w = mapped({ pos = { 1, 60, 0, 100 }, cfg = { vendorMode = "auto" }, zones = { [100] = "Elwynn" } })
w.c.Evaluate()
eq(w.says[1], "Navigating to Home Seller (Elwynn, 10 yards).", "single candidate: no other choice")
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
eq(w.says[1], "Navigating to Home Miner (Elwynn, 50 yards). The other choice was Other Miner (Westfall, 10 yards).", "trainer notice")
eq(w.notes[1], w.says[1], "trainer on-screen message")
w = mapped({ autoAccept = false })
w.c.Evaluate()
eq(#w.notes, 0, "ask mode: no on-screen message")

H.done()
