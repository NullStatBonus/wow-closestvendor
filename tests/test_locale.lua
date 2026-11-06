-- Localization: every sentence is an L["English"] literal, locale files only translate sentences
-- that exist and keep their %s/%d placeholders, translations are shown, and English is the fallback.
package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local function read(path)
    local f = assert(io.open(path, "r"), path)
    local s = f:read("*a")
    f:close()
    return s
end

local function lines(cmd)
    local out = {}
    local p = io.popen(cmd)
    for l in p:lines() do out[#out + 1] = l end
    p:close()
    return out
end

-- Read a Lua string literal starting at position i (a quote); returns the value and the next position.
local function literal(src, i)
    local q = src:sub(i, i)
    if q ~= '"' and q ~= "'" then return nil end
    local j = i + 1
    while j <= #src do
        local c = src:sub(j, j)
        if c == "\\" then j = j + 2
        elseif c == q then break
        else j = j + 1 end
    end
    local chunk = loadstring("return " .. src:sub(i, j))
    return chunk and chunk(), j + 1
end

-- Every L[...] use: returns the literal keys and the number of uses that are not a plain literal.
local function uses(src)
    local keys, dynamic = {}, 0
    for start in src:gmatch("()L%[") do
        local before = src:sub(start - 1, start - 1)
        if not before:match("[%w_]") then
            local value, nextPos = literal(src, start + 2)
            if value and src:sub(nextPos, nextPos) == "]" then keys[#keys + 1] = value else dynamic = dynamic + 1 end
        end
    end
    return keys, dynamic
end

-- Assignments L["key"] = "value".
local function assignments(src)
    local out = {}
    for start in src:gmatch("()L%[") do
        local key, p = literal(src, start + 2)
        if key and src:sub(p, p) == "]" then
            local rest = src:match("^%s*=%s*()", p + 1)
            if rest then
                local value = literal(src, rest)
                if value then out[#out + 1] = { key = key, value = value } end
            end
        end
    end
    return out
end

local function specs(s)
    local t = {}
    for spec in s:gmatch("%%[%-%d%.]*[sdfi]") do t[#t + 1] = spec end
    table.sort(t)
    return table.concat(t, " ")
end

-- 1. The code: every use is a plain literal sentence.
local codeKeys, total, dynamic = {}, 0, 0
for _, file in ipairs(lines("ls ClosestVendor/*.lua")) do
    local keys, dyn = uses(read(file))
    dynamic = dynamic + dyn
    for _, k in ipairs(keys) do codeKeys[k] = true; total = total + 1 end
end
eq(dynamic, 0, "every L[...] in the code is a plain string literal (no concatenation or variables)")
local count = 0
for _ in pairs(codeKeys) do count = count + 1 end
eq(count > 40, true, "the code has plenty of sentences to translate (found " .. count .. ")")

-- 1b. Nothing player-facing is printed without going through L.
local core = read("ClosestVendor/Core.lua")
eq(core:find('say%("') , nil, 'Core.lua never says a raw string: say("...")')
eq(read("ClosestVendor/Nav.lua"):find('api%.print%("'), nil, "Nav.lua never prints a raw string")

-- 2. Locale files (the example included): only existing sentences, same placeholders, not empty.
local files = lines("ls ClosestVendor/Locales/*.lua")
local translated = 0
for _, file in ipairs(files) do
    if not file:find("enUS.lua", 1, true) then
        for _, a in ipairs(assignments(read(file))) do
            translated = translated + 1
            eq(codeKeys[a.key], true, file .. ": '" .. a.key:sub(1, 40) .. "' is a sentence the code uses")
            eq(specs(a.value), specs(a.key), file .. ": placeholders match for '" .. a.key:sub(1, 40) .. "'")
            eq(#a.value > 0, true, file .. ": not empty")
        end
    end
end
eq(translated >= 5, true, "the example translates a handful of sentences (found " .. translated .. ")")

-- The checker itself catches a bad key and bad placeholders.
local bad = assignments('L["No such sentence in the code"] = "x"\nL["Bag space"] = "%s"')
eq(bad[1].key, "No such sentence in the code", "parser reads keys")
eq(codeKeys[bad[1].key], nil, "a made-up key is not a code sentence")
eq(specs(bad[2].value) == specs(bad[2].key), false, "a placeholder added to a translation is caught")
eq(specs("%d of %s") == specs("%s of %d"), true, "placeholder order may change")
eq(specs("%.1f and %%") == specs("%.1f"), true, "an escaped percent is not a placeholder")
local _, dyn = uses('local x = L["a" .. b] + L[k] + L["fine"]')
eq(dyn, 2, "concatenation and variables are flagged")

-- 3. Behavior. English is the key; a translation replaces it; a missing one falls back.
local ns = H.locale({})
eq(ns.L["Any sentence at all"], "Any sentence at all", "unknown sentence comes back as written")
eq(ns.L["%d left"]:format(5), "5 left", "placeholders survive")

local function loadModules(ns2, names, locale)
    local env = setmetatable({ GetLocale = function() return locale end }, { __index = _G })
    for _, name in ipairs(names) do
        local chunk = assert(loadfile("ClosestVendor/" .. name .. ".lua"))
        setfenv(chunk, env)
        chunk("ClosestVendor", ns2)
    end
end

-- The example, when its locale matches, translates what it lists and nothing else.
local ns2 = {}
loadModules(ns2, { "Locales/enUS", "Locales/Example" }, "xxXX")
eq(ns2.L["Bag space"], "[xx] Bag space", "a listed sentence is translated")
eq(ns2.L["Ammo"], "Ammo", "an unlisted sentence stays English")
-- ...and does nothing on other clients.
ns2 = {}
loadModules(ns2, { "Locales/enUS", "Locales/Example" }, "enUS")
eq(ns2.L["Bag space"], "Bag space", "wrong locale: untouched")

-- A translation is shown by the code, for text built at call time and at load time.
ns2 = {}
loadModules(ns2, { "Locales/enUS", "Locales/Example", "Commands" }, "xxXX")
local cfg = { bagThreshold = 2, durThreshold = 20, ammoThreshold = 200, bagEnabled = true, durEnabled = true, ammoEnabled = true }
eq(ns2.Commands.Run(cfg, "config")[1], "[xx] Opening the settings page...", "translated at call time")
local helpTexts = ns2.Commands.Run(cfg, "help")
eq(helpTexts[1], "/cvn  show settings", "an untranslated help line stays English")

ns2 = {}
loadModules(ns2, { "Locales/enUS" }, "xxXX")
ns2.L["/cvn  show settings"] = "translated help line"
loadModules(ns2, { "Commands" }, "xxXX")
eq(ns2.Commands.Run(cfg, "help")[1], "translated help line", "translated before the module loads (help lines)")

-- Translated prompts keep their placeholders working.
ns2 = {}
loadModules(ns2, { "Locales/enUS", "Locales/Example", "Controller" }, "xxXX")
eq(ns2.Controller.PromptText("repair", { 1, "Smith" }, "Elwynn Forest"), "[xx] Your gear needs repair.\n\nNavigate to the closest repair vendor, Smith (Elwynn Forest)?", "translated prompt with its vendor")
eq(ns2.Controller.PromptText("arrow", { 1, "Smith" }, nil, 150):find("[xx]", 1, true), 1, "translated prompt with a count")

H.done()
