-- Navigation adapters. No direct WoW globals: everything arrives through `api`:
--   api.isAddOnLoaded(name), api.TomTom, api.WaypointUIAPI, api.C_Map, api.C_SuperTrack,
--   api.UiMapPoint, api.print(text), api.mapName(uiMapID)
-- Vendor record: {npcId, name, uiMapID, mx, my, ...} with mx,my in 0-1.
-- First available adapter wins; an adapter that errors falls through to the next. A preferred adapter
-- (the player's choice) is tried first; if it is missing or fails, the usual order applies.
local _, ns = ...

local L = ns.L

local N = {}
ns.Nav = N

local FLAG = "ClosestVendor"

local function isFn(t, name) return type(t) == "table" and type(t[name]) == "function" end

local byKind = {}
local adapters = {
    {
        name = "tomtom",
        -- Check IsAddOnLoaded: other addons define a fake global `TomTom`.
        available = function(api)
            return api.isAddOnLoaded("TomTom") and isFn(api.TomTom, "AddWaypoint")
        end,
        set = function(api, v)
            local uid = api.TomTom:AddWaypoint(v[3], v[4], v[5],
                { title = v[2], from = FLAG, persistent = false, crazy = true })
            if not uid then return nil end
            return { kind = "tomtom", uid = uid }
        end,
        clear = function(api, h)
            if isFn(api.TomTom, "RemoveWaypoint") then api.TomTom:RemoveWaypoint(h.uid) end
        end,
    },
    {
        name = "waypointui",
        available = function(api)
            local nav = api.WaypointUIAPI and api.WaypointUIAPI.Navigation
            return isFn(nav, "NewUserNavigation") and isFn(nav, "ClearUserNavigation")
        end,
        set = function(api, v)
            -- WaypointUI takes x/y in 0-100.
            local r = api.WaypointUIAPI.Navigation.NewUserNavigation(
                { name = v[2], mapID = v[3], x = v[4] * 100, y = v[5] * 100, flags = FLAG })
            if r == false then return nil end
            return { kind = "waypointui" }
        end,
        clear = function(api, h)
            local nav = api.WaypointUIAPI.Navigation
            -- Only clear our own destination; if ownership cannot be checked, leave it alone.
            if isFn(nav, "GetUserNavigation") then
                local cur = nav.GetUserNavigation()
                if cur and cur.flags == FLAG then nav.ClearUserNavigation(false, true) end
            end
        end,
    },
    {
        name = "native",
        available = function(api)
            local m, s = api.C_Map, api.C_SuperTrack
            return isFn(m, "SetUserWaypoint") and isFn(m, "CanSetUserWaypointOnMap")
                and isFn(s, "SetSuperTrackedUserWaypoint")
                and type(api.UiMapPoint) == "table" and type(api.UiMapPoint.CreateFromCoordinates) == "function"
        end,
        set = function(api, v)
            if not api.C_Map.CanSetUserWaypointOnMap(v[3]) then return nil end
            api.C_Map.SetUserWaypoint(api.UiMapPoint.CreateFromCoordinates(v[3], v[4], v[5]))
            api.C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            return { kind = "native", map = v[3], x = v[4], y = v[5] }
        end,
        clear = function(api, h)
            local m = api.C_Map
            -- Single slot: do not remove a waypoint the user has since replaced.
            if isFn(m, "GetUserWaypoint") then
                local cur = m.GetUserWaypoint()
                local p = cur and cur.position
                if not (cur and p and cur.uiMapID == h.map
                        and math.abs(p.x - h.x) < 0.001 and math.abs(p.y - h.y) < 0.001) then
                    return
                end
            end
            if isFn(m, "ClearUserWaypoint") then m.ClearUserWaypoint() end
            api.C_SuperTrack.SetSuperTrackedUserWaypoint(false)
        end,
    },
    {
        name = "chat",
        available = function() return true end,
        set = function(api, v)
            local zone = api.mapName and api.mapName(v[3]) or "?"
            api.print(L["Closest vendor: %s in %s (%.1f, %.1f)"]:format(v[2], zone, v[4] * 100, v[5] * 100))
            return { kind = "chat" }
        end,
        clear = function() end,
    },
}

for _, a in ipairs(adapters) do byKind[a.name] = a end

-- The choices for the player: { key, label }. "auto" is the usual order.
N.PROVIDERS = {
    { "auto", L["Automatic"] },
    { "tomtom", L["TomTom"] },
    { "waypointui", L["WaypointUI"] },
    { "native", L["Game waypoint"] },
}

-- The saved key a player means by text (the key or the label, case ignored); nil if none.
function N.FindProvider(text)
    local want = tostring(text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    for _, p in ipairs(N.PROVIDERS) do
        if p[1] == want or p[2]:lower() == want then return p[1] end
    end
end

-- The adapters in the order to try: the preferred one first, then the rest in the usual order.
local function ordered(prefer)
    local first = prefer ~= "auto" and byKind[prefer]
    if not first or first.name == "chat" then return adapters end
    local list = { first }
    for _, a in ipairs(adapters) do if a ~= first then list[#list + 1] = a end end
    return list
end

-- Name of the adapter that would be used now.
function N.Select(api, prefer)
    for _, a in ipairs(ordered(prefer)) do
        local ok, avail = pcall(a.available, api)
        if ok and avail then return a.name end
    end
end

-- Show the vendor with the first adapter that works. Returns a handle for Clear, never errors.
function N.Set(api, vendor, prefer)
    for _, a in ipairs(ordered(prefer)) do
        local ok, avail = pcall(a.available, api)
        if ok and avail then
            local ok2, h = pcall(a.set, api, vendor)
            if ok2 and h then return h end
        end
    end
end

function N.Clear(api, handle)
    local a = handle and byKind[handle.kind]
    if a then pcall(a.clear, api, handle) end
end
