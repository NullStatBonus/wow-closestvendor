-- The in-game test plans (plans/closestvendor*.yaml: the core plan, plus any feature plan) keep their numbers in order, and
-- every reference to a check in the code, tests and docs names a step or section one of the plans has
-- (AGENTS.md, CheckThat). The plans are read with patterns: CI has no YAML library and no CheckThat. Each
-- plan owns a range of section numbers, so "test plan check N.M" names one step across the set. Ids may
-- have gaps (a removed step keeps its number unused, so no step is renumbered), and no doc points at a
-- CheckThat checkout or a replay hooks file.
package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

local function read(path)
    local f = assert(io.open(path), path)
    local s = f:read("*a")
    f:close()
    return s
end

-- Each plan, its section range and its step limit (a plan with 25 or more steps is split; AGENTS.md).
-- version is the ClosestVendor version the plan's first step asks for (major*10000 + minor*100 + patch): the
-- version that has what it checks. The core plan is the release gate. A feature plan, written when a feature is
-- built or changed, joins this list with its own section range from s30 on: s10 to s29 belonged to the removed
-- ui and addons plans, and their ids stay retired.
local PLANS = {
    { path = "plans/closestvendor.yaml", first = 0, last = 9, core = true, version = 11300 },
}
local MAX_STEPS = 24

