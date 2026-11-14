local ns = {}
loadfile("ClosestVendor/Triggers.lua")("ClosestVendor", ns)
local T = ns.Triggers

package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq
-- A clear also names what ended (a[2], a[3]); those are checked where they matter.
local function act(a) return a and ((a[2] and a[1] ~= "clear") and (a[1] .. ":" .. a[2]) or a[1]) or "nil" end
local function cfg() return { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, bagEnabled = true, durEnabled = true, ammoEnabled = true, suppliesEnabled = true, reagentsEnabled = true } end

-- FreeSlots: sums general bags only, skips quivers/special bags.
local fam = { [0] = { 3, 0 }, [1] = { 4, 0 }, [2] = { 10, 1 }, [3] = { nil, nil } }
local function getFree(b) local r = fam[b]; if r then return r[1], r[2] end end
eq(T.FreeSlots(getFree, 0, 3), 7, "free slots ignore special bag and missing bag")

-- Unknown is not zero: with no readable bag the count is nil; with some, only those count.
eq(T.FreeSlots(function() return nil end, 0, 4), nil, "no bag readable: unknown")
eq(T.FreeSlots(function(b) if b == 1 then return 5, 0 end end, 0, 4), 5, "one readable bag counts")
eq(T.FreeSlots(function() return 0, 1 end, 0, 2), 0, "only special bags readable: 0 free, not unknown")
eq(T.FreeSlots(function() return 2, 0 end, 0, 3), 8, "all bags readable")

-- LowestDurability: lowest %, items without durability ignored.
local dur = { [1] = { 90, 100 }, [2] = { 15, 100 }, [3] = { nil, nil }, [4] = { 0, 0 }, [5] = { 50, 100 } }
local function getDur(s) local r = dur[s]; if r then return r[1], r[2] end end
eq(T.LowestDurability(getDur, { 1, 2, 3, 4, 5 }), 15, "mixed items lowest")
eq(T.LowestDurability(getDur, { 3, 4 }), nil, "no durable items")

-- An unknown bag count never requests a sale, and does not hide the other triggers.
t = T.New(cfg())
eq(act(t.Update(nil, nil, false, nil)), "nil", "unknown bags: nothing")
eq(act(t.Update(nil, 5, false, nil)), "go:repair", "unknown bags: repair still works")
t = T.New(cfg())
eq(act(t.Update(nil, nil, false, 10)), "go:ammo", "unknown bags: ammo still works")
t = T.New(cfg())
eq(act(t.Update(1, nil, false, nil)), "go:sell", "known bags: sells")
eq(act(t.Update(nil, nil, false, nil)), "nil", "bags turn unknown: the request is neither withdrawn nor repeated")
eq(act(t.Update(1, nil, false, nil)), "nil", "bags known and still full: not asked again")
eq(act(t.Update(10, nil, false, nil)), "clear", "bags known and freed: withdrawn")

-- Unknown data does not reset the latch: after a vendor visit, a failing read must not cause a re-ask.
t = T.New(cfg())
eq(act(t.Update(1, nil, false, nil)), "go:sell", "asked once")
eq(act(t.OnMerchantShow()), "clear", "merchant visit")
eq(act(t.Update(nil, nil, false, nil)), "nil", "bag read fails")
eq(act(t.Update(1, nil, false, nil)), "nil", "read works again, still full: not asked again")

-- Bag threshold boundary (default 2).
local t = T.New(cfg())
eq(act(t.Update(3, nil, false)), "nil", "3 free: above threshold")
eq(act(t.Update(2, nil, false)), "go:sell", "2 free: triggers")
eq(act(t.Update(1, nil, false)), "nil", "no repeat while condition holds")
eq(act(t.Update(2, nil, false)), "nil", "no repeat after small change")
eq(act(t.Update(5, nil, false)), "clear", "condition clears")
eq(act(t.Update(2, nil, false)), "go:sell", "recurs after clearing")

-- Durability boundary: strictly below 20.
t = T.New(cfg())
eq(act(t.Update(10, 20, false)), "nil", "20% is not below 20%")
eq(act(t.Update(10, 19.9, false)), "go:repair", "19.9% triggers")

