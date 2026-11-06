package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local ns = {}
H.locale(ns)
loadfile("ClosestVendor/Nav.lua")("ClosestVendor", ns)
local N = ns.Nav


local V = { 54, "Corina Steele", 1429, 0.415, 0.659, 1, true }

-- Fake environment builder. Each piece is optional; calls are logged.
local function env(opts)
    local log = {}
    local api = { print = function(t) log[#log + 1] = "print:" .. t end,
                  mapName = function() return "Elwynn Forest" end,
                  isAddOnLoaded = function(name) return opts.loaded and opts.loaded[name] or false end }
    if opts.tomtom then
        api.TomTom = { AddWaypoint = function(_, map, x, y, o)
                          log[#log + 1] = ("tt:add %d %.3f %.3f %s %s"):format(map, x, y, o.title, tostring(o.crazy))
                          return opts.tomtomUid == nil and {} or opts.tomtomUid
                      end,
                      RemoveWaypoint = function(_, uid) log[#log + 1] = "tt:remove" end }
    end
    if opts.wui then
        local nav = { NewUserNavigation = function(o)
                          log[#log + 1] = ("wui:new %d %.1f %.1f %s"):format(o.mapID, o.x, o.y, o.name)
                          if opts.wuiThrows then error("boom") end
                          return opts.wuiResult
                      end,
                      ClearUserNavigation = function(a, b) log[#log + 1] = "wui:clear" end }
        if opts.wui ~= "nogetter" then nav.GetUserNavigation = function() return opts.wuiCurrent end end
        if opts.wui == "missing" then nav.ClearUserNavigation = nil end
        api.WaypointUIAPI = { Navigation = nav }
    end
    if opts.native then
        local current
        api.C_Map = { CanSetUserWaypointOnMap = function() return opts.canSet ~= false end,
                      SetUserWaypoint = function(p) current = p; log[#log + 1] = ("native:set %d %.3f"):format(p.uiMapID, p.position.x) end,
                      GetUserWaypoint = function() return opts.replaced or current end,
                      ClearUserWaypoint = function() log[#log + 1] = "native:clear" end }
        api.C_SuperTrack = { SetSuperTrackedUserWaypoint = function(b) log[#log + 1] = "super:" .. tostring(b) end }
        api.UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { uiMapID = m, position = { x = x, y = y } } end }
    end
    return api, log
end

-- Selection order.
eq(N.Select(env({ tomtom = true, loaded = { TomTom = true }, wui = true, native = true })), "tomtom", "tomtom first")
eq(N.Select(env({ tomtom = true, loaded = {}, wui = true, native = true })), "waypointui", "fake TomTom global ignored")
eq(N.Select(env({ wui = true, native = true })), "waypointui", "waypointui before native")
eq(N.Select(env({ wui = "missing", native = true })), "native", "waypointui missing method -> native")
eq(N.Select(env({})), "chat", "era without anything -> chat")

-- TomTom: 0-1 coords, title, crazy arrow; remove with returned uid.
local api, log = env({ tomtom = true, loaded = { TomTom = true } })
local h = N.Set(api, V)
eq(log[1], "tt:add 1429 0.415 0.659 Corina Steele true", "tomtom add args")
N.Clear(api, h)
eq(log[2], "tt:remove", "tomtom remove")

-- TomTom returns no uid -> falls through (to chat here).
api, log = env({ tomtom = true, loaded = { TomTom = true }, tomtomUid = false })
eq(N.Set(api, V).kind, "chat", "tomtom failure falls through")

-- WaypointUI: 0-100 coords.
api, log = env({ wui = true })
h = N.Set(api, V)
eq(log[1], "wui:new 1429 41.5 65.9 Corina Steele", "waypointui scale 0-100")
eq(h.kind, "waypointui", "waypointui handle")

-- WaypointUI clear only when the current destination is ours.
api, log = env({ wui = true, wuiCurrent = { flags = "ClosestVendor" } })
h = N.Set(api, V); N.Clear(api, h)
eq(log[#log], "wui:clear", "clears own destination")
api, log = env({ wui = true, wuiCurrent = { flags = "SomeoneElse" } })
h = N.Set(api, V); N.Clear(api, h)
eq(log[#log], "wui:new 1429 41.5 65.9 Corina Steele", "leaves foreign destination")
api, log = env({ wui = "nogetter" })
h = N.Set(api, V); N.Clear(api, h)
eq(#log, 1, "cannot verify ownership -> no clear")

-- WaypointUI reports failure (false) -> next adapter.
api, log = env({ wui = true, wuiResult = false, native = true })
eq(N.Set(api, V).kind, "native", "waypointui returned false falls to native")
api, log = env({ wui = true, wuiResult = nil })
eq(N.Set(api, V).kind, "waypointui", "nil result counts as success")

-- WaypointUI throws -> next adapter (native), no error escapes.
api, log = env({ wui = true, wuiThrows = true, native = true })
eq(N.Set(api, V).kind, "native", "error in waypointui falls to native")

-- Native: set + supertrack; clear only if still ours.
api, log = env({ native = true })
h = N.Set(api, V)
eq(log[1], "native:set 1429 0.415", "native set")
eq(log[2], "super:true", "supertracked")
N.Clear(api, h)
eq(log[3], "native:clear", "native clear")
eq(log[4], "super:false", "supertrack off")
api, log = env({ native = true, replaced = { uiMapID = 1429, position = { x = 0.9, y = 0.9 } } })
h = N.Set(api, V); N.Clear(api, h)
eq(#log, 2, "user's replacement waypoint is left alone")

-- Native refuses the map -> chat.
api, log = env({ native = true, canSet = false })
eq(N.Set(api, V).kind, "chat", "cannot set on map -> chat")
eq(log[#log]:sub(1, 6), "print:", "chat printed")
eq(log[#log], "print:Closest vendor: Corina Steele in Elwynn Forest (41.5, 65.9)", "chat text")

-- Clear with nothing is a no-op and never errors.
N.Clear(api, nil)
N.Clear(api, { kind = "unknown" })

H.done()
