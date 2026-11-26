-- Loads the real Tracker.lua against fake frames and drives it with clicks and drags.
package.path = "tests/?.lua;" .. package.path
local H = require("harness")
local eq = H.eq

-- A fake game: frames record what the window needs to be checked on and ignore every other call.
local function boot(opts)
    opts = opts or {}
    local g = { frames = {}, shift = false, went = {}, opened = 0, cfg = opts.cfg or { hudLocked = false, hudScale = 100, hudAlpha = 80 },
        pos = opts.pos or {} }
    local function newFrame(kind, name)
        local f = { kind = kind, name = name, scripts = {}, shown = true, points = {} }
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:SetText(t) self.textValue = t end
        function f:SetTextColor(r, gr, b) self.color = r .. "," .. gr .. "," .. b end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:IsShown() return self.shown end
        function f:SetSize(w, h) self.w, self.h = w, h end
        function f:SetScale(s) self.scale = s end
        function f:SetColorTexture(r, gr, b, a) self.rgb, self.alpha = r .. "," .. gr .. "," .. b, a end
        function f:SetAlpha(a) self.opacity = a end
        function f:SetTexture(t) self.texture = t end
        function f:GetTexture() if opts.noCog then return nil end return self.texture end
        function f:ClearAllPoints() self.points = {} end
        function f:SetPoint(point, a, b, c, d)
            if type(a) == "table" then self.points[#self.points + 1] = { point, b, c, d }
            else self.points[#self.points + 1] = { point, point, a, b } end
        end
        function f:GetPoint(i) local p = self.points[i]; if p then return p[1], nil, p[2], p[3], p[4] end end
        function f:SetClampedToScreen(on) self.clamped = on end
        function f:SetMovable(on) self.movable = on end
        function f:RegisterForDrag(button) self.drag = button end
        function f:StartMoving() g.moves = (g.moves or 0) + 1; self.isMoving = true end
        function f:StopMovingOrSizing()
            self.isMoving = false
            self.points = { { "TOPLEFT", "TOPLEFT", 321, -123 } } -- where the game says it was dropped
        end
        function f:CreateTexture() local t = newFrame("Texture"); self.textures = self.textures or {}; self.textures[#self.textures + 1] = t; return t end
        function f:CreateFontString() return newFrame("FontString") end
        function f:GetStringWidth() return opts.textWidth end
        return setmetatable(f, { __index = function(_, k) if k:match("^%u") then return function() end end end })
    end
    g.tip = { text = nil, owner = nil, shown = false }
    local tip = {}
    function tip:SetOwner(o) g.tip.owner = o end
    function tip:SetText(t) g.tip.text = t end
    function tip:Show() g.tip.shown = true end
    function tip:Hide() g.tip.shown = false end
    local env = setmetatable({
        UIParent = {}, GameTooltip = tip,
        CreateFrame = function(kind, name)
            if opts.frameThrows then error("no frames today", 0) end
            local f = newFrame(kind, name)
            g.frames[#g.frames + 1] = f
            return f
        end,
    }, { __index = _G })
    local ns = {}
    H.locale(ns)
    for _, file in ipairs({ "Status", "Presentation", "Move", "Tracker" }) do
        local chunk = assert(loadfile("ClosestVendor/" .. file .. ".lua"))
        setfenv(chunk, env)
        chunk("ClosestVendor", ns)
    end
    g.ns = ns
    g.new = function()
        return ns.Tracker.New({ cfg = g.cfg, pos = g.pos,
            choiceTitle = (not opts.noChoice) and function(row) return g.titles and g.titles[row.key] end or nil,
            choose = function(row, anchor) g.chosen = { row = row, anchor = anchor } end,
            go = function(row) g.went[#g.went + 1] = row.key end,
            openSettings = function() g.opened = g.opened + 1 end,
            shiftDown = function() return g.shift end,
            moveEnded = function() g.moveEnded = (g.moveEnded or 0) + 1 end })
    end
    return g
end

local ROWS = {
    { key = "ammo", kind = "ammo", text = "Arrows: 50", low = true, routable = true },
    { key = "bags", kind = "sell", text = "Bag space: 10 free", low = false, routable = true },
    { key = "reagent:6265", kind = "reagent", id = 6265, text = "Soul Shards: 3", low = false, routable = false },
}

-- Built hidden, named, clamped to the screen, with a plain background.
local g = boot()
local t = g.new()
local f = t.frame
eq(f.name, "ClosestVendorTracker", "the window frame")
eq(f.shown, false, "hidden until there is a row")
eq(f.clamped, true, "stays on screen")
eq(f.movable, true, "can be moved")
eq(f.textures[1].alpha, 0.8, "background opacity from the settings (percent)")
eq(f.textures[1].rgb, "0,0,0", "the background is pure black unless the player chose a colour")
eq(f.textures[1].shown, true, "and it is drawn")
eq(#f.textures, 1, "the background is the only texture of the window: no border, no other fill")
eq(t.title.opacity .. "/" .. t.cog.opacity, "1/1", "text and icons are fully solid by default")
eq(f.scale, 1, "scale from the settings (percent)")
eq(f.points[1][1] .. ":" .. f.points[1][3] .. ":" .. f.points[1][4], "LEFT:60:60", "default position")
eq(t.title.text.textValue, "Closest Vendor", "title text")

-- Rows are drawn, low ones marked, and the window shows.
t.Show(ROWS)
local b = t.Buttons()
eq(f.shown, true, "shown with rows")
eq(#b, 3, "one line per row")
eq(b[1].text.textValue .. "|" .. b[2].text.textValue, "Low: Arrows: 50|Bag space: 10 free", "row texts")
eq(b[1].text.color, "1,0.25,0.25", "a low row is red")
eq(b[2].text.color, "0.867,0.867,0.867", "a row that is not low has neutral ink")
eq(b[2].text.color, b[3].text.color, "rows that are not low look alike")
eq(tostring(b[1].textures) .. "/" .. tostring(b[1].text.textures), "nil/nil", "a low row is marked by its text colour only, not by a filled block")
local tall = f.h
-- Fewer rows: the extra lines go, the window shrinks; none: hidden.
t.Show({ ROWS[2] })
eq(b[1].text.textValue, "Bag space: 10 free", "lines are reused")
eq(tostring(b[1].shown) .. "/" .. tostring(b[2].shown) .. "/" .. tostring(b[3].shown), "true/false/false", "unused lines hidden")
eq(f.h < tall, true, "window shrinks")
t.Show({})
eq(f.shown, false, "no rows: no window")
t.Show(ROWS)
eq(f.shown, true, "back again")
-- Wide text widens the window.
local wide = boot({ textWidth = 400 })
local tw = wide.new(); tw.Show(ROWS)
eq(tw.frame.w > f.w, true, "the window fits its longest line")

-- Clicks: a routable row goes, a display-only row does nothing.
b[1].scripts.OnClick()
eq(table.concat(g.went, ","), "ammo", "click on a routable row is forwarded")
b[3].scripts.OnClick()
eq(table.concat(g.went, ","), "ammo", "click on a display-only row does nothing")
b[2].scripts.OnClick()
eq(table.concat(g.went, ","), "ammo,bags", "each line forwards its own row")
t.Show({ ROWS[2] })
b[2].scripts.OnClick()
eq(#g.went, 2, "a hidden line has no row to forward")
t.Show(ROWS)

-- The cog opens the settings.
eq(t.cog.textures[1].texture ~= nil, true, "cog has its texture")
eq(t.cog.text, nil, "no text mark while the texture loads")
t.cog.scripts.OnClick()
eq(g.opened, 1, "cog opens the settings page")
local nocog = boot({ noCog = true }).new()
eq(nocog.cog.text.textValue, "*", "no texture: a plain mark instead")

-- Moving: the title drags by itself and the position is saved.
eq(t.title.drag, "LeftButton", "title is draggable")
t.title.scripts.OnDragStart()
eq(g.moves, 1, "dragging the title moves the window")
t.title.scripts.OnDragStop()
eq(g.pos.point .. ":" .. g.pos.relPoint .. ":" .. g.pos.x .. ":" .. g.pos.y, "TOPLEFT:TOPLEFT:321:-123", "position saved when the drag ends")
-- Anywhere else needs Shift.
b[1].scripts.OnDragStart()
f.scripts.OnDragStart()
eq(g.moves, 1, "dragging a row or the body without Shift does nothing")
g.shift = true
b[1].scripts.OnDragStart()
eq(g.moves, 2, "Shift-drag on a row moves the window")
b[1].scripts.OnClick()
eq(#g.went, 2, "the click that ends a move is not a row click")
b[1].scripts.OnDragStop()
f.scripts.OnDragStart(); f.scripts.OnDragStop()
eq(g.moves, 3, "Shift-drag on the body moves the window")
b[1].scripts.OnClick()
eq(#g.went, 2, "Shift-click on an unlocked window is the move gesture, not a row click")
g.shift = false
-- A stop without a start saves nothing.
g.pos.x = 1
t.title.scripts.OnDragStop()
eq(g.pos.x, 1, "no move in progress: position untouched")

-- Locked: neither the title nor Shift-drag moves it; clicks still work.
g.cfg.hudLocked = true
t.title.scripts.OnDragStart()
g.shift = true
b[1].scripts.OnDragStart()
f.scripts.OnDragStart()
eq(g.moves, 3, "locked: no dragging at all, Shift-drag included")
b[1].scripts.OnClick()
eq(#g.went, 3, "locked: a click goes even with Shift held")
g.shift, g.cfg.hudLocked = false, false

-- A saved position is restored, and Reset returns to the default.
local g2 = boot({ pos = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 10, y = -20 }, cfg = { hudScale = 150, hudAlpha = 40 } })
local t2 = g2.new()
local p = t2.frame.points[1]
eq(p[1] .. ":" .. p[2] .. ":" .. p[3] .. ":" .. p[4], "TOPLEFT:TOPLEFT:10:-20", "saved position restored")
eq(t2.frame.scale, 1.5, "scale 150 is 1.5 times")
eq(t2.frame.textures[1].alpha, 0.4, "opacity 40 percent")
t2.Reset()
eq(next(g2.pos), nil, "reset forgets the saved position")
eq(t2.frame.points[1][1] .. ":" .. t2.frame.points[1][3], "LEFT:60", "and the window is back at the default")
-- Apply picks up changed settings; out-of-range and missing values are held to the limits.
g2.cfg.hudScale = 75; t2.Apply()
eq(t2.frame.scale, 0.75, "new scale applied")
g2.cfg.hudScale = 1000; t2.Apply()
eq(t2.frame.scale, 2, "scale held to 200 percent")
g2.cfg.hudScale, g2.cfg.hudAlpha = nil, nil; t2.Apply()
eq(t2.frame.scale .. "/" .. t2.frame.textures[1].alpha, "1/0.8", "missing settings use the defaults")

-- Opacity. Background 0: nothing is drawn behind the text (no fill, no border, no texture).
local go = boot({ cfg = { hudAlpha = 0, hudTextAlpha = 50 } })
local to = go.new()
to.Show({ ROWS[1] })
local bo = to.Buttons()
eq(to.frame.textures[1].shown, false, "background 0: the background is not drawn")
eq(to.frame.textures[1].alpha, nil, "and is not even coloured")
eq(#to.frame.textures, 1, "and there is nothing else behind the text")
eq(to.frame.shown, true, "the window itself still shows its lines")
-- Text opacity dims the title, the cog (icon) and every line, also lines made after Apply.
eq(to.title.opacity .. "/" .. to.cog.opacity .. "/" .. bo[1].opacity, "0.5/0.5/0.5", "text opacity applies to the title, the cog and a line")
eq(to.frame.opacity, nil, "the window as a whole is not dimmed: the background has its own opacity")
to.Show(ROWS)
eq(bo[3].opacity, 0.5, "a line added later has the text opacity too")
go.cfg.hudAlpha, go.cfg.hudTextAlpha = 1, 75; to.Apply()
eq(to.frame.textures[1].shown, true, "above 0 the background is drawn again")
eq(to.frame.textures[1].rgb .. "/" .. to.frame.textures[1].alpha, "0,0,0/0.01", "pure black at 1 percent")
eq(to.title.opacity .. "/" .. to.cog.opacity .. "/" .. bo[1].opacity .. "/" .. bo[3].opacity, "0.75/0.75/0.75/0.75", "a new text opacity reaches every line")
go.cfg.hudAlpha, go.cfg.hudTextAlpha = -5, 5; to.Apply()
eq(to.frame.textures[1].shown, false, "below 0 is 0: not drawn")
eq(to.title.opacity, 0.2, "text opacity is held to 20 percent, so the window can always be read")
go.cfg.hudAlpha, go.cfg.hudTextAlpha = 500, 500; to.Apply()
eq(to.frame.textures[1].alpha .. "/" .. bo[1].opacity, "1/1", "both are held to 100 percent")
go.cfg.hudAlpha, go.cfg.hudTextAlpha = nil, nil; to.Apply()
eq(to.frame.textures[1].alpha .. "/" .. to.cog.opacity, "0.8/1", "missing settings use the defaults")
-- Background colour: the player's choice, with the opacity from the other setting; black otherwise.
go.cfg.hudColor, go.cfg.hudAlpha = "ff0080", 50; to.Apply()
eq(to.frame.textures[1].rgb .. "/" .. to.frame.textures[1].alpha, "1," .. 0 .. "," .. (128 / 255) .. "/0.5", "the chosen colour at the chosen opacity")
for _, bad in ipairs({ "red", "12345", "#000000", 7, false }) do
    go.cfg.hudColor = bad; to.Apply()
    eq(to.frame.textures[1].rgb, "0,0,0", "not a colour (" .. tostring(bad) .. "): black")
end
go.cfg.hudColor, go.cfg.hudAlpha = "ffffff", 0; to.Apply()
eq(to.frame.textures[1].shown, false, "background 0 draws nothing, whatever the colour")
eq(to.frame.textures[1].rgb, "0,0,0", "and the colour is not even set")

-- Demo: made-up rows are drawn in place of the real ones, clicks on them go nowhere, and the real
-- rows (the latest given meanwhile) come back when it ends.
local gd = boot()
local td = gd.new()
td.Show({ ROWS[2] })
local bd = td.Buttons()
td.Demo({ ROWS[1], ROWS[3] })
eq(bd[1].text.textValue .. "|" .. bd[2].text.textValue, "Low: Arrows: 50|Soul Shards: 3", "demo rows replace the real ones")
td.Show({ ROWS[2], ROWS[1] })
eq(bd[1].text.textValue, "Low: Arrows: 50", "a redraw during the demo does not show the real rows")
bd[1].scripts.OnClick()
eq(#gd.went, 1, "a click on a demo row is passed on: it ends the demo and routes")
td.Demo(nil)
eq(bd[1].text.textValue .. "|" .. bd[2].text.textValue, "Bag space: 10 free|Low: Arrows: 50", "demo over: the latest real rows are drawn")
bd[1].scripts.OnClick()
eq(table.concat(gd.went, ","), "ammo,bags", "and real rows route as usual")
td.Show({})
td.Demo({ ROWS[1] })
eq(td.frame.shown, true, "a demo shows the window even when the real one is hidden")
td.Demo(nil)
eq(td.frame.shown, false, "and it is hidden again afterwards")

-- Chevron: shown only on a routable row with alternatives, never during a demo.
local gc = boot({ textWidth = 200 })
local tc = gc.new()
gc.titles = { ammo = "Other repair vendors" }
tc.Show(ROWS)
local bc = tc.Buttons()
eq(bc[1].more.shown, true, "chevron shown when choiceTitle gives a title")
eq(tostring(bc[2].more.shown) .. "/" .. tostring(bc[3].more.shown), "false/false", "no chevron when choiceTitle is nil or the row is not routable")
gc.titles["reagent:6265"] = "Other vendors"
tc.Show(ROWS)
eq(bc[3].more.shown, false, "a non-routable row never gets a chevron")
gc.titles["reagent:6265"] = nil
local withChev = tc.frame.w
tc.Show({ ROWS[2] })
eq(withChev - tc.frame.w, 14, "the window is wider by the chevron width when one shows")
eq(bc[1].more.shown, false, "hidden once the row has no alternatives")
tc.Show(ROWS)
eq(bc[1].more.opacity == nil or bc[1].more.opacity == 1, true, "chevron is a child of the row (dims with it)")
eq(#bc[1].more.textures, 1, "chevron has only its arrow texture: no fill")
eq(bc[1].more.drag, nil, "chevron is not draggable")
eq(bc[1].more.text, nil, "arrow texture loads: no text mark")
local nc = boot({ noCog = true }); nc.titles = { ammo = "T" }
local tn = nc.new(); tn.Show(ROWS)
eq(tn.Buttons()[1].more.text.textValue, ">", "no texture: a > mark instead")
local nochoice = boot({ noChoice = true }); nochoice.titles = { ammo = "T" }
local tnc = nochoice.new(); tnc.Show(ROWS)
eq(tnc.Buttons()[1].more.shown, false, "no env.choiceTitle: no chevrons")
tc.Demo({ ROWS[1] })
eq(bc[1].more.shown, false, "no chevron while demo rows are drawn")
tc.Demo(nil)
eq(bc[1].more.shown, true, "and it is back after the demo")
-- Tooltip.
bc[1].more.scripts.OnEnter()
eq(gc.tip.text .. "/" .. tostring(gc.tip.owner == bc[1].more) .. "/" .. tostring(gc.tip.shown), "Other repair vendors/true/true", "tooltip shows the title, owned by the chevron")
bc[1].more.scripts.OnLeave()
eq(gc.tip.shown, false, "leaving hides the tooltip")
-- Click.
gc.cfg.hudLocked = true
bc[1].more.scripts.OnClick()
eq(gc.chosen.row == ROWS[1] and gc.chosen.anchor == bc[1].more, true, "click calls choose with the row and the chevron")
eq(#gc.went, 0, "and does not go to the vendor")
gc.chosen = nil
gc.cfg.hudLocked = false; gc.shift = true
bc[1].more.scripts.OnClick()
eq(gc.chosen, nil, "Shift on an unlocked window is the move gesture: nothing")
gc.shift = false
gc.shift = true; bc[1].scripts.OnDragStart(); gc.shift = false
bc[1].more.scripts.OnClick()
eq(gc.chosen, nil, "while moving: nothing")
bc[1].scripts.OnDragStop()
bc[1].more.scripts.OnClick()
eq(gc.chosen ~= nil, true, "after the move ends, it works again")
gc.chosen = nil
tc.Move.Begin()
bc[1].more.scripts.OnClick()
eq(gc.chosen, nil, "during a Move transaction: nothing")
tc.Move.Cancel()

-- No frames on this client: New fails cleanly for the caller's pcall.
local broken = boot({ frameThrows = true })
eq(pcall(broken.new), false, "frame creation failing is an error the caller catches")

-- Deliberate Move does not write tentative drags; Escape uses the same Cancel callback.
g = boot({pos={point="LEFT",x=12,y=34}});t=g.new();t.Show(ROWS)
eq(t.Move.Begin(),true,"Move begins unlocked")
t.title.scripts.OnDragStart();t.title.scripts.OnDragStop()
eq(g.pos.x,12,"tentative drag not persisted")
t.Move.Cancel();eq(g.pos.x,12,"Cancel retains stored position")
eq(t.frame.points[1][3],12,"Cancel restores live anchor")
t.Move.Begin();t.title.scripts.OnDragStart();t.title.scripts.OnDragStop();t.Move.Done()
eq(g.pos.x,321,"Done saves dropped x");eq(g.pos.y,-123,"Done saves dropped y")
g.cfg.hudLocked=true;eq(t.Move.Begin(),false,"lock blocks Move")
g.cfg.hudLocked=false;t.Move.Begin();g.cfg.hudLocked=true;t.Apply()
eq(t.Move.active,false,"locking while moving cancels")
-- Move ending (Done or Cancel) tells the owner, so it can log the real rows again.
g.cfg.hudLocked=false;g.moveEnded=0;t.Move.Begin();t.Move.Done();eq(g.moveEnded,1,"Done calls moveEnded")
t.Move.Begin();t.Move.Cancel();eq(g.moveEnded,2,"Cancel calls moveEnded")
t.Move.Cancel();eq(g.moveEnded,2,"Cancel with no Move running does not call it")
local alpha=g.cfg.hudAlpha;local scale=g.cfg.hudScale;t.Reset()
eq(g.cfg.hudAlpha,alpha,"Reset preserves opacity");eq(g.cfg.hudScale,scale,"Reset preserves scale")

-- Shown and Demoing: whether the frame is on screen, as the frame says, and whether made-up rows are drawn.
do
    local gs = boot()
    local ts = gs.new()
    eq(ts.Shown(), false, "Shown: hidden before any row")
    ts.Show(ROWS)
    eq(ts.Shown(), true, "Shown: the rows are drawn")
    eq(ts.Demoing(), false, "Demoing: the real rows")
    ts.Demo({ ROWS[1] })
    eq(ts.Demoing(), true, "Demoing: made-up rows drawn")
    ts.Demo(nil)
    eq(ts.Demoing(), false, "Demoing: ended")
    ts.Show({})
    eq(ts.Shown(), false, "Shown: no rows, hidden")
    -- A failed read is unknown (nil), never "hidden".
    for _, f in ipairs(gs.frames) do
        if f.name == "ClosestVendorTracker" then f.IsShown = function() error("no read", 0) end end
    end
    eq(ts.Shown(), nil, "Shown: nil when the game cannot tell")
end

H.done()