-- Repair beats sell when both newly active; sell is then handled.
t = T.New(cfg())
eq(act(t.Update(1, 10, false)), "go:repair", "both -> repair")
eq(act(t.Update(1, 10, false)), "nil", "sell not requested separately")

-- Combat defers, then fires if still true.
t = T.New(cfg())
eq(act(t.Update(1, nil, true)), "nil", "no start in combat")
eq(act(t.Update(1, nil, false)), "go:sell", "starts after combat")
t = T.New(cfg())
eq(act(t.Update(1, nil, true)), "nil", "deferred")
eq(act(t.Update(9, nil, false)), "nil", "cleared during combat: nothing fires")

-- Merchant clears navigation, does not re-request while condition holds.
t = T.New(cfg())
t.Update(1, nil, false)
eq(act(t.OnMerchantShow()), "clear", "merchant clears")
eq(act(t.OnMerchantShow()), "nil", "merchant with nothing active")
eq(act(t.Update(1, nil, false)), "nil", "no re-request after dismissal")

-- Selling at the vendor resolves the condition.
t = T.New(cfg())
t.Update(1, nil, false)
eq(act(t.Update(20, nil, false)), "clear", "sold items clears waypoint")

-- Custom threshold and independent disable.
local c = cfg(); c.bagThreshold = 5
t = T.New(c)
eq(act(t.Update(5, nil, false)), "go:sell", "custom threshold 5")
c = cfg(); c.bagEnabled = false
t = T.New(c)
eq(act(t.Update(0, nil, false)), "nil", "bag trigger disabled")
eq(act(t.Update(0, 5, false)), "go:repair", "durability still works")

-- Weapon -> ammo kind.
eq(T.AmmoNeeded(2, 2), "arrow", "bow")
eq(T.AmmoNeeded(2, 18), "arrow", "crossbow")
eq(T.AmmoNeeded(2, 3), "bullet", "gun")
eq(T.AmmoNeeded(2, 16), nil, "thrown not monitored")
eq(T.AmmoNeeded(2, 19), nil, "wand not monitored")
eq(T.AmmoNeeded(2, 7), nil, "sword not monitored")
eq(T.AmmoNeeded(4, 2), nil, "armor is not a weapon")
eq(T.AmmoNeeded(nil, nil), nil, "nothing equipped")

-- Ammo count: right kind counts, wrong kind or empty slot is 0.
eq(T.AmmoCount("arrow", 6, 2, 150), 150, "arrows with a bow")
eq(T.AmmoCount("bullet", 6, 3, 90), 90, "bullets with a gun")
eq(T.AmmoCount("bullet", 6, 2, 500), 0, "arrows with a gun count 0")
eq(T.AmmoCount("arrow", nil, nil, nil), 0, "empty ammo slot counts 0")
eq(T.AmmoCount("arrow", 4, 2, 500), 0, "a non-ammo item in the slot counts 0")
eq(T.AmmoCount(nil, 6, 2, 500), 0, "no ranged weapon")

-- Ammo trigger: at or below 200 (default), not above; nil means not monitored.
t = T.New(cfg())
eq(act(t.Update(10, nil, false, 201)), "nil", "201 ammo: above threshold")
eq(act(t.Update(10, nil, false, 200)), "go:ammo", "200 ammo: triggers")
eq(act(t.Update(10, nil, false, 150)), "nil", "no repeat while low")
eq(act(t.Update(10, nil, false, 900)), "clear", "restocked clears")
eq(act(t.Update(10, nil, false, 100)), "go:ammo", "recurs after restocking")
t = T.New(cfg())
eq(act(t.Update(10, nil, false, nil)), "nil", "no ranged weapon: nothing")
eq(act(t.Update(10, nil, false, 0)), "go:ammo", "zero ammo triggers")

-- Ammo trigger obeys its own switch and threshold and combat.
c = cfg(); c.ammoEnabled = false
t = T.New(c)
eq(act(t.Update(10, nil, false, 0)), "nil", "ammo trigger disabled")
c = cfg(); c.ammoThreshold = 50
t = T.New(c)
eq(act(t.Update(10, nil, false, 51)), "nil", "custom threshold: above")
eq(act(t.Update(10, nil, false, 50)), "go:ammo", "custom threshold: at")
t = T.New(cfg())
eq(act(t.Update(10, nil, true, 10)), "nil", "deferred in combat")
eq(act(t.Update(10, nil, false, 10)), "go:ammo", "fires after combat")

