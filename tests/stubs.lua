-- Fake WoW API for tests. install() sets globals, restore() puts them back.
local M = {}
local saved = {}

function M.install(globals)
    for k, v in pairs(globals) do
        if saved[k] == nil then saved[k] = { old = _G[k] } end
        _G[k] = v
    end
end

function M.restore()
    for k, s in pairs(saved) do _G[k] = s.old end
    saved = {}
end

return M
