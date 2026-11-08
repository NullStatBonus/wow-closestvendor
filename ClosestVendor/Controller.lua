-- Ties triggers, search and navigation together. No WoW globals: `env` supplies everything.
--   env.cfg                         live settings table (see Triggers.New)
--   env.freeSlots()                 -> number
--   env.lowestDurability()          -> percent or nil
--   env.inCombat()                  -> boolean
--   env.playerPos()                 -> continentId, x, y (world coords), mapId  or nil (mapId may be nil)
--   env.playerFaction               -> 1 Alliance, 2 Horde, 0 unknown
--   env.buckets                     { [continentId] = { vendor records, see Search.lua } }
--   env.nav                         { Set(vendor) -> handle|nil, Clear(handle) }
--   env.ammo()                      -> "arrow"|"bullet", count  for the equipped ranged weapon, or nil
--   env.confirm(kind, vendor, accept, count, trade, two)  ask the player; call accept() only on Yes
--       kind is "sell", "repair", "arrow", "bullet" or "trainer"; count is the ammo left, or for a
--       trainer the points left to the cap; trade names the profession. two (optional) is a second
--       choice { other = record, acceptOther = fn, dist, otherDist (yards), mapFirst = bool }: vendor
--       is the first button, other the second; mapFirst says whether vendor is the one on the player's map
--   env.cancelConfirm()             close the question if it is showing
--   env.questionOpen()              optional: true while a question is showing
--   env.skills()                    -> list of { name, rank, max } for the player's skills, or nil
--   env.known                       set of profession names the addon has seen (live table)
--   env.trainerBuckets              { [continentId] = { trainer records, see Search.NearestTrainer } }
--   env.say(text)                   optional: print a line to chat
--   env.notify(text)                optional: show text on screen, silently (used by "auto" pins)
--   env.zoneName(mapId)             optional: the name of a map, or nil
--   env.log(text)                   optional: record a decision in the debug log
local _, ns = ...

local L = ns.L

local C = {}
ns.Controller = C

-- One target for the two-target question: name, zone (may be nil) and distance in yards.
local function target(v, zone, dist)
    if zone then return L["%s (%s, %d yards)"]:format(v[2], zone, dist) end
    return L["%s (%d yards)"]:format(v[2], dist)
end