-- Priority: repair > ammo > sell. An ammo trip covers selling.
t = T.New(cfg())
eq(act(t.Update(1, nil, false, 10)), "go:ammo", "ammo beats sell")
eq(act(t.Update(1, nil, false, 10)), "nil", "sell is covered by the ammo trip")
t = T.New(cfg())
eq(act(t.Update(10, 10, false, 10)), "go:repair", "repair beats ammo")
eq(act(t.Update(10, 10, false, 10)), "nil", "ammo waits while repair is active")
eq(act(t.Update(10, 100, false, 10)), "clear", "repaired: repair clears")
eq(act(t.Update(10, 100, false, 10)), "go:ammo", "then ammo is asked")

-- The ammo trip covered selling: once ammo is restocked, a still-full bag does not ask again.
t = T.New(cfg())
eq(act(t.Update(1, nil, false, 10)), "go:ammo", "ammo asked while bags are also full")
eq(act(t.Update(1, nil, false, 900)), "clear", "ammo restocked")
eq(act(t.Update(1, nil, false, 900)), "nil", "bags still full but covered by the ammo trip")
-- ...but a sell condition that appears during the trip is asked afterwards.
t = T.New(cfg())
eq(act(t.Update(10, nil, false, 10)), "go:ammo", "ammo asked first")
eq(act(t.Update(1, nil, false, 10)), "nil", "sell held back during the ammo trip")
eq(act(t.Update(1, nil, false, 900)), "clear", "ammo restocked")
eq(act(t.Update(1, nil, false, 900)), "go:sell", "the sell question comes after")

-- A lower priority never replaces an open or active higher one.
t = T.New(cfg())
eq(act(t.Update(10, 10, false, nil)), "go:repair", "repair active")
eq(act(t.Update(1, 10, false, nil)), "nil", "sell does not replace repair")
eq(act(t.Update(1, 10, false, 5)), "nil", "ammo does not replace repair")
-- A higher one replaces a lower one.
t = T.New(cfg())
eq(act(t.Update(1, nil, false, nil)), "go:sell", "sell active")
eq(act(t.Update(1, nil, false, 10)), "go:ammo", "ammo replaces sell")
eq(act(t.Update(1, 10, false, 10)), "go:repair", "repair replaces ammo")

-- Merchant clears an active ammo request without re-asking.
t = T.New(cfg())
t.Update(10, nil, false, 10)
eq(act(t.OnMerchantShow()), "clear", "merchant clears ammo")
eq(act(t.Update(10, nil, false, 10)), "nil", "not re-asked while still low")

-- Active() names the open or active vendor request.
t = T.New(cfg())
eq(t.Active(), nil, "nothing active at first")
t.Update(1, nil, false, nil)
eq(t.Active(), "sell", "sell request active")
t.Update(10, nil, false, nil)
eq(t.Active(), nil, "cleared with the condition")
t.Update(1, nil, false, nil)
t.OnMerchantShow()
eq(t.Active(), nil, "cleared by a merchant")

-- Reagents: one request per low item, in the order given, and never while ammo or repair is open.
local function ract(a) return a and ((a[2] and a[1] ~= "clear") and (a[1] .. ":" .. a[2] .. (a[3] and (":" .. a[3]) or "")) or a[1]) or "nil" end
t = T.New(cfg())
eq(ract(t.Update(10, nil, false, nil, nil)), "nil", "no reagents: nothing")
eq(ract(t.Update(10, nil, false, nil, {})), "nil", "empty list: nothing")
eq(ract(t.Update(10, nil, false, nil, { 17020 })), "go:reagent:17020", "a low reagent asks")
eq(t.Active(), "reagent", "reagent request active")
eq(ract(t.Update(10, nil, false, nil, { 17020 })), "nil", "not asked again while low")
eq(ract(t.Update(10, nil, false, nil, { 17020, 17032 })), "nil", "a second reagent waits for the first")
eq(ract(t.OnMerchantShow()), "clear", "a merchant resolves the first")
eq(ract(t.Update(10, nil, false, nil, { 17020, 17032 })), "go:reagent:17032", "then the second asks")
eq(ract(t.Update(10, nil, false, nil, { 17020 })), "clear", "the active reagent recovered: withdrawn")
eq(ract(t.Update(10, nil, false, nil, {})), "nil", "all recovered")
eq(ract(t.Update(10, nil, false, nil, { 17020 })), "go:reagent:17020", "falls low again: asked again")

