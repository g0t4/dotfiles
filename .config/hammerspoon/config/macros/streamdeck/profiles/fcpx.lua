local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local verbose = require("config.macros.streamdeck.helpers").verbose
local MenuButton = require("config.macros.streamdeck.menuButton")
local LuaButton = require("config.macros.streamdeck.luaButton")



function menu(menu)
    return function()
        selectMenuItemWithFailureTroubleshooting(menu)
    end
end

local FcpxObserver = AppObserver:new("Final Cut Pro")

FcpxObserver:addProfile("2XL", function(_, deck)
    return {
        MaestroButton:new(1, deck, hsIcon("fcpx/commands/customize-command-sets.png"), "E5D823AF-6720-4228-940B-C7FC472CBBE5"),
        MaestroButton:new(6, deck, hsIcon("fcpx/viewer/disable-captions.png"), "CE9D34A3-348C-457D-BFB9-65908EF3A25B"),
        MaestroButton:new(7, deck, hsIcon("fcpx/viewer/dual-screen.png"), "7967644C-59AE-4AB5-A65F-6EE7D29B9E4C"),
        MaestroButton:new(8, deck, hsIcon("fcpx/viewer/single-screen.png"), "2D134D9A-EABB-4658-A745-27228C12FF94"),


        LuaButton:new(25, deck, drawTextIcon("Save\nCurrent\nFrame", deck), menu({ "File", "Share", "Save Current Frame…" })),
        LuaButton:new(26, deck, drawTextIcon("Save\n4K", deck), menu({ "File", "Share", "Apple Devices 4K…" })),
        MaestroButton:new(27, deck, drawTextIcon("Delete GEN'D", deck), "B8053FBF-6B8D-4679-A3AA-81A6DFA65A36"), -- Delete Generated/Preview assets
    }
end)

FcpxObserver:addProfile("3XL", function(_, deck)
    -- local macro = "'Titles - Add wes-arrows-* (Parameterized)'"
    local macro = "BEE464BB-0C6F-4B8A-9AAF-81603BBA8351"
    return {
        MaestroButton:new(26, deck, hsIcon("fcpx/titles/down-arrow.png"), macro, "wes-arrows-down"),
        MaestroButton:new(27, deck, hsIcon("fcpx/titles/right-arrow.png"), macro, "wes-arrows-right"),
        MaestroButton:new(25, deck, hsIcon("fcpx/titles/left-arrow.png"), macro, "wes-arrows-left"),
        MaestroButton:new(18, deck, hsIcon("fcpx/titles/up-arrow.png"), macro, "wes-arrows-up"),
        KeyStrokeButton:new(14, deck, hsIcon("fcpx/timeline/edges/select-right-60x60.png"), {}, "["),
        KeyStrokeButton:new(15, deck, hsIcon("fcpx/timeline/edges/select-both-edges-60x60.png"), {}, "\\"),
        KeyStrokeButton:new(16, deck, hsIcon("fcpx/timeline/edges/select-left-60x60.png"), {}, "]"),


        MaestroButton:new(30, deck, hsIcon("fcpx/timeline/playhead/select-and-delete-elgato72.png"), "EFEF889C-3C4C-404A-8592-A3BBBD7A5AD6"),
        -- TODO ; \    -- two separate key strokes (add KeyStrokesButton (plural?))
        MaestroButton:new(31, deck, hsIcon("fcpx/timeline/edges/prev-edge-both-elgato72.png"), "392700A6-2CB4-44ED-ADDC-F2AC3024116D"),
        -- TODO ' \    -- two separate key strokes
        MaestroButton:new(32, deck, hsIcon("fcpx/timeline/edges/next-edge-both-elgato72.png"), "9EA4E03C-31AE-4A25-A683-DFCF265C0FAA"),
    }
end)

FcpxObserver:addProfile("4+", function(_, deck)
    return {
        -- *** row 1
        -- KeyStrokeButton:new(1, deck, drawTextIcon("Detach\nAudio", deck), { "ctrl", "shift" }, "s"),
        MenuButton:new(1, deck, drawTextIcon("***\nDetach\nAudio", deck), { "Clip", "Detach Audio" }),
        -- LuaButton:new(1, deck, drawTextIcon("***\nDetach\nAudio", deck), menu({ "Clip", "Detach Audio" })),
        --  TODO which do I prefer? lets try menu() approach => one drawback is in dumping the menu details, I would need to reflect over the lua code to dump that which I dunno if that is impossible... but then again do I really need __tostring() on menu classes, that was so not what I think was the point of making them :)

        KeyStrokeButton:new(2, deck, drawTextIcon("Freeze\nFrame", deck), { "alt" }, "f"), -- TODO MenuButton?
        KeyStrokeButton:new(3, deck, drawTextIcon("Precision\nEditor", deck), { "ctrl" }, "e"), -- TODO MenuButton?
        MaestroButton:new(4, deck, drawTextIcon("Silence\n0dB", deck), "9EA0CC0E-D4C8-4BC0-B8DD-A4AA6F905940"), -- TODO MenuButton
        -- TODO add speed up/down buttons 4x/2x/1x/custom/0.5/0.25 => most are menu items IIRC

        -- *** row 2
        -- 5
        KeyStrokeButton:new(6, deck, drawTextIcon("Hold", deck), { "shift" }, "h"),
        -- 6
        MaestroButton:new(8, deck, drawTextIcon("Reset\nVolume", deck), "E6640B8F-29B7-49A3-ACBA-3E0B7D4CF92E"), -- TODO MenuButton

        -- TODO I would love to have this style:
        -- keyStroke(1, drawTextIcon("Detach\nAudio", deck), { "alt", "f" })
        --   A builder pattern but I don't think methods can be called without fully qualifying the class (table) name?
    }
