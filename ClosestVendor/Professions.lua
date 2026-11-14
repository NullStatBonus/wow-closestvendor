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

-- Known professions (set of names) within threshold points of their current cap, with a higher
-- tier still to learn. Nearest the cap first, then by name. Unreadable skills give an empty list.
-- level is the player's level; a skill whose next tier the player is too low to learn is left out
-- (the trainer would refuse). An unknown level (nil) gates nothing.
function P.Within(skills, known, threshold, level)
    local out = {}
    if type(skills) ~= "table" then return out end
    for _, s in ipairs(skills) do
        local rank, max = s.rank, s.max
        if known[s.name] and type(rank) == "number" and type(max) == "number"
                and max > 0 and max < P.LAST_CAP and rank <= max and max - rank <= threshold
                and not (type(level) == "number" and level < (P.TIER_LEVEL[max] or 0)) then
            out[#out + 1] = { name = s.name, remaining = max - rank }
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