-- Combat holds it back; the reagents switch (reagentsEnabled) turns reagents off, the ammo switch does not.
t = T.New(cfg())
eq(ract(t.Update(10, nil, true, nil, { 17020 })), "nil", "no question in combat")
eq(ract(t.Update(10, nil, false, nil, { 17020 })), "go:reagent:17020", "asked after combat")
local off = cfg(); off.reagentsEnabled = false
t = T.New(off)
eq(ract(t.Update(10, nil, false, nil, { 17020 })), "nil", "reagents switch off: no reagent question")
eq(ract(t.Update(10, nil, false, 10, { 17020 })), "go:ammo", "but ammo is still asked")
off = cfg(); off.ammoEnabled = false
t = T.New(off)
eq(ract(t.Update(10, nil, false, nil, { 17020 })), "go:reagent:17020", "ammo switch off: reagents still asked")
t = T.New(off)
eq(ract(t.Update(10, nil, false, 10, {})), "nil", "and no ammo question")

-- Priority: repair, ammo, reagent, sell. A reagent trip does not cover selling.
t = T.New(cfg())
eq(ract(t.Update(1, nil, false, nil, { 17020 })), "go:reagent:17020", "reagent before sell")
eq(ract(t.Update(1, nil, false, nil, { 17020 })), "nil", "sell does not replace reagent")
eq(ract(t.OnMerchantShow()), "clear", "merchant")
eq(ract(t.Update(1, nil, false, nil, { 17020 })), "go:sell", "sell asked after the reagent resolved")
t = T.New(cfg())
eq(ract(t.Update(10, nil, false, 10, { 17020 })), "go:ammo", "ammo before reagent")
eq(ract(t.Update(10, nil, false, 10, { 17020 })), "nil", "reagent waits for ammo")
eq(ract(t.OnMerchantShow()), "clear", "ammo vendor")
eq(ract(t.Update(10, nil, false, 10, { 17020 })), "go:reagent:17020", "reagent after ammo")
t = T.New(cfg())
eq(ract(t.Update(10, 5, false, nil, { 17020 })), "go:repair", "repair before reagent")
eq(ract(t.Update(10, 5, false, nil, { 17020 })), "nil", "reagent waits for repair")
t = T.New(cfg())
eq(ract(t.Update(10, nil, false, nil, { 17020 })), "go:reagent:17020", "reagent open")
eq(ract(t.Update(10, nil, false, 10, { 17020 })), "go:ammo", "ammo replaces an open reagent question")
eq(ract(t.OnMerchantShow()), "clear", "ammo vendor visited")
eq(ract(t.Update(10, nil, false, 300, { 17020 })), "go:reagent:17020", "the displaced reagent is asked again")

-- Conditions: the one "is it low" test, shared by the warnings and the status window.
local function cond(c, free, d, ammo) local n = T.Conditions(c, free, d, ammo); return tostring(n.sell) .. "/" .. tostring(n.repair) .. "/" .. tostring(n.ammo) end
eq(cond(cfg(), 2, 19.9, 200), "true/true/true", "at the bag and ammo thresholds, below the durability one: all low")
eq(cond(cfg(), 3, 20, 201), "false/false/false", "just past each threshold: none low")
eq(cond(cfg(), nil, nil, nil), "nil/false/false", "unknown bags are neither low nor fine; unknown durability and ammo are not low")
c = cfg(); c.bagEnabled, c.durEnabled, c.ammoEnabled = false, false, false
eq(cond(c, 0, 0, 0), "false/false/false", "a switched-off warning is never low")
-- Update decides with Conditions: a replaced Conditions changes what Update asks.
local real = T.Conditions
T.Conditions = function() return { sell = false, repair = true, ammo = false } end
eq(act(T.New(cfg()).Update(20, 100, false, 900)), "go:repair", "Update asks what Conditions reports")
T.Conditions = real

