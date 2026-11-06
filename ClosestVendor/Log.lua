-- Bounded debug log and report text. No WoW globals: the clock and the saved table come in.
-- store is a SavedVariables sub-table: { enabled = bool, entries = { { t = number, msg = string }, ... } }.
local _, ns = ...

local L = {}
ns.Log = L

L.MAX = 300

function L.New(store, clock, max)
    max = max or L.MAX
    store.entries = store.entries or {}
    local self = {}

    function self.Enabled() return store.enabled == true end
    function self.SetEnabled(on) store.enabled = on and true or false end

    -- Does nothing while the log is off, so it costs nothing in normal play.
    function self.Add(msg)
        if store.enabled ~= true then return end
        local e = store.entries
        e[#e + 1] = { t = clock(), msg = tostring(msg) }
        while #e > max do table.remove(e, 1) end
    end

    function self.Entries() return store.entries end
    function self.Clear() store.entries = {} end

    return self
end

-- "[12.3] text" lines for the newest `limit` entries (all when limit is nil), oldest first.
function L.Format(entries, limit)
    local first = 1
    if limit and #entries > limit then first = #entries - limit + 1 end
    local out = {}
    for i = first, #entries do
        out[#out + 1] = ("[%.1f] %s"):format(entries[i].t or 0, entries[i].msg)
    end
    return out
end

-- Report text: header lines (already "key: value"), then the log.
function L.Report(header, entries, enabled)
    local out = { "Closest Vendor report" }
    for _, line in ipairs(header) do out[#out + 1] = line end
    if enabled then
        out[#out + 1] = ("Debug log: on, %d entries"):format(#entries)
    else
        out[#out + 1] = "Debug log: off (turn it on with /cvn debug on, repeat the problem, then use /cvn log)"
    end
    if #entries > 0 then
        out[#out + 1] = ""
        for _, line in ipairs(L.Format(entries)) do out[#out + 1] = line end
    end
    return table.concat(out, "\n")
end
