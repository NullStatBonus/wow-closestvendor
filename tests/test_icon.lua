package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

-- The AddOns list icon: both TOCs name the same file, which ships in the addon folder as a
-- square, power-of-two, 32-bit TGA with alpha (what the game can load).
local function iconOf(name)
    for line in io.lines("ClosestVendor/ClosestVendor_" .. name .. ".toc") do
        local path = line:gsub("\r", ""):match("^## IconTexture:%s*(.-)%s*$")
        if path then return path end
    end
end
local icon = iconOf("Vanilla")
eq(icon, "Interface\\AddOns\\ClosestVendor\\Media\\icon.tga", "Classic Era TOC names the icon")
eq(iconOf("Camelot"), icon, "WoW Forever TOC names the same icon")
local file = icon and io.open((icon:gsub("^Interface\\AddOns\\", ""):gsub("\\", "/")), "rb")
eq(file ~= nil, true, "the icon file ships in the addon folder")
if file then
    local h = file:read(18); file:close()
    local w, hgt = h:byte(13) + h:byte(14) * 256, h:byte(15) + h:byte(16) * 256
    eq(h:byte(3), 2, "uncompressed truecolor TGA")
    eq(w == hgt and (w == 64 or w == 128 or w == 256), true, "square, power of two")
    eq(h:byte(17), 32, "32 bits per pixel")
    eq(h:byte(18) % 16, 8, "with an 8-bit alpha channel")
end

H.done()