-- A clear names the request that ended.
t = T.New(cfg())
t.Update(1, nil, false)
local a = t.Update(20, nil, false)
eq(a[1] .. ":" .. a[2], "clear:sell", "clear names sell")
t = T.New(cfg())
t.Update(10, nil, false, nil, { 17020 })
a = t.Update(10, nil, false, nil, {})
eq(a[1] .. ":" .. a[2] .. ":" .. a[3], "clear:reagent:17020", "clear names the reagent")

-- Instances: nothing is asked inside, and the latch is not used up (the battleground case: bags fill
-- inside, the question comes after leaving).
t = T.New(cfg())
eq(act(t.Update(1, nil, false, nil, nil, true)), "nil", "full bags in a battleground: nothing asked")
eq(t.Active(), nil, "nothing active inside")
eq(act(t.Update(1, nil, false, nil, nil, true)), "nil", "still inside: still nothing")
eq(act(t.Update(1, nil, false, nil, nil, false)), "go:sell", "left with full bags: asked now")
t = T.New(cfg())
eq(act(t.Update(1, nil, false, nil, nil, true)), "nil", "full inside")
eq(act(t.Update(9, nil, false, nil, nil, false)), "nil", "emptied before leaving: nothing asked")
t = T.New(cfg())
eq(ract(t.Update(10, 5, false, 10, { 17020 }, true)), "nil", "repair, ammo and reagents all wait inside")
eq(ract(t.Update(10, 5, false, 10, { 17020 }, false)), "go:repair", "and are asked in the usual order outside")
t = T.New(cfg())
t.Update(1, nil, false)
eq(act(t.Update(20, nil, false, nil, nil, true)), "clear", "a request from outside still ends inside when it resolves")

-- Take: the player went for it unasked. A low condition becomes the handled, active request.
t = T.New(cfg())
eq(t.Take("sell"), false, "nothing seen yet: not taken")
t.Update(1, nil, true)
eq(t.Take("sell"), true, "low (seen in combat): taken")
eq(t.Active(), "sell", "taken request is active")
eq(act(t.Update(1, nil, false)), "nil", "not asked about afterwards")
a = t.Update(20, nil, false)
eq(a[1] .. ":" .. a[2], "clear:sell", "ends when it resolves")
eq(act(t.Update(1, nil, false)), "go:sell", "and may be asked again later")
t = T.New(cfg())
t.Update(10, nil, false)
eq(t.Take("sell"), false, "not low: not taken")
eq(t.Active(), nil, "nothing active")
eq(t.Take("nonsense"), false, "unknown kind: not taken")
-- Taking replaces the active request, even one of a higher priority; that one stays handled.
t = T.New(cfg())
eq(act(t.Update(1, 5, false)), "go:repair", "repair active")
eq(t.Take("sell"), true, "sell taken over repair")
eq(t.Active(), "sell", "sell is the active one")
eq(act(t.Update(1, 5, false)), "nil", "repair is not asked again")
eq(act(t.Update(20, 5, false)), "clear", "the taken sell ends on its own")
-- Reagents are taken by item id.
t = T.New(cfg())
t.Update(10, nil, false, nil, { 17020 }, true)
eq(t.Take("reagent", 17032), false, "a reagent that is not low is not taken")
eq(t.Take("reagent", 17020), true, "the low reagent is taken")
eq(ract(t.Update(10, nil, false, nil, { 17020 })), "nil", "and not asked about")
a = t.Update(10, nil, false, nil, {})
eq(a[1] .. ":" .. a[2] .. ":" .. a[3], "clear:reagent:17020", "it ends when restocked")