end)





local observer = nil
function onAppActivated(hsApp, appName)
    if observer then
        observer:stop()
    end
    if appName ~= "Final Cut Pro" then
        return
    end
    -- set _group to group 2 of group 2 of splitter group 1 of ¬ window "Final Cut Pro" of application process "Final Cut Pro"
    local window = hs.axuielement.windowElement(hsApp:mainWindow())
    assert(window ~= nil, "window is nil")

    -- ! headerGroup paths so far:
    -- local headerGroup = window:splitGroup(1):group(2):group(2)
    local headerGroup = window:splitGroup(1):group(1):group(2)
    assert(headerGroup ~= nil, "headerGroup is nil")

    local staticTextElement = headerGroup:staticText(1)
    verbose("staticTextElement:", hs.inspect(staticTextElement))
    verbose("  value:", staticTextElement:attributeValue("AXValue"))
    verbose(" identifier:", staticTextElement:attributeValue("AXIdentifier"))
    -- FYI does have AXIdentifier _NS:84  -  AXRoleDescription: text    -    AXDescription: text
    --    TODO have a strategy set for finding any given element, go through it in order and then cache the strategy until (if) it fails, and/or cache the object
    --       two ways I've seen to find the Title Inspector checkbox so I could code up both into a class and defer to it
    --          and 3rd fallback can be search!
    --    probably need to find it relative to the buttons next to it (Title Inspector)... as nothing is likely to uniquely identify this element

    observer = hs.axuielement.observer.new(hsApp:pid())
    -- local elem = hs.axuielement.applicationElement(hsApp:pid())
    -- exammple notification types:   hs.axuielement.observer.notifications
    assert(observer ~= nil, "observer is nil")
    observer:callback(function(_, element, notification, infoTable)
        local value = element:attributeValue("AXValue")
        local text = notification
        if value then
            text = text .. " '" .. value .. "'"
        end
        local luaScript = BuildHammerspoonLuaTo(element)
        verbose("AXValueChanged: ", hs.inspect(element), text, hs.inspect(infoTable), luaScript)
    end)
    --
    local appElement = hs.axuielement.applicationElement(hsApp) -- works, for all elements!
    assert(appElement ~= nil, "appElement is nil")
    -- local watchElement = hs.axuielement.windowElement(hsApp:mainWindow()) -- nothing for AXValueChanged
    -- local watchElement = staticTextElement -- not working so far :(
    -- TODO why can't I get watching to work beneath the app level?!
    --   appElement => all events (including the AXValueChanged I want)
    --   mainWindow => nothing
    --   individual element that has value changing => nothing
    -- FYI raises an error if cannot watch the given element
    --   i.e. pass element from different app than was used for pid of observer
    --      observer:addWatcher(hs.axuielement.applicationElement(hs.application.find("Finder")), "AXValueChanged")
    -- local test = appElement:childrenWithRole("AXWindow")[2]:childrenWithRole("AXSplitGroup")[1]:childrenWithRole("AXGroup")[1]:childrenWithRole("AXSplitGroup")[1]:childrenWithRole("AXGroup")[2]
    --     :childrenWithRole("AXSplitGroup")[1]:childrenWithRole("AXGroup")[4]:childrenWithRole("AXGroup")[2]:childrenWithRole("AXStaticText")[1] -- 00:00:25:24 - AXValueChanged
    -- local watchElement = test
    -- local watchElement = appElement
    -- local watchElement = appElement:window(2):splitGroup(1):group(2):group(2):staticText(1)
    local watchElement = staticTextElement
    -- local watchElement = appElement:childrenWithRole("AXWindow")[2]:childrenWithRole("AXSplitGroup")[1]
    --     :childrenWithRole("AXGroup")[2]:childrenWithRole("AXGroup")[2]:childrenWithRole("AXStaticText")[2]

    observer:addWatcher(watchElement, "AXValueChanged")
    observer:start()
end

return FcpxObserver
