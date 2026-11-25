package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
loadfile("ClosestVendor/Professions.lua")("ClosestVendor", ns)
local P = ns.Professions

local known = { Mining = true, Herbalism = true, Tailoring = true }
local function names(list) local t = {} for i, p in ipairs(list) do t[i] = p.name .. ":" .. p.remaining end return table.concat(t, ",") end

-- Near the cap, far from it, exactly at the threshold, at the cap.
eq(names(P.Within({ { name = "Mining", rank = 295, max = 300 } }, known, 10)), "", "300 is the last tier: no question")
eq(names(P.Within({ { name = "Mining", rank = 145, max = 150 } }, known, 10)), "Mining:5", "5 from the cap")
eq(names(P.Within({ { name = "Mining", rank = 140, max = 150 } }, known, 10)), "Mining:10", "exactly the threshold")
eq(names(P.Within({ { name = "Mining", rank = 139, max = 150 } }, known, 10)), "", "11 away")
-- Artisan comes after 225: few trainers teach it and the addon cannot tell which, so no question.
eq(names(P.Within({ { name = "Mining", rank = 220, max = 225 } }, known, 10)), "", "Artisan next: not routed")
eq(names(P.Within({ { name = "Mining", rank = 220, max = 225 }, { name = "Herbalism", rank = 148, max = 150 } }, known, 10)), "Herbalism:2", "Expert next still is")
eq(names(P.Within({ { name = "Mining", rank = 75, max = 75 } }, known, 10)), "Mining:0", "at the cap")
eq(names(P.Within({ { name = "Mining", rank = 75, max = 75 } }, known, 0)), "Mining:0", "threshold 0 still asks at the cap")
eq(names(P.Within({ { name = "Mining", rank = 74, max = 75 } }, known, 0)), "", "threshold 0, one short")

-- Final tier: 300 of 300 and anything at or above the last cap.
eq(names(P.Within({ { name = "Mining", rank = 300, max = 300 } }, known, 10)), "", "final tier")
eq(names(P.Within({ { name = "Mining", rank = 375, max = 375 } }, known, 10)), "", "above the last cap")

-- Only known professions; weapon skills and unseen skills are ignored.
eq(names(P.Within({ { name = "Swords", rank = 70, max = 75 } }, known, 10)), "", "unknown skill ignored")
eq(names(P.Within({ { name = "Mining", rank = 70, max = 75 } }, {}, 10)), "", "nothing known")

-- Unreadable or malformed input.
eq(names(P.Within(nil, known, 10)), "", "no skills")
eq(names(P.Within({ { name = "Mining", rank = "x", max = 75 } }, known, 10)), "", "non-numeric rank")
eq(names(P.Within({ { name = "Mining", rank = 10, max = nil } }, known, 10)), "", "missing max")
eq(names(P.Within({ { name = "Mining", rank = 80, max = 75 } }, known, 10)), "", "rank above max is unreadable")

-- Level gate: the trainer refuses the next tier below level 10 / 20 / 35.
local at75, at150, at225 = { { name = "Mining", rank = 75, max = 75 } }, { { name = "Mining", rank = 150, max = 150 } }, { { name = "Mining", rank = 225, max = 225 } }
eq(names(P.Within(at75, known, 10, 9)), "", "75 at level 9: Journeyman not teachable yet")
eq(names(P.Within(at75, known, 10, 10)), "Mining:0", "75 at level 10")
eq(names(P.Within(at150, known, 10, 19)), "", "150 at level 19")
eq(names(P.Within(at150, known, 10, 20)), "Mining:0", "150 at level 20")
eq(names(P.Within(at225, known, 10, 34)), "", "225 at level 34")
eq(names(P.Within(at225, known, 10, 35)), "", "225 at level 35: Artisan is never routed")
eq(names(P.Within(at150, known, 10, nil)), "Mining:0", "unknown level gates nothing")
eq(names(P.Within({ { name = "Mining", rank = 100, max = 100 } }, known, 100, 1)), "Mining:0", "a cap with no listed tier is not gated")
eq(names(P.Within({ { name = "Mining", rank = 0, max = 0 } }, known, 10)), "", "zero cap")

