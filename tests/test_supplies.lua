package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
H.locale(ns)
loadfile("ClosestVendor/Reagents.lua")("ClosestVendor", ns)
loadfile("ClosestVendor/Supplies.lua")("ClosestVendor", ns)
local S = ns.Supplies

-- Item masks: 1 food, 2 drink, 4 Meat, 8 Fish, 16 Bread, 32 Cheese, 64 Fruit, 128 Fungus, 256 healthstone.
local JERKY, BREAD, WATER, CHEESE, WOLF, STONE = 117, 4540, 159, 414, 729, 5509
ns.PetFamilies = { [1] = 4, [2] = 12, [4] = 252, [21] = 200 }
ns.SupplyItems = { [JERKY] = 1 + 4, [BREAD] = 1 + 16, [WATER] = 2, [CHEESE] = 1 + 32, [WOLF] = 4, [STONE] = 256 }

local function knowing(...)
    local set = {}
    for _, id in ipairs({ ... }) do set[id] = true end
    return function(id) return set[id] == true end
end
local CFG = { foodEnabled = true, waterEnabled = true, petFoodEnabled = true, healthstoneRemind = true,
              foodThreshold = 5, waterThreshold = 5, petFoodThreshold = 5 }
local function cfg(over) local c = {} for k, v in pairs(CFG) do c[k] = v end for k, v in pairs(over or {}) do c[k] = v end return c end
local function keys(list) local t = {} for i, e in ipairs(list) do t[i] = e.key end return table.concat(t, ",") end

-- Masks and bits.
eq(S.ItemMask(JERKY), 5, "item mask")
eq(S.ItemMask(99999), 0, "not a supply")
eq(S.Or(5, 18), 23, "or")
eq(S.VendorMask({ [BREAD] = true, [JERKY] = true, [STONE] = true }), 21, "vendor mask ORs items and drops the healthstone bit")
eq(S.VendorMask({ [99999] = true }), 0, "unknown items add nothing")
eq(S.Sells(21, S.FOOD), true, "sells food")
eq(S.Sells(21, S.WATER), false, "does not sell water")
eq(S.DietBits(S.FamilyDiets(2)), 12, "Cat eats Meat and Fish")
eq(S.FamilyDiets(21).Fungus, true, "Turtle eats Fungus")
eq(S.FamilyDiets(10), nil, "a family that eats nothing")
eq(S.FamilyDiets(nil), nil, "no id")
eq(S.Sells(16, S.DietBits({ Bread = true, Cheese = true })), true, "any of several diets")
eq(S.Sells(16, 32), false, "cheese not sold")
eq(S.DietBits({ Bread = true, Cheese = true, Nonsense = true }), 48, "unknown diet ignored")
eq(S.Want("pet", nil), nil, "no diet, nothing to ask for")
eq(S.Want("pet", { Meat = true }), 4, "pet wants its diet")
eq(S.Want("food"), 1, "food bit")

-- Totals: mixed food counted, drink not counted as food, an item counts once toward the pet total.
local t = S.Totals({ [JERKY] = 3, [BREAD] = 2, [WATER] = 4, [STONE] = 1, [99999] = 50 }, { Meat = true, Bread = true })
eq(t.food, 5, "food count")
eq(t.water, 4, "water count")
eq(t.healthstone, 1, "healthstone count")
eq(t.pet, 5, "pet count: jerky (meat) + bread, each once")
eq(S.Totals({}, nil).pet, nil, "no diet: pet total is nil")
eq(S.Totals(nil, { Meat = true }), nil, "unreadable bags")
eq(S.Totals({ [CHEESE] = 2 }, { Cheese = true, Bread = true }).pet, 2, "cheese eater")

