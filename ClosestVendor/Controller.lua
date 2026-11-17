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
--   env.reagents()                  -> list of { item, count, name } for the class reagents being watched
--                                      (spell known, not switched off, count readable), or nil; name is
--                                      what the question calls the reagent
--   env.supplies()                  -> { class, totals, knows, diets } or nil: the player's class token, the
--                                      bag totals (Supplies.Totals, nil when bags are unreadable), knows(spellId)
--                                      and the active pet's diet set (nil without a pet); see Supplies.Evaluate
--   env.confirm(kind, vendor, accept, count, trade, two)  ask the player; call accept() only on Yes
--       kind is "sell", "repair", "arrow", "bullet", "reagent", "supply" or "trainer"; count is the ammo or
--       reagent left, or for a trainer the points left to the cap; trade names the profession (or,
--       for a reagent, the reagent). two (optional) is a second
--       choice { other = record, acceptOther = fn, dist, otherDist (yards), mapFirst = bool }: vendor
--       is the first button, other the second; mapFirst says whether vendor is the one on the player's map
--   env.cancelConfirm()             close the question if it is showing
--   env.questionOpen()              optional: true while a question is showing
--   env.skills()                    -> list of { name, rank, max } for the player's skills, or nil
--   env.known                       set of profession names the addon has seen (live table)
--   env.trainerBuckets              { [continentId] = { trainer records, see Search.NearestTrainer } }
--   env.say(text)                   optional: print a line to chat
--   env.notify(text)                optional: show text on screen as a Toast or Warning (the player's style)
--   env.playSound(key)              optional: play the notification sound saved as key ("none" plays nothing)
--   env.zoneName(mapId)             optional: the name of a map, or nil
--   env.log(text)                   optional: record a decision in the debug log
--   env.auctionBuckets              optional: { [continentId] = { auctioneer records, same shape as vendors } }
--   env.instanceType()              optional: "none", "party", "raid" or "pvp"; nil (unknown) counts as "none"
--   env.anchor(which)               optional: { continent, x, y, map } (world x,y) for "hearth" (the
--                                      hearthstone point) or "last" (the last position outside an
--                                      instance), or nil when that one is not known
local _, ns = ...

local L = ns.L

local C = {}
ns.Controller = C

-- One target for the two-target question: name, zone (may be nil) and distance in yards.
local function target(v, zone, dist)
    if zone then return L["%s (%s, %d yards)"]:format(v[2], zone, dist) end
    return L["%s (%d yards)"]:format(v[2], dist)
end

-- Dialog text for a found vendor or trainer; kind is "sell", "repair", "arrow", "bullet", "reagent"
-- or "trainer"; zone and count may be nil. For a trainer, count is the points left and trade the
-- profession; for a reagent, count is how many are left and trade the reagent's name.
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
        elseif kind == "reagent" or kind == "supply" then
            return L["You are low on %s (%d left).\n\nWhich vendor that sells %s do you want to navigate to?\n\n%s\n%s"]:format(trade, count, trade, a, b)
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
    elseif kind == "reagent" or kind == "supply" then
        return L["You are low on %s (%d left).\n\nNavigate to the closest vendor that sells %s, %s?"]:format(trade, count, trade, who)
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


-- Seconds /cvn demo shows each of its steps.
C.DEMO_STEP = 5

function C.New(env)
    local triggers = ns.Triggers.New(env.cfg)
    local self = { pending = nil } -- "sell"/"repair"/"ammo" waiting for a position
    local ammoKind, ammoCount -- from the last Evaluate
    local handle
    local pinTrade -- profession of the active trainer waypoint, if the waypoint is a trainer's
    local pinKind, pinId -- what the waypoint is for: "sell"/"repair"/"ammo"/"reagent" (+ item id)/"trainer"
    local lastKind, lastTrade -- what the most recent question was about
    local noticed = {} -- professions already told about having no known trainer
    local noticedReagent = {} -- reagents already told about having no known seller
    local lowReagents = {} -- item id -> { item, count, name } for the reagents low at the last Evaluate
    local lowSupply = {} -- "food"/"water"/"pet" -> { count, name, bits } for the supplies low at the last Evaluate
    local noticedSupply = {} -- supplies already told about having no known seller
    local SUPPLY = { food = true, water = true, pet = true }
    local promptId = 0
    local log = env.log or function() end
    local professions = ns.Professions.New()
    local questionOpen = env.questionOpen or function() return false end
    local say = env.say or function() end
    local pinVendor -- the record the current waypoint is for, so a demo can put it back
    local demoing = false -- a /cvn demo is running: its notifications show even with On-screen notice off
    local function clearNav()
        if handle then env.nav.Clear(handle) end
        handle, pinTrade, pinKind, pinId, pinVendor = nil, nil, nil, nil, nil
    end

    -- Vendor triggers end a vendor waypoint, never a trainer's. With kind (and the item id for a
    -- reagent), only a waypoint set for that same thing ends: a trigger never removes another's pin.
    -- Without kind (a merchant window) every vendor waypoint ends.
    local function clearVendorNav(kind, id)
        if pinTrade then return end
        if kind and (pinKind ~= kind or pinId ~= id) then return end
        clearNav()
    end

    -- "party", "raid" or "pvp" while the player is in an instance, else nil (unknown is the open world).
    local function instance()
        local kind = env.instanceType and env.instanceType()
        if kind and kind ~= "none" then return kind end
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

    -- The player's position as { continent, x, y, map }, or nil.
    local function here()
        local continent, x, y, map = env.playerPos()
        if continent then return { continent = continent, x = x, y = y, map = map } end
    end

    -- Nearest eligible vendor for kind, or nil plus "nopos" / "novendor". A third value is the nearest
    -- one on the player's map when the overall nearest is on another map, else nil; then x, y. With
    -- at ({ continent, x, y, map }, an anchor) the search starts there instead of at the player.
    local function findVendor(kind, reagent, at, supplyBits)
        at = at or here()
        if not at then return nil, "nopos" end
        local need = (kind == "repair" or kind == "arrow" or kind == "bullet") and kind or nil
        if kind == "reagent" then need = { reagent = reagent } end
        if kind == "supply" then need = { supply = supplyBits } end
        local v, onMap = ns.Search.NearestFrom(env.buckets, at, need, env.playerFaction)
        if not v then return nil, "novendor" end
        if onMap == v then onMap = nil end
        return v, nil, onMap, at.x, at.y
    end

    -- Take a chosen target: the usual accept path for vendors and trainers. kind and id (a reagent's
    -- item id) are remembered as what the waypoint is for.
    local function pin(v, trade, kind, id)
        clearNav()
        handle = env.nav.Set(v)
        if handle then
            pinTrade = trade
            pinKind = (kind == "arrow" or kind == "bullet") and "ammo" or kind
            pinId = id
            pinVendor = v
        end
        log(("accepted: %s via %s"):format(v[2], handle and handle.kind or "nothing available"))
    end

    -- Every on-screen notification: shown in the player's style with the notification sound. Nothing
    -- is shown or played while On-screen notice is off. quiet skips the sound (later notices of a batch).
    local function notice(text, quiet)
        if (env.cfg.autoNotice == false and not demoing) or not env.notify then return end
        env.notify(text)
        if not quiet and env.playSound then env.playSound(env.cfg.remindSound) end
    end

    -- Pin without asking and say why, in chat and on screen: the nearest target v, or onMap (the nearest
    -- on the player's map) when there is one and the map is preferred. x, y is where the search started.
    local function autoPin(kind, v, onMap, x, y, trade, name, id)
        local cfg = env.cfg
        local i = kind == "trainer" and 8 or 9
        local pick = (onMap and cfg.vendorPrefer ~= "distance") and onMap or v
        log(("auto: %s (npc %s)%s"):format(pick[2], tostring(pick[1]), onMap and " chosen from two candidates" or ""))
        lastKind, lastTrade = kind, trade
        pin(pick, trade, kind, id)
        local function describe(t) return target(t, env.zoneName and env.zoneName(t[3]), yards(t, i, x, y)) end
        local text
        local why
        if trade then why = L["to train %s"]:format(trade)
        elseif name then why = L["to buy %s"]:format(name)
        elseif kind == "arrow" or kind == "bullet" then why = L["to buy ammo"]
        elseif kind == "repair" then why = L["to repair your gear"]
        elseif kind == "sell" then why = L["to sell items and free bag space"] end
        if why and onMap then
            text = L["Navigating to %s %s. The other choice was %s."]:format(describe(pick), why, describe(pick == v and onMap or v))
        elseif why then
            text = L["Navigating to %s %s."]:format(describe(pick), why)
        elseif onMap then
            text = L["Navigating to %s. The other choice was %s."]:format(describe(pick), describe(pick == v and onMap or v))
        else
            text = L["Navigating to %s."]:format(describe(pick))
        end
        say(text)
        notice(text)
    end

    local function dead() return env.dead and env.dead() or false end

    -- The trigger a question's kind answers: ammo for arrows and bullets, the supply key for supplies.
    local function triggerOf(kind, id)
        if kind == "arrow" or kind == "bullet" then return "ammo" end
        if kind == "supply" then return id end
        return kind
    end

    -- The request for kind ended without a trip (No, or no vendor): the next need may be asked.
    local function release(kind, id)
        if triggers.Release(triggerOf(kind, id), id) then
            log("request released: " .. kind)
            if env.after then env.after(0.1, function() self.Evaluate() end) end
        end
    end

    -- Ask about the nearest target v (and, when v is on another map, the nearest on the player's
    -- map), navigating only on a choice. trade is set for trainers, count is the ammo or reagent left
    -- or the points left to the cap. name is the reagent's name and id its item id for a reagent.
    -- pinned (optional) is called after an answer set the waypoint; declined (optional) after No.
    local function ask(kind, v, onMap, x, y, count, trade, name, id, pinned, declined)
        local cfg = env.cfg
        local mapFirst = cfg.vendorPrefer ~= "distance"
        local i = kind == "trainer" and 8 or 9
        promptId = promptId + 1
        local mine = promptId
        lastKind, lastTrade = kind, trade
        local first, second = v, nil
        if onMap and mapFirst then first, second = onMap, v elseif onMap then second = onMap end
        if trade then
            log(("question shown: trainer for %s, %s (npc %s), %d point(s) left"):format(trade, first[2], tostring(first[1]), count))
        elseif name then
            log(("question shown: %s %s, %s (npc %s), %d left"):format(kind == "supply" and "supply" or "reagent", name, first[2], tostring(first[1]), count))
        else
            log(("question shown: %s, %s (npc %s)"):format(kind, first[2], tostring(first[1])))
        end
        local function answer(t)
            return function()
                if mine ~= promptId then log("answer ignored: the question was withdrawn") return end
                pin(t, trade, kind, id)
                if pinned then pinned() end
            end
        end
        local function decline()
            if mine ~= promptId then return end
            log("question declined: " .. kind)
            if declined then declined() end
        end
        local two = second and { other = second, acceptOther = answer(second), mapFirst = mapFirst,
            dist = yards(first, i, x, y), otherDist = yards(second, i, x, y) }
        env.confirm(kind, first, answer(first), count, trade or name, two, decline)
    end

    -- Offer a target: in "auto" mode pin without asking, otherwise ask (see ask for the arguments).
    -- yields: a warning asked this, so No ends that request (a test command's question does not).
    local function offer(kind, v, onMap, x, y, count, trade, name, id, yields)
        if env.cfg.vendorMode == "auto" then return autoPin(kind, v, onMap, x, y, trade, name, id) end
        ask(kind, v, onMap, x, y, count, trade, name, id, nil, yields and function() release(kind, id) end or nil)
    end

    -- skills: the player's skill list. Asks about the profession nearest its cap that has a
    -- known trainer. Runs on every skill change and craft: there is deliberately no latch.
    local function checkTrade(skills)
        if not env.cfg.tradeEnabled then return end
        local within = ns.Professions.Within(skills, env.known or {}, env.cfg.tradeThreshold, env.level and env.level())
        -- A trainer waypoint ends once its profession is no longer near the cap.
        if pinTrade then
            local still = false
            for _, p in ipairs(within) do if p.name == pinTrade then still = true end end
            if not still then log("trainer waypoint cleared: " .. pinTrade .. " is no longer near its cap") clearNav() end
        end
        if #within == 0 then return end
        if env.inCombat() or dead() then log("profession check skipped: in combat or dead") return end
        if instance() then log("profession check skipped: in an instance") return end
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

    -- "Meat, Fish" for a pet's diet set, in the table's order.
    local function dietList(diets)
        local out = {}
        for _, d in ipairs(ns.Supplies.DIETS) do if diets and diets[d] then out[#out + 1] = d end end
        return table.concat(out, ", ")
    end

    -- What a supply is called in a question: "food", "water" or "pet food (Meat, Fish)".
    local function supplyName(key, diets)
        if key == "food" then return L["food"] end
        if key == "water" then return L["water"] end
        return L["pet food (%s)"]:format(dietList(diets))
    end

    -- The one line (chat and on-screen) of a notice-only reminder; key is "food", "water" or "healthstone".
    local function reminderText(key, count)
        if key == "food" then return L["You are low on food (%d left). Cast Conjure Food to make more."]:format(count) end
        if key == "water" then return L["You are low on water (%d left). Cast Conjure Water to make more."]:format(count) end
        return L["You have no healthstone. Cast Create Healthstone to make one."]
    end

    local function remind(key, count, quiet)
        local text = reminderText(key, count)
        log("reminder: " .. key .. " (" .. tostring(count) .. ")")
        say(text)
        notice(text, quiet)
    end

    -- A supply request: key is "food", "water" or "pet" (the pet's diets are in lowSupply[key].bits).
    -- Mirrors place() for a reagent: ask or pin the nearest seller, or say once that none is known.
    local function placeSupply(key)
        local s = lowSupply[key]
        if not s then self.pending, self.pendingId = nil, nil return end
        local v, why, onMap, x, y = findVendor("supply", nil, nil, s.bits)
        if why == "nopos" then
            self.pending, self.pendingId = key, nil
            log("no map position yet: " .. key .. " request kept for a retry")
        elseif v then
            self.pending, self.pendingId = nil, nil
            offer("supply", v, onMap, x, y, s.count, nil, s.name, key, true)
        else
            self.pending, self.pendingId = nil, nil
            log("no known vendor for " .. key .. " on this continent")
            release("supply", key)
            if not noticedSupply[s.noticeKey] then
                noticedSupply[s.noticeKey] = true
                if key == "pet" then
                    say(L["No known vendor sells food your pet eats on this continent yet. Open a vendor that sells it once and the addon will remember it."])
                else
                    say(L["No known vendor sells %s on this continent yet. Open a vendor that sells it once and the addon will remember it."]:format(s.name))
                end
            end
        end
    end

    -- trigger is "sell", "repair", "ammo", "reagent", "food", "water" or "pet"; ammo resolves to arrows or
    -- bullets from the weapon, reagent needs the item id.
    local function place(trigger, id)
        if SUPPLY[trigger] then return placeSupply(trigger) end
        -- ammo resolves to arrows or bullets from the weapon seen by the last Evaluate
        local kind = trigger == "ammo" and ammoKind or trigger
        local r = trigger == "reagent" and lowReagents[id] or nil
        if trigger == "reagent" and not r then self.pending, self.pendingId = nil, nil return end
        local v, why, onMap, x, y = findVendor(kind, r and r.item)
        if why == "nopos" then
            self.pending, self.pendingId = trigger, id -- no map position yet (loading, instance); retry later
            log("no map position yet: " .. trigger .. " request kept for a retry")
        elseif v then
            self.pending, self.pendingId = nil, nil
            offer(kind, v, onMap, x, y, trigger == "ammo" and ammoCount or (r and r.count) or nil, nil, r and r.name, id, true)
        else
            self.pending, self.pendingId = nil, nil
            log("no known vendor for " .. kind .. " on this continent")
            release(kind, id)
            if r and not noticedReagent[id] then
                noticedReagent[id] = true
                say(L["No known vendor sells %s on this continent yet. Open a vendor that sells it once and the addon will remember it."]:format(r.name))
            end
        end
    end

    function self.Evaluate()
        ammoKind, ammoCount = env.ammo()
        -- Dead or a ghost is held like combat: the game would hide the question and use it up.
        local free, dur, combat, inside = env.freeSlots(), env.lowestDurability(), env.inCombat() or dead(), instance()
        -- Reagents.Low is the one "is it low" test for reagents; the status window uses it too.
        local items, watched = {}, {}
        for _, r in ipairs(env.reagents and env.reagents() or {}) do
            items[#items + 1] = r.item
            watched[r.item.id] = r
        end
        lowReagents = {}
        local lowIds = {}
        for _, low in ipairs(ns.Reagents.Low(items, function(id) return watched[id].count end, env.cfg.reagentThreshold)) do
            lowReagents[low.item.id] = watched[low.item.id]
            lowIds[#lowIds + 1] = low.item.id
        end
        -- Supplies.Evaluate is the one "is it low" test for food, water and pet food, and for the reminders.
        lowSupply = {}
        local supKeys, remindKeys, remindCount = {}, {}, {}
        -- Reading the bags costs a scan of every slot, so only when something supply-related can fire.
        local c = env.cfg
        local watching = c.suppliesEnabled and (c.foodEnabled or c.waterEnabled or c.petFoodEnabled or c.healthstoneRemind)
        local state = watching and env.supplies and env.supplies()
        if state then
            local ev = ns.Supplies.Evaluate(state.class, state.totals, state.knows, env.cfg)
            for _, e in ipairs(ev.go) do
                local bits = ns.Supplies.Want(e.key, state.diets)
                if bits then
                    lowSupply[e.key] = { count = e.count, name = supplyName(e.key, state.diets), bits = bits,
                        noticeKey = e.key == "pet" and ("pet:" .. dietList(state.diets)) or e.key }
                    supKeys[#supKeys + 1] = e.key
                end
            end
            for _, e in ipairs(ev.remind) do
                remindKeys[#remindKeys + 1] = e.key
                remindCount[e.key] = e.count
            end
        end
        local a = triggers.Update(free, dur, combat, ammoKind and ammoCount or nil, lowIds, inside ~= nil, supKeys)
        if a then
            log(("trigger %s%s%s (bags=%s durability=%s ammo=%s combat=%s)"):format(a[1], a[2] and (" " .. a[2]) or "",
                a[3] and (" " .. a[3]) or "",
                tostring(free), dur and ("%.0f%%"):format(dur) or "n/a",
                ammoKind and (ammoKind .. ":" .. tostring(ammoCount)) or "n/a", tostring(combat)))
            if a[1] == "clear" then
                self.pending = nil
                cancelPrompt()
                if SUPPLY[a[2]] then clearVendorNav("supply", a[2]) else clearVendorNav(a[2], a[3]) end -- only the waypoint of the request that ended
            else
                place(a[2], a[3])
            end
        elseif self.pending and not combat and not inside then
            log("retrying the " .. self.pending .. " request")
            place(self.pending, self.pendingId)
        end
        local due = triggers.Reminders(remindKeys, combat, inside ~= nil)
        for i, key in ipairs(due) do remind(key, remindCount[key], i > 1) end -- one sound for the batch
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

    local function noVendorText(kind, name)
        if kind == "reagent" or kind == "supply" then return L["No known vendor selling %s on this continent for your faction."]:format(name) end
        if kind == "repair" then return L["No known repair vendor on this continent for your faction."] end
        if kind == "arrow" then return L["No known vendor selling arrows on this continent for your faction."] end
        if kind == "bullet" then return L["No known vendor selling bullets on this continent for your faction."] end
        return L["No known vendor on this continent for your faction."]
    end

    -- /cvn test food, water or petfood: the usual supply question whatever the count. Returns a message
    -- when there is nothing to ask about.
    local function testSupply(kind)
        local s = env.supplies and env.supplies()
        if not s then return L["Your bags cannot be read right now."] end
        local key = kind == "petfood" and "pet" or kind
        if key == "water" and not ns.Supplies.UsesMana(s.class) then return L["Your class does not use water."] end
        if key == "pet" and not (s.class == "HUNTER" and ns.Supplies.Want("pet", s.diets)) then
            return L["There is no pet to feed."]
        end
        local name = supplyName(key, s.diets)
        local v, why, onMap, x, y = findVendor("supply", nil, nil, ns.Supplies.Want(key, s.diets))
        if why == "nopos" then
            return L["No map position here (dungeons and some areas have none). Try again outside."]
        elseif why == "novendor" then
            return noVendorText("supply", name)
        end
        offer("supply", v, onMap, x, y, s.totals and s.totals[key] or 0, nil, name, key)
    end

    -- /cvn test remind: always shows a reminder and plays the sound, whatever the class, count, settings,
    -- combat or bags. A mage and a warlock get their own; any other class gets a plain test line.
    local function testRemind()
        local s = env.supplies and env.supplies()
        local class = s and s.class
        if class == "MAGE" then remind("food", s.totals and s.totals.food or 0)
        elseif class == "WARLOCK" then remind("healthstone", 0)
        else
            local text = L["This is a test reminder. Only mages and warlocks get real ones."]
            log("reminder: test")
            say(text)
            notice(text)
        end
    end

    -- For /cvn test: ask the usual question for kind, ignoring triggers and combat.
    -- Returns a message when there is nothing to ask about, otherwise nil.
    function self.Test(kind)
        log("test command: " .. kind)
        if kind == "food" or kind == "water" or kind == "petfood" then return testSupply(kind) end
        if kind == "remind" then return testRemind() end
        local r
        if kind == "reagent" then
            r = (env.reagents and env.reagents() or {})[1]
            if not r then
                return L["No class reagent to ask about. Your class has none, or you do not know the spells that use them."]
            end
        end
        local v, why, onMap, x, y = findVendor(kind, r and r.item)
        if why == "nopos" then
            return L["No map position here (dungeons and some areas have none). Try again outside."]
        elseif why == "novendor" then
            return noVendorText(kind, r and r.name)
        end
        offer(kind, v, onMap, x, y, r and r.count, nil, r and r.name, r and r.item.id)
    end

    -- Where a direct pin searches from: nil in the open world (the player's position). In an instance,
    -- the anchor { continent, x, y, map } and which one it is ("hearth" or "last"), or nil and "none"
    -- when neither is known. A battleground starts from the last position outside; a dungeon or raid
    -- from the instanceAnchor setting; either falls back to the other anchor.
    local function anchorFor(inside)
        if not inside then return nil end
        local first = (inside == "pvp" or env.cfg.instanceAnchor == "last") and "last" or "hearth"
        local second = first == "last" and "hearth" or "last"
        for _, which in ipairs({ first, second }) do
            local at = env.anchor and env.anchor(which)
            if at then return at, which end
        end
        return nil, "none"
    end

    -- A direct pin (a click on a status window row): pin the nearest target for kind at once. No
    -- question, whatever vendorMode is, and combat does not hold it back: the player asked for it.
    -- kind is "sell", "repair", "ammo", "reagent" (id: the item id), "supply" (id: food, water or pet) or "trainer" (id: the profession
    -- name). An open question is closed, and a condition that is low counts as handled, as if the
    -- player had answered Yes. Returns true when a target was pinned; otherwise chat says why not
    -- (nothing is said for a row that cannot be routed to).
    local function direct(kind, id, demo)
        log(("direct pin: %s%s"):format(tostring(kind), id and (" " .. tostring(id)) or ""))
        local find, name, trade, supplyBits = kind, nil, nil, nil -- find: what to search for
        local item
        if kind == "ammo" then
            ammoKind, ammoCount = env.ammo()
            if not ammoKind then log("direct pin: no ranged weapon that uses ammo") return false end
            find = ammoKind
        elseif kind == "reagent" then
            item = ns.Reagents.ById(id)
            -- An item no vendor sells (display-only) cannot be routed to.
            if not item or item.vendor == false then log("direct pin: not an item a vendor sells") return false end
            name = item.name
            for _, r in ipairs(env.reagents and env.reagents() or {}) do
                if r.item.id == id then name = r.name end
            end
        elseif kind == "supply" then
            -- id is "food", "water" or "pet"; a pet needs a pet out and a known diet.
            local s = env.supplies and env.supplies()
            supplyBits = s and ns.Supplies.Want(id, s.diets)
            if not supplyBits then log("direct pin: nothing to look for") return false end
            name = supplyName(id, s.diets)
        elseif kind == "trainer" then
            -- Only while the profession is near its cap: otherwise the next skill check would clear the pin.
            local near = false
            for _, p in ipairs(ns.Professions.Within(env.skills and env.skills(), env.known or {}, env.cfg.tradeThreshold, env.level and env.level())) do
                if p.name == id then near = true end
            end
            if not near then log("direct pin: profession is not near its cap") return false end
            trade = id
        elseif kind ~= "sell" and kind ~= "repair" then
            return false
        end

        local inside = instance()
        local at, which = anchorFor(inside)
        if which == "none" then
            say(L["No target is known yet: the addon has not seen your hearthstone point or a position outside an instance."])
            return false
        end
        at = at or here()
        if not at then
            say(L["No map position here (dungeons and some areas have none). Try again outside."])
            return false
        end

        local v, onMap
        if trade then
            v, onMap = ns.Search.NearestTrainer((env.trainerBuckets or {})[at.continent] or {}, at.x, at.y, trade, env.playerFaction, at.map)
            if not v then
                say(L["No known trainer for %s on this continent yet. Open a %s trainer window once and the addon will remember where it is."]:format(trade, trade))
                return false
            end
            if onMap == v then onMap = nil end
        else
            local _
            v, _, onMap = findVendor(find, item, at, supplyBits)
            -- Only a click, never an automatic trigger, may route to an auctioneer: for something that
            -- is bought (ammo, a reagent) that is not soulbound, with the setting on, outside instances.
            local ah
            if env.cfg.ahEnabled and not inside and (kind == "ammo" or kind == "reagent") and not (item and item.soulbound) then
                ah = ns.Search.NearestFrom(env.auctionBuckets or {}, at, "auction", env.playerFaction)
            end
            if ah and (not v or yards(ah, 9, at.x, at.y) < yards(v, 9, at.x, at.y)) then
                cancelPrompt()
                log(("direct pin: auctioneer %s (npc %s) is closer"):format(ah[2], tostring(ah[1])))
                lastKind, lastTrade = kind, nil
                pin(ah, nil, kind, item and id or nil)
                local where = target(ah, env.zoneName and env.zoneName(ah[3]), yards(ah, 9, at.x, at.y))
                local text
                if name then text = L["Navigating to %s to buy %s at the auction house."]:format(where, name)
                else text = L["Navigating to %s to buy ammo at the auction house."]:format(where) end
                say(text)
                notice(text)
                if not demo and triggers.Take(kind, id) then self.pending, self.pendingId = nil, nil end
                return true
            end
            if not v then say(noVendorText(find, name)) return false end
        end

        cancelPrompt() -- a question about something else is answered by this choice
        autoPin(trade and "trainer" or find, v, onMap, at.x, at.y, trade, name, (item or kind == "supply") and id or nil)
        if which == "hearth" then
            say(L["You are in an instance, so the search started from your hearthstone point."])
        elseif which == "last" then
            say(L["You are in an instance, so the search started from your last position outside."])
        end
        -- A low condition is now handled and active, so it ends the usual way and is not asked about.
        local takeKind, takeId = kind, id -- a supply request is kept under its own key
        if kind == "supply" then takeKind, takeId = id, nil end
        if not demo and not trade and triggers.Take(takeKind, takeId) then self.pending, self.pendingId = nil, nil end
        return true
    end

    function self.Go(kind, id) return direct(kind, id) end

    -- /cvn demo: a tour of real outcomes through the usual code. Each step searches the real vendor
    -- data, sets a real waypoint or asks a real question, and shows the real notification in the
    -- player's style with the notification sound. Every C.DEMO_STEP seconds the previous step is taken
    -- back and the next one runs. At the end the waypoint the player had before the demo is restored.
    -- Settings are only read, and no warning is marked as handled. done() runs when the tour is over.
    local demoToken, demoHandle, demoPrompt, demoBefore = 0, nil, nil, nil
    local function undoStep()
        if demoHandle and demoHandle == handle then clearNav() end
        if demoPrompt and demoPrompt == promptId then cancelPrompt() end
        demoHandle, demoPrompt = nil, nil
    end
    local function endDemo()
        undoStep()
        demoing = false
        local before = demoBefore
        demoBefore = nil
        if before then lastKind, lastTrade = before.lastKind, before.lastTrade end
        if before and before.v and not handle then
            pin(before.v, before.trade, before.kind, before.id)
            log("demo: previous waypoint restored")
        end
    end
    -- Pin without asking (way "auto") or ask (way "ask") for kind; key is the supply key for "supply".
    local function demoRoute(way, kind, key)
        local name, bits
        if kind == "supply" then
            local s = env.supplies and env.supplies()
            local diets = s and s.diets
            if key == "pet" and not diets then diets = { [ns.Supplies.DIETS[1]] = true } end
            name, bits = supplyName(key, diets), ns.Supplies.Want(key, diets)
        end
        log(("demo: %s, %s"):format(way == "auto" and "pin without asking" or "question", key or kind))
        local v, why, onMap, x, y = findVendor(kind, nil, nil, bits)
        if why == "nopos" then say(L["No map position here (dungeons and some areas have none). Try again outside."]) return end
        if why == "novendor" then say(noVendorText(kind, name)) return end
        if way == "auto" then
            autoPin(kind, v, onMap, x, y, nil, name, key)
            demoHandle = handle
        else
            demoPrompt = promptId + 1 -- the id ask gives this question
            ask(kind, v, onMap, x, y, kind == "supply" and 2 or nil, nil, name, key, function() demoHandle, demoPrompt = handle, nil end)
        end
    end
    -- The tour for this character's class: notifications, questions, every vendor type, a row click
    -- and a reminder.
    local function demoSteps()
        local s = env.supplies and env.supplies()
        local class = s and s.class
        local steps = {
            function() demoRoute("auto", "sell") end,
            function() demoRoute("ask", "repair") end,
            function() demoRoute("auto", "supply", "food") end,
        }
        if class == "HUNTER" then steps[#steps + 1] = function() demoRoute("ask", "supply", "pet") end
        elseif class and ns.Supplies.UsesMana(class) then steps[#steps + 1] = function() demoRoute("ask", "supply", "water") end end
        steps[#steps + 1] = function() demoRoute("auto", "arrow") end
        steps[#steps + 1] = function()
            -- A row click: the class's first watched reagent (a closer auction house may win), else repair.
            local r = (env.reagents and env.reagents() or {})[1]
            log("demo: row click, " .. (r and "reagent" or "repair"))
            local ok
            if r then ok = direct("reagent", r.item.id, true) else ok = direct("repair", nil, true) end
            if ok then demoHandle = handle end
        end
        steps[#steps + 1] = function() log("demo: reminder"); testRemind() end
        return steps
    end
    -- Stop a running demo now: its waypoint and question go and the previous waypoint comes back.
    function self.StopDemo()
        if not demoing then return end
        demoToken = demoToken + 1 -- its next step timer does nothing
        log("demo: stopped")
        endDemo()
    end
    function self.Demo(done)
        if not env.after then return false end
        if demoing then endDemo() end -- a running demo is taken back first, its own waypoint put back
        demoBefore = { v = pinVendor, trade = pinTrade, kind = pinKind, id = pinId, lastKind = lastKind, lastTrade = lastTrade }
        demoToken = demoToken + 1
        local mine = demoToken
        local steps = demoSteps()
        local function run(i)
            if mine ~= demoToken then return end -- a newer demo is running
            undoStep()
            if i > #steps then
                log("demo: over")
                endDemo()
                if done then done() end
                return
            end
            steps[i]()
            if not env.after(C.DEMO_STEP, function() run(i + 1) end) then endDemo(); return false end
            return true
        end
        demoing = true
        return run(1)
    end

    -- What the current waypoint is for: "sell", "repair", "ammo", "reagent" (plus the item id) or
    -- "trainer"; nil when the addon has no waypoint set.
    function self.PinKind() return pinKind, pinId end

    return self
end