-- Trainer tiers.
eq(tostring(P.NeedTier(75)) .. tostring(P.NeedTier(150)) .. tostring(P.NeedTier(225)) .. tostring(P.NeedTier(300)) .. tostring(P.NeedTier(100)), "234nilnil", "tier to learn from the cap")
eq(P.TitleTier("Journeyman Blacksmith") .. P.TitleTier("Expert Alchemist") .. P.TitleTier("Artisan Tailor") .. P.TitleTier("Master Engineer"), "1234", "title rank: teaches below it")
eq(tostring(P.TitleTier("Master Gnome Engineer")) .. tostring(P.TitleTier("Mining Trainer")) .. tostring(P.TitleTier("Weapon Master")) .. tostring(P.TitleTier(nil)), "nilnilnilnil", "other titles: not known")
eq(tostring(P.Teaches(2, 2)) .. tostring(P.Teaches(1, 2)) .. tostring(P.Teaches(true, 3)) .. tostring(P.Teaches(true, 4)) .. tostring(P.Teaches(4, 4)) .. tostring(P.Teaches(nil, 2)) .. tostring(P.Teaches(true, nil)),
    "truefalsetruefalsetruefalsetrue", "Teaches")
eq(names(P.Within(at225, known, 10, 35, true)), "Mining:0", "tiers known: Artisan is routed")
eq(P.Within(at225, known, 10, 35, true)[1].need, 4, "and needs tier 4")
eq(P.Within(at75, known, 10, 10)[1].need, 2, "75 needs Journeyman")

-- Order: closest to the cap first, ties by name.
local many = { { name = "Tailoring", rank = 70, max = 75 }, { name = "Mining", rank = 73, max = 75 }, { name = "Herbalism", rank = 70, max = 75 } }
eq(names(P.Within(many, known, 10)), "Mining:2,Herbalism:5,Tailoring:5", "ordering")

-- Why a skill near its cap is not asked about, for the debug log.
local function why(list) local t = {} for i, p in ipairs(list) do t[i] = p.name .. " " .. p.rank .. "/" .. p.max .. ": " .. p.why end return table.concat(t, "; ") end
eq(why(P.LeftOut({ { name = "Swords", rank = 70, max = 75 } }, known, 10)), "Swords 70/75: no trainer or crafting window seen", "an unknown skill near its cap: never seen")
eq(why(P.LeftOut({ { name = "Common", rank = 300, max = 300 } }, known, 10)), "", "an unknown skill at the last cap (a language) is not listed")
eq(why(P.LeftOut({ { name = "Mining", rank = 295, max = 300 } }, known, 10)), "Mining 295/300: the last tier", "the last tier")
eq(why(P.LeftOut(at225, known, 10, 40)), "Mining 225/225: Artisan: trainer tiers unknown", "Artisan without trainer tiers")
eq(why(P.LeftOut(at225, known, 10, 40, true)), "", "Artisan with trainer tiers: asked, not left out")
eq(why(P.LeftOut(at150, known, 10, 19)), "Mining 150/150: level 20 needed", "the level gate names the level")
eq(why(P.LeftOut(at150, known, 10, 20)), "", "at level 20: asked, not left out")
eq(why(P.LeftOut({ { name = "Mining", rank = 139, max = 150 }, { name = "Swords", rank = 50, max = 100 } }, known, 10, 10)), "", "far from the cap: not listed")
eq(why(P.LeftOut(nil, known, 10)), "", "unreadable skills: nothing")

-- Change detection.
local c = P.New()
local a = { { name = "Mining", rank = 10 }, { name = "Swords", rank = 5 } }
eq(c.Changed(nil), false, "unreadable first")
eq(c.Changed(a), false, "first read only stores")
eq(c.Changed({ { name = "Mining", rank = 10 }, { name = "Swords", rank = 5 } }), false, "same values")
eq(c.Changed({ { name = "Mining", rank = 11 }, { name = "Swords", rank = 5 } }), true, "a rank rose")
eq(c.Changed({ { name = "Mining", rank = 11 }, { name = "Swords", rank = 5 } }), false, "stored the new rank")
eq(c.Changed({ { name = "Mining", rank = 11 }, { name = "Swords", rank = 5 }, { name = "Herbalism", rank = 1 } }), true, "a new skill appeared")
eq(c.Changed(nil), false, "unreadable keeps the old ranks")
eq(c.Changed({ { name = "Mining", rank = 11 }, { name = "Swords", rank = 5 }, { name = "Herbalism", rank = 1 } }), false, "ranks survived the unreadable read")
eq(c.Changed({ { name = "Mining", rank = 11 }, { name = "Swords", rank = 5 } }), true, "a skill unlearned")
eq(c.Changed({ { name = "Mining", rank = 11 }, { name = "Swords", rank = 5 } }), false, "stored without it")

H.done()