-- Evaluate: classes and gates.
local function ev(class, counts, diets, knows, c) return S.Evaluate(class, S.Totals(counts, diets), knows or knowing(), c or cfg()) end
eq(keys(ev("WARRIOR", {}, nil).go), "food", "warrior: food only")
eq(keys(ev("ROGUE", {}, nil).go), "food", "rogue: no water")
eq(keys(ev("PRIEST", {}, nil).go), "food,water", "priest: food then water")
eq(keys(ev("HUNTER", {}, { Meat = true }).go), "food,water,pet", "hunter with a pet: food, water, pet")
eq(keys(ev("HUNTER", {}, nil).go), "food,water", "hunter without a pet: no pet food")
eq(keys(ev("MAGE", { [JERKY] = 6 }, { Meat = true }).go), "water", "pet food is only for hunters")
eq(keys(ev("PRIEST", { [JERKY] = 6, [WATER] = 6 }, nil).go), "", "above threshold")
eq(keys(ev("PRIEST", { [JERKY] = 5, [WATER] = 5 }, nil).go), "food,water", "at threshold is low")
eq(#S.Evaluate("PRIEST", nil, knowing(), cfg()).go, 0, "unreadable bags: never low")
eq(keys(ev("PRIEST", {}, nil, nil, cfg({ waterEnabled = false })).go), "food", "water switch")
eq(keys(ev("PRIEST", {}, nil, nil, cfg({ foodEnabled = false })).go), "water", "food switch")
eq(keys(ev("PRIEST", { [JERKY] = 8 }, nil, nil, cfg({ foodThreshold = 10 })).go), "food,water", "own thresholds")
eq(keys(ev("HUNTER", { [WOLF] = 5 }, { Meat = true }, nil, cfg({ petFoodThreshold = 4 })).go), "food,water", "pet threshold")

-- Mage reminders: the conjure spell turns a trip into a reminder, kind by kind.
local r = ev("MAGE", {}, nil, knowing(587, 5504))
eq(keys(r.go), "", "mage who can conjure both is not sent")
eq(keys(r.remind), "food,water", "mage is reminded to conjure both")
r = ev("MAGE", {}, nil, knowing(587))
eq(keys(r.remind), "food", "knows Conjure Food only")
eq(keys(r.go), "water", "water goes to a vendor")
r = ev("MAGE", {}, nil, knowing())
eq(keys(r.go), "food,water", "low-level mage is sent")
eq(keys(r.remind), "", "no reminder without the spell")
eq(keys(ev("PRIEST", {}, nil, knowing(587)).remind), "", "only mages are reminded to conjure")

-- Warlock healthstone reminder.
eq(keys(ev("WARLOCK", {}, nil, knowing(6201)).remind), "healthstone", "no healthstone")
eq(keys(ev("WARLOCK", { [STONE] = 1 }, nil, knowing(6201)).remind), "", "has one")
eq(keys(ev("WARLOCK", {}, nil, knowing()).remind), "", "spell not known")
eq(keys(ev("WARLOCK", {}, nil, knowing(6201), cfg({ healthstoneRemind = false })).remind), "", "switched off")
eq(keys(ev("MAGE", {}, nil, knowing(6201)).remind), "", "not a warlock")
eq(#S.Evaluate("WARLOCK", nil, knowing(6201), cfg()).remind, 0, "unreadable bags")

-- Reminder sounds: stable keys, game ids, the default, and lookup by key or label.
do
    local keys = {}
    for _, s in ipairs(S.SOUNDS) do keys[#keys + 1] = s[1] end
    eq(table.concat(keys, ","), "whisper,ping,invite,ready,none", "the choices, whisper first")
    eq(S.DEFAULT_SOUND, "whisper", "default is the whisper ping")
    eq(S.SoundId("whisper"), 3081, "whisper ping id")
    eq(S.SoundId("ping") .. "/" .. S.SoundId("invite") .. "/" .. S.SoundId("ready"), "3175/880/8960", "other ids")
    eq(S.SoundId("none"), nil, "none is silent")
    eq(S.SoundId("banana"), 3081, "an unknown saved key gets the default")
    eq(S.SoundId(nil), 3081, "nothing saved gets the default")
    eq(S.FindSound("Ping") .. S.FindSound("  group INVITE ") .. S.FindSound("ready"), "pinginviteready", "key or label, case and spaces ignored")
    eq(S.FindSound("minimap ping"), "ping", "label")
    eq(S.FindSound("banana"), nil, "not a choice")
    eq(S.FindSound(""), nil, "empty")
end

H.done()
