-- Pure profession-cap logic: no WoW globals.
-- A skill is { name = "Mining", rank = 290, max = 300 } (a profession line from the game's skill list).
local _, ns = ...

local P = {}
ns.Professions = P

-- The game does not say whether a higher tier exists; the last tier is taken to end at 300.
P.LAST_CAP = 300

-- The character level the trainer asks for before teaching the tier that follows a cap: 75 -> Journeyman
-- (level 10), 150 -> Expert (20), 225 -> Artisan (35). A cap not listed has no level gate.
P.TIER_LEVEL = { [75] = 10, [150] = 20, [225] = 35 }

-- The cap before the highest tier (Artisan). Few trainers teach Artisan, so the addon routes for it only
-- when it knows which ones do (NorgannonDB's trainer titles); Journeyman and Expert trainers usually
-- stand side by side.
P.NO_ROUTE_CAP = 225

-- Tiers are numbered 1 Apprentice (cap 75), 2 Journeyman (150), 3 Expert (225), 4 Artisan (300).
-- The tier a profession needs next, from its current cap: 75 -> 2 ... 225 -> 4; nil for other caps.
function P.NeedTier(max)
    if max == 75 or max == 150 or max == P.NO_ROUTE_CAP then return max / 75 + 1 end
    return nil
end

-- The highest tier a trainer teaches, from its English title. Before patch 2.3 a trainer teaches only
-- the tiers below its title: "<Journeyman Blacksmith>" teaches Apprentice (1), Expert 2, Artisan 3,
-- "<Master Blacksmith>" teaches Artisan (4). Any other title (a specialization master, "Mining
-- Trainer") gives nil: not known.
P.TITLE_RANK = { Journeyman = 1, Expert = 2, Artisan = 3, Master = 4 }
local TITLE_NOUN = { Alchemist = true, Blacksmith = true, Enchanter = true, Engineer = true, Leatherworker = true, Tailor = true }
function P.TitleTier(title)
    local rank, noun = (type(title) == "string" and title or ""):match("^(%a+) (%a+)$")
    return rank and TITLE_NOUN[noun] and P.TITLE_RANK[rank] or nil
end

-- Whether a trainer teaches tier need. tier is the highest tier it teaches (a number), or true when
-- not known. Not known is trusted for Journeyman and Expert, never for Artisan. need nil: any trainer.
function P.Teaches(tier, need)
    if not tier then return false end
    if not need then return true end
    if type(tier) == "number" then return tier >= need end
    return need < 4
end

-- Known professions (set of names) within threshold points of their current cap, with a higher
-- tier still to learn that the addon routes for (not Artisan, see NO_ROUTE_CAP). Nearest the cap first, then by name. Unreadable skills give an empty list.
-- level is the player's level; a skill whose next tier the player is too low to learn is left out
-- (the trainer would refuse). An unknown level (nil) gates nothing. artisan: trainer tiers are known
-- (NorgannonDB), so Artisan is routed too. Each entry also has need, the tier to learn (NeedTier).
function P.Within(skills, known, threshold, level, artisan)
    local out = {}
    if type(skills) ~= "table" then return out end
    for _, s in ipairs(skills) do
        local rank, max = s.rank, s.max
        if known[s.name] and type(rank) == "number" and type(max) == "number"
                and max > 0 and max < P.LAST_CAP and (artisan or max ~= P.NO_ROUTE_CAP) and rank <= max and max - rank <= threshold
                and not (type(level) == "number" and level < (P.TIER_LEVEL[max] or 0)) then
            out[#out + 1] = { name = s.name, remaining = max - rank, need = P.NeedTier(max) }
        end
    end
    table.sort(out, function(a, b)
        if a.remaining ~= b.remaining then return a.remaining < b.remaining end
        return a.name < b.name
    end)
    return out
end

-- Skill-change detector. Changed(skills) is true when any skill differs from the previous call;
-- the first readable call only stores what is there.
function P.New()
    local ranks, seen = {}, false
    local self = {}

    function self.Changed(skills)
        if type(skills) ~= "table" then return false end
        local now, changed = {}, false
        for _, s in ipairs(skills) do now[s.name] = s.rank end
        if seen then
            for name, rank in pairs(now) do
                if ranks[name] ~= rank then changed = true break end
            end
        end
        ranks, seen = now, true
        return changed
    end

    return self
end
