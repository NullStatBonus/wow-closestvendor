-- Ties triggers, search and navigation together. No WoW globals: `env` supplies everything.
--   env.cfg                         live settings table (see Triggers.New)
--   env.freeSlots()                 -> number
--   env.lowestDurability()          -> percent or nil
--   env.inCombat()                  -> boolean
--   env.playerPos()                 -> continentId, x, y  (world coords) or nil
--   env.playerFaction               -> 1 Alliance, 2 Horde, 0 unknown
--   env.buckets                     { [continentId] = { vendor records, see Search.lua } }
--   env.nav                         { Set(vendor) -> handle|nil, Clear(handle) }
--   env.ammo()                      -> "arrow"|"bullet", count  for the equipped ranged weapon, or nil
--   env.confirm(kind, vendor, accept, count)  ask the player; call accept() only on Yes
--       kind is "sell", "repair", "arrow", "bullet" or "trainer"; count is the ammo left, or for a
--       trainer the points left to the cap; a 5th argument names the profession
--   env.cancelConfirm()             close the question if it is showing
--   env.questionOpen()              optional: true while a question is showing
--   env.skills()                    -> list of { name, rank, max } for the player's skills, or nil
--   env.known                       set of profession names the addon has seen (live table)
--   env.trainerBuckets              { [continentId] = { trainer records, see Search.NearestTrainer } }
--   env.say(text)                   optional: print a line to chat
--   env.log(text)                   optional: record a decision in the debug log
local _, ns = ...

local L = ns.L

local C = {}
ns.Controller = C

-- Dialog text for a found vendor or trainer; kind is "sell", "repair", "arrow", "bullet" or
-- "trainer"; zone and count may be nil. For a trainer, count is the points left and trade the profession.
function C.PromptText(kind, vendor, zone, count, trade)
    local who = vendor[2] .. (zone and (" (" .. zone .. ")") or "")
    if kind == "trainer" then
        if count and count > 0 then
            return L["Your %s skill is %d point(s) from its current limit.\n\nNavigate to the closest %s trainer, %s?"]:format(trade, count, trade, who)
        end
        return L["Your %s skill has reached its current limit.\n\nNavigate to the closest %s trainer, %s?"]:format(trade, trade, who)
    elseif kind == "arrow" then
        if count then
            return L["You are low on arrows (%d left).\n\nNavigate to the closest vendor that sells arrows, %s?"]:format(count, who)
        end
        return L["You are low on arrows.\n\nNavigate to the closest vendor that sells arrows, %s?"]:format(who)
    elseif kind == "bullet" then
        if count then
            return L["You are low on bullets (%d left).\n\nNavigate to the closest vendor that sells bullets, %s?"]:format(count, who)
        end
        return L["You are low on bullets.\n\nNavigate to the closest vendor that sells bullets, %s?"]:format(who)
    elseif kind == "repair" then
        return L["Your gear needs repair.\n\nNavigate to the closest repair vendor, %s?"]:format(who)
    end
    return L["Your bags are almost full.\n\nNavigate to the closest vendor, %s?"]:format(who)
end

