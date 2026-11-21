package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
loadfile("ClosestVendor/Move.lua")("ClosestVendor", ns)

local function rig(locked)
    local r = { locked = locked or false, calls = {} }
    local function note(s) r.calls[#r.calls + 1] = s end
    r.move = ns.Move.New({
        locked = function() return r.locked end,
        placeholder = function() note("placeholder") end,
        stop = function() note("stop") end,
        save = function() note("save") end,
        apply = function() note("apply") end,
        finish = function(done) note("finish:" .. tostring(done)) end,
    })
    function r.text() return table.concat(r.calls, ",") end
    return r
end

-- Begin shows the placeholder and starts a transaction; nothing is saved yet.
local r = rig()
eq(r.move.Begin(), true, "Begin starts")
eq(r.move.active, true, "active after Begin")
eq(r.text(), "placeholder", "Begin only shows the placeholder")

-- Done saves, restores the live frame from the saved state and ends the transaction.
r.calls = {}
r.move.Done()
eq(r.text(), "stop,save,apply,finish:true", "Done stops dragging, saves, applies, finishes done")
eq(r.move.active, false, "not active after Done")

-- Cancel (or Escape) never saves: the frame goes back to the saved place.
r = rig()
r.move.Begin(); r.calls = {}
r.move.Cancel()
eq(r.text(), "stop,apply,finish:false", "Cancel restores without saving")
eq(r.move.active, false, "not active after Cancel")
r.calls = {}
r.move.Cancel(); r.move.Done()
eq(r.text(), "", "Cancel and Done do nothing when no move is active")

-- Lock blocks moving.
r = rig(true)
eq(r.move.Begin(), false, "locked: Begin refuses")
eq(r.move.active, false, "locked: not active")
eq(r.text(), "", "locked: no placeholder")

-- Locked while moving: Done becomes Cancel and saves nothing.
r = rig()
r.move.Begin(); r.calls = {}
r.locked = true
r.move.Done()
eq(r.text(), "stop,apply,finish:false", "locked before Done: restores, no save")
eq(r.move.active, false, "locked before Done: ended")

-- Begin again restarts: the first move is cancelled first.
r = rig()
r.move.Begin(); r.calls = {}
eq(r.move.Begin(), true, "second Begin starts")
eq(r.text(), "stop,apply,finish:false,placeholder", "the earlier move is cancelled, then a new placeholder")

H.done()
