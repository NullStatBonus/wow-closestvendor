-- The in-game test plan (plans/closestvendor.yaml) keeps its numbers in order, and every reference to a
-- check in the code, tests and docs names a step or section the plan has (AGENTS.md, CheckThat).
-- The plan is read with patterns: CI has no YAML library and no CheckThat. Sections start at s0. Ids may
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

local plan = read("plans/closestvendor.yaml")
eq(plan:match("\naddon: (%S+)"), "ClosestVendor", "the plan is ClosestVendor's")

-- Sections are "- id: s<N>" at the top level; steps are "  - id: cv.s<N>.<M>" inside them.
local sections, steps, order = {}, {}, {}
local section, lastStep = -1, 0
for line in (plan .. "\n"):gmatch("([^\n]*)\n") do
    local s = line:match("^%- id: (%S+)$")
    if s then
        eq(sections[s], nil, "section id is unique: " .. s)
        sections[s] = true
        order[#order + 1] = s
        local n = tonumber(s:match("^s(%d+)$"))
        eq(n ~= nil and n > section, true, "sections are numbered in increasing order: " .. s)
        section, lastStep = n or section, 0
    end
    local id = line:match("^  %- id: (%S+)$")
    if id then
        eq(steps[id], nil, "step id is unique: " .. id)
        steps[id] = true
        local sec, n = id:match("^cv%.s(%d+)%.(%d+)$")
        eq(tonumber(sec), section, "a step's id names its section: " .. id)
        eq(n ~= nil and tonumber(n) > lastStep, true, "steps are numbered in increasing order within their section: " .. id)
        lastStep = tonumber(n) or lastStep
    end
end
eq(order[1], "s0", "the plan starts with the setup section")
eq(#order >= 30, true, "the plan has its sections (" .. #order .. ")")
eq(steps["cv.s0.1"], true, "the version step is first")
-- The version step calls the version entry and needs it at least at the version under test (op: ge).
local first = plan:match("\n  %- id: cv%.s0%.1\n(.-)\n  %- id: ")
eq(first ~= nil, true, "cv.s0.1 has a body")
eq((first or ""):find("\n      entry: version\n", 1, true) ~= nil, true, "cv.s0.1 calls the version entry")
eq((first or ""):find("key: entry.version", 1, true) ~= nil, true, "cv.s0.1 asserts the entry.version fact")
eq((first or ""):find("op: ge", 1, true) ~= nil, true, "cv.s0.1 passes at the version under test or newer")

-- "test plan check 4.1", "test plan 8.2, 8.3", "test-plan section 20", "manual test plan §7".
local files = {}
local p = io.popen("find ClosestVendor tests docs openspec/specs plans README.md DESIGN.md AGENTS.md CONTRIBUTING.md -path ClosestVendor/Libs -prune -o -type f \\( -name '*.lua' -o -name '*.md' -o -name '*.yaml' \\) -print")
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

for _, path in ipairs(files) do
    for _, n in ipairs(refs(read(path))) do
        local ok, want = resolves(n)
        eq(ok, true, path .. " cites test plan " .. n .. ", which the plan has as " .. want)
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
