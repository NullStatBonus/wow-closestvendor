-- Player-facing text. English is the key: L["Some sentence"] returns "Some sentence" unless a
-- locale file loaded after this one has assigned a translation. A missing entry never errors.
-- See docs/localization.md for how to add a language.
local _, ns = ...

ns.L = setmetatable({}, { __index = function(_, key) return key end })