-- Dialog text for a found vendor or trainer; kind is "sell", "repair", "arrow", "bullet" or
-- "trainer"; zone and count may be nil. For a trainer, count is the points left and trade the profession.
-- two (see env.confirm) with otherZone gives the text that offers both targets.
function C.PromptText(kind, vendor, zone, count, trade, two, otherZone)
    local who = vendor[2] .. (zone and (" (" .. zone .. ")") or "")
    if two then
        local a, b = target(vendor, zone, two.dist), target(two.other, otherZone, two.otherDist)
        if kind == "trainer" then
            if count and count > 0 then
                return L["Your %s skill is %d point(s) from its current limit.\n\nWhich %s trainer do you want to navigate to?\n\n%s\n%s"]:format(trade, count, trade, a, b)
            end
            return L["Your %s skill has reached its current limit.\n\nWhich %s trainer do you want to navigate to?\n\n%s\n%s"]:format(trade, trade, a, b)
        elseif kind == "arrow" then
            if count then
                return L["You are low on arrows (%d left).\n\nWhich vendor that sells arrows do you want to navigate to?\n\n%s\n%s"]:format(count, a, b)
            end
            return L["You are low on arrows.\n\nWhich vendor that sells arrows do you want to navigate to?\n\n%s\n%s"]:format(a, b)
        elseif kind == "bullet" then
            if count then
                return L["You are low on bullets (%d left).\n\nWhich vendor that sells bullets do you want to navigate to?\n\n%s\n%s"]:format(count, a, b)
            end
            return L["You are low on bullets.\n\nWhich vendor that sells bullets do you want to navigate to?\n\n%s\n%s"]:format(a, b)
        elseif kind == "repair" then
            return L["Your gear needs repair.\n\nWhich repair vendor do you want to navigate to?\n\n%s\n%s"]:format(a, b)
        end
        return L["Your bags are almost full.\n\nWhich vendor do you want to navigate to?\n\n%s\n%s"]:format(a, b)
    end
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

    -- Straight-line distance in whole yards from the player to a record (world x,y at index i, i+1).
    local function yards(v, i, x, y)
        local dx, dy = v[i] - x, v[i + 1] - y
        return math.floor(math.sqrt(dx * dx + dy * dy) + 0.5)
    end

    -- Nearest eligible vendor for kind, or nil plus "nopos" / "novendor". A third value is the nearest
    -- one on the player's map when the overall nearest is on another map, else nil; then x, y.
    local function findVendor(kind)
        local continent, x, y, map = env.playerPos()
        if not continent then return nil, "nopos" end
        local need = (kind == "repair" or kind == "arrow" or kind == "bullet") and kind or nil
        local v, onMap = ns.Search.Nearest(env.buckets[continent] or {}, x, y, need, env.playerFaction, map)
        if not v then return nil, "novendor" end
        if onMap == v then onMap = nil end
        return v, nil, onMap, x, y
    end

    -- Take a chosen target: the usual accept path for vendors and trainers.
    local function pin(v, trade)
        clearNav()
        handle = env.nav.Set(v)
        if trade and handle then pinTrade = trade end
        log(("accepted: %s via %s"):format(v[2], handle and handle.kind or "nothing available"))
    end

    -- Offer the nearest target v (and, when v is on another map, the nearest on the player's map).
    -- In "auto" mode pin without asking; otherwise ask, navigating only on a choice. trade is set for
    -- trainers, count is the ammo left or the points left to the cap.
    local function offer(kind, v, onMap, x, y, count, trade)
        local cfg = env.cfg
        local mapFirst = cfg.vendorPrefer ~= "distance"
        local i = kind == "trainer" and 8 or 9
        if cfg.vendorMode == "auto" then
            local pick = (onMap and mapFirst) and onMap or v
            log(("auto: %s (npc %s)%s"):format(pick[2], tostring(pick[1]), onMap and " chosen from two candidates" or ""))
            lastKind, lastTrade = kind, trade
            pin(pick, trade)
            local function describe(t) return target(t, env.zoneName and env.zoneName(t[3]), yards(t, i, x, y)) end
            local text
            if onMap then
                text = L["Navigating to %s. The other choice was %s."]:format(describe(pick), describe(pick == v and onMap or v))
            else
                text = L["Navigating to %s."]:format(describe(pick))
            end
            say(text)
            if env.notify and cfg.autoNotice ~= false then env.notify(text) end
            return
        end
        promptId = promptId + 1
        local mine = promptId
        lastKind, lastTrade = kind, trade
        local first, second = v, nil
        if onMap and mapFirst then first, second = onMap, v elseif onMap then second = onMap end
        if trade then
            log(("question shown: trainer for %s, %s (npc %s), %d point(s) left"):format(trade, first[2], tostring(first[1]), count))
        else
            log(("question shown: %s, %s (npc %s)"):format(kind, first[2], tostring(first[1])))
        end
        local function answer(t)
            return function()
                if mine ~= promptId then log("answer ignored: the question was withdrawn") return end
                pin(t, trade)
            end
        end
        local two = second and { other = second, acceptOther = answer(second), mapFirst = mapFirst,
            dist = yards(first, i, x, y), otherDist = yards(second, i, x, y) }
        env.confirm(kind, first, answer(first), count, trade, two)
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
        local continent, x, y, map = env.playerPos()
        if not continent then log("profession check: no map position") return end
        for _, p in ipairs(within) do
            local v, onMap = ns.Search.NearestTrainer((env.trainerBuckets or {})[continent] or {}, x, y, p.name, env.playerFaction, map)
            if v then
                if onMap == v then onMap = nil end
                return offer("trainer", v, onMap, x, y, p.remaining, p.name)
            end
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
        local v, why, onMap, x, y = findVendor(kind)
        if why == "nopos" then
            self.pending = trigger -- no map position yet (loading, instance); retry later
            log("no map position yet: " .. trigger .. " request kept for a retry")
        elseif v then
            self.pending = nil
            offer(kind, v, onMap, x, y, trigger == "ammo" and ammoCount or nil)
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
        local v, why, onMap, x, y = findVendor(kind)
        if why == "nopos" then
            return L["No map position here (dungeons and some areas have none). Try again outside."]
        elseif why == "novendor" then
            if kind == "repair" then return L["No known repair vendor on this continent for your faction."] end
            if kind == "arrow" then return L["No known vendor selling arrows on this continent for your faction."] end
            if kind == "bullet" then return L["No known vendor selling bullets on this continent for your faction."] end
            return L["No known vendor on this continent for your faction."]
        end
        offer(kind, v, onMap, x, y)
    end

    return self
end
