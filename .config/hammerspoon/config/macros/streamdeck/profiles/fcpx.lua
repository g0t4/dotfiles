local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
require("config.macros.streamdeck.helpers")




local FcpxObserver = AppObserver:new("Final Cut Pro")

FcpxObserver:addProfile("2XL", function(_, deck)
    return {
        -- TODO can I decouple deck here?
        MaestroButton:new(1, deck, hsIcon("fcpx/commands/customize-command-sets.png"), "E5D823AF-6720-4228-940B-C7FC472CBBE5"),
        MaestroButton:new(6, deck, hsIcon("fcpx/viewer/disable-captions.png"), "CE9D34A3-348C-457D-BFB9-65908EF3A25B"),
        MaestroButton:new(7, deck, hsIcon("fcpx/viewer/dual-screen.png"), "7967644C-59AE-4AB5-A65F-6EE7D29B9E4C"),
        MaestroButton:new(8, deck, hsIcon("fcpx/viewer/single-screen.png"), "2D134D9A-EABB-4658-A745-27228C12FF94")
    }
end)

FcpxObserver:addProfile("3XL", function(_, deck)
    -- local macro = "'Titles - Add wes-arrows-* (Parameterized)'"
    local macro = "BEE464BB-0C6F-4B8A-9AAF-81603BBA8351"
    return {
        -- TODO can I decouple deck here?
        MaestroButton:new(26, deck, hsIcon("fcpx/titles/down-arrow.png"), macro, "wes-arrows-down"),
        MaestroButton:new(27, deck, hsIcon("fcpx/titles/right-arrow.png"), macro, "wes-arrows-right"),
        MaestroButton:new(25, deck, hsIcon("fcpx/titles/left-arrow.png"), macro, "wes-arrows-left"),
        MaestroButton:new(18, deck, hsIcon("fcpx/titles/up-arrow.png"), macro, "wes-arrows-up"),
        KeyStrokeButton:new(14, deck, hsIcon("fcpx/timeline/edges/select-right-60x60.png"), {}, "["),
        KeyStrokeButton:new(15, deck, hsIcon("fcpx/timeline/edges/select-both-edges-60x60.png"), {}, "\\"),
        KeyStrokeButton:new(16, deck, hsIcon("fcpx/timeline/edges/select-left-60x60.png"), {}, "]")
    }
end)





-- TODO app observing profile changes! (only update buttons that are dynamic, should help with speed, don't redo all buttons... right?)
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
