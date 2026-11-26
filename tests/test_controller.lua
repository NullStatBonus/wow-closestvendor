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
                prompts = {}, menus = {}, notes = {}, cancelCount = 0, ammoKind = nil, ammoCount = 0, logs = {}, says = {}, sounds = {}, known = {}, open = false }
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
        trainerTiers = function() return w.tiers or false end,
        auctionBuckets = w.auction,
        say = function(t) w.says[#w.says + 1] = t end,
        notify = (not w.noNotify) and function(t) w.notes[#w.notes + 1] = t end or nil,
        zoneName = function(id) return w.zones and w.zones[id] end,
        itemName = function(id) return w.itemNames and w.itemNames[id] end,
        itemIcon = function(id) return w.icons and w.icons[id] end,
        menu = (not w.noMenu) and function(title, items) w.menus[#w.menus + 1] = { title = title, items = items }; return true end or nil,
        questionOpen = function() return w.open end,
        freeSlots = function() return w.free end,
        lowestDurability = function() return w.dur end,
        inCombat = function() return w.combat end,
        dead = function() return w.dead end,
        instanceType = function() return w.instance end,
        anchor = function(which) return w.anchors and w.anchors[which] end,
        evaluate = w.evaluate,
        after = (not w.noAfter) and function(s, fn)
            w.afterCalls = (w.afterCalls or 0) + 1
            if w.noTimers or (w.afterFailsAt and w.afterCalls >= w.afterFailsAt) then return false end
            w.timers = w.timers or {}
            w.timers[#w.timers + 1] = { s = s, fn = fn }
            return true
        end or nil,
        playerPos = function() if w.pos then return w.pos[1], w.pos[2], w.pos[3], w.pos[4] end end,
        playerFaction = 1,
        sourceOf = w.sourceOf,
        buckets = w.buckets or { [1] = VENDORS },
        log = (not w.noLog) and function(m) w.logs[#w.logs + 1] = m end or nil,
        ammo = function() return w.ammoKind, w.ammoCount end,
        confirm = function(kind, v, accept, count, trade, two, decline)
            w.prompts[#w.prompts + 1] = { kind = kind, vendor = v, accept = accept, count = count, trade = trade, two = two, decline = decline }
            if w.autoAccept ~= false then (w.pickOther and two and two.acceptOther or accept)() else w.open = true end -- tests say autoAccept = false to hold the question open
        end,
        cancelConfirm = function() w.cancelCount = w.cancelCount + 1; w.open = w.stuckOpen or false end, -- stuckOpen: the dialog does not close
        nav = {
            Set = function(v) w.setCount = w.setCount + 1; w.last = v; if not w.nilNav then return { kind = "x" } end end,
            Clear = function() w.clearCount = w.clearCount + 1; if w.clearFails then return false end; if w.clearUnknown then return nil end; return true end,
        },
        now = function() return w.clock end,
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

-- The question line names where the target came from and how far it is, in whole yards (covers: Question lines name the source and the distance).
local function questionLine(world_)
    for _, l in ipairs(world_.logs) do if l:find("question shown:", 1, true) then return l end end
end
w = world({ autoAccept = false })
w.c.Test("sell")
eq(questionLine(w), "question shown: sell, Near Seller (npc 1), shipped, 10 yd", "no source lookup: shipped, 10 yards away")
w = world({ autoAccept = false, pos = { 1, 10, 0 } })
w.c.Test("sell")
eq(questionLine(w), "question shown: sell, Near Seller (npc 1), shipped, 0 yd", "standing at the vendor: 0 yd")
w = world({ autoAccept = false, pos = { 1, 0.4, 0 } })
w.c.Test("sell")
eq(questionLine(w), "question shown: sell, Near Seller (npc 1), shipped, 10 yd", "9.6 yards rounds up")
w = world({ autoAccept = false, pos = { 1, 0.6, 0 } })
w.c.Test("sell")
eq(questionLine(w), "question shown: sell, Near Seller (npc 1), shipped, 9 yd", "9.4 yards rounds down")
local asked
w = world({ autoAccept = false, sourceOf = function(kind, id) asked = kind .. ":" .. tostring(id); return "learned" end })
w.c.Test("repair")
eq(questionLine(w), "question shown: repair, Far Repairer (npc 2), learned, 90 yd", "the source comes from the lookup")
eq(asked, "repair:2", "the lookup is asked for the kind and the npc id of the target")

-- The trainer form from a skill check keeps its points left after the distance.
w = world({ skills = { { name = "Mining", rank = 70, max = 75 } }, known = { Mining = true }, trainers = { [1] = { { 20, "Near Miner", 100, 0.1, 0.1, 0, { Mining = true }, 10, 0 } } }, autoAccept = false,
            sourceOf = function(kind, id) return kind == "trainer" and id == 20 and "NorgannonDB" or "?" end })
w.c.OnCraft()
eq(questionLine(w), "question shown: trainer for Mining, Near Miner (npc 20), NorgannonDB, 10 yd, 5 point(s) left", "trainer line from a skill check: " .. tostring(questionLine(w)))
-- A real trainer question is withdrawn by a zone change, a test one is not (below).

-- /cvn test trainer: the trainer question whatever the skill, and any class can run it (covers: Trainer test command).
local TRAINERS = { [1] = {
    { 30, "Near Smith", 100, 0.1, 0.1, 0, { Blacksmithing = true }, 10, 0 },
    { 31, "Far Miner", 100, 0.5, 0.1, 0, { Mining = true, Herbalism = true }, 50, 0 },
    { 32, "Herbalist Kay", 100, 0.7, 0.1, 0, { Herbalism = true }, 70, 0 },
} }
w = world({ autoAccept = false, trainers = TRAINERS })
eq(w.c.Test("trainer"), nil, "test trainer: nothing to complain about, with no profession known")
eq(#w.prompts, 1, "test trainer asks with no profession, no skills and no threshold")
eq(w.prompts[1].kind, "trainer", "test trainer kind")
eq(w.prompts[1].vendor[2], "Near Smith", "no profession known: the nearest trainer of any profession")
eq(w.prompts[1].trade, "Blacksmithing", "and a profession it teaches")
eq(w.prompts[1].count, nil, "no points left to name")
eq(questionLine(w), "question shown: trainer for Blacksmithing, Near Smith (npc 30), shipped, 10 yd", "the line has no points part: " .. tostring(questionLine(w)))
eq(w.setCount, 0, "no pin before Yes")
w.prompts[1].accept()
eq(w.setCount, 1, "Yes sets the pin")
eq(w.last[2], "Near Smith", "to that trainer")
w = world({ autoAccept = false, trainers = TRAINERS, known = { Mining = true } })
w.c.Test("trainer")
eq(w.prompts[1].vendor[2], "Far Miner", "a known profession wins over a nearer trainer of another")
eq(w.prompts[1].trade, "Mining", "the profession is the known one")
w = world({ autoAccept = false, trainers = TRAINERS, known = { Herbalism = true } })
w.c.Test("trainer")
eq(w.prompts[1].vendor[2], "Far Miner", "two known-profession trainers: the nearest one")
eq(w.prompts[1].trade, "Herbalism", "teaching the known profession")
w = world({ autoAccept = false, trainers = TRAINERS, combat = true, cfg = { tradeEnabled = false } })
w.c.Test("trainer")
eq(#w.prompts, 1, "asks in combat and with the profession warning off")
-- The texts of a test question.
eq(ns.Controller.PromptText("trainer", { 30, "Near Smith" }, "Ironforge", nil, "Blacksmithing"), "Navigate to the closest Blacksmithing trainer, Near Smith (Ironforge)?", "test trainer text")
eq(ns.Controller.PromptText("trainer", { 30, "Near Smith" }, "Ironforge", 0, "Blacksmithing"):find("reached its current limit", 1, true) ~= nil, true, "a real question with 0 points keeps its text")
-- Nothing to ask about: say why, ask nothing, leave nothing pending.
w = world({ pos = false, trainers = TRAINERS })
eq(w.c.Test("trainer"):find("No map position", 1, true) ~= nil, true, "test trainer: no position message")
eq(#w.prompts, 0, "no question without a position")
w = world({ trainers = TRAINERS, pos = { 7, 0, 0 } })
eq(w.c.Test("trainer"):find("No known profession trainer", 1, true) ~= nil, true, "test trainer: no trainer message")
eq(table.concat(w.logs, "\n"):find("test command: nothing asked: no known trainer", 1, true) ~= nil, true, "and the log says why")
eq(#w.prompts, 0, "no question without a trainer")
-- A test question is not withdrawn by a zone change; a real trainer question is.
w = world({ autoAccept = false, trainers = TRAINERS })
w.c.Test("trainer")
local cancelsBefore = w.cancelCount
w.c.OnPlaceChange()
eq(w.cancelCount, cancelsBefore, "a zone change does not withdraw a test trainer question")
w.prompts[1].accept()
eq(w.setCount, 1, "a Yes after the zone change still sets the waypoint")

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
eq(has(w, "trigger go"), false, "nothing decided in combat")
eq(has(w, "trigger held in combat: ammo"), true, "the request combat holds back is named: " .. table.concat(w.logs, " / "))

-- A hold is logged once for a burst of checks, and again after it ended; the reason is exact.
local function count(w, text)
    local n = 0
    for _, m in ipairs(w.logs) do if m == text then n = n + 1 end end
    return n
end
w = world({ dur = 10, combat = true, autoAccept = false })
w.c.Evaluate(); w.c.Evaluate(); w.c.Evaluate()
eq(count(w, "trigger held in combat: repair"), 1, "a burst of checks in combat logs the hold once")
w.combat = false
w.c.Evaluate()
eq(has(w, "trigger go repair"), true, "asked once combat ends")
w = world({ dur = 10, dead = true, autoAccept = false })
w.c.Evaluate(); w.c.Evaluate()
eq(count(w, "trigger held while dead: repair"), 1, "dead or a ghost: its own reason, once")
eq(has(w, "in combat"), false, "dead is not called combat")
w.dead = false
w.c.Evaluate()
eq(has(w, "trigger go repair"), true, "asked once alive")
w.prompts[1].decline()
w.dur = 100; w.c.Evaluate() -- repaired: the latch clears
w.dur = 10; w.dead = true; w.c.Evaluate()
eq(count(w, "trigger held while dead: repair"), 2, "a second death logs the hold again")
w = world({ free = 1, instance = "party", combat = true })
w.c.Evaluate()
w.combat = false; w.c.Evaluate()
eq(count(w, "trigger held in an instance: sell"), 1, "an instance is the reason, also in a fight there")
eq(has(w, "in combat"), false, "a fight inside does not change the reason")
w = world({ free = 1, combat = true })
w.c.Evaluate()
w.free = 20; w.c.Evaluate() -- nothing wanted any more
w.free = 1; w.c.Evaluate()
eq(count(w, "trigger held in combat: sell"), 1, "the same fight: a hold after nothing was wanted is not logged again")
w.combat = false; w.free = 20; w.c.Evaluate()
w.combat = true; w.free = 1; w.c.Evaluate()
eq(count(w, "trigger held in combat: sell"), 2, "the next fight logs the hold again")
-- A check in the same fight that ends another request holds nothing; the hold is still not logged again.
w = world({ free = 1, autoAccept = false })
w.c.Evaluate() -- the sell question is open
w.combat = true; w.dur = 10; w.c.Evaluate() -- repair would replace it: held
w.free = 20; w.c.Evaluate() -- the sell request ends: a clear, nothing held at this check
w.c.Evaluate()
eq(count(w, "trigger held in combat: repair"), 1, "a clear in the same fight does not log the hold again: " .. table.concat(w.logs, " / "))
w = world({ combat = true })
w.c.Evaluate()
eq(has(w, "trigger held"), false, "nothing wanted: no hold line")

-- The ammo the addon watches: each change is logged once, both ways.
w = world({ ammoKind = "arrow", ammoCount = 900 })
w.c.Evaluate(); w.c.Evaluate()
eq(count(w, "ammo watched: arrow"), 1, "the watched ammo is logged once")
w.ammoKind = nil; w.c.Evaluate(); w.c.Evaluate()
eq(count(w, "ammo not watched: no bow, crossbow or gun equipped, or its ammo cannot be read"), 1, "no ammo weapon: logged once")
w.ammoKind = "bullet"; w.c.Evaluate()
eq(count(w, "ammo watched: bullet"), 1, "another ammo kind is logged")
-- With the ammo warning off, a bow is not watched: no "ammo watched" line, its own reason instead.
w = world({ cfg = { ammoEnabled = false } })
w.c.Evaluate()
w.ammoKind, w.ammoCount = "arrow", 5; w.c.Evaluate(); w.c.Evaluate()
eq(has(w, "ammo watched"), false, "ammo warning off: equipping a bow is not watched")
eq(count(w, "ammo not watched: the ammo warning is off"), 1, "ammo warning off: logged once")
w.liveCfg.ammoEnabled = true; w.c.Evaluate()
eq(count(w, "ammo watched: arrow"), 1, "turned back on: the bow is watched")

-- Active: the request that is open or active.
w = world({ dur = 10, autoAccept = false })
eq(w.c.Active(), nil, "nothing active")
w.c.Evaluate()
eq(w.c.Active(), "repair", "the repair request is active")

-- A merchant window closes an open vendor question and says so; a trainer question stays open.
w = world({ free = 1, autoAccept = false })
w.c.Evaluate()
w.c.OnMerchantShow()
eq(count(w, "question closed: merchant opened (sell)"), 1, "an open vendor question closed by a merchant is logged")
eq(w.open, false, "the vendor question is closed")
w.c.OnMerchantShow()
eq(count(w, "question closed: merchant opened (sell)"), 1, "no question open: no closed line")
w = world({})
w.c.OnMerchantShow()
eq(has(w, "question closed"), false, "a merchant with no question: no closed line")
-- A question that does not close when the merchant opens is a failure, not a closed line.
w = world({ free = 1, autoAccept = false, stuckOpen = true })
w.c.Evaluate()
w.c.OnMerchantShow()
eq(count(w, "FAILED: question still shown after the merchant opened (sell)"), 1, "a question still shown after the merchant opened is logged as a failure")
eq(has(w, "question closed: merchant opened"), false, "and no closed line")
w = world({ skills = { { name = "Mining", rank = 70, max = 75 } }, known = { Mining = true }, trainers = { [1] = { { 20, "Near Miner", 100, 0.1, 0.1, 0, { Mining = true }, 10, 0 } } }, autoAccept = false })
w.c.OnCraft()
eq(has(w, "question shown: trainer for Mining"), true, "trainer question open: " .. table.concat(w.logs, " / "))
w.c.OnMerchantShow()
eq(has(w, "question closed"), false, "a trainer question stays open at a merchant: no closed line")
eq(w.open, true, "the trainer question is still open")

-- Dead and in combat at once: death is the reason.
w = world({ dur = 10, dead = true, combat = true, autoAccept = false })
w.c.Evaluate()
eq(count(w, "trigger held while dead: repair"), 1, "dead and in combat: held while dead")
eq(has(w, "trigger held in combat"), false, "dead and in combat: not called combat")

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
-- Unlearning a profession ends its trainer waypoint at the next skill update.
w = trade({ skills = { { name = "Mining", rank = 70, max = 75 }, { name = "Swords", rank = 5, max = 75 } } })
w.c.OnSkillChange()
w.c.OnCraft()
eq(w.c.PinKind(), "trainer", "trainer waypoint set")
local clears = w.clearCount
w.skills = { { name = "Swords", rank = 5, max = 75 } }
w.c.OnSkillChange()
eq(w.clearCount, clears + 1, "Mining unlearned: its waypoint ends")
eq(has(w, "trainer waypoint cleared: Mining was unlearned"), true, "unlearned: its own log line")
eq(has(w, "is no longer near its cap"), false, "unlearned: not logged as past the cap")
-- Pinned by a craft before the first skill read: the first read already ends it.
w = trade({ skills = { { name = "Mining", rank = 70, max = 75 }, { name = "Swords", rank = 5, max = 75 } } })
w.c.OnCraft()
eq(w.c.PinKind(), "trainer", "pinned before any skill read")
clears = w.clearCount
w.skills = { { name = "Swords", rank = 5, max = 75 } }
w.c.OnSkillChange()
eq(w.clearCount, clears + 1, "unlearned before the first read: the waypoint still ends")
-- Profession warnings off: a trainer pinned from the status window ends too.
w = trade({ skills = { { name = "Mining", rank = 70, max = 75 }, { name = "Swords", rank = 5, max = 75 } }, cfg = { tradeEnabled = false } })
w.c.OnSkillChange()
eq(w.c.Go("trainer", "Mining"), true, "row click pins the trainer")
clears = w.clearCount
w.skills = { { name = "Swords", rank = 5, max = 75 } }
w.c.OnSkillChange()
eq(w.clearCount, clears + 1, "warnings off: unlearned, the waypoint ends")
eq(has(w, "trainer waypoint cleared: Mining was unlearned"), true, "warnings off: unlearned log line")
w.skills = nil
w.c.OnSkillChange()
eq(w.clearCount, clears + 1, "unreadable skills end nothing")

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
eq(#w.sounds, 1, "a route notification plays the notification sound")
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
eq(#w.sounds, 0, "notice off: no sound")
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
w = trade({ skills = { { name = "Mining", rank = 220, max = 225 } } })
eq(w.c.Go("trainer", "Mining"), false, "Artisan next: not routed")
eq(w.setCount, 0, "no pin")
eq(w.says[1], "Artisan Mining is taught by only a few trainers, so the addon does not route to one.", "chat says why")
-- With trainer tiers known (NorgannonDB), each tier goes only to a trainer that teaches it, Artisan included.
local TIERED = {
    { 30, "Journeyman Miner", 100, 0.1, 0.1, 0, { Mining = 1 }, 5, 0 },
    { 31, "Expert Miner",     100, 0.2, 0.1, 0, { Mining = 2 }, 20, 0 },
    { 32, "Unknown Miner",    100, 0.3, 0.1, 0, { Mining = true }, 30, 0 },
    { 33, "Master Miner",     100, 0.9, 0.1, 0, { Mining = 4 }, 90, 0 },
}
w = trade({ tiers = true, trainers = { [1] = TIERED }, autoAccept = false })
w.c.OnCraft()
eq(w.prompts[1] and w.prompts[1].vendor[2], "Expert Miner", "Journeyman next: the closest one that teaches it")
w = trade({ tiers = true, trainers = { [1] = TIERED }, skills = { { name = "Mining", rank = 220, max = 225 } }, level = 40, autoAccept = false })
w.c.OnCraft()
eq(w.prompts[1] and w.prompts[1].vendor[2], "Master Miner", "Artisan next: only a trainer known to teach it")
eq(w.c.Go("trainer", "Mining"), true, "a row click routes for Artisan too")
eq(w.last[2], "Master Miner", "to that trainer")
w = trade({ tiers = true, trainers = { [1] = { TIERED[1], TIERED[3] } }, skills = { { name = "Mining", rank = 220, max = 225 } }, level = 40 })
eq(w.c.Go("trainer", "Mining"), false, "no trainer known to teach Artisan")
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
-- Two sellers that round to the same whole yards: the truly closer one wins.
w = auction({ pos = { 1, 0, 0 }, buckets = { [1] = { RV[2] } }, auction = { [1] = { { 90, "Auctioneer Near", 100, 0.2, 0.1, 0, nil, 0, 29.6, 0, 0 } } } })
w.c.Go("reagent", 17020)
eq(w.last[2], "Auctioneer Near", "30 yards and 29.6 yards: the auctioneer is closer")
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
-- The supply form keeps its count after the source and the distance.
w = supply("WARRIOR", { food = 3, water = 0, healthstone = 0 }, nil, nil, { autoAccept = false, sourceOf = function() return "learned" end })
w.c.Evaluate()
eq(questionLine(w):match("^question shown: supply food, Baker %(npc %d+%), learned, %d+ yd, 3 left$") ~= nil, true, "supply line: source, distance, then the count: " .. tostring(questionLine(w)))

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
do -- the diet names in the question are the translated labels
    local saved = ns.Supplies.DIET_LABEL.Bread
    ns.Supplies.DIET_LABEL.Bread = "Brot"
    w = supply("HUNTER", { food = 30, water = 30, healthstone = 0, pet = 1 }, { Bread = true, Cheese = true })
    w.c.Evaluate()
    eq(w.prompts[1].trade, "pet food (Brot, Cheese)", "diet names use the translated labels")
    ns.Supplies.DIET_LABEL.Bread = saved
end

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
eq(#w.sounds, 0, "on-screen notice switched off: a reminder makes no sound")

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
-- The reminder combat held back is logged once, then the reminder after combat ends, in that order.
local function at(w2, text) for i, m in ipairs(w2.logs) do if m:find(text, 1, true) == 1 then return i end end end
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, { [587] = true }, { combat = true })
w.c.Evaluate()
w.c.Evaluate()
eq(count(w, "reminder held in combat: food"), 1, "a reminder combat holds back is logged once: " .. table.concat(w.logs, " / "))
eq(at(w, "reminder: "), nil, "no reminder in combat")
w.combat = false
w.c.Evaluate()
eq((at(w, "reminder: food") or 0) > (at(w, "reminder held in combat: food") or math.huge), true, "the reminder comes after the hold")
w.c.Evaluate()
eq(count(w, "reminder held in combat: food"), 1, "already shown: nothing more is held")
w = supply("WARLOCK", { food = 30, water = 30, healthstone = 0 }, nil, { [6201] = true }, { instance = "party" })
w.c.Evaluate()
eq(count(w, "reminder held in an instance: healthstone"), 1, "an instance holds the reminder back too")
w = supply("MAGE", { food = 2, water = 30, healthstone = 0 }, nil, { [587] = true })
w.c.Evaluate()
eq(at(w, "reminder held "), nil, "out of combat: nothing is held")
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

-- No to a question ends that request: the next need is asked, the declined one is not asked again.
w = world({ dur = 10, free = 1, autoAccept = false })
w.c.Evaluate()
eq(#w.prompts .. ":" .. w.prompts[1].kind, "1:repair", "repair asked first")
w.c.Evaluate()
eq(#w.prompts, 1, "nothing else while repair is open")
w.prompts[1].decline()
eq(w.timers and #w.timers, 1, "No checks again shortly")
w.timers[1].fn()
eq(#w.prompts .. ":" .. w.prompts[2].kind, "2:sell", "No to repair: selling is asked next")
w.c.Evaluate()
eq(#w.prompts, 2, "repair is not asked again")
eq(w.setCount, 0, "No sets no waypoint")
w = world({ dur = 10, free = 1, autoAccept = false })
w.c.Evaluate()
local stale = w.prompts[1].decline
w.dur = 100; w.c.Evaluate() -- the repair question is withdrawn
w.dur = 10; w.c.Evaluate() -- and a new one asked
eq(#w.prompts .. ":" .. w.prompts[2].kind, "2:repair", "a new repair question")
stale()
eq(w.timers == nil or #w.timers == 0, true, "No to the withdrawn question does nothing")
w.c.Evaluate()
eq(#w.prompts, 2, "the new repair request is still the active one: selling waits")

-- No to a test command's question leaves the real request alone.
w = world({ dur = 10 })
w.c.Evaluate()
eq(w.setCount, 1, "real repair request accepted")
w.autoAccept = false
w.c.Test("repair")
w.prompts[#w.prompts].decline()
eq(w.timers == nil or #w.timers == 0, true, "No to /cvn test releases nothing")
local cleared = w.clearCount
w.dur = 100; w.c.Evaluate()
eq(w.clearCount > cleared, true, "repairing still clears the real waypoint")

-- No vendor for the need: it ends too, so it does not hold back the next one.
w = world({ dur = 10, free = 1, autoAccept = false, buckets = { [1] = { VENDORS[1] } } })
w.c.Evaluate()
eq(#w.prompts, 0, "no repairer: no question")
w.timers[1].fn()
eq(#w.prompts .. ":" .. w.prompts[1].kind, "1:sell", "no repairer: selling is asked")

-- Dead or a ghost: the game would hide the question, so nothing is asked or used up until alive.
w = world({ dur = 10, dead = true, autoAccept = false })
w.c.Evaluate()
eq(#w.prompts, 0, "dead: no question")
w.dead = false
w.c.Evaluate()
eq(#w.prompts .. ":" .. w.prompts[1].kind, "1:repair", "alive again: repair asked")
w = world({ free = 1, dead = true, cfg = { vendorMode = "auto" } })
w.c.Evaluate()
eq(w.setCount, 0, "dead: auto mode sets no waypoint either")

-- Changing zone or entering an instance withdraws a warning's open question; it is asked again
-- from the new place, or once outside the instance. Combat withdraws nothing.
w = world({ free = 1, autoAccept = false })
w.c.Evaluate()
eq(#w.prompts, 1, "sell asked")
local cancels = w.cancelCount
w.combat = true; w.c.Evaluate(); w.combat = false
eq(w.cancelCount .. "/" .. #w.prompts, cancels .. "/1", "combat leaves the question open")
w.instance = "party"
w.c.OnPlaceChange()
eq(w.cancelCount, cancels + 1, "entering an instance withdraws the question")
w.c.Evaluate()
eq(#w.prompts, 1, "not asked inside")
w.instance = nil
w.c.Evaluate()
eq(#w.prompts .. ":" .. w.prompts[2].kind, "2:sell", "asked again outside")
w.c.OnPlaceChange()
w.c.Evaluate()
eq(#w.prompts, 3, "a zone change asks again from the new place")
w.prompts[3].accept(); w.open = false
cancels = w.cancelCount
w.c.OnPlaceChange()
eq(w.cancelCount, cancels, "an answered question is not withdrawn")
w = world({ free = 1, autoAccept = false })
w.c.Test("sell")
cancels = w.cancelCount
w.c.OnPlaceChange()
eq(w.cancelCount, cancels, "a test command's question is not withdrawn")

-- Seller choice (the status window's chevron) ---------------------------------------------------------------
-- One seller on the player's map (100), farther than four on another map (200).
local CV = {
    { 41, "Map Far",   100, 0.6, 0.1, 0, false, 0, 60, 0 },
    { 42, "Off Near",  200, 0.1, 0.1, 0, false, 0, 10, 0 },
    { 42, "Off Near",  200, 0.1, 0.1, 0, false, 0, 12, 0 },
    { 43, "Off Two",   200, 0.2, 0.1, 0, false, 0, 20, 0 },
    { 44, "Off Three", 200, 0.3, 0.1, 0, false, 0, 30, 0 },
    { 45, "Off Four",  200, 0.4, 0.1, 0, false, 0, 40, 0 },
}
local function names(c)
    local out = {}
    for _, e in ipairs(c and c.entries or {}) do out[#out + 1] = e.v[2] .. (e.default and "*" or "") .. (e.auction and "@" or "") end
    return table.concat(out, ", ")
end
local function chooser(over)
    local o = { buckets = { [1] = CV }, pos = { 1, 0, 0, 100 } }
    for k, v in pairs(over or {}) do o[k] = v end
    return world(o)
end
w = chooser()
local c = w.c.Choices("sell")
eq(names(c), "Map Far*, Off Near, Off Two, Off Three", "map preference: the map seller first, then three others by distance")
eq(c.title, "Other vendors to sell to", "title")
eq(c.entries[1].label, "Map Far (60 yards)", "label: name and distance")
eq(c.entries[2].default, false, "only the first is the default")
eq(c.entries[2].auction, false, "not an auctioneer")
eq(w.c.ChoiceTitle("sell"), "Other vendors to sell to", "a title while there is another seller")
eq(#w.says + #w.logs + #w.notes + w.setCount + w.cancelCount, 0, "asking prints, logs and pins nothing")
w = chooser({ cfg = { vendorPrefer = "distance" } })
eq(names(w.c.Choices("sell")), "Off Near*, Off Two, Off Three, Off Four", "distance preference: the nearest first, listed once")
w = chooser({ zones = { [200] = "Elsewhere" } })
eq(w.c.Choices("sell").entries[2].label, "Off Near (Elsewhere, 10 yards)", "label names the zone when known")
eq(w.c.Choices("repair"), nil, "no repair vendor known: nothing")
eq(w.c.ChoiceTitle("repair"), nil, "and no title")
w = world()
eq(names(w.c.Choices("repair")), "Far Repairer*", "one seller only")
eq(w.c.ChoiceTitle("repair"), nil, "one seller: no title")
eq(w.c.Choices("repair").title, "Other repair vendors", "repair title")
w = world({ ammoKind = "arrow", ammoCount = 50 })
eq(w.c.Choices("ammo").title, "Other ammo vendors", "ammo title")
eq(names(w.c.Choices("ammo")), "Arrow Man*", "arrows: only arrow sellers")
eq(world().c.Choices("ammo"), nil, "no ranged weapon: nothing")
eq(world().c.Choices("nonsense"), nil, "unknown kind: nothing")

-- Quiet: a row that cannot be routed says and logs nothing.
w = trade({ skills = { { name = "Mining", rank = 220, max = 225 } } })
eq(w.c.Choices("trainer", "Mining"), nil, "Artisan: nothing")
local w2 = world({ instance = "party", anchors = {} })
eq(w2.c.Choices("sell"), nil, "no anchor: nothing")
local w3 = world({ pos = false })
eq(w3.c.Choices("sell"), nil, "no position: nothing")
eq(#w.says + #w.logs + #w2.says + #w2.logs + #w3.says + #w3.logs, 0, "and nothing said or logged")
w = reagent()
ns.Reagents.ById = function(id) if id == 6265 then return shard end return realById(id) end
eq(w.c.Choices("reagent", 6265), nil, "display-only reagent: nothing")
ns.Reagents.ById = realById

-- Titles for reagents, supplies and trainers; the trainer tier rule holds.
eq(reagent().c.Choices("reagent", 17020).title, "Other sellers of Arcane Powder", "reagent title")
eq(supply("WARRIOR", { food = 3, water = 0, healthstone = 0 }).c.Choices("supply", "food").title, "Other food vendors", "food title")
eq(names(supply("WARRIOR", { food = 3, water = 0, healthstone = 0 }).c.Choices("supply", "food")), "Baker*, Butcher", "food sellers only")
eq(supply("PRIEST", { food = 30, water = 3, healthstone = 0 }).c.Choices("supply", "water").title, "Other water vendors", "water title")
eq(supply("HUNTER", { food = 30, water = 30, pet = 2, healthstone = 0 }, { Meat = true }).c.Choices("supply", "pet").title,
    "Other pet food vendors", "pet food title")
w = trade({ tiers = true, trainers = { [1] = TIERED } })
c = w.c.Choices("trainer", "Mining")
eq(names(c), "Expert Miner*, Unknown Miner, Master Miner", "trainers that teach the next tier only")
eq(c.title, "Other Mining trainers", "trainer title")
eq(c.entries[1].label, "Expert Miner (20 yards)", "trainer distance")

-- Inside an instance the distances are from the anchor.
w = world({ instance = "party", pos = false, anchors = { hearth = HEARTH, last = LAST } })
c = w.c.Choices("sell")
eq(names(c), "Far Repairer*, Gun Shop, Arrow Man, Near Seller", "ordered from the hearthstone point")
eq(c.entries[1].label .. " / " .. c.entries[2].label, "Far Repairer (5 yards) / Gun Shop (25 yards)", "distances from the anchor")
eq(#w.says, 0, "the anchor line is not printed")

-- The auctioneer: once, only with the setting on, outside, for a tradeable item.
eq(names(auction().c.Choices("reagent", 17020)), "Auctioneer Near*@, Powder Seller", "the closer auctioneer is the default, listed once")
eq(names(auction({ pos = { 1, 28, 0 } }).c.Choices("reagent", 17020)), "Powder Seller*, Auctioneer Near@", "a farther auctioneer is another choice")
eq(names(auction({ cfg = { ahEnabled = false } }).c.Choices("reagent", 17020)), "Powder Seller*", "setting off: no auctioneer")
eq(names(auction({ instance = "party", anchors = { last = { continent = 1, x = 0, y = 0 } } }).c.Choices("reagent", 17020)),
    "Powder Seller*", "in an instance: no auctioneer")
POWDER.soulbound = true
eq(names(auction().c.Choices("reagent", 17020)), "Powder Seller*", "soulbound: no auctioneer")
POWDER.soulbound = nil
eq(names(auction({ buckets = { [1] = VENDORS } }).c.Choices("repair")), "Far Repairer*", "repair: never an auctioneer")
eq(names(auction({ buckets = { [1] = {} } }).c.Choices("reagent", 17020)), "Auctioneer Near*@", "no vendor known: the auctioneer alone")

-- Pick pins the chosen seller like a row click: waypoint, chat, notice, and the warning is handled.
w = chooser({ free = 1, combat = true, autoAccept = false })
w.c.Evaluate()
c = w.c.Choices("sell")
eq(w.c.Pick("sell", nil, c.entries[3]), true, "pinned")
eq(w.last[2], "Off Two", "the chosen seller")
eq(w.says[1], "Navigating to Off Two (20 yards) to sell items and free bag space.", "chat names it, with no other choice")
eq(w.notes[1], w.says[1], "the notification too")
eq(w.c.PinKind(), "sell", "a sell pin")
w.combat = false
w.c.Evaluate()
eq(#w.prompts, 0, "picked while low: not asked about afterwards")
w.free = 20
w.c.Evaluate()
eq(w.clearCount, 1, "resolved: the picked pin is cleared")
w = auction({ pos = { 1, 28, 0 } })
c = w.c.Choices("reagent", 17020)
eq(w.c.Pick("reagent", 17020, c.entries[2]), true, "auctioneer pinned")
eq(w.last[2], "Auctioneer Near", "the auctioneer")
eq(w.says[1], "Navigating to Auctioneer Near (8 yards) to buy Arcane Powder at the auction house.", "the auction house text")
eq(w.c.PinKind(), "reagent", "still a reagent pin")
w = auction({ pos = { 1, 28, 0 } })
c = w.c.Choices("reagent", 17020)
w.instance, w.anchors = "party", { last = { continent = 1, x = 28, y = 0 } }
eq(w.c.Pick("reagent", 17020, c.entries[2]), false, "entered an instance since: the auctioneer is not pinned")
eq(w.setCount, 0, "no waypoint")
w = trade({ tiers = true, trainers = { [1] = TIERED } })
eq(w.c.Pick("trainer", "Mining", w.c.Choices("trainer", "Mining").entries[3]), true, "trainer pinned")
eq(w.last[2], "Master Miner", "the chosen trainer")
w = world({ instance = "party", pos = false, anchors = { hearth = HEARTH } })
w.c.Pick("sell", nil, w.c.Choices("sell").entries[2])
eq(w.says[2], "You are in an instance, so the search started from your hearthstone point.", "chat names the anchor")
w = world({ instance = "party", anchors = {} })
eq(w.c.Pick("sell", nil, { v = VENDORS[1] }), false, "nothing to route now: not pinned")
eq(w.setCount, 0, "no waypoint")
-- The list was built for arrows; a gun equipped since makes an arrow-only seller wrong.
w = world({ ammoKind = "arrow", ammoCount = 10, autoAccept = false })
c = w.c.Choices("ammo")
eq(c.entries[1].v[2], "Arrow Man", "arrow seller listed")
w.ammoKind = "bullet"
eq(w.c.Pick("ammo", nil, c.entries[1]), false, "gun equipped since: the arrow seller is not pinned")
eq(w.setCount, 0, "no waypoint")
eq(w.says[1], "The seller list changed. Open it again to choose.", "chat says to open the list again")
eq(w.c.Pick("ammo", nil, w.c.Choices("ammo").entries[1]), true, "a fresh list pins")
eq(w.last[2], "Gun Shop", "the bullet seller")
w = world({ ammoKind = "arrow", ammoCount = 10, autoAccept = false })
c = w.c.Choices("ammo")
w.ammoKind = nil -- the bow is put away
eq(w.c.Pick("ammo", nil, c.entries[1]), false, "no ranged weapon now: nothing pinned")
eq(w.says[1], "The seller list changed. Open it again to choose.", "and chat still says so")
w = trade({ tiers = true, trainers = { [1] = TIERED } })
eq(w.c.Pick("trainer", "Mining", { v = { 9, "Herbalist", 100, 0.1, 0.1, 0, { Herbalism = true }, 10, 0 } }), false,
    "a trainer that does not teach the row's profession is not pinned")

-- A click keeps the warning it closes (#39).
local SMITH = { 5, "Smith", 100, 0.9, 0.1, 0, true, 0, 90, 0, 0, 0 }
local function clicky(totals, over)
    local o = { dur = 10, autoAccept = false, buckets = { [1] = { SV[1], SV[2], SV[3], SV[4], SMITH } } }
    for k, v in pairs(over or {}) do o[k] = v end
    return supply("WARRIOR", totals, nil, nil, o)
end
w = clicky({ food = 3, water = 0, healthstone = 0 })
w.c.Evaluate()
eq(w.prompts[1].kind, "repair", "repair question open")
eq(w.c.Go("supply", "food"), true, "low food row clicked")
eq(w.cancelCount >= 1, true, "the repair question closes")
w.c.Evaluate()
eq(#w.prompts, 1, "no repair question during the clicked trip")
w.c.OnMerchantShow()
w.c.Evaluate()
eq(#w.prompts .. ":" .. w.prompts[#w.prompts].kind, "2:repair", "repair asked after the merchant")
w = clicky({ food = 3, water = 0, healthstone = 0 })
w.c.Evaluate()
local ch = w.c.Choices("supply", "food")
eq(w.c.Pick("supply", "food", ch.entries[1]), true, "a seller choice")
w.c.Evaluate()
eq(#w.prompts, 1, "choice: no repair question during the trip")
w.c.OnMerchantShow(); w.c.Evaluate()
eq(w.prompts[#w.prompts].kind, "repair", "choice: repair asked after the merchant")
-- A row that is not low: the closed warning is asked at the next check, and lower ones follow No.
w = clicky({ food = 30, water = 0, healthstone = 0 }, { free = 1 })
w.c.Evaluate()
eq(w.prompts[1].kind, "repair", "repair question open")
eq(w.c.Go("supply", "food"), true, "food row clicked while food is fine")
w.c.Evaluate()
eq(#w.prompts .. ":" .. w.prompts[2].kind, "2:repair", "repair asked again at the next check")
w.prompts[2].decline()
w.c.Evaluate()
eq(w.prompts[#w.prompts].kind, "sell", "No to repair: the sell question is asked")
-- Auto mode: a click replaces an active pinned warning trip, which comes back after it.
w = clicky({ food = 3, water = 0, healthstone = 0 }, { cfg = { vendorMode = "auto" } })
w.c.Evaluate()
eq(w.last[2], "Smith", "repair pinned without asking")
w.c.Go("supply", "food")
eq(w.last[2], "Baker", "food pinned by the click")
w.c.Evaluate()
eq(w.last[2], "Baker", "repair does not replace the clicked trip")
w.c.OnMerchantShow(); w.c.Evaluate()
eq(w.last[2], "Smith", "repair pinned again after the merchant")

-- After No, the re-check goes through Core's evaluate (which arms the position retry).
local viaCore = 0
w = world({ free = 1, dur = 10, autoAccept = false, evaluate = function() viaCore = viaCore + 1 end })
w.c.Evaluate()
w.prompts[1].decline()
w.timers[#w.timers].fn()
eq(viaCore, 1, "the re-check after No uses env.evaluate")

-- A trainer question ends with the place.
w = trade({ autoAccept = false })
w.c.OnCraft()
eq(#w.prompts, 1, "trainer question open")
w.c.OnPlaceChange()
eq(w.cancelCount >= 1, true, "zone change withdraws it")
w.prompts[1].accept()
eq(w.setCount, 0, "a late Yes sets no waypoint")

-- The ammo request follows the weapon.
w = world({ ammoKind = "arrow", ammoCount = 10 })
w.c.Evaluate()
eq(w.last[2], "Arrow Man", "arrow vendor pinned")
w.ammoKind = "bullet"
w.c.Evaluate()
eq(w.clearCount >= 1 and w.last[2], "Gun Shop", "gun equipped: the arrow pin ends and bullets are asked")
w = world({ ammoKind = "arrow", ammoCount = 10, autoAccept = false })
w.c.Evaluate()
w.ammoKind = "bullet"
w.c.Evaluate()
eq(w.cancelCount >= 1 and #w.prompts .. ":" .. w.prompts[2].kind, "2:bullet", "the arrow question closes, the bullet one is asked")
w = world({ ammoKind = "arrow", ammoCount = 10, autoAccept = false, combat = true })
w.c.Evaluate() -- in combat: nothing asked, the low ammo is only seen
w.combat = false
w.c.Go("ammo")
eq(w.last[2], "Arrow Man", "arrow row clicked")
w.ammoKind = "bullet"
w.c.Evaluate()
eq(w.prompts[#w.prompts].kind, "bullet", "a clicked arrow trip also follows the weapon")
-- The pet food request follows the pet's diet.
w = supply("HUNTER", { food = 30, water = 30, pet = 2, healthstone = 0 }, { Meat = true })
w.c.Evaluate()
eq(w.last[2], "Butcher", "meat seller pinned")
w.supplies.diets = { Meat = true }
w.c.Evaluate()
eq(w.setCount, 1, "same diet: the pin stays")
w.supplies.diets = { Bread = true }
w.c.Evaluate()
eq(w.clearCount >= 1 and w.last[2], "Baker", "a bread eater: the meat pin ends and a bread seller is asked")

-- A step timer that cannot be scheduled ends the tour and still tells the caller (done), so the
-- made-up status rows go away.
w = world({ afterFailsAt = 2, autoAccept = false })
local doneCount = 0
w.c.Demo(function() doneCount = doneCount + 1 end)
eq(doneCount, 0, "the tour runs while timers work")
table.remove(w.timers, 1).fn()
eq(doneCount, 1, "the second timer failed: done runs")


-- Find: look up an item by link or name and list its known sellers ----------------------------------------
do
    local saved = ns.SupplyItems
    ns.SupplyItems = { [1179] = 2, [1205] = 2, [117] = 1 + 4, [4599] = 1 + 16 }
    local NAMES = { [1179] = "Ice Cold Milk", [1205] = "Melon Juice", [117] = "Tough Jerky", [4599] = "Cured Ham Steak",
        [17020] = "Arcane Powder" }
    local function finder(over)
        local o = { itemNames = NAMES, icons = { [1179] = 132800, [1205] = 132801 } }
        for k, v in pairs(over or {}) do o[k] = v end
        return supply("MAGE", { food = 30, water = 30, healthstone = 0 }, nil, nil, o)
    end

    -- Nothing matches: its own line, no list, no route.
    w = finder()
    w.c.Find("moonberry")
    eq(w.says[1], "No supply item matches moonberry.", "find: no match says so")
    eq(w.logs[#w.logs], "find: no item matches", "find: no match is logged")
    eq(#w.menus, 0, "find: no match opens no menu")
    eq(w.setCount, 0, "find: no match sets no waypoint")

    -- Too many: asked to type more; no menu.
    local many, mnames = {}, {}
    for i = 1, 9 do many[100 + i] = 2; mnames[100 + i] = "Juice " .. i end
    w = finder({ itemNames = mnames })
    ns.SupplyItems = many
    w.c.Find("juice")
    eq(w.says[1], "Too many items match juice. Type more of the name.", "find: more than 8 matches asks for more of the name")
    eq(w.logs[#w.logs], "find: too many items match", "find: too many is logged")
    eq(#w.menus, 0, "find: too many opens no menu")
    ns.SupplyItems = { [1179] = 2, [1205] = 2, [117] = 1 + 4, [4599] = 1 + 16 }
    local eight = {}
    for i = 1, 8 do eight[100 + i] = 2 end
    ns.SupplyItems = eight
    w = finder({ itemNames = mnames })
    w.c.Find("juice")
    eq(#w.menus, 1, "find: exactly 8 matches still list")
    eq(#w.menus[1].items, 8, "find: all 8 items listed")
    ns.SupplyItems = { [1179] = 2, [1205] = 2, [117] = 1 + 4, [4599] = 1 + 16 }

    -- One item, a drink: the seller list opens with the category note, and browsing pins nothing.
    w = finder()
    w.c.Find("melon")
    eq(#w.menus, 1, "find: one match opens the seller list")
    eq(w.menus[1].title, "Sellers of Melon Juice", "find: seller list title names the item")
    eq(#w.menus[1].items, 1, "find: the one drink seller")
    eq(w.menus[1].items[1].checked, true, "find: the nearest seller is marked")
    eq(w.says[1], "Vendors are known by category, not by item, so these sell drink in general and may not stock Melon Juice.", "find: a supply says it is category-level")
    eq(w.setCount, 0, "find: browsing sets no waypoint")
    eq(#w.prompts, 0, "find: browsing asks nothing")
    w.menus[1].items[1].func()
    eq(w.setCount, 1, "find: choosing pins the seller")
    eq(w.last[2], "Well", "find: the drink seller is pinned")

    -- Food: the nearest of the sellers of food, others follow; the other faction is skipped.
    w = finder()
    w.c.Find("jerky")
    eq(#w.menus[1].items, 2, "find: both food sellers listed")
    local fv = {}
    for i, v in ipairs(SV) do fv[i] = v end
    fv[#fv + 1] = { 5, "Rival Baker", 100, 0.05, 0.1, 2, false, 0, 2, 0, 0, 1 }
    w = finder({ buckets = { [1] = fv } })
    w.c.Find("jerky")
    eq(w.menus[1].items[1].text:find("Baker", 1, true) ~= nil, true, "find: the other faction's nearer seller is skipped")
    eq(w.menus[1].items[1].text:find("Rival", 1, true), nil, "find: the other faction is never listed")

    -- Recognized, but no seller of its category is known.
    w = finder({ buckets = { [1] = { SV[1], SV[2] } } })
    w.c.Find("melon")
    eq(w.says[1], "Melon Juice is a known item, but no known vendor sells it yet for your faction.", "find: a recognized item with no seller says so")
    eq(#w.menus, 0, "find: no seller opens no menu")

    -- Several items: a menu of icon and name first; choosing one opens its seller list after the item menu closes.
    w = finder()
    w.c.Find("e")
    eq(w.menus[1].title, "Which item?", "find: several matches ask which item")
    eq(#w.menus[1].items, 5, "find: every matching item listed")
    eq(w.menus[1].items[3].text, "Ice Cold Milk", "find: items sorted by name")
    eq(w.menus[1].items[3].icon, 132800, "find: an item shows its icon")
    eq(w.menus[1].items[4].icon, 132801, "find: each item its own icon")
    w.menus[1].items[3].func()
    eq(#w.menus, 1, "find: the seller list waits until the item menu has closed")
    w.timers[1].fn()
    eq(#w.menus, 2, "find: choosing an item opens its seller list")
    eq(w.menus[2].title, "Sellers of Ice Cold Milk", "find: the list is for the chosen item")
    eq(w.setCount, 0, "find: choosing an item pins nothing")
    w = finder({ noAfter = true })
    w.c.Find("e")
    w.menus[1].items[3].func()
    eq(#w.menus, 2, "find: with no timer the seller list opens at once")

    -- A class reagent is exact: no category note, the seller of that reagent.
    w = reagent({ supplies = { class = "MAGE", totals = {}, diets = nil, knows = function() return false end }, itemNames = NAMES })
    w.c.Find("arcane powder")
    eq(#w.says, 1, "find: a reagent says its sellers are listed, with no category note")
    eq(w.says[1], "The sellers of Arcane Powder are listed. Pick one to set a waypoint.", "find: the reagent outcome line")
    eq(w.menus[1].title, "Sellers of Arcane Powder", "find: reagent list")
    eq(w.menus[1].items[1].text:find("Powder Seller", 1, true) ~= nil, true, "find: the seller of that reagent, not the nearest vendor")
    w = reagent({ supplies = { class = "ROGUE", totals = {}, knows = function() return false end }, itemNames = NAMES })
    w.c.Find("arcane powder")
    eq(w.says[1], "No supply item matches arcane powder.", "find: another class's reagent is not found")

    -- No menu control: the nearest seller goes to chat and nothing is pinned.
    w = finder({ noMenu = true })
    w.c.Find("melon")
    eq(w.says[2], "Nearest known seller of Melon Juice: Well (60 yards).", "find: without a menu the nearest seller is in chat")
    eq(w.setCount, 0, "find: without a menu nothing is pinned")
    w = finder({ noMenu = true })
    w.c.Find("e")
    eq(w.says[1], "Several items match e. Type more of the name.", "find: without a menu several matches ask for more")

    -- In an instance the list is measured from the anchor a row click uses; no position says so.
    w = finder({ instance = "party", anchors = { hearth = { continent = 1, x = 55, y = 0, map = 100 } } })
    w.c.Find("melon")
    eq(w.menus[1].items[1].text, "Well (5 yards)", "find: measured from the hearthstone point in an instance")
    w = finder({ pos = false })
    w.c.Find("melon")
    eq(#w.menus, 0, "find: with no position nothing opens")
    eq(w.says[1], "No map position here (dungeons and some areas have none). Try again outside.", "find: no position says so")


    -- Review fixes -------------------------------------------------------------------------------
    -- A pet-food pick only counts for the pet's warning when the seller sells what the pet eats.
    do
        local FISH, MEAT = { 21, "Fish Seller", 100, 0.3, 0.1, 0, false, 0, 30, 0, 0, 8 }, { 22, "Meat Seller", 100, 0.5, 0.1, 0, false, 0, 50, 0, 0, 4 }
        ns.SupplyItems = { [800] = 8, [801] = 4 }
        local petNames = { [800] = "Raw Fish", [801] = "Raw Meat" }
        local function hunter()
            local h = supply("HUNTER", { food = 30, water = 30, pet = 1, healthstone = 0 }, { Meat = true },
                nil, { buckets = { [1] = { FISH, MEAT } }, itemNames = petNames, autoAccept = false })
            h.c.Evaluate()
            return h
        end
        w = hunter()
        eq(#w.prompts, 1, "fix 1: the low pet food question is open")
        w.c.Find("raw fish")
        w.menus[1].items[1].func()
        w.c.Evaluate()
        eq(#w.prompts, 2, "fix 1: a seller of fish does not answer a meat pet's warning, it is asked again")
        w = hunter()
        w.c.Find("raw meat")
        w.menus[1].items[1].func()
        w.c.Evaluate()
        eq(#w.prompts, 1, "fix 1: a seller of what the pet eats answers the warning")
        ns.SupplyItems = { [1179] = 2, [1205] = 2, [117] = 1 + 4, [4599] = 1 + 16 }
    end

    -- Picking a seller ends a running demo, so its next step cannot replace the waypoint.
    w = finder()
    w.c.Demo(function() end)
    w.c.Find("melon")
    w.menus[#w.menus].items[1].func()
    eq(w.last[2], "Well", "fix 2: the seller is pinned")
    local sets, clears, ranTimers = w.setCount, w.clearCount, 0
    for _, t in ipairs(w.timers or {}) do t.fn(); ranTimers = ranTimers + 1 end
    eq(ranTimers > 0, true, "fix 2: the demo had a step waiting")
    eq(w.setCount .. "," .. w.clearCount, sets .. "," .. clears, "fix 2: the demo's next steps neither clear nor replace the chosen seller")
    eq(w.last[2], "Well", "fix 2: the chosen seller stays pinned")

    -- Without a menu the chat names the seller that is nearest, not the one a row click would pick.
    do
        local far = { 11, "Map Well", 100, 0.9, 0.1, 0, false, 0, 900, 0, 0, 2 }
        local near = { 12, "Near Well", 200, 0.1, 0.1, 0, false, 0, 50, 0, 0, 2 }
        w = finder({ noMenu = true, buckets = { [1] = { far, near } }, pos = { 1, 0, 0, 100 } })
        w.c.Find("melon")
        eq(w.says[2], "Nearest known seller of Melon Juice: Near Well (50 yards).", "fix 3: the chat fallback names the nearest seller")
        w = finder({ buckets = { [1] = { far, near } }, pos = { 1, 0, 0, 100 } })
        w.c.Find("melon")
        eq(w.menus[1].items[1].text:find("Map Well", 1, true) ~= nil, true, "fix 3: the menu still marks the row-click default first")
    end

    -- A reagent found by its game-language name keeps that name when picked, even when its warning is off.
    w = reagent({ reagents = {}, supplies = { class = "MAGE", totals = {}, knows = function() return false end },
        itemNames = { [17020] = "Poudre Arcanique" } })
    w.c.Find("poudre")
    w.menus[1].items[1].func()
    eq(w.says[#w.says], "Navigating to Powder Seller (30 yards) to buy Poudre Arcanique.", "fix 6: the notice uses the game-language name")

    -- A link works whatever the name; empty text matches nothing.
    w = finder({ itemNames = {} })
    w.c.Find("|cff1eff00|Hitem:1205::::::::60:::::|h[Melon Juice]|h|r")
    eq(#w.menus, 1, "find: a link finds an item the client has not named")
    w = finder()
    w.c.Find("   ")
    eq(w.says[1], "No supply item matches .", "find: empty text matches nothing")
    ns.SupplyItems = saved
end

-- Debug log lines the in-game plans assert or keep as diagnostics (docs/contracts.md): exact text.
do
    local function logged(w, line) for _, m in ipairs(w.logs) do if m == line then return true end end return false end
    local function all(w) return table.concat(w.logs, " / ") end
    -- Two targets: both named with the rule, before the question or the automatic pin.
    w = mapped({ autoAccept = false })
    w.c.Evaluate()
    eq(logged(w, "two targets: on your map Home Seller (npc 32), closest Other Seller (npc 31), prefer map"), true, "two targets, prefer map: " .. all(w))
    w = mapped({ autoAccept = false, cfg = { vendorPrefer = "distance" } })
    w.c.Evaluate()
    eq(logged(w, "two targets: on your map Home Seller (npc 32), closest Other Seller (npc 31), prefer distance"), true, "two targets, prefer distance")
    w = mapped({ cfg = { vendorMode = "auto" } })
    w.c.Evaluate()
    eq(logged(w, "two targets: on your map Home Seller (npc 32), closest Other Seller (npc 31), prefer map"), true, "two targets, automatic pin")
    eq(w.logs[#w.logs - 2]:find("^two targets: ") ~= nil and w.logs[#w.logs - 1]:find("^auto: Home Seller") ~= nil, true, "two targets come just before the auto line: " .. all(w))
    -- The auto line says which of the two it took, so a reversed preference shows.
    eq(logged(w, "auto: Home Seller (npc 32) chosen from two candidates: the one on your map"), true, "prefer map: the one on your map: " .. all(w))
    eq(logged(w, "accepted: Home Seller via x"), true, "and that one was accepted")
    w = mapped({ cfg = { vendorMode = "auto", vendorPrefer = "distance" } })
    w.c.Evaluate()
    eq(logged(w, "auto: Other Seller (npc 31) chosen from two candidates: the closest"), true, "prefer distance: the closest: " .. all(w))
    w = world({ free = 1, autoAccept = false })
    w.c.Evaluate()
    eq(has(w, "two targets: "), false, "one target: no two-targets line")

    -- Skills near their cap that are not asked about.
    w = trade({ skills = { { name = "Swords", rank = 70, max = 75 }, { name = "Mining", rank = 70, max = 75 } }, autoAccept = false })
    w.c.OnCraft()
    eq(logged(w, "profession check: left out: Swords 70/75 (no trainer or crafting window seen)"), true, "a weapon skill is left out: " .. all(w))
    w = trade({ skills = mining(150, 150), level = 15 })
    w.c.OnCraft()
    eq(logged(w, "profession check: left out: Mining 150/150 (level 20 needed)"), true, "the level gate is logged")
    w = trade({ skills = mining(220, 225), level = 40 })
    w.c.OnCraft()
    eq(logged(w, "profession check: left out: Mining 220/225 (Artisan: trainer tiers unknown)"), true, "Artisan without tiers is logged")
    w = trade({ skills = mining(295, 300) })
    w.c.OnCraft()
    eq(logged(w, "profession check: left out: Mining 295/300 (the last tier)"), true, "the last tier is logged")
    w = trade({ skills = mining(295, 300), cfg = { tradeEnabled = false } })
    w.c.OnCraft()
    eq(has(w, "profession check: left out"), false, "profession warning off: nothing logged")
    w = trade()
    w.c.OnCraft()
    eq(has(w, "left out"), false, "a profession that is asked about is not left out")

    -- Why a profession near its cap asked nothing.
    w = trade({ autoAccept = false })
    w.c.OnCraft(); w.c.OnCraft()
    eq(logged(w, "profession check skipped: a question is open"), true, "open question: skip logged")
    w = trade()
    w.c.OnCraft(); w.c.OnCraft()
    eq(logged(w, "profession check skipped: a Mining trainer waypoint is set"), true, "trainer waypoint: skip logged")
    w = trade({ free = 1 })
    w.c.Evaluate(); w.c.OnCraft()
    eq(logged(w, "profession check skipped: the sell request is open or active"), true, "active request: skip logged")

    -- The tier a trainer question needs, and what the chosen trainer teaches.
    w = trade({ tiers = true, trainers = { [1] = TIERED }, skills = mining(145, 150), level = 20, autoAccept = false })
    w.c.OnCraft()
    eq(logged(w, "trainer search: Mining needs tier 3; nearest Unknown Miner (npc 32) teaches an unknown tier"), true, "tier 3: " .. all(w))
    w = trade({ tiers = true, trainers = { [1] = TIERED }, skills = mining(220, 225), level = 40, autoAccept = false })
    w.c.OnCraft()
    eq(logged(w, "trainer search: Mining needs tier 4; nearest Master Miner (npc 33) teaches tier 4"), true, "tier 4")

    -- A merchant window clears a vendor waypoint and keeps a trainer's.
    w = trade()
    w.c.OnCraft(); w.c.OnMerchantShow()
    eq(logged(w, "waypoint kept: it leads to a Mining trainer"), true, "trainer waypoint kept at a merchant")
    w = world({ free = 1 })
    w.c.Evaluate(); w.c.OnMerchantShow()
    eq(logged(w, "waypoint cleared: a merchant window opened"), true, "vendor waypoint cleared at a merchant")
    w = world()
    w.c.OnMerchantShow()
    eq(has(w, "waypoint cleared") or has(w, "waypoint kept"), false, "no waypoint: nothing logged")

    -- The profession's own trainer window ends the trainer waypoint.
    w = trade()
    w.c.OnCraft(); w.c.OnTrainerShow({ Herbalism = true })
    eq(has(w, "trainer waypoint cleared"), false, "another profession's trainer: nothing logged")
    w.c.OnTrainerShow({ Mining = true })
    eq(logged(w, "trainer waypoint cleared: the Mining trainer window opened"), true, "its trainer window: cleared and logged")

    -- A row click for Artisan without trainer tiers; the seller list asks quietly.
    w = trade({ skills = mining(220, 225), level = 40 })
    eq(w.c.Choices("trainer", "Mining"), nil, "Artisan: no seller list")
    eq(has(w, "Artisan"), false, "the seller list logs nothing")
    w.c.Go("trainer", "Mining")
    eq(logged(w, "direct pin: Artisan Mining is not routed: trainer tiers unknown"), true, "Artisan refusal logged")

    -- The Artisan reason only for Artisan near its cap without tiers; other refusals say their own reason.
    w = trade({ skills = mining(100, 225), level = 40 })
    w.c.Go("trainer", "Mining")
    eq(has(w, "Artisan"), false, "Artisan far from its cap: not the tiers reason: " .. all(w))
    eq(logged(w, "direct pin: profession is not near its cap"), true, "far from its cap: that reason")
    eq(#w.says, 0, "and nothing in chat")
    w = trade({ tiers = true, trainers = { [1] = TIERED }, skills = mining(220, 225), level = 30 })
    w.c.Go("trainer", "Mining")
    eq(logged(w, "direct pin: profession is not routed: level 35 needed"), true, "tiers known, level too low: the level reason: " .. all(w))
    eq(has(w, "Artisan"), false, "and not the tiers reason")
    w = trade({ skills = mining(295, 300) })
    w.c.Go("trainer", "Mining")
    eq(logged(w, "direct pin: profession is not routed: the last tier"), true, "the last tier: its own reason: " .. all(w))
    w = trade({ skills = mining(220, 225), known = {}, level = 40 })
    w.c.Go("trainer", "Mining")
    eq(logged(w, "direct pin: profession is not routed: no trainer or crafting window seen"), true, "never seen: its own reason: " .. all(w))

    -- A waypoint method that raises while removing: the clear is logged as FAILED.
    w = world({ free = 1, clearFails = true })
    w.c.Evaluate(); w.c.OnMerchantShow()
    eq(logged(w, "FAILED: waypoint not cleared: a merchant window opened"), true, "merchant: failed clear: " .. all(w))
    eq(has(w, "waypoint cleared: a merchant"), false, "and no cleared line")
    w = trade({ clearFails = true })
    w.c.OnCraft(); w.c.OnTrainerShow({ Mining = true })
    eq(logged(w, "FAILED: trainer waypoint not cleared: the Mining trainer window opened"), true, "trainer window: failed clear")
    eq(has(w, "trainer waypoint cleared"), false, "and no cleared line")
    w = trade({ clearFails = true })
    w.c.OnCraft()
    w.skills = mining(50); w.c.OnSkillChange()
    eq(logged(w, "FAILED: trainer waypoint not cleared: Mining is no longer near its cap"), true, "skill moved away: failed clear: " .. all(w))
    w = trade()
    w.c.OnCraft()
    w.skills = mining(50); w.c.OnSkillChange()
    eq(logged(w, "trainer waypoint cleared: Mining is no longer near its cap"), true, "skill moved away: cleared")
    -- A waypoint method that cannot confirm the removal (Nav.Clear nil): said so, never "cleared".
    w = world({ free = 1, clearUnknown = true })
    w.c.Evaluate(); w.c.OnMerchantShow()
    eq(logged(w, "waypoint clear not confirmed: a merchant window opened"), true, "merchant: unconfirmed clear: " .. all(w))
    eq(has(w, "waypoint cleared: "), false, "and no cleared line")
    w = trade({ clearUnknown = true })
    w.c.OnCraft(); w.c.OnTrainerShow({ Mining = true })
    eq(logged(w, "trainer waypoint clear not confirmed: the Mining trainer window opened"), true, "trainer window: unconfirmed clear: " .. all(w))
    eq(has(w, "waypoint cleared: "), false, "and no cleared line")
    w = trade({ clearUnknown = true })
    w.c.OnCraft()
    w.skills = mining(50); w.c.OnSkillChange()
    eq(logged(w, "trainer waypoint clear not confirmed: Mining is no longer near its cap"), true, "skill moved away: unconfirmed clear")

    -- A repeated left-out or skip line is written once, again after a change of state or 30 seconds.
    local function count(gw, line) local n = 0 for _, m in ipairs(gw.logs) do if m == line then n = n + 1 end end return n end
    local SW = "profession check: left out: Swords 70/75 (no trainer or crafting window seen)"
    w = trade({ skills = { { name = "Swords", rank = 70, max = 75 }, { name = "Mining", rank = 295, max = 300 } } })
    local BOTH = "profession check: left out: Swords 70/75 (no trainer or crafting window seen), Mining 295/300 (the last tier)"
    w.clock = 100
    w.c.OnCraft(); w.c.OnCraft(); w.c.OnCraft()
    eq(count(w, BOTH), 1, "the same left-out line once: " .. all(w))
    w.clock = 129; w.c.OnCraft()
    eq(count(w, BOTH), 1, "not again within 30 seconds")
    w.clock = 130; w.c.OnCraft()
    w.clock = 131; w.c.OnCraft()
    eq(count(w, BOTH), 2, "again after 30 seconds, then quiet again")
    w = trade({ skills = { { name = "Swords", rank = 70, max = 75 }, { name = "Mining", rank = 70, max = 75 } }, autoAccept = false })
    w.c.OnCraft(); w.c.OnCraft(); w.c.OnCraft()
    eq(count(w, SW), 2, "a question shown in between: written again: " .. all(w))
    eq(count(w, "profession check skipped: a question is open"), 1, "the same skip line once")
    -- A skill-up alone (same skills, same reasons, new rank) writes nothing new within 30 seconds.
    w = trade({ skills = { { name = "Swords", rank = 70, max = 75 } } })
    w.clock = 100
    w.c.OnSkillChange(); w.c.OnCraft()
    w.skills = { { name = "Swords", rank = 71, max = 75 } }; w.clock = 110; w.c.OnSkillChange()
    w.skills = { { name = "Swords", rank = 72, max = 75 } }; w.clock = 120; w.c.OnSkillChange()
    local n = 0 for _, m in ipairs(w.logs) do if m:find("profession check: left out: ", 1, true) then n = n + 1 end end
    eq(n, 1, "weapon skill-ups: one left-out line: " .. all(w))
    w.skills = { { name = "Swords", rank = 72, max = 75 }, { name = "Mining", rank = 295, max = 300 } }; w.clock = 121; w.c.OnSkillChange()
    eq(logged(w, "profession check: left out: Swords 72/75 (no trainer or crafting window seen), Mining 295/300 (the last tier)"), true, "a new skill left out: written")

    -- A row click inside an instance names where the search started.
    w = world({ instance = "party", pos = false, anchors = { hearth = HEARTH, last = LAST } })
    w.c.Go("sell")
    eq(logged(w, "direct pin: the search started from your hearthstone point"), true, "hearthstone anchor logged")
    w = world({ instance = "party", pos = false, anchors = { last = LAST } })
    w.c.Go("sell")
    eq(logged(w, "direct pin: the search started from your last position outside"), true, "last position anchor logged")
end

-- /cvn test that asks nothing writes why, after the test command line.
do
    local wt = supply("WARRIOR", { food = 30, water = 0, healthstone = 0 })
    eq(wt.c.Test("water"), "Your class does not use water.", "test water as a warrior: the message")
    eq(wt.logs[#wt.logs], "test command: nothing asked: the class does not use water", "test water: why nothing was asked")
    eq(wt.logs[#wt.logs - 1], "test command: water", "after the test command line")
    wt = supply("HUNTER", { food = 30, water = 0, pet = 0, healthstone = 0 })
    wt.c.Test("petfood")
    eq(wt.logs[#wt.logs], "test command: nothing asked: no pet to feed", "test petfood without a pet")
    wt = reagent({ reagents = {} })
    wt.c.Test("reagent")
    eq(wt.logs[#wt.logs], "test command: nothing asked: no class reagent watched", "test reagent with nothing watched")
    wt = reagent({ buckets = {} })
    wt.c.Test("reagent")
    eq(wt.logs[#wt.logs], "test command: nothing asked: no known vendor", "test reagent with no seller known")
    wt = reagent({ reagents = { { item = POWDER, count = 80, name = "Arcane Powder" } } })
    wt.c.Test("reagent")
    eq(has(wt, "test command: nothing asked"), false, "a test that asks writes no nothing-asked line")
end

-- Reagents(): what the last Evaluate watched, for the CheckThat reagents entry; no game read.
do
    local wr = reagent({ reagents = { { item = PORTALS, count = 2, name = "Rune of Portals" }, { item = POWDER, count = 7, name = "Arcane Powder" } } })
    eq(wr.c.Reagents(), nil, "reagents: nothing before the first check")
    wr.c.Evaluate()
    eq(wr.c.Reagents(), "17020:7,17032:2", "reagents: id:count sorted by id")
    eq(wr.c.Reagents(17032), 2, "reagents: one reagent's count")
    eq(wr.c.Reagents("17020"), 7, "reagents: an id typed as text")
    eq(wr.c.Reagents(1), nil, "reagents: not watched")
    wr.reagents = {}
    wr.c.Evaluate()
    eq(wr.c.Reagents(), "none", "reagents: none watched")
    -- The reagents cannot be read (class unknown): nothing, never "none".
    wr.reagents = { { item = POWDER, count = 7, name = "Arcane Powder" } }
    wr.c.Evaluate()
    wr.reagents = nil
    wr.c.Evaluate()
    eq(wr.c.Reagents(), nil, "reagents: nothing when the list is unknown")
    eq(wr.c.Reagents(17020), nil, "reagents: no count when the list is unknown")
end

H.done()