function C.New(env)
    local triggers = ns.Triggers.New(env.cfg)
    local self = { pending = nil } -- "sell"/"repair"/"ammo" waiting for a position
    local ammoKind, ammoCount -- from the last Evaluate
    local handle
    local pinTrade -- profession of the active trainer waypoint, if the waypoint is a trainer's
    local lastKind, lastTrade -- what the most recent question was about
    local noticed = {} -- professions already told about having no known trainer
    local promptId = 0
    local log = env.log or function() end
    local professions = ns.Professions.New()
    local questionOpen = env.questionOpen or function() return false end
    local say = env.say or function() end

    local function clearNav()
        if handle then env.nav.Clear(handle) end
        handle, pinTrade = nil, nil
    end

    -- Vendor triggers end a vendor waypoint, never a trainer's.
    local function clearVendorNav()
        if not pinTrade then clearNav() end
    end

    -- Invalidate any open question so a late Yes cannot navigate.
    local function cancelPrompt()
        promptId = promptId + 1
        env.cancelConfirm()
    end

    -- Nearest eligible vendor for kind, or nil plus "nopos" / "novendor".
    local function findVendor(kind)
        local continent, x, y = env.playerPos()
        if not continent then return nil, "nopos" end
        local need = (kind == "repair" or kind == "arrow" or kind == "bullet") and kind or nil
        local v = ns.Search.Nearest(env.buckets[continent] or {}, x, y, need, env.playerFaction)
        if not v then return nil, "novendor" end
        return v
    end

    -- Ask the player; navigate only on Yes.
    local function ask(kind, v, count)
        promptId = promptId + 1
        local mine = promptId
        lastKind, lastTrade = kind, nil
        log(("question shown: %s, %s (npc %s)"):format(kind, v[2], tostring(v[1])))
        env.confirm(kind, v, function()
            if mine ~= promptId then log("answer ignored: the question was withdrawn") return end
            clearNav()
            handle = env.nav.Set(v)
            log(("accepted: %s via %s"):format(v[2], handle and handle.kind or "nothing available"))
        end, count)
    end

    -- Ask about the trainer for trade, remaining points from its cap; navigate only on Yes.
    local function askTrainer(v, trade, remaining)
        promptId = promptId + 1
        local mine = promptId
        lastKind, lastTrade = "trainer", trade
        log(("question shown: trainer for %s, %s (npc %s), %d point(s) left"):format(trade, v[2], tostring(v[1]), remaining))
        env.confirm("trainer", v, function()
            if mine ~= promptId then log("answer ignored: the question was withdrawn") return end
            clearNav()
            handle = env.nav.Set(v)
            if handle then pinTrade = trade end
            log(("accepted: %s via %s"):format(v[2], handle and handle.kind or "nothing available"))
        end, remaining, trade)
    end

    -- skills: the player's skill list. Asks about the profession nearest its cap that has a
    -- known trainer. Runs on every skill change and craft: there is deliberately no latch.
    local function checkTrade(skills)
        if not env.cfg.tradeEnabled then return end
        local within = ns.Professions.Within(skills, env.known or {}, env.cfg.tradeThreshold)
        -- A trainer waypoint ends once its profession is no longer near the cap.
        if pinTrade then
            local still = false
            for _, p in ipairs(within) do if p.name == pinTrade then still = true end end
            if not still then log("trainer waypoint cleared: " .. pinTrade .. " is no longer near its cap") clearNav() end
        end
        if #within == 0 then return end
        if env.inCombat() then log("profession check skipped: in combat") return end
        -- Lowest priority: never over an open question, an open or active vendor request, or a trainer trip.
        if pinTrade or questionOpen() or triggers.Active() then return end
        local continent, x, y = env.playerPos()
        if not continent then log("profession check: no map position") return end
        for _, p in ipairs(within) do
            local v = ns.Search.NearestTrainer((env.trainerBuckets or {})[continent] or {}, x, y, p.name, env.playerFaction)
            if v then return askTrainer(v, p.name, p.remaining) end
            if not noticed[p.name] then
                noticed[p.name] = true
                say(L["No known trainer for %s on this continent yet. Open a %s trainer window once and the addon will remember where it is."]:format(p.name, p.name))
                log("no known trainer for " .. p.name)
            end
        end
    end

    -- trigger is "sell", "repair" or "ammo"; ammo resolves to arrows or bullets from the weapon.
    local function place(trigger)
        -- ammo resolves to arrows or bullets from the weapon seen by the last Evaluate
        local kind = trigger == "ammo" and ammoKind or trigger
        local v, why = findVendor(kind)
        if why == "nopos" then
            self.pending = trigger -- no map position yet (loading, instance); retry later
            log("no map position yet: " .. trigger .. " request kept for a retry")
        elseif v then
            self.pending = nil
            ask(kind, v, trigger == "ammo" and ammoCount or nil)
        else
            self.pending = nil
            log("no known vendor for " .. kind .. " on this continent")
        end
    end

    function self.Evaluate()
        ammoKind, ammoCount = env.ammo()
        local free, dur, combat = env.freeSlots(), env.lowestDurability(), env.inCombat()
        local a = triggers.Update(free, dur, combat, ammoKind and ammoCount or nil)
        if a then
            log(("trigger %s%s (bags=%s durability=%s ammo=%s combat=%s)"):format(a[1], a[2] and (" " .. a[2]) or "",
                tostring(free), dur and ("%.0f%%"):format(dur) or "n/a",
                ammoKind and (ammoKind .. ":" .. tostring(ammoCount)) or "n/a", tostring(combat)))
            if a[1] == "clear" then
                self.pending = nil
                cancelPrompt()
                clearVendorNav()
            else
                place(a[2])
            end
        elseif self.pending and not combat then
            log("retrying the " .. self.pending .. " request")
            place(self.pending)
        end
    end

    function self.OnMerchantShow()
        log("merchant window opened")
        -- a merchant window answers a vendor question by itself, but not a trainer question
        if lastKind ~= "trainer" then cancelPrompt() end
        if triggers.OnMerchantShow() then self.pending = nil end
        clearVendorNav() -- any merchant counts as arriving, including after a test pin
    end

    -- The player's skills may have changed (SKILL_LINES_CHANGED).
    function self.OnSkillChange()
        local skills = env.skills()
        if professions.Changed(skills) then
            log("a skill changed")
            checkTrade(skills)
        end
    end

    -- A craft finished.
    function self.OnCraft()
        log("a craft finished")
        checkTrade(env.skills())
    end

    -- A trainer window opened; trades is the set of professions it teaches.
    function self.OnTrainerShow(trades)
        log("trainer window opened")
        if pinTrade and trades[pinTrade] then clearNav() end
        if lastKind == "trainer" and lastTrade and trades[lastTrade] then
            cancelPrompt()
            lastKind, lastTrade = nil, nil
        end
    end

    -- For /cvn test: ask the usual question for kind, ignoring triggers and combat.
    -- Returns a message when there is nothing to ask about, otherwise nil.
    function self.Test(kind)
        log("test command: " .. kind)
        local v, why = findVendor(kind)
        if why == "nopos" then
            return L["No map position here (dungeons and some areas have none). Try again outside."]
        elseif why == "novendor" then
            if kind == "repair" then return L["No known repair vendor on this continent for your faction."] end
            if kind == "arrow" then return L["No known vendor selling arrows on this continent for your faction."] end
            if kind == "bullet" then return L["No known vendor selling bullets on this continent for your faction."] end
            return L["No known vendor on this continent for your faction."]
        end
        ask(kind, v)
    end

    return self
end
