-- Contract fake for Ace registration; option tables are also checked by upstream registry tests.
local M = {}
function M.new(opts)
    opts = opts or {}
    local rec = { registrations = 0, categories = 0, notifications = 0 }
    local registry = {
        RegisterOptionsTable = function(_, app, tree)
            if opts.failRegister then error("registration unavailable") end
            rec.app, rec.tree = app, tree; rec.registrations = rec.registrations + 1
        end,
        NotifyChange = function() rec.notifications = rec.notifications + 1 end,
    }
    local dialog = {
        SetDefaultSize = function(_, app, width, height) rec.defaultSize = {app=app,width=width,height=height} end,
        AddToBlizOptions = function(_, app, name, parent, ...)
            if opts.noNative then error("native registration unavailable") end
            rec.categories = rec.categories + 1
            rec.entries = rec.entries or {}
            rec.entries[#rec.entries + 1] = { app = app, name = name, parent = parent, path = table.concat({ ... }, "/") }
            return 42
        end,
        Open = function() if opts.failOpen then error("dialog unavailable") end; rec.opened = 42 end,
        SelectGroup = function(_, _, ...) rec.page = table.concat({ ... }, "/") end,
    }
    rec.dialog = dialog
    return function(name)
        if opts.missing then return end
        return ({ ["AceConfigRegistry-3.0"] = registry, ["AceConfigDialog-3.0"] = dialog, ["AceGUI-3.0"] = {} })[name]
    end, rec
end
return M
