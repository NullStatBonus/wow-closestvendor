local ns = {}
loadfile("ClosestVendor/Triggers.lua")("ClosestVendor", ns)
local T = ns.Triggers

package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq
local function act(a) return a and (a[2] and (a[1] .. ":" .. a[2]) or a[1]) or "nil" end
local function cfg() return { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, bagEnabled = true, durEnabled = true, ammoEnabled = true } end

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

H.done()