-- Supplies: food, water and pet food are one request each, below reagents and above selling.
local function fresh(over) local c = cfg() for k, v in pairs(over or {}) do c[k] = v end return T.New(c) end
local function sup(t, free, supplies, reagents, combat, inst) return t.Update(free, nil, combat or false, nil, reagents, inst or false, supplies) end
t = fresh()
eq(act(sup(t, 10, { "food" })), "go:food", "food low asks")
eq(act(sup(t, 10, { "food" })), "nil", "no repeat while low")
eq(t.Active(), "food", "active")
eq(act(sup(t, 10, {})), "clear", "food restored: withdrawn")
eq(act(sup(t, 10, { "food" })), "go:food", "falls low again: asked again")

t = fresh()
eq(act(sup(t, 10, { "food", "water", "pet" })), "go:food", "food first")
eq(act(sup(t, 10, { "food", "water", "pet" })), "nil", "water waits for food")
eq(act(sup(t, 10, { "water", "pet" })), "clear", "food resolved")
eq(act(sup(t, 10, { "water", "pet" })), "go:water", "then water")
eq(act(sup(t, 10, { "pet" })), "clear", "water resolved")
eq(act(sup(t, 10, { "pet" })), "go:pet", "then pet food")

t = fresh()
eq(act(sup(t, 10, { "food" }, { 17020 })), "go:reagent", "reagent before food")
t = fresh()
eq(act(sup(t, 10, { "food" })), "go:food", "food asked first")
eq(act(sup(t, 10, { "food" }, { 17020 })), "go:reagent", "a reagent replaces an open food request")
t = fresh()
eq(act(sup(t, 1, { "pet" })), "go:pet", "pet food before sell")
eq(act(sup(t, 1, { "pet" })), "nil", "sell does not replace pet food")
eq(act(sup(t, 1, {})), "clear", "pet food resolved")
eq(act(sup(t, 1, {})), "go:sell", "a pet food trip does not cover selling")
t = fresh()
eq(act(sup(t, 1, { "food" })), "go:food", "food before sell")
t = fresh()
eq(act(t.Update(10, 5, false, nil, nil, false, { "food" })), "go:repair", "repair before food")

-- The ammo switch does not gate supplies; combat and instances defer without using the request up.
t = fresh({ ammoEnabled = false })
eq(act(sup(t, 10, { "food" })), "go:food", "ammo switch off: supplies still asked")
t = fresh({ suppliesEnabled = false })
eq(act(sup(t, 10, { "food" })), "nil", "supplies switch off: no supply request")
t = fresh()
eq(act(sup(t, 10, { "food" }, nil, true)), "nil", "combat: nothing")
eq(act(sup(t, 10, { "food" }, nil, false, true)), "nil", "instance: nothing")
eq(act(sup(t, 10, { "food" })), "go:food", "asked once out and still low")

-- Take: the player chose to go without being asked.
t = fresh()
eq(t.Take("water"), false, "nothing seen yet")
sup(t, 10, { "water" }, nil, true)
eq(t.Take("water"), true, "taken while low")
eq(t.Active(), "water", "active after Take")
eq(act(sup(t, 10, { "water" })), "nil", "taken: not asked again")
eq(t.Take("pet"), false, "not low: not taken")

-- Reminders: notices once each until the condition clears; never in combat or instances; never touch a request.
t = fresh()
local function due(list, combat, inst) return table.concat(t.Reminders(list, combat or false, inst or false), ",") end
eq(due({ "food", "healthstone" }), "food,healthstone", "both announced")
eq(due({ "food", "healthstone" }), "", "once")
eq(due({ "food" }), "", "still low, healthstone cleared")
eq(due({ "food", "healthstone" }), "healthstone", "healthstone returns after clearing")
eq(due({}), "", "all clear")
eq(due({ "food" }), "food", "food again after clearing")
t = fresh()
eq(due({ "water" }, true), "", "combat: not announced")
eq(due({ "water" }, false, true), "", "instance: not announced")
eq(due({ "water" }), "water", "announced once out, because combat did not use it up")
t = fresh({ ammoEnabled = false })
eq(due({ "water" }), "water", "ammo switch off: reminders still come")
t = fresh({ suppliesEnabled = false })
eq(due({ "water" }), "", "supplies switch off: no reminders")
t = fresh()
sup(t, 1, { "pet" })
due({ "food" })
eq(t.Active(), "pet", "a reminder leaves the active request alone")
eq(due({ "food", "water", "food" }), "water", "a repeated key is announced once")

H.done()
