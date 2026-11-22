-- One AceConfig tree, backed directly by the existing character configuration.
local _, ns = ...
local L, P = ns.L, ns.Presentation
local O = { APP = "ClosestVendor.Presentation.v1" }
ns.Options = O
local function library(name)
    if not LibStub then return end
    local ok, lib = pcall(function() return LibStub(name, true) end)
    if ok then return lib end
end
function O.Refresh()
    local reg = library("AceConfigRegistry-3.0")
    if reg then pcall(reg.NotifyChange, reg, O.APP) end
end
-- Pages listed under the Closest Vendor entry in the game's AddOns list, in tree order.
O.SUBPAGES = { "restock", "navigation", "appearance", "advanced", "about" }
function O.Register(cfg, defaults, onChange, class, pickColor, note)
    if O.tree then return O.APP end
    local reg, dialog = library("AceConfigRegistry-3.0"), library("AceConfigDialog-3.0")
    if not (reg and dialog and library("AceGUI-3.0")) then
        O.failure = "Required AceConfig/AceGUI libraries unavailable"
        if note then note(O.failure) end
        return
    end
    local pages = {}
    local tree = { type = "group", name = L["Closest Vendor"], childGroups = "tree", args = pages }
    local function page(key, name, order)
        local g = { type = "group", name = name, order = order, args = {} }; pages[key] = g
        return g.args
    end
    -- Six top-level pages; Restock holds Ammo, Reagents and Supplies, and Appearance has a Sound tab.
    local function child(parent, key, name, order)
        local g = { type = "group", name = name, order = order, args = {} }; parent[key] = g
        return g.args
    end
    local home = page("home", L["Home"], 1)
    local restock = page("restock", L["Restock"], 2)
    local ammo = child(restock, "ammo", L["Ammo"], 1)
    local reagents = child(restock, "reagents", L["Reagents"], 2)
    local supplies = child(restock, "supplies", L["Supplies"], 3)
    local nav = page("navigation", L["Navigation"], 3)
    local appearance = page("appearance", L["Appearance"], 4)
    local soundPage = child(appearance, "sound", L["Sound"], 3)
    local advanced = page("advanced", L["Advanced"], 5)
    local about = page("about", L["About"], 6)
    local order = 0
    local function add(dest, key, opt)
        order = order + 1; opt.order = order
        opt.width = opt.width or ((opt.type == "select" or opt.type == "range" or opt.type == "execute") and 1.5 or "full")
        dest[key] = opt; return opt
    end
    local function control(dest, key, name, kind, limits, values, disabled, desc)
        local opt = { name = name, type = kind, desc = desc, disabled = disabled,
            get = function() return cfg[key] end,
            set = function(_, v) cfg[key] = v; onChange(); O.Refresh() end }
        if limits then opt.min, opt.max, opt.step = limits[1], limits[2], 1 end
        if values then opt.values = values end
        return add(dest, key, opt)
    end
    local function public(dest, key, name, disabled)
        local e = P.KEYS[key]
        local opt = { name = name, disabled = disabled, desc = disabled and L["Enable the related warning or On-screen notice to edit this value. Disabled values are retained."] or L["Changes apply to this character immediately."],
            type = e.kind == "boolean" and "toggle" or e.kind == "enum" and "select" or "range",
            get = function() return e.get(cfg) end,
            set = function(_, v) P.Set(cfg, key, v, onChange); O.Refresh() end }
        if e.values then opt.values = { warning = L["Warning"], toast = L["Toast"] } end
        if e.limits then local b = ns.Commands.LIMITS[e.limits]; opt.min, opt.max, opt.step = b[1], b[2], 1 end
        return add(dest, key, opt)
    end
    local function action(dest, key, name, fn)
        return add(dest, key, { type = "execute", name = name, func = fn })
    end
    local function run(command) if O.Run then O.Run(command) end end
    local function toggle(dest, key, name, disabled, desc) return control(dest, key, name, "toggle", nil, nil, disabled, desc) end
    local function range(dest, key, name, limit, disabled)
        return control(dest, key, name, "range", ns.Commands.LIMITS[limit], nil, disabled,
            L["Enable the related warning or buying switch to edit this value. Disabled values are retained."])
    end
    local function select(dest, key, name, values) return control(dest, key, name, "select", nil, values) end
    local function off(key) return function() return cfg[key] == false end end
    toggle(home, "bagEnabled", L["Warn about bag space"])
    public(home, "bags.threshold", L["Free bag slots at or below"], off("bagEnabled"))
    toggle(home, "durEnabled", L["Warn about durability"])
    range(home, "durThreshold", L["Warn below this durability (%)"], "dur", off("durEnabled"))
    toggle(home, "tradeEnabled", L["Warn about profession training"])
    range(home, "tradeThreshold", L["Points below the skill limit"], "trade", off("tradeEnabled"))
    toggle(home, "ammoEnabled", L["Ammo"])
    toggle(home, "reagentsEnabled", L["Reagents"])
    toggle(home, "suppliesEnabled", L["Supplies"])
    range(ammo, "ammoThreshold", L["Warn at this much ammo or less"], "ammo", off("ammoEnabled"))
    toggle(ammo, "ammoBuyEnabled", L["Buy ammo"])
    local noAmmoBuy = function() return not cfg.ammoBuyEnabled end
    toggle(ammo, "ammoBuyPrompt", L["Ask before buying ammo"], noAmmoBuy, L["Enable Buy ammo to edit this value."])
    local grades = { equipped = L["same as equipped"], best = L["best usable"], cheapest = L["cheapest"] }
    select(ammo, "arrowGrade", L["Arrows to buy"], grades).disabled = noAmmoBuy
    select(ammo, "bulletGrade", L["Bullets to buy"], grades).disabled = noAmmoBuy
    range(reagents, "reagentThreshold", L["Count of each reagent at or below"], "reagent", off("reagentsEnabled"))
    local items = ns.Reagents.ForClass(class)
    cfg.reagentOff = cfg.reagentOff or {}
    for _, item in ipairs(items) do
        local id = item.id
        -- The game's name for the item, in the player's language, once it has loaded; English until then.
        add(reagents, "item" .. id, { type = "toggle", name = function() return L["Reagent: %s"]:format(O.itemName and O.itemName(id) or item.name) end,
            disabled = off("reagentsEnabled"), desc = L["Enable Reagents on Home to edit this value."],
            get = function() return not cfg.reagentOff[id] end,
            set = function(_, v) cfg.reagentOff[id] = not v or nil; onChange(); O.Refresh() end })
    end
    local noReagent = function() return #items == 0 end
    toggle(reagents, "reagentBuyEnabled", L["Buy reagents"], noReagent, L["Your class does not use reagents."])
    local noReagentBuy = function() return #items == 0 or not cfg.reagentBuyEnabled end
    toggle(reagents, "reagentBuyPrompt", L["Ask before buying reagents"], noReagentBuy, L["Enable Buy reagents to edit this value; a class reagent is required."])
    range(reagents, "reagentBuyTarget", L["Target count for each reagent"], "reagentBuyTarget", noReagentBuy)
    local function supply(key, name)
        toggle(supplies, key .. "Enabled", name, off("suppliesEnabled"), L["Enable Supplies on Home to edit this value."])
        range(supplies, key .. "Threshold", name, key, function() return cfg.suppliesEnabled == false or cfg[key .. "Enabled"] == false end)
    end
    supply("food", L["Food"])
    if ns.Supplies.UsesMana(class) then supply("water", L["Water"]) end
    if class == "HUNTER" then supply("petFood", L["Pet food"]) end
    if class == "WARLOCK" then toggle(supplies, "healthstoneRemind", L["Healthstone reminder"], off("suppliesEnabled")) end
    -- Built on each open: sound-pack sounds can appear later, and a saved but missing one keeps its name.
    local function sounds()
        local t = {}; for _, s in ipairs(ns.Supplies.SoundList(cfg.remindSound)) do t[s[1]] = s[2] end
        return t
    end
    select(home, "vendorMode", L["Destination on another map"], { ask = L["Ask which one"], auto = L["Navigate without asking"] })
    select(home, "vendorPrefer", L["Preferred target"], { map = L["On your map"], distance = L["Closest"] })
    local providers = {}; for _, p in ipairs(ns.Nav.PROVIDERS) do providers[p[1]] = p[2] end
    select(nav, "navProvider", L["Waypoint"], providers)
    select(nav, "instanceAnchor", L["Search origin in instances"], { hearth = L["Hearthstone location"], last = L["Last outdoor position"] })
    toggle(nav, "ahEnabled", L["Route to the auction house"])
    -- Appearance has three tabs: Notifications (every Toast or Warning), Status window and Sound.
    pages.appearance.childGroups = "tab"
    local notices = {}
    appearance.notices = { type = "group", name = L["Notifications"], order = 1, args = notices }
    toggle(home, "autoNotice", L["On-screen notice"])
    -- Last on Home: a one-time search, not a setting. It saves nothing and runs the same lookup as /cvn find.
    add(home, "findSupplies", { type = "input", name = L["Item name or link"],
        desc = L["Type part of an item name or paste an item link, then press Okay. Nothing is saved."],
        get = function() return "" end,
        set = function(_, v) if type(v) == "string" and v:match("%S") then run("find " .. v) end end })
    public(notices, "appearance.notification-style", L["Style"])
    local sound = select(soundPage, "remindSound", L["Notification sound"], sounds)
    sound.set = function(_, v) cfg.remindSound = v; onChange(); run("sound " .. v) end
    action(notices, "preview", L["Preview"], function() run("preview notice") end)
    local isWarning = function() return cfg.notificationStyle == "warning" end
    add(notices, "warningLook", { type = "description", fontSize = "small", hidden = function() return not isWarning() end,
        name = L["Warning uses the game's large centered text. It has no appearance or position settings."] })
    local function surface(key, name)
        local args, hidden
        if key == "toast" then args, hidden = notices, isWarning
        else args = {}; add(appearance, key, { type = "group", name = name, args = args }).order = 2 end
        local function shown(opt) opt.hidden = hidden; return opt end
        if key == "hud" then public(args, "appearance.hud.locked", L["Lock position"]) end
        shown(public(args, "appearance." .. key .. ".background-opacity", L["Background opacity"], key == "toast" and off("autoNotice") or nil))
        shown(public(args, "appearance." .. key .. ".text-opacity", L["Text and icon opacity"], key == "toast" and off("autoNotice") or nil))
        shown(public(args, "appearance." .. key .. ".scale", L["Scale"], key == "toast" and off("autoNotice") or nil))
        if key == "hud" then action(args, "preview", L["Preview"], function() run("preview hud") end) end
        shown(action(args, "move", L["Move"], function() if O.Move then O.Move(key) end end)).desc = key == "hud" and L["Unlock the position before moving. Done saves; Cancel or Escape restores the starting position."] or L["Move the toast placeholder. Done saves; Cancel or Escape restores the starting position."]
        shown(action(args, "reset", L["Reset position"], function() if O.Reset then O.Reset(key) end end))
        return args
    end
    local hud = surface("hud", L["Status window"])
    if pickColor then
        action(hud, "color", L["Background color"], function()
            local r,g,b = ns.Status.Color(cfg.hudColor)
            pickColor(r or 0,g or 0,b or 0,function(nr,ng,nb) cfg.hudColor = ns.Status.Hex(nr,ng,nb); onChange(); O.Refresh() end)
        end)
    else add(hud, "color", { type = "description", name = L["Color picker unavailable; use /cvn hud color #rrggbb."] }) end
    for _, group in ipairs(ns.Status.GROUPS) do
        local key = group
        local reason = key == "ammo" and not ({ HUNTER=true, WARRIOR=true, ROGUE=true })[class] and L["Your class does not use ammo."] or
            key == "reagents" and #items == 0 and #ns.Reagents.DisplayOnly(class) == 0 and L["Your class does not use reagents."] or nil
        add(hud, "row" .. key, { type = "select", name = L["Show: %s"]:format(ns.Status.KeyName(key)),
            values = { low = L["Only when low"], always = L["Always"], never = L["Never"] },
            disabled = reason ~= nil, desc = reason or L["Choose when this row group is visible."],
            get = function() return ns.Status.Mode(cfg, key) end,
            set = function(_, v) if not reason and ns.Status.MODES[v] then cfg.hudRow = cfg.hudRow or {}; cfg.hudRow[key] = v; onChange(); O.Refresh() end end })
    end
    surface("toast", L["Toast"])
    add(advanced, "scopeInfo", { type = "description", name = L["Settings are saved for this character. Vendors, trainers and auctioneers you learn are shared by your account."] })
    add(advanced, "debug", { type = "toggle", name = L["Record debug information"],
        get = function() return O.DebugEnabled and O.DebugEnabled() or false end,
        set = function(_, v) run(v and "debug on" or "debug off") end })
    action(advanced, "log", L["Show debug report"], function() run("log") end)
    action(advanced, "clear", L["Clear debug report"], function() run("log clear") end)
    -- KeepThat's local visual vocabulary: full rows, neutral body, muted notes and section gaps.
    local function grey(value) return "|cffaaaaaa" .. value .. "|r" end
    local function body(dest, key, value, size)
        return add(dest, key, { type = "description", fontSize = size or "medium", name = value })
    end
    local function section(dest, id, label, first)
        local start = dest[first].order
        dest[id .. "Gap"] = { type = "description", fontSize = "small", width = "full", name = " ", order = start - .4 }
        dest[id] = { type = "header", width = "full", name = label, order = start - .2 }
    end
    local function context(dest, key, value, first)
        dest[key] = { type = "description", fontSize = "small", width = "full", name = grey(value), order = dest[first].order - .1 }
    end
    local function intro(dest, value)
        dest.intro = { type = "description", fontSize = "medium", width = "full", name = "|cffdddddd" .. value .. "|r", order = 0 }
    end
    intro(home, L["Get help finding a vendor or trainer before supplies run out or bags fill up. Start by choosing what to watch; buying and route preferences have their own pages."])
    section(home, "bagsHeading", L["Bag space"], "bagEnabled")
    section(home, "durHeading", L["Durability"], "durEnabled")
    section(home, "tradeHeading", L["Professions"], "tradeEnabled")
    section(home, "featuresHeading", L["Other warnings"], "ammoEnabled")
    intro(ammo, L["Get a vendor recommendation when equipped ammo runs low. Merchant buying is a separate choice: it can refill your quiver or ammo pouch when you open a merchant."])
    if not ({ HUNTER=true, WARRIOR=true, ROGUE=true })[class] then
        ammo.intro.name = "|cffdddddd" .. L["Your class does not use equipped ammo. These settings apply to characters with a bow, crossbow or gun; no ammo warning is generated for this character."] .. "|r"
    end
    section(ammo, "warningHeading", L["Low ammo"], "ammoThreshold")
    section(ammo, "buyingHeading", L["Buying"], "ammoBuyEnabled")
    section(ammo, "gradesHeading", L["Ammo grades"], "arrowGrade")
    intro(reagents, L["Watch the reagents used by your class spells. Choose what to watch, then optionally stock up at merchants; the warning threshold and buying target are separate amounts."])
    section(reagents, "warningHeading", L["Warnings"], "reagentThreshold")
    section(reagents, "buyingHeading", L["Buying"], "reagentBuyEnabled")
    intro(supplies, L["Find a vendor when food, drinks or pet food run low. Only supplies your class uses are listed. These warnings do not buy supplies for you."])
    section(supplies, "foodHeading", L["Food"], "foodEnabled")
    if supplies.waterEnabled then section(supplies, "waterHeading", L["Water"], "waterEnabled") end
    if supplies.petFoodEnabled then section(supplies, "petFoodHeading", L["Pet food"], "petFoodEnabled") end
    if supplies.healthstoneRemind then section(supplies, "healthstoneHeading", L["Healthstone"], "healthstoneRemind") end
    supplies.foodThreshold.name = L["Ask when food is at or below"]
    if supplies.waterThreshold then supplies.waterThreshold.name = L["Ask when water is at or below"] end
    if supplies.petFoodThreshold then supplies.petFoodThreshold.name = L["Ask when pet food is at or below"] end
    intro(nav, L["Choose how a waypoint is set, where searches start inside instances and whether the auction house counts."])
    intro(restock, L["Set the counts that warn you, choose items, and decide whether to buy at merchants. Turn each warning on or off on Home."])
    section(home, "targetHeading", L["Destination choice"], "vendorMode")
    section(home, "noticeHeading", L["Notifications"], "autoNotice")
    section(home, "findHeading", L["Find supplies"], "findSupplies")
    context(home, "findHelp", L["Shows the nearest known sellers of a food, drink, pet food or class reagent item. Vendors are known by category, not by item."], "findSupplies")
    section(nav, "waypointHeading", L["Waypoint"], "navProvider")
    section(nav, "instanceHeading", L["Inside instances"], "instanceAnchor")
    section(nav, "auctionHeading", L["Auction house"], "ahEnabled")
    context(home, "bagsHelp", L["Suggests a vendor when free bag slots reach this limit. Selling items is still up to you."], "bagEnabled")
    context(home, "durHelp", L["Suggests a repair vendor when any equipped item falls below this durability."], "durEnabled")
    context(home, "tradeHelp", L["Suggests a trainer when a known profession is close to its current skill limit and your level allows the next tier."], "tradeEnabled")
    context(home, "featuresHelp", L["These switches control warnings. Set counts, individual items and merchant buying under Restock."], "ammoEnabled")
    context(ammo, "warningHelp", L["Enable Ammo on Home to use this warning. The count follows your equipped ammo; it is not a buying target."], "ammoThreshold")
    context(ammo, "buyingHelp", L["Buys into available quiver or ammo-pouch space when a merchant sells suitable ammo. Leave Ask before buying on to review the count and price; turning it off allows purchases without confirmation."], "ammoBuyEnabled")
    context(ammo, "gradesHelp", L["Same as equipped matches your current ammo. Best usable chooses the highest grade your level allows; Cheapest chooses the lowest price per piece."], "arrowGrade")
    context(reagents, "warningHelp", #items > 0 and L["Enable Reagents on Home to use these warnings. Checked items are watched and included when reagent buying is enabled."] or L["Your class has no vendor-sold reagents to watch or buy. Display-only item counts, when available, are controlled under Appearance, Status window."], "reagentThreshold")
    context(reagents, "buyingHelp", L["Buys checked class reagents up to the amount below, counting what is already in your bags. Zero buys none. Turning off Ask before buying allows purchases without confirmation."], "reagentBuyEnabled")
    context(supplies, "foodHelp", L["Enable Supplies on Home, then choose which supply warnings to use. Counts at or below the chosen amount need attention."], "foodEnabled")
    if supplies.waterEnabled then context(supplies, "waterHelp", L["Counts drinks in your bags. Mages who know the conjure spell are reminded to make water instead of visiting a vendor."], "waterEnabled") end
    if supplies.petFoodEnabled then context(supplies, "petFoodHelp", L["Counts food your current pet can eat. No pet-food warning is shown while your pet is dismissed."], "petFoodEnabled") end
    if supplies.healthstoneRemind then context(supplies, "healthstoneHelp", L["Reminds you to cast Create Healthstone when you know the spell and carry no healthstone."], "healthstoneRemind") end
    if class == "MAGE" then supplies.foodHelp.name = grey(L["Enable Supplies on Home to use food warnings. When you know Conjure Food, a low count reminds you to make food instead of visiting a vendor."]) end
    context(home, "targetHelp", L["When a closer destination is on another map, Ask lets you choose. Navigate without asking uses your preference: On your map or Closest by distance."], "vendorMode")
    context(nav, "waypointHelp", L["Automatic tries TomTom, then WaypointUI, then the game waypoint. If your selected method is unavailable, the usual fallback order is used."], "navProvider")
    context(nav, "instanceHelp", L["A status-window row click inside a dungeon or raid searches from your hearthstone location or last outdoor position. Automatic questions are suppressed inside instances."], "instanceAnchor")
    context(nav, "auctionHelp", L["A row click for tradable ammo or reagents can choose a closer auction house. The row sets a route; it does not place an auction order."], "ahEnabled")
    intro(appearance, L["Choose how notifications look and sound, and how the status window looks."])
    intro(notices, L["Every route, reminder and test message is a notification. It shows in the style you choose and plays the sound you choose."])
    section(notices, "noticeHeading", L["Notifications"], "appearance.notification-style")
    section(notices, "toastHeading", L["Toast"], "appearance.toast.background-opacity")
    notices.toastHeading.hidden, notices.toastHeadingGap.hidden = isWarning, isWarning
    intro(hud, L["Keep useful counts and warnings on screen. Click a routable row to navigate, or choose below when each group of rows should appear."])
    section(hud, "positionHeading", L["Position"], "appearance.hud.locked")
    section(hud, "lookHeading", L["Appearance"], "appearance.hud.background-opacity")
    section(hud, "actionHeading", L["Preview and position"], "preview")
    section(hud, "rowsHeading", L["Row visibility"], "row" .. ns.Status.GROUPS[1])
    section(advanced, "scopeHeading", L["Settings scope"], "scopeInfo")
    section(advanced, "debugHeading", L["Debug"], "debug")
    context(home, "noticeHelp", L["Turn On-screen notice off to keep only the chat line. Choose the style and sound under Appearance."], "autoNotice")
    context(notices, "styleHelp", L["Turn notifications on or off on Home. Set the sound on the Sound tab. Preview does not change your settings."], "appearance.notification-style")
    intro(soundPage, L["Choose the sound that plays with every notification. Choosing a sound plays it; None is silent."])
    context(soundPage, "soundHelp", L["Routes, class reminders and test messages all use this sound. No sound plays while On-screen notice is off. Questions play no notification sound."], "remindSound")
    context(notices, "toastHelp", L["Move shows a placeholder. Select Done to save. Select Cancel or press Escape to discard changes. Reset position changes only the position."], "appearance.toast.background-opacity")
    notices.toastHelp.hidden = isWarning
    context(hud, "positionHelp", L["Lock position blocks Move, title dragging and Shift-dragging. Unlock to move; Done saves, while Cancel or Escape restores the starting position."], "appearance.hud.locked")
    context(hud, "lookHelp", L["Background and text dim independently. Background opacity zero removes the fill; black is the default color. Scale changes the window size."], "appearance.hud.background-opacity")
    context(hud, "actionHelp", L["Preview shows sample rows. Move shows a placeholder even when no live rows are visible. Reset position keeps your colors, opacity, scale and row choices."], "preview")
    context(hud, "rowsHelp", L["Only when low shows rows needing attention; Always also shows normal counts; Never hides the group. Rows unavailable to your class are disabled with an explanation."], "row" .. ns.Status.GROUPS[1])
    intro(advanced, L["Use this page to understand where settings are saved or collect information when something goes wrong. You do not need debug recording for normal play."])
    context(advanced, "debugHelp", L["Turn recording on, repeat the problem, then open the report to copy it. Clearing asks for confirmation and removes diagnostic entries only; settings and learned places are kept."], "debug")
    body(about, "title", L["Closest Vendor"], "large")
    body(about, "version", function() return grey(L["Version %s"]:format(tostring(O.Version and O.Version() or "?"))) end, "small")
    body(about, "gap0", " ", "small")
    body(about, "purpose", L["Finds nearby vendors, trainers and supplies when you need them."])
    local function ink(args)
        for _, opt in pairs(args) do
            if opt.type == "description" then
                opt.fontSize = opt.fontSize or "medium"
                if type(opt.name) == "string" and opt.name ~= " " and not opt.name:find("^|c") then opt.name = "|cffdddddd" .. opt.name .. "|r" end
            end
            if opt.args then ink(opt.args) end
        end
    end
    ink(pages)
    local ok, err = pcall(reg.RegisterOptionsTable, reg, O.APP, tree)
    if not ok then O.failure = tostring(err); if note then note(O.failure) end; return end
    O.tree = tree
    -- Match KeepThat's initial size; Ace retains manual resizing between opens.
    if dialog.SetDefaultSize then pcall(dialog.SetDefaultSize, dialog, O.APP, 600, 460) end
    -- The game's AddOns list, as in KeepThat: the Closest Vendor entry shows Home and every other
    -- top-level page is listed under it. Optional native registration must never prevent the
    -- standalone tree from opening.
    local registered, why = pcall(function()
        dialog:AddToBlizOptions(O.APP, L["Closest Vendor"], nil, "home")
        for _, key in ipairs(O.SUBPAGES) do
            dialog:AddToBlizOptions(O.APP, pages[key].name, L["Closest Vendor"], key)
        end
    end)
    if note then note(registered and "AceConfig registered; standalone settings available" or "AceConfig standalone only: " .. tostring(why)) end
    return O.APP
end
-- Where a page name lives in the tree.
O.PATHS = { ammo = { "restock", "ammo" }, reagents = { "restock", "reagents" }, supplies = { "restock", "supplies" },
    sound = { "appearance", "sound" }, notifications = { "appearance", "notices" }, ["status-window"] = { "appearance", "hud" } }
function O.Open(_, page)
    local dialog = library("AceConfigDialog-3.0")
    if not (O.tree and dialog) then return false, O.failure end
    local ok = pcall(function() dialog:Open(O.APP); dialog:SelectGroup(O.APP, unpack(O.PATHS[page or "home"] or { page or "home" })) end)
    return ok
end