local found = {}
local p = io.popen("ls plans/closestvendor*.yaml")
for path in p:lines() do found[#found + 1] = path end
p:close()
eq(#found, #PLANS, "the plan set is the three plans: " .. table.concat(found, " "))
for _, plan in ipairs(PLANS) do
    local ok = false
    for _, path in ipairs(found) do if path == plan.path then ok = true end end
    eq(ok, true, "the plan exists: " .. plan.path)
end

-- Sections are "- id: s<N>" at the top level; steps are "  - id: cv.s<N>.<M>" inside them. Ids are unique
-- across the whole set.
local sections, steps = {}, {}
for _, plan in ipairs(PLANS) do
    local text = read(plan.path)
    eq(text:match("\naddon: (%S+)"), "ClosestVendor", plan.path .. " is ClosestVendor's")
    local order, count, firstStep = {}, 0, nil
    local section, lastStep = plan.first - 1, 0
    local lineNo = 0
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        lineNo = lineNo + 1
        -- Every id key is in one of the two layouts read here (a comment after it, another indent or a flow
        -- mapping would hide a step from the count, the order and the uniqueness checks), so anything else fails.
        if not line:match("^%s*#") and (line:match("^[%s%-]*id:") or line:match("[{,]%s*id:")) then
            eq(line:match("^%- id: s%d+$") ~= nil or line:match("^  %- id: cv%.s%d+%.%d+$") ~= nil, true,
                plan.path .. ":" .. lineNo .. ": an id line in a layout the test reads ('- id: s<N>' or '  - id: cv.s<N>.<M>'): " .. line)
        end
        local s = line:match("^%- id: (%S+)$")
        if s then
            eq(sections[s], nil, "section id is unique across the plans: " .. s)
            sections[s] = true
            order[#order + 1] = s
            local n = tonumber(s:match("^s(%d+)$"))
            eq(n ~= nil and n > section, true, plan.path .. ": sections are numbered in increasing order: " .. s)
            eq(n ~= nil and n >= plan.first and n <= plan.last, true, plan.path .. ": section " .. s .. " is in the plan's range s" .. plan.first .. " to s" .. plan.last)
            eq(n ~= nil and (n < 10 or n >= 30), true, plan.path .. ": section " .. s .. " is not one of the retired s10 to s29")
            section, lastStep = n or section, 0
        end
        local id = line:match("^  %- id: (%S+)$")
        if id then
            eq(steps[id], nil, "step id is unique across the plans: " .. id)
            steps[id] = true
            count = count + 1
            firstStep = firstStep or id
            local sec, n = id:match("^cv%.s(%d+)%.(%d+)$")
            eq(tonumber(sec), section, "a step's id names its section: " .. id)
            eq(n ~= nil and tonumber(n) > lastStep, true, "steps are numbered in increasing order within their section: " .. id)
            lastStep = tonumber(n) or lastStep
        end
    end
    local setup = "s" .. plan.first
    eq(order[1], setup, plan.path .. " starts with its setup section " .. setup)
    eq(count >= 2 and count <= MAX_STEPS, true, plan.path .. " has 2 to " .. MAX_STEPS .. " steps (" .. count .. ")")
    -- The first step calls the version entry and needs it at least at the version under test (op: ge).
    local vid = ("cv.s%d.1"):format(plan.first)
    eq(firstStep, vid, plan.path .. ": the version step " .. vid .. " is first")
    local first = text:match("\n  %- id: " .. vid:gsub("%.", "%%.") .. "\n(.-)\n  %- id: ")
    eq(first ~= nil, true, vid .. " has a body")
    eq((first or ""):find("\n      entry: version\n", 1, true) ~= nil, true, vid .. " calls the version entry")
    eq((first or ""):find("key: entry.version", 1, true) ~= nil, true, vid .. " asserts the entry.version fact")
    eq((first or ""):find("op: ge", 1, true) ~= nil, true, vid .. " passes at the version under test or newer")
    eq((first or ""):find("\n      value: " .. plan.version .. "\n", 1, true) ~= nil, true, vid .. " asks for the version " .. plan.version .. " or newer")
    -- Setup turns the debug log on, then test settings on, then reloads; the plan asserts both lines at login.
    local setupId = ("cv.s%d.2"):format(plan.first)
    local setup = text:match("\n  %- id: " .. setupId:gsub("%.", "%%.") .. "\n(.-)\n  %- id: ") or text:match("\n  %- id: " .. setupId:gsub("%.", "%%.") .. "\n(.-)\n%- id: ") or ""
    local cDebug, cTest, cReload = setup:find('"/cvn debug on"', 1, true), setup:find('"/cvn testsettings on"', 1, true), setup:find('"/reload"', 1, true)
    eq(cDebug ~= nil and cTest ~= nil and cReload ~= nil and cDebug < cTest and cTest < cReload, true, setupId .. ": debug on, then testsettings on, then /reload")
    local sDebug, sLogin, sTest = setup:find("contains: debug log turned on", 1, true), setup:find('contains: "---- login ----"', 1, true), setup:find('contains: "test settings: on at login"', 1, true)
    eq(sDebug ~= nil and sLogin ~= nil and sTest ~= nil and sDebug < sLogin and sLogin < sTest, true, setupId .. " asserts the debug log, the login marker, then test settings on at login")
    -- The last step is the automatic no-Lua-error check on CheckThat's error list, for the whole run.
    local tail = text:match(".*\n  %- id: [^\n]+\n(.*)$") or ""
    eq(tail:find("source: errors", 1, true) ~= nil and tail:find("absent: true", 1, true) ~= nil, true, plan.path .. " ends with the no-Lua-error step")
    eq(tail:find('"/cvn testsettings off"', 1, true) ~= nil, true, plan.path .. ": the last step runs /cvn testsettings off")
    eq(tail:find("contains: 'test settings: off (own settings restored)'\n      scope: attempt\n", 1, true) ~= nil, true, plan.path .. ": the last step asserts the off line, scoped to the attempt")
    eq(tail:find("timeout: 120", 1, true) ~= nil, true, plan.path .. ": the last step waits for the player to press Run (timeout 120)")
    eq(setup:find("title: Turn on Lua errors, debug logging and test settings, then reload", 1, true) ~= nil, true, setupId .. " is titled for test settings too")
    eq(tail:find("scope: session", 1, true) ~= nil and tail:find("auto: true", 1, true) ~= nil, true, plan.path .. ": the no-Lua-error step is automatic and covers the run")

    -- Assertion-first rules. Every step opens its action with one fixed sentence, and a timeout belongs only to
    -- a step with a required absence (the setup, version and last steps keep theirs).
    local OPENERS = {
        "A question appears. Click Yes.",
        "A question appears. Click No.",
        "Nothing appears. CheckThat checks by itself.",
        "Look, then press Pass or Fail.",
    }
    local all, cur = {}, nil
    for line in (text .. "\n- id: end\n"):gmatch("([^\n]*)\n") do
        local id = line:match("^  %- id: (cv%.s%d+%.%d+)$")
        if id or line:match("^%- id: ") then
            cur = id and { id = id, body = "" } or nil
            if cur then all[#all + 1] = cur end
        elseif cur then
            cur.body = cur.body .. "\n" .. line
        end
    end
    local lastId = all[#all] and all[#all].id
    eq(#all, count, plan.path .. ": the step scan sees every step (" .. #all .. " of " .. count .. ")")
    for _, st in ipairs(all) do
        local actionText = st.body:match("\n    action:\n      kind: manual\n      text: ([^\n]*)") or ""
        actionText = actionText:gsub('^"', ""):gsub("^'", "")
        local ok = false
        for _, o in ipairs(OPENERS) do if actionText:sub(1, #o) == o then ok = true end end
        eq(ok, true, st.id .. ": the action text opens with one of the four fixed sentences: " .. actionText:sub(1, 60))
        if plan.core then
            -- The core plan reads like player steps: the commands sit behind Run, never in the sentence.
            eq(actionText:find("/cvn", 1, true) == nil and actionText:find("|cff", 1, true) == nil, true, st.id .. ": the action text has no slash command or color code: " .. actionText:sub(1, 80))
            -- One ordinary character runs it: no step needs a class, a profession, a dungeon, a fight or another addon.
            local setupText = (st.body:match("\n    setup: ([^\n]*)") or ""):lower()
            for _, word in ipairs({ "hunter", "mage", "warlock", "priest", "warrior", "rogue", "paladin", "shaman", "druid", "death knight",
                                    "profession", "dungeon", "instance", "fight", "combat", "tomtom", "waypointui", "norgannondb", "addon" }) do
                eq(setupText:find(word, 1, true) == nil, true, st.id .. ": the setup does not need '" .. word .. "': " .. setupText)
            end
            -- Only the two waypoint steps differ by client.
            if st.body:find("\n    clients:", 1, true) then
                eq(st.id == "cv.s1.1" or st.id == "cv.s1.2", true, st.id .. ": only the waypoint steps are limited to one client")
            end
        end
        if st.body:find("\n    timeout: ", 1, true) then
            local exempt = st.id:match("^cv%.s%d+%.[12]$") ~= nil and (st.id:match("^cv%.s(%d+)") == tostring(plan.first)) or st.id == lastId
            eq(exempt or st.body:find("absent: true", 1, true) ~= nil, true, st.id .. ": a timeout needs a required absence check")
            eq(st.body:find("\n    auto: true", 1, true) ~= nil, true, st.id .. ": only an automatic step has a timeout")
        end
    end
end

-- Ids of steps that were merged into another or removed stay retired: no plan has them again.
local RETIRED = { "cv.s3.2", "cv.s3.4", "cv.s4.3", "cv.s4.4", "cv.s21.2", "cv.s21.6", "cv.s21.9",
                  -- The core plan became the one-character release gate; these steps moved to unit tests, the
                  -- offline block or a feature plan (openspec change core-release-plan).
                  "cv.s2.2", "cv.s2.3", "cv.s2.6", "cv.s3.1", "cv.s3.3", "cv.s4.1", "cv.s4.2", "cv.s5.1", "cv.s5.2" }
for _, id in ipairs(RETIRED) do
    eq(steps[id], nil, "a retired step id is not used again: " .. id)
end
-- The core plan is exactly the foundation steps: each system that makes the addon work, in the real game.
do
    local want = { "cv.s0.1", "cv.s0.2", "cv.s1.1", "cv.s1.2", "cv.s1.3", "cv.s1.4", "cv.s1.5", "cv.s2.1", "cv.s2.4", "cv.s2.5", "cv.s2.7",
                   "cv.s6.1", "cv.s6.2", "cv.s6.3" }
    local have = {}
    for id in read("plans/closestvendor.yaml"):gmatch("\n  %- id: (cv%.s%d+%.%d+)") do have[#have + 1] = id end
    eq(table.concat(have, " "), table.concat(want, " "), "the core plan holds the foundation steps, in order")
end

-- "test plan check 4.1", "test plan 8.2, 8.3", "test-plan section 20", "manual test plan §7".
local files = {}
p = io.popen("find ClosestVendor tests docs openspec/specs plans README.md DESIGN.md AGENTS.md CONTRIBUTING.md -path ClosestVendor/Libs -prune -o -type f \\( -name '*.lua' -o -name '*.md' -o -name '*.yaml' \\) -print")
for path in p:lines() do
    if path ~= "tests/test_plan.lua" then files[#files + 1] = path end
end
p:close()
eq(#files > 20, true, "the reference scan finds the source files (" .. #files .. ")")

local function refs(text)
    local out = {}
    text = text:lower():gsub("(%d)%s+and%s+(%d)", "%1, %2")
    for nums in text:gmatch("test[%- ]plan%s+[%a\194\167]*%s*([%d][%d%.,%s]*)") do
        for n in nums:gmatch("%d+[%.%d]*") do out[#out + 1] = (n:gsub("%.$", "")) end
    end
    return out
end
local function resolves(n)
    local major, minor = n:match("^(%d+)%.(%d+)$")
    if major then return steps[("cv.s%s.%s"):format(major, minor)] == true, ("cv.s%s.%s"):format(major, minor) end
    return sections["s" .. n] == true, "s" .. n
end

-- The scan itself: each citation form is found, and a citation of a missing step fails.
local seen = refs("see test-plan section 20; test plan check 2.1, 2.3 and 2.4; test plan §7")
eq(table.concat(seen, " "), "20 2.1 2.3 2.4 7", "the scan reads every citation form")
eq((resolves("99.1")), false, "a missing step does not resolve")
eq((resolves("2.1")), true, "a step of the core plan resolves")
eq((resolves("11.3")), false, "a step of a removed plan does not resolve")

for _, path in ipairs(files) do
    for _, n in ipairs(refs(read(path))) do
        local ok, want = resolves(n)
        eq(ok, true, path .. " cites test plan " .. n .. ", which the plans have as " .. want)
    end
end

-- The CheckThat tools run as the installed `ct` (AGENTS.md, CheckThat): no file names a sibling checkout or a hooks file.
local tooling = { "Makefile" }
for _, path in ipairs(files) do
    if path:match("%.md$") or path:match("%.yaml$") then tooling[#tooling + 1] = path end
end
for _, path in ipairs(tooling) do
    local text = read(path)
    for _, bad in ipairs({ "%.%./wow%-checkthat", "replay_plan%.lua", "%.replay%.lua" }) do
        eq(text:find(bad) == nil, true, path .. " points at a CheckThat checkout or hooks file (" .. bad .. ")")
    end
end

H.done()
