-- Usage (from the project root): luajit tests/run.lua [pattern]
-- Runs every tests/test_*.lua whose name contains the optional pattern, each in its own
-- process so tests cannot leak state into each other. Prints failures in full, a summary,
-- and exits non-zero if anything failed.
local pattern = arg and arg[1]

local files = {}
local ls = io.popen("ls tests/test_*.lua 2>/dev/null")
for line in ls:lines() do
    if not pattern or line:find(pattern, 1, true) then files[#files + 1] = line end
end
ls:close()

if #files == 0 then
    print("no tests match" .. (pattern and (" '" .. pattern .. "'") or ""))
    os.exit(1)
end

local failed = {}
for _, file in ipairs(files) do
    local p = io.popen("luajit " .. file .. " 2>&1; echo EXIT:$?")
    local out = p:read("*a")
    p:close()
    local code = tonumber(out:match("EXIT:(%d+)%s*$"))
    out = out:gsub("EXIT:%d+%s*$", ""):gsub("%s+$", "")
    local name = file:match("[^/]+$")
    if code == 0 then
        print(("ok    %-24s %s"):format(name, out:match("[^\n]*$")))
    else
        print(("FAIL  %s"):format(name))
        print((out:gsub("[^\n]*\n?", "      %0")))
        failed[#failed + 1] = name
    end
end

print(("\n%d test file(s), %d failed"):format(#files, #failed))
os.exit(#failed == 0 and 0 or 1)
