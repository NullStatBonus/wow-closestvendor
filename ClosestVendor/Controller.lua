-- Ties triggers, search and navigation together. No WoW globals: `env` supplies everything.
--   env.cfg                         live settings table (see Triggers.New)
--   env.freeSlots()                 -> number
--   env.lowestDurability()          -> percent or nil
--   env.inCombat()                  -> boolean
--   env.playerPos()                 -> continentId, x, y (world coords), mapId  or nil (mapId may be nil)
--   env.playerFaction               -> 1 Alliance, 2 Horde, 0 unknown
--   env.buckets                     { [continentId] = { vendor records, see Search.lua } }
--   env.nav                         { Set(vendor) -> handle|nil, Clear(handle), and optional
--                                     ReadGame() -> { map, x, y, tracked }|nil, SetGame(p) (the
--                                     game's own map waypoint, for /cvn demo) }
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
--   env.now()                       optional: seconds (GetTime); a repeated debug line is written again after
--                                      30 of them
--   env.auctionBuckets              optional: { [continentId] = { auctioneer records, same shape as vendors } }
--   env.evaluate()                  optional: Core's check (arms the position retry); used for re-checks
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
            if count == nil then return L["Which %s trainer do you want to navigate to?\n\n%s\n%s"]:format(trade, a, b) end
            if count > 0 then
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
        if count == nil then return L["Navigate to the closest %s trainer, %s?"]:format(trade, who) end
        if count > 0 then
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
    -- The reagents watched at the last Evaluate, "<item id>:<count>" sorted by id and joined by ",",
    -- "none" when none is watched, nil before the first Evaluate; and the counts by item id.
    local watchedText, watchedCount
    local lowSupply = {} -- "food"/"water"/"pet" -> { count, name, bits } for the supplies low at the last Evaluate
    local noticedSupply = {} -- supplies already told about having no known seller
    local SUPPLY = { food = true, water = true, pet = true }
    -- What the ammo or pet food request was placed for: the ammo kind, or the pet's diet key. A change
    -- of weapon or pet with another one asks again (see Evaluate).
    local placedFor = {}
    local promptId = 0
    local log = env.log or function() end
    local professions = ns.Professions.New()
    local questionOpen = env.questionOpen or function() return false end
    local say = env.say or function() end
    local pinVendor -- the record the current waypoint is for, so a demo can put it back
    local demoing = false -- a /cvn demo is running: its notifications show even with On-screen notice off
    -- Lines that can repeat on every craft or target (left out, skipped): each key's last text and when
    -- it was written. The same text again is written only after QUIET seconds or a change of state (a
    -- question shown or declined, a waypoint set or cleared), so a check rerun still sees its line.
    local QUIET = 30
    local said = {}
    local function fresh() said = {} end
    -- sig (default: the text) is what must differ: the left-out line passes its names and reasons
    -- without the ranks, so a skill-up alone writes nothing new.
    local function logChanged(key, text, sig)
        sig = sig or text
        local t = env.now and env.now()
        local s = said[key]
        if s and s.sig == sig and not (t and s.at and t - s.at >= QUIET) then return end
        said[key] = { sig = sig, at = t }
        log(text)
    end

    -- Ends the waypoint. False when the waypoint method raised an error while removing it, nil when it
    -- could not confirm the removal (Nav.Clear), true otherwise (also when there was none).
    local function clearNav()
        local ok = true
        if handle then
            local r = env.nav.Clear(handle)
            if r == false then ok = false elseif r ~= true then ok = nil end
        end
        handle, pinTrade, pinKind, pinId, pinVendor = nil, nil, nil, nil, nil
        fresh()
        return ok
    end

    -- Vendor triggers end a vendor waypoint, never a trainer's. With kind (and the item id for a
    -- reagent), only a waypoint set for that same thing ends: a trigger never removes another's pin.
    -- Without kind (a merchant window) every vendor waypoint ends.
    local function clearVendorNav(kind, id)
        if pinTrade then return end
        if kind and (pinKind ~= kind or pinId ~= id) then return end
        return clearNav()
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
    local function dist(v, i, x, y)
        local dx, dy = v[i] - x, v[i + 1] - y
        return math.sqrt(dx * dx + dy * dy)
    end
    local function yards(v, i, x, y) return math.floor(dist(v, i, x, y) + 0.5) end

    -- The player's position as { continent, x, y, map }, or nil.
    local function here()
        local continent, x, y, map = env.playerPos()
        if continent then return { continent = continent, x = x, y = y, map = map } end
    end

    -- Nearest eligible vendor for kind, or nil plus "nopos" / "novendor". A third value is the nearest
    -- one on the player's map when the overall nearest is on another map, else nil; then x, y. With
    -- at ({ continent, x, y, map }, an anchor) the search starts there instead of at the player.
    -- The Search need for kind (as findVendor takes it).
    local function needFor(kind, reagent, supplyBits)
        if kind == "reagent" then return { reagent = reagent } end
        if kind == "supply" then return { supply = supplyBits } end
        return (kind == "repair" or kind == "arrow" or kind == "bullet") and kind or nil
    end

    local function findVendor(kind, reagent, at, supplyBits)
        at = at or here()
        if not at then return nil, "nopos" end
        local v, onMap = ns.Search.NearestFrom(env.buckets, at, needFor(kind, reagent, supplyBits), env.playerFaction)
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

    -- Two targets for one need, for the debug log: the nearest one on the player's map, the nearest
    -- overall (on another map), and the rule that puts one first (/cvn prefer).
    local function logTwo(v, onMap)
        log(("two targets: on your map %s (npc %s), closest %s (npc %s), %s"):format(onMap[2], tostring(onMap[1]),
            v[2], tostring(v[1]), env.cfg.vendorPrefer ~= "distance" and "prefer map" or "prefer distance"))
    end

    -- Pin without asking and say why, in chat and on screen: the nearest target v, or onMap (the nearest
    -- on the player's map) when there is one and the map is preferred. x, y is where the search started.
    local function autoPin(kind, v, onMap, x, y, trade, name, id)
        local cfg = env.cfg
        local i = kind == "trainer" and 8 or 9
        local pick = (onMap and cfg.vendorPrefer ~= "distance") and onMap or v
        if onMap then logTwo(v, onMap) end
        log(("auto: %s (npc %s)%s"):format(pick[2], tostring(pick[1]), not onMap and ""
            or (pick == onMap and " chosen from two candidates: the one on your map" or " chosen from two candidates: the closest")))
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
    -- Trainer tiers are known (NorgannonDB), so Artisan is routed too, to trainers that teach it.
    local function tiers() return env.trainerTiers and env.trainerTiers() or false end

    -- The trigger a question's kind answers: ammo for arrows and bullets, the supply key for supplies.
    local function triggerOf(kind, id)
        if kind == "arrow" or kind == "bullet" then return "ammo" end
        if kind == "supply" then return id end
        return kind
    end

    local asking -- { kind, id, prompt }: the question a warning asked, while it may still be open
    -- The requests combat, death or an instance held back while that reason lasts, by log line: each
    -- reason and kind is logged once while the reason lasts (a burst of checks, or a check in the same
    -- fight that held nothing), and again once the reason ended or changed. Instance comes first, so
    -- a fight inside a dungeon does not change the reason.
    local HOLD = { instance = "trigger held in an instance: ", dead = "trigger held while dead: ",
        combat = "trigger held in combat: " }
    local REMIND_HOLD = { instance = "reminder held in an instance: ", dead = "reminder held while dead: ",
        combat = "reminder held in combat: " }
    local holdWhy, held = nil, {}
    local ammoSeen -- the ammo kind at the last check, "none" without one, "off" with the warning off: each change is logged once

    -- The request for kind ended without a trip (No, or no vendor): the next need may be asked.
    local function release(kind, id)
        if triggers.Release(triggerOf(kind, id), id) then
            log("request released: " .. kind)
            -- Core's evaluate arms the position retry; plain Evaluate is the fallback.
            if env.after then env.after(0.1, function() (env.evaluate or self.Evaluate)() end) end
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
        if onMap then logTwo(v, onMap) end
        -- Where the target came from and how far it is from the search start, after its npc id.
        local from = ("%s, %d yd"):format(env.sourceOf and env.sourceOf(kind, first[1]) or "shipped", yards(first, i, x, y))
        if trade then
            log(("question shown: trainer for %s, %s (npc %s), %s%s"):format(trade, first[2], tostring(first[1]), from,
                count and (", %d point(s) left"):format(count) or ""))
        elseif name then
            log(("question shown: %s %s, %s (npc %s), %s, %d left"):format(kind == "supply" and "supply" or "reagent", name, first[2], tostring(first[1]), from, count))
        else
            log(("question shown: %s, %s (npc %s), %s"):format(kind, first[2], tostring(first[1]), from))
        end
        fresh()
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
            fresh()
            if declined then declined() end
        end
        local two = second and { other = second, acceptOther = answer(second), mapFirst = mapFirst,
            dist = yards(first, i, x, y), otherDist = yards(second, i, x, y) }
        env.confirm(kind, first, answer(first), count, trade or name, two, decline)
    end

    -- Offer a target: in "auto" mode pin without asking, otherwise ask (see ask for the arguments).
    -- yields: a warning asked this, so No ends that request (a test command's question does not).
    -- test: a /cvn test trainer question, which a zone change does not withdraw.
    local function offer(kind, v, onMap, x, y, count, trade, name, id, yields, test)
        if env.cfg.vendorMode == "auto" then return autoPin(kind, v, onMap, x, y, trade, name, id) end
        ask(kind, v, onMap, x, y, count, trade, name, id, nil, yields and function() release(kind, id) end or nil)
        -- A warning's question, or an automatic trainer question: either ends with the place.
        asking = (yields or (kind == "trainer" and not test)) and { kind = kind, id = id, prompt = promptId } or nil
    end

    -- The professions near their cap now, or nil when the skills cannot be read.
    local function within(skills)
        if type(skills) ~= "table" then return nil end
        return ns.Professions.Within(skills, env.known or {}, env.cfg.tradeThreshold, env.level and env.level(), tiers())
    end
    -- A trainer waypoint ends once its profession is no longer near the cap or is unlearned, also with
    -- profession warnings off (the player may have pinned it from the status window).
    local function dropTrainerPin(near, skills)
        if not pinTrade or type(near) ~= "table" then return end
        for _, p in ipairs(near) do if p.name == pinTrade then return end end
        local learned = false
        for _, s in ipairs(skills) do if s.name == pinTrade then learned = true break end end
        local why = pinTrade .. (learned and " is no longer near its cap" or " was unlearned")
        local ok = clearNav()
        if ok then log("trainer waypoint cleared: " .. why)
        elseif ok == nil then log("trainer waypoint clear not confirmed: " .. why)
        else log("FAILED: trainer waypoint not cleared: " .. why) end
    end
    -- skills: the player's skill list. Asks about the profession nearest its cap that has a
    -- known trainer. Runs on every skill change and craft: there is deliberately no latch.
    local function checkTrade(skills)
        local near = within(skills)
        dropTrainerPin(near, skills)
        -- Each skill near its cap that is not asked about, and why (one line per check).
        if env.cfg.tradeEnabled and type(skills) == "table" then
            local out, sig = {}, {}
            for _, p in ipairs(ns.Professions.LeftOut(skills, env.known or {}, env.cfg.tradeThreshold, env.level and env.level(), tiers())) do
                out[#out + 1] = ("%s %d/%d (%s)"):format(p.name, p.rank, p.max, p.why)
                sig[#sig + 1] = p.name .. "|" .. p.why
            end
            if #out > 0 then logChanged("left out", "profession check: left out: " .. table.concat(out, ", "), table.concat(sig, ";"))
            else said["left out"] = nil end
        end
        if not (env.cfg.tradeEnabled and near) or #near == 0 then return end
        local function skip(line) logChanged("skip", line) end
        if env.inCombat() or dead() then return skip("profession check skipped: in combat or dead") end
        if instance() then return skip("profession check skipped: in an instance") end
        -- Lowest priority: never over an open question, an open or active vendor request, or a trainer trip.
        if pinTrade then return skip("profession check skipped: a " .. pinTrade .. " trainer waypoint is set") end
        if questionOpen() then return skip("profession check skipped: a question is open") end
        local act = triggers.Active()
        if act then return skip("profession check skipped: the " .. act .. " request is open or active") end
        said.skip = nil
        local continent, x, y, map = env.playerPos()
        if not continent then log("profession check: no map position") return end
        for _, p in ipairs(near) do
            local v, onMap = ns.Search.NearestTrainer((env.trainerBuckets or {})[continent] or {}, x, y, p.name, env.playerFaction, map, p.need)
            if v then
                if onMap == v then onMap = nil end
                if p.need then
                    local tier = type(v[7]) == "table" and v[7][p.name]
                    log(("trainer search: %s needs tier %d; nearest %s (npc %s) teaches %s"):format(p.name, p.need, v[2], tostring(v[1]),
                        type(tier) == "number" and ("tier " .. tier) or "an unknown tier"))
                end
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
        for _, d in ipairs(ns.Supplies.DIETS) do if diets and diets[d] then out[#out + 1] = ns.Supplies.DIET_LABEL[d] end end
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
            if key == "pet" then placedFor.pet = s.noticeKey end
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
            if trigger == "ammo" then placedFor.ammo = ammoKind end
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
        -- The ammo warning turned off watches nothing either, whatever the weapon.
        local seen = not ammoKind and "none" or (env.cfg.ammoEnabled and ammoKind or "off")
        if seen ~= ammoSeen then
            ammoSeen = seen
            if seen == "none" then log("ammo not watched: no bow, crossbow or gun equipped, or its ammo cannot be read")
            elseif seen == "off" then log("ammo not watched: the ammo warning is off")
            else log("ammo watched: " .. ammoKind) end
        end
        -- Dead or a ghost is held like combat: the game would hide the question and use it up.
        local fighting, isDead = env.inCombat(), dead()
        local free, dur, combat, inside = env.freeSlots(), env.lowestDurability(), fighting or isDead, instance()
        -- Reagents.Low is the one "is it low" test for reagents; the status window uses it too.
        local items, watched = {}, {}
        local list = env.reagents and env.reagents() -- nil: the class or the spells are unknown
        for _, r in ipairs(list or {}) do
            items[#items + 1] = r.item
            watched[r.item.id] = r
        end
        local ids = {}
        watchedCount = {}
        for id, r in pairs(watched) do ids[#ids + 1] = id; watchedCount[id] = r.count end
        table.sort(ids)
        for i, id in ipairs(ids) do ids[i] = id .. ":" .. tostring(watched[id].count) end
        watchedText = #ids > 0 and table.concat(ids, ",") or "none"
        -- Unknown is not "none": the entry answers nothing until a check can read the reagents.
        if list == nil then watchedText, watchedCount = nil, nil end
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
        -- The ammo or pet food request follows its weapon or pet: another ammo kind or diet ends its
        -- question and waypoint, and the request is asked again below for the new one.
        local act = triggers.Active()
        local cur = (act == "ammo" and ammoKind) or (act == "pet" and state and state.diets and ("pet:" .. dietList(state.diets))) or nil
        if cur and placedFor[act] and placedFor[act] ~= cur then
            log(("%s request restarted: %s -> %s"):format(act, tostring(placedFor[act]), cur))
            if asking and asking.prompt == promptId and triggerOf(asking.kind, asking.id) == act then cancelPrompt() end
            if act == "ammo" then clearVendorNav("ammo") else clearVendorNav("supply", "pet") end
            triggers.Release(act, nil, true)
            placedFor[act], self.pending, self.pendingId = nil, nil, nil
        end
        local a, heldKind, heldId = triggers.Update(free, dur, combat, ammoKind and ammoCount or nil, lowIds, inside ~= nil, supKeys)
        local why = (inside and "instance") or (isDead and "dead") or (fighting and "combat") or nil
        if why ~= holdWhy then holdWhy, held = why, {} end
        if heldKind and why then
            local line = HOLD[why] .. heldKind .. (heldId and (" " .. tostring(heldId)) or "")
            if not held[line] then held[line] = true; log(line) end
        end
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
        local due, heldBack = triggers.Reminders(remindKeys, combat, inside ~= nil)
        for _, key in ipairs(why and heldBack or {}) do
            local line = REMIND_HOLD[why] .. key
            if not held[line] then held[line] = true; log(line) end
        end
        for i, key in ipairs(due) do remind(key, remindCount[key], i > 1) end -- one sound for the batch
    end

    function self.OnMerchantShow()
        log("merchant window opened")
        -- a merchant window answers a vendor question by itself, but not a trainer question
        if lastKind ~= "trainer" then
            local wasOpen = questionOpen()
            cancelPrompt()
            if wasOpen then -- logged once the question is gone, or as a failure when it is still shown
                if questionOpen() then log("FAILED: question still shown after the merchant opened (" .. tostring(lastKind) .. ")")
                else log("question closed: merchant opened (" .. tostring(lastKind) .. ")") end
            end
        end
        if triggers.OnMerchantShow() then self.pending = nil end
        local had, trade = handle, pinTrade
        local ok = clearVendorNav() -- any merchant counts as arriving, including after a test pin
        if trade then log("waypoint kept: it leads to a " .. trade .. " trainer")
        elseif had and ok == false then log("FAILED: waypoint not cleared: a merchant window opened")
        elseif had and ok == nil and not handle then log("waypoint clear not confirmed: a merchant window opened")
        elseif had and not handle then log("waypoint cleared: a merchant window opened") end
    end

    -- The player's skills may have changed (SKILL_LINES_CHANGED).
    function self.OnSkillChange()
        local skills = env.skills()
        if professions.Changed(skills) then
            log("a skill changed")
            checkTrade(skills)
        else
            dropTrainerPin(within(skills), skills) -- also the first read: a pin set before it may be for a skill gone now
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
        if pinTrade and trades[pinTrade] then
            local trade = pinTrade
            local ok = clearNav()
            if ok then log("trainer waypoint cleared: the " .. trade .. " trainer window opened")
            elseif ok == nil then log("trainer waypoint clear not confirmed: the " .. trade .. " trainer window opened")
            else log("FAILED: trainer waypoint not cleared: the " .. trade .. " trainer window opened") end
        end
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
        if not s then return L["Your bags cannot be read right now."], "the bags cannot be read" end
        local key = kind == "petfood" and "pet" or kind
        if key == "water" and not ns.Supplies.UsesMana(s.class) then return L["Your class does not use water."], "the class does not use water" end
        if key == "pet" and not (s.class == "HUNTER" and ns.Supplies.Want("pet", s.diets)) then
            return L["There is no pet to feed."], "no pet to feed"
        end
        local name = supplyName(key, s.diets)
        local v, why, onMap, x, y = findVendor("supply", nil, nil, ns.Supplies.Want(key, s.diets))
        if why == "nopos" then
            return L["No map position here (dungeons and some areas have none). Try again outside."], "no map position here"
        elseif why == "novendor" then
            return noVendorText("supply", name), "no known vendor"
        end
        offer("supply", v, onMap, x, y, s.totals and s.totals[key] or 0, nil, name, key)
    end

    -- /cvn test trainer: the trainer question whatever the skill, tier, threshold or combat. The nearest
    -- trainer of a profession the player knows, else the nearest trainer of any profession (the first
    -- one it teaches by name). Returns a message when there is nothing to ask about.
    local function testTrainer()
        local at = here()
        if not at then return L["No map position here (dungeons and some areas have none). Try again outside."], "no map position here" end
        local bucket = (env.trainerBuckets or {})[at.continent] or {}
        local names, seen = {}, {}
        for _, t in ipairs(bucket) do
            for name in pairs(t[7]) do if not seen[name] then seen[name] = true; names[#names + 1] = name end end
        end
        table.sort(names)
        -- The nearest trainer among the professions in set (a table of names), or nil.
        local function nearest(set)
            local best, bestOnMap, bestTrade, bestD
            for _, name in ipairs(names) do
                if set == nil or set[name] then
                    local v, onMap = ns.Search.NearestTrainer(bucket, at.x, at.y, name, env.playerFaction, at.map)
                    if v then
                        local d = dist(v, 8, at.x, at.y)
                        if not bestD or d < bestD then best, bestOnMap, bestTrade, bestD = v, onMap, name, d end
                    end
                end
            end
            return best, bestOnMap, bestTrade
        end
        local v, onMap, trade = nearest(env.known or {})
        if not v then v, onMap, trade = nearest(nil) end
        if not v then
            return L["No known profession trainer on this continent for your faction. Open a trainer window once and the addon will remember where it is."], "no known trainer"
        end
        if onMap == v then onMap = nil end
        offer("trainer", v, onMap, at.x, at.y, nil, trade, nil, nil, nil, true) -- a test question is not withdrawn by a zone change
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

    -- The test itself: nil when it asked, else the chat message and why, for the debug log.
    local function test(kind)
        if kind == "food" or kind == "water" or kind == "petfood" then return testSupply(kind) end
        if kind == "remind" then return testRemind() end
        if kind == "trainer" then return testTrainer() end
        local r
        if kind == "reagent" then
            r = (env.reagents and env.reagents() or {})[1]
            if not r then
                return L["No class reagent to ask about. Your class has none, or you do not know the spells that use them."], "no class reagent watched"
            end
        end
        local v, why, onMap, x, y = findVendor(kind, r and r.item)
        if why == "nopos" then
            return L["No map position here (dungeons and some areas have none). Try again outside."], "no map position here"
        elseif why == "novendor" then
            return noVendorText(kind, r and r.name), "no known vendor"
        end
        offer(kind, v, onMap, x, y, r and r.count, nil, r and r.name, r and r.item.id)
    end
    -- For /cvn test: ask the usual question for kind, ignoring triggers and combat. Returns a message
    -- when there is nothing to ask about (logged as "test command: nothing asked: <why>"), otherwise nil.
    function self.Test(kind)
        log("test command: " .. kind)
        local problem, why = test(kind)
        if problem then log("test command: nothing asked: " .. tostring(why)) end
        return problem
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

    -- What a direct pin or the seller choice looks for and where it searches from. kind and id as for
    -- direct. Returns a query { kind, id, find, item, name, trade, need, supplyBits, ammoCount, at,
    -- which, inside, ahOk } or nil when there is nothing to route. find is what to search for (the ammo
    -- type for ammo), need a trainer tier, at the search start and which the anchor used ("hearth",
    -- "last" or nil). ahOk: an auctioneer may compete. Unless quiet, chat and the debug log say why
    -- nothing can be routed, and the ammo seen is remembered as Evaluate does; quiet changes and
    -- prints nothing, so the status window can ask on every refresh. A second result, true, means
    -- the row no longer applies (no weapon, pet, item or profession near its cap) and chat said nothing.
    local function resolve(kind, id, quiet, opts)
        local speak = quiet and function() end or say
        local note = quiet and function() end or log
        local function gone(why) note(why) return nil, true end
        local q = { kind = kind, id = id, find = kind }
        if kind == "ammo" then
            local ak, ac = env.ammo()
            if not quiet then ammoKind, ammoCount = ak, ac end
            if not ak then return gone("direct pin: no ranged weapon that uses ammo") end
            q.find, q.ammoCount = ak, ac
        elseif kind == "reagent" then
            local item = ns.Reagents.ById(id)
            -- An item no vendor sells (display-only) cannot be routed to.
            if not item or item.vendor == false then return gone("direct pin: not an item a vendor sells") end
            q.item, q.name = item, item.name
            for _, r in ipairs(env.reagents and env.reagents() or {}) do
                if r.item.id == id then q.name = r.name end
            end
            if opts and opts.name then q.name = opts.name end -- a find: the name the player matched
        elseif kind == "supply" then
            -- id is "food", "water" or "pet"; a pet needs a pet out and a known diet.
            -- opts { bits, name } is a find: the bits of the item looked up, whatever the player carries.
            if opts and opts.bits then
                q.supplyBits, q.name, q.fromFind = opts.bits, opts.name, true
            else
                local s = env.supplies and env.supplies()
                q.supplyBits = s and ns.Supplies.Want(id, s.diets)
                if not q.supplyBits then return gone("direct pin: nothing to look for") end
                q.name = supplyName(id, s.diets)
                if id == "pet" then q.petKey = "pet:" .. dietList(s.diets) end
            end
        elseif kind == "trainer" then
            -- Only while the profession is near its cap: otherwise the next skill check would clear the pin.
            local near = false
            for _, p in ipairs(ns.Professions.Within(env.skills and env.skills(), env.known or {}, env.cfg.tradeThreshold, env.level and env.level(), tiers())) do
                if p.name == id then near, q.need = true, p.need end
            end
            if not near then
                -- Why it is not routed, as the profession check says it (Professions.LeftOut): only Artisan
                -- near its cap without trainer tiers gets the Artisan reason (and chat); any other its own.
                for _, p in ipairs(ns.Professions.LeftOut(env.skills and env.skills(), env.known or {}, env.cfg.tradeThreshold, env.level and env.level(), tiers())) do
                    if p.name == id and p.why == "Artisan: trainer tiers unknown" then
                        note("direct pin: Artisan " .. id .. " is not routed: trainer tiers unknown")
                        speak(L["Artisan %s is taught by only a few trainers, so the addon does not route to one."]:format(id))
                        return nil
                    elseif p.name == id then
                        return gone("direct pin: profession is not routed: " .. p.why)
                    end
                end
                return gone("direct pin: profession is not near its cap")
            end
            q.trade = id
        elseif kind ~= "sell" and kind ~= "repair" then
            return nil
        end

        q.inside = instance()
        local at, which = anchorFor(q.inside)
        if which == "none" then
            speak(L["No target is known yet: the addon has not seen your hearthstone point or a position outside an instance."])
            return nil
        end
        at = at or here()
        if not at then
            speak(L["No map position here (dungeons and some areas have none). Try again outside."])
            return nil
        end
        q.at, q.which = at, which
        -- Only a click, never an automatic trigger, may route to an auctioneer: for something that
        -- is bought (ammo, a reagent) that is not soulbound, with the setting on, outside instances.
        q.ahOk = (env.cfg.ahEnabled and not q.inside and (kind == "ammo" or kind == "reagent")
            and not (q.item and q.item.soulbound)) and true or false
        return q
    end

    -- The search for a query: the nearest target, the nearest on the start's map when that is another
    -- one (else nil), and the nearest auctioneer when one may compete (else nil).
    local function search(q)
        local at = q.at
        if q.trade then
            local v, onMap = ns.Search.NearestTrainer((env.trainerBuckets or {})[at.continent] or {}, at.x, at.y, q.trade, env.playerFaction, at.map, q.need)
            if onMap == v then onMap = nil end
            return v, onMap, nil
        end
        local v, _, onMap = findVendor(q.find, q.item, at, q.supplyBits)
        local ah = q.ahOk and ns.Search.NearestFrom(env.auctionBuckets or {}, at, "auction", env.playerFaction) or nil
        return v, onMap, ah
    end

    -- True when the auctioneer ah is the one to route to instead of the vendor v (which may be nil).
    local function auctionWins(q, v, ah)
        return ah and (not v or dist(ah, 9, q.at.x, q.at.y) < dist(v, 9, q.at.x, q.at.y)) or false
    end

    -- After a click pinned something: the low condition it serves becomes the handled request. When it
    -- serves none (not low, or a trainer), the warning request that was open or active, whose question
    -- or waypoint the click replaced, is asked again at the next check instead of blocking.
    local function handOver(takeKind, takeId, demo, placed)
        if demo then return end
        if takeKind and triggers.Take(takeKind, takeId) then
            if placed then placedFor[takeKind] = placed end
            self.pending, self.pendingId = nil, nil
            return
        end
        local act, actId = triggers.Active()
        if act and triggers.Release(act, actId, true) then
            self.pending, self.pendingId = nil, nil
            log("request put back: " .. act .. " (a click replaced it)")
        end
    end

    -- Pin the auctioneer ah for a query and say so; the warning counts as handled (not in a demo).
    local function pinAuction(q, ah, demo)
        local kind, id = q.kind, q.id
        cancelPrompt()
        lastKind, lastTrade = kind, nil
        pin(ah, nil, kind, q.item and id or nil)
        local where = target(ah, env.zoneName and env.zoneName(ah[3]), yards(ah, 9, q.at.x, q.at.y))
        local text
        if q.name then text = L["Navigating to %s to buy %s at the auction house."]:format(where, q.name)
        else text = L["Navigating to %s to buy ammo at the auction house."]:format(where) end
        say(text)
        notice(text)
        handOver(kind, id, demo, kind == "ammo" and q.find or nil)
        return true
    end

    -- Pin the vendor or trainer v for a query (onMap as for autoPin) and say why and from where; the
    -- warning counts as handled (not in a demo, never for a trainer).
    local function pinTarget(q, v, onMap, demo)
        local kind, id, trade = q.kind, q.id, q.trade
        cancelPrompt() -- a question about something else is answered by this choice
        autoPin(trade and "trainer" or q.find, v, onMap, q.at.x, q.at.y, trade, q.name, (q.item or kind == "supply") and id or nil)
        if q.which == "hearth" then
            log("direct pin: the search started from your hearthstone point")
            say(L["You are in an instance, so the search started from your hearthstone point."])
        elseif q.which == "last" then
            log("direct pin: the search started from your last position outside")
            say(L["You are in an instance, so the search started from your last position outside."])
        end
        -- A low condition is now handled and active, so it ends the usual way and is not asked about.
        local takeKind, takeId = kind, id -- a supply request is kept under its own key
        if kind == "supply" then takeKind, takeId = id, nil end
        -- A find may pick a seller of something else than the warning needs (fish for a pet that eats meat).
        if q.fromFind and kind == "supply" then
            local s = env.supplies and env.supplies()
            local want = s and ns.Supplies.Want(id, s.diets)
            if not (want and ns.Search.Fits(v, { supply = want })) then takeKind, takeId = nil, nil end
        end
        if trade then takeKind = nil end -- a trainer trip takes no warning
        local placed = (kind == "ammo" and q.find) or (kind == "supply" and id == "pet" and q.petKey) or nil
        handOver(takeKind, takeId, demo, placed)
        return true
    end

    -- A direct pin (a click on a status window row): pin the nearest target for kind at once. No
    -- question, whatever vendorMode is, and combat does not hold it back: the player asked for it.
    -- kind is "sell", "repair", "ammo", "reagent" (id: the item id), "supply" (id: food, water or pet) or "trainer" (id: the profession
    -- name). An open question is closed, and a condition that is low counts as handled, as if the
    -- player had answered Yes. Returns true when a target was pinned; otherwise chat says why not
    -- (nothing is said for a row that cannot be routed to).
    local function direct(kind, id, demo)
        log(("direct pin: %s%s"):format(tostring(kind), id and (" " .. tostring(id)) or ""))
        local q = resolve(kind, id)
        if not q then return false end
        local v, onMap, ah = search(q)
        if q.trade then
            if not v then
                say(L["No known trainer for %s on this continent yet. Open a %s trainer window once and the addon will remember where it is."]:format(q.trade, q.trade))
                return false
            end
        else
            if auctionWins(q, v, ah) then
                log(("direct pin: auctioneer %s (npc %s) is closer"):format(ah[2], tostring(ah[1])))
                return pinAuction(q, ah, demo)
            end
            if not v then say(noVendorText(q.find, q.name)) return false end
        end
        return pinTarget(q, v, onMap, demo)
    end

    function self.Go(kind, id) return direct(kind, id) end

    -- The menu title for a kind's other sellers (supply: id is food, water or pet).
    local function choiceTitle(q)
        local kind = q.kind
        if kind == "repair" then return L["Other repair vendors"] end
        if kind == "ammo" then return L["Other ammo vendors"] end
        if kind == "sell" then return L["Other vendors to sell to"] end
        if kind == "reagent" then return L["Other sellers of %s"]:format(q.name) end
        if kind == "trainer" then return L["Other %s trainers"]:format(q.trade) end
        if q.id == "water" then return L["Other water vendors"] end
        if q.id == "pet" then return L["Other pet food vendors"] end
        return L["Other food vendors"]
    end

    -- How many other sellers the choice offers besides the default one.
    local CHOICE_OTHERS = 3

    -- The sellers a status row can route to: nil when the row cannot be routed to, else { title,
    -- entries = { { v = record, label = "Name (Zone, N yards)", default, auction } } }. entries[1] is
    -- what a row click pins (default = true), then up to CHOICE_OTHERS others by straight-line
    -- distance from the search start, one per NPC. Prints and logs nothing.
    function self.Choices(kind, id, opts)
        local q = resolve(kind, id, true, opts)
        if not q then return nil end
        local v, onMap, ah = search(q)
        local at, i = q.at, q.trade and 8 or 9
        local entries, seen = {}, {}
        local function add(r, auction, default)
            seen[r[1]] = true
            local d = yards(r, i, at.x, at.y)
            entries[#entries + 1] = { v = r, label = target(r, env.zoneName and env.zoneName(r[3]), d), d = d,
                default = default, auction = auction }
        end
        local ahFirst = auctionWins(q, v, ah)
        if ahFirst then add(ah, true, true)
        elseif v then add((onMap and env.cfg.vendorPrefer ~= "distance") and onMap or v, false, true)
        else return nil end
        local list
        if q.trade then
            list = ns.Search.SeveralTrainers((env.trainerBuckets or {})[at.continent] or {}, at.x, at.y, q.trade, env.playerFaction, CHOICE_OTHERS + 1, q.need)
        else
            list = ns.Search.Several((env.buckets or {})[at.continent] or {}, at.x, at.y, needFor(q.find, q.item, q.supplyBits),
                env.playerFaction, CHOICE_OTHERS + 1)
        end
        local others = {}
        for _, r in ipairs(list) do others[#others + 1] = { r = r, d = yards(r, i, at.x, at.y), n = #others } end
        if ah and not ahFirst then others[#others + 1] = { r = ah, d = yards(ah, 9, at.x, at.y), n = #others, auction = true } end
        table.sort(others, function(a, b) if a.d ~= b.d then return a.d < b.d end return a.n < b.n end)
        for _, o in ipairs(others) do
            if #entries > CHOICE_OTHERS then break end
            if not seen[o.r[1]] then add(o.r, o.auction or false, false) end
        end
        return { title = choiceTitle(q), entries = entries }
    end

    -- The menu title when a row has another seller to choose, else nil.
    function self.ChoiceTitle(kind, id)
        local c = self.Choices(kind, id)
        if c and #c.entries > 1 then return c.title end
    end

    -- Pin entry (one of Choices(kind, id).entries) as a row click pins its default: waypoint, chat,
    -- notification, and the warning counts as handled. Returns true when pinned.
    function self.Pick(kind, id, entry, opts)
        log(("chosen pin: %s%s, %s"):format(tostring(kind), id and (" " .. tostring(id)) or "", entry and entry.v and tostring(entry.v[2]) or "nothing"))
        if not (entry and entry.v) then return false end
        local q, gone = resolve(kind, id, false, opts)
        if not q then
            -- The row no longer applies (weapon, pet or profession gone since the list opened).
            if gone then say(L["The seller list changed. Open it again to choose."]) end
            return false
        end
        if entry.auction then
            if not q.ahOk then log("chosen pin: an auctioneer is not allowed here now") return false end
            return pinAuction(q, entry.v)
        end
        -- The list was built when the menu opened; the row may want something else now (another weapon).
        local v = entry.v
        local fits
        if q.trade then fits = type(v[7]) == "table" and ns.Professions.Teaches(v[7][q.trade], q.need)
        else fits = ns.Search.Fits(v, needFor(q.find, q.item, q.supplyBits)) end
        if not fits then
            log("chosen pin: the seller no longer fits")
            say(L["The seller list changed. Open it again to choose."])
            return false
        end
        return pinTarget(q, v, nil)
    end

    -- A find (/cvn find, or the Home box) ----------------------------------------------------------

    -- More matching items than this and the player is asked to type more of the name.
    local FIND_MAX = 8

    -- What a supply item's sellers are called: vendors are known by category, not by item.
    local function categoryName(key)
        if key == "food" then return L["food"] end
        if key == "water" then return L["drink"] end
        return L["pet food"]
    end

    -- Run fn after the choice that called it has returned, so a menu opened now is not closed by the
    -- menu that is still handling the click; at once when nothing can wait.
    local function later(fn)
        if not (env.after and env.after(0, fn)) then fn() end
    end

    -- The sellers of one matched item m (an entry of Search.FindItems): say what is known, then open
    -- the seller list at the cursor. Nothing is pinned until the player chooses a seller.
    local function findSellers(m)
        local kind = m.kind == "reagent" and "reagent" or "supply"
        local id = m.kind == "reagent" and m.item.id or m.key
        local opts = m.kind == "supply" and { bits = m.bits, name = categoryName(m.key) } or { name = m.name }
        local q = resolve(kind, id, false, opts)
        if not q then return end
        local c = self.Choices(kind, id, opts)
        if not c then
            log(("find: %s is known, no seller"):format(m.name))
            say(L["%s is a known item, but no known vendor sells it yet for your faction."]:format(m.name))
            return
        end
        c.title = L["Sellers of %s"]:format(m.name)
        if m.kind == "supply" then
            log(("find: %s looked up as %s"):format(m.name, opts.name))
            say(L["Vendors are known by category, not by item, so these sell %s in general and may not stock %s."]:format(opts.name, m.name))
        end
        local items = {}
        for i, e in ipairs(c.entries) do
            items[i] = { text = e.label, checked = e.default, func = function()
                log(("find: chosen %s"):format(tostring(e.v[2])))
                self.StopDemo() -- a running demo's next step would replace the waypoint chosen now
                if not self.Pick(kind, id, e, opts) then log("find: nothing pinned") end
            end }
        end
        if env.menu and env.menu(c.title, items) then
            log(("find: seller list for %s, %d entries"):format(m.name, #c.entries))
            if m.kind == "reagent" then say(L["The sellers of %s are listed. Pick one to set a waypoint."]:format(m.name)) end
        else
            log("find: no menu control")
            -- The default entry follows the map preference; the chat line names the nearest one.
            local nearest = c.entries[1]
            for _, e in ipairs(c.entries) do if e.d < nearest.d then nearest = e end end
            say(L["Nearest known seller of %s: %s."]:format(m.name, nearest.label))
        end
    end

    -- Look up what the player typed: an item link or part of an item name. No match, too many and
    -- no known seller each get their own chat line. One match opens its seller list; two or more
    -- open a menu of the items first. Changes no waypoint and no setting.
    function self.Find(text)
        text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local s = env.supplies and env.supplies()
        local found = ns.Search.FindItems(text, s and s.class, env.itemName)
        log(("find: %q, %d item(s)"):format(text, #found))
        if #found == 0 then
            log("find: no item matches")
            say(L["No supply item matches %s."]:format(text))
        elseif #found > FIND_MAX then
            log("find: too many items match")
            say(L["Too many items match %s. Type more of the name."]:format(text))
        elseif #found == 1 then
            findSellers(found[1])
        else
            local items = {}
            for i, m in ipairs(found) do
                items[i] = { text = m.name, icon = env.itemIcon and env.itemIcon(m.id), func = function() later(function() findSellers(m) end) end }
            end
            if not (env.menu and env.menu(L["Which item?"], items)) then
                log("find: no menu control")
                say(L["Several items match %s. Type more of the name."]:format(text))
            end
        end
    end

    -- The player changed zone or entered an instance: a warning's open question names a vendor
    -- chosen from where they were, so it is withdrawn and the warning is asked again at the next
    -- check outside an instance. Combat withdraws nothing: the player may still answer and route.
    local function withdraw(line)
        local a = asking
        asking = nil
        if not (a and a.prompt == promptId and env.questionOpen and env.questionOpen()) then return end
        log(line)
        cancelPrompt()
        triggers.Release(triggerOf(a.kind, a.id), a.id, true)
    end
    function self.OnPlaceChange() withdraw("question withdrawn: the player changed zone") end
    -- Test settings were switched: the open question was chosen under the other set of settings.
    function self.OnSettingsSwap() withdraw("question withdrawn: test settings switched") end

    -- /cvn demo: a tour of real outcomes through the usual code. Each step searches the real vendor
    -- data, sets a real waypoint or asks a real question, and shows the real notification in the
    -- player's style with the notification sound. Every C.DEMO_STEP seconds the previous step is taken
    -- back and the next one runs. At the end the waypoint the player had before the demo is restored.
    -- Settings are only read, and no warning is marked as handled. done() runs when the tour is over.
    local demoToken, demoHandle, demoPrompt, demoBefore = 0, nil, nil, nil
    -- The game waypoint slot holds p when the map matches and x, y are within 0.001 (as Nav checks).
    local function sameSpot(a, b)
        return a and b and a.map == b.map and math.abs(a.x - b.x) < ns.Nav.SPOT and math.abs(a.y - b.y) < ns.Nav.SPOT
    end
    local demoSpots = {} -- the game waypoints this addon set: its pin from before the demo, and the steps' pins
    local function ours(cur)
        if demoHandle and demoHandle.kind == "native" and sameSpot(cur, demoHandle) then return true end
        for _, h in ipairs(demoSpots) do if sameSpot(cur, h) then return true end end
        return false
    end
    -- The game waypoint slot holds the player's own point (not one this addon set): the one to put back
    -- at the end, so a point the player sets during the tour is the one that comes back.
    local function noteGame()
        local cur = demoBefore and env.nav.ReadGame and env.nav.ReadGame()
        if cur and not ours(cur) then
            if not (demoBefore.game and sameSpot(cur, demoBefore.game)) then log("demo: noted your game waypoint") end
            demoBefore.game = cur
        end
    end
    local function undoStep()
        noteGame()
        if demoHandle and demoHandle.kind == "native" then demoSpots[#demoSpots + 1] = demoHandle end
        if demoHandle and demoHandle == handle then clearNav() end
        if demoPrompt and demoPrompt == promptId then cancelPrompt() end
        demoHandle, demoPrompt = nil, nil
    end
    local function endDemo()
        undoStep()
        demoing = false
        local before = demoBefore
        -- The slot now: empty, one this addon set, or the player's own point (left as it is).
        local cur, unreadable = nil, false
        if env.nav.ReadGame then cur, unreadable = env.nav.ReadGame() end
        local theirs = cur and not ours(cur)
        demoBefore, demoSpots = nil, {}
        if before then lastKind, lastTrade = before.lastKind, before.lastTrade end
        if before and before.v and not handle then
            if before.native and unreadable then
                log("demo: previous waypoint not set again: the game would not tell what is there now")
            elseif before.native and theirs then
                log("demo: previous waypoint not set again: the game waypoint is yours now")
            else
                pin(before.v, before.trade, before.kind, before.id)
                log("demo: previous waypoint restored")
            end
        end
        if before and before.game and unreadable then
            log("demo: your game waypoint not set again: the game would not tell what is there now")
        elseif before and before.game and not theirs and env.nav.SetGame and env.nav.SetGame(before.game) then
            log(before.game.tracked and "demo: your game waypoint restored, tracked"
                or "demo: your game waypoint restored, not tracked")
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
        -- The addon's own game waypoint is put back as pinVendor, never taken for the player's.
        demoBefore.native = handle and handle.kind == "native" or nil
        demoHandle, demoSpots = nil, {}
        if demoBefore.native then demoSpots[1] = handle end
        noteGame()
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
            if not env.after(C.DEMO_STEP, function() run(i + 1) end) then
                endDemo()
                if done then done() end
                return false
            end
            return true
        end
        demoing = true
        return run(1)
    end

    -- What the current waypoint is for: "sell", "repair", "ammo", "reagent" (plus the item id) or
    -- "trainer"; nil when the addon has no waypoint set.
    function self.PinKind() return pinKind, pinId end

    -- The vendor request that is open or active and the item id for a reagent, or nil (Triggers.Active).
    function self.Active() return triggers.Active() end
    -- What the last Evaluate watched (see watchedText), read by the CheckThat reagents entry: no game
    -- read. With an item id, that reagent's count, or nil when it is not watched.
    function self.Reagents(id)
        if id ~= nil then return watchedCount and watchedCount[tonumber(id)] end
        return watchedText
    end

    return self
end
