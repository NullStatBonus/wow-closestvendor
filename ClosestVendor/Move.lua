-- A position transaction. Only Done writes; Cancel restores the live frame from saved state.
local _, ns = ...
local M = {}
ns.Move = M
function M.New(env)
    local self = { active = false }
    function self.Cancel()
        if not self.active then return end
        env.stop(); self.active = false; env.apply(); env.finish(false)
    end
    function self.Begin()
        if env.locked() then return false end
        self.Cancel(); self.active = true; env.placeholder(); return true
    end
    function self.Done()
        if not self.active then return end
        if env.locked() then self.Cancel(); return end
        env.stop(); env.save(); self.active = false; env.apply(); env.finish(true)
    end
    return self
end
