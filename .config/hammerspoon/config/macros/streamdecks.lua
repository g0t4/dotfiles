--  I want dynamic keys based on context in a given app
--    i.e. FCPX when I select a shape (title)
--    light up the dials for adjusting its specific properties...
--  I can do this with an accessibility observer
local log = require("hs.logger").new("streamdeck", "verbose") -- set to "warning" or "error" when done developing this module
local ClockButton = require("config.macros.streamdeck.clockButton")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
local Encoder = require("config.macros.streamdeck.encoder")
local DecksController = require("config.macros.streamdeck.decksController")
-- FYI buttons and encoders controllers comprise a DeckController (singular)
local EncodersController = require("config.macros.streamdeck.encodersController")
local ButtonsController = require("config.macros.streamdeck.buttonsController")
local AppsObserver = require("config.macros.streamdeck.appsObserver")
require("config.macros.streamdeck.helpers")

function verbose(...)
    log.v(...)
end

function reloadOnMacrosChanges(path)
    local scriptPath = path or "/Users/wesdemos/.hammerspoon/config/macros"

    -- local function hotReloadModule()
    --     package.loaded[scriptPath] = nil -- Unload from cache
    --     dofile(scriptPath) -- Reload the script
    --     hs.alert.show("Reloaded: " .. scriptPath)
    -- end

    local watcher = hs.pathwatcher.new(scriptPath, function(files, flagTables)
        -- for _, file in ipairs(files) do ... hot reload each? (FYI symlinks might not match if checking based on file name
        hs.reload() -- crude, reload config as a pseudo restart
        -- PRN setup hot reload type functionality? or at least module reload
    end)

    watcher:start()
    verbose("Auto-reload enabled for: " .. scriptPath)
end

-- TODO turn this into hot reload for just streamdeck lua scripts?
reloadOnMacrosChanges()

local decks = DecksController:new()
decks:init()
local apps = AppsObserver:new(decks)
apps:start()

---@param connected boolean
---@param deck hs.streamdeck
local function onDeviceDiscovery(connected, deck)
    -- deck:reset() -- FYI if smth goes wrong use reset one off when testing new configs... otherwise my resetButton that sets black background is AWESOME (no flashing logos)
    do return end
    local name = "foo"

    -- PRN deck:setBrightness(80) -- 0 to 100 (FYI persists across restarts of hammerspoon... IIAC only need to set this once when I wanna change it)
    -- TODO on hammerspon QUIT, reset the decks... right? sooo... do that on disconnect? or?

    if name == "1XL" then
        deck1XL = deck
        deck1page = ButtonsController:newXL(deck1XL)
        deck1page:addButton(ClockButton:new(1, deck))
        deck1page:start()
    elseif name == "2XL" then
        deck2XL = deck
        deck2page = ButtonsController:newXL(deck2XL)
        deck2page:addButtons(
            MaestroButton:new(1, deck, hsIcon("fcpx/commands/customize-command-sets.png"), "E5D823AF-6720-4228-940B-C7FC472CBBE5"),
            MaestroButton:new(6, deck, hsIcon("fcpx/viewer/disable-captions.png"), "CE9D34A3-348C-457D-BFB9-65908EF3A25B"),
            MaestroButton:new(7, deck, hsIcon("fcpx/viewer/dual-screen.png"), "7967644C-59AE-4AB5-A65F-6EE7D29B9E4C"),
            MaestroButton:new(8, deck, hsIcon("fcpx/viewer/single-screen.png"), "2D134D9A-EABB-4658-A745-27228C12FF94")
        )
        deck2page:start()
    elseif name == "4+" then
        deck4Plus = deck
        deck4page = ButtonsController:newPlus(deck4Plus)
        deck4page:addButtons(
            LuaButton:new(4, deck, drawTextIcon("Clear Console"), hs.console.clearConsole),
            LuaButton:new(3, deck, appIconHammerspoon(), hs.openConsole),
            LuaButton:new(8, deck, drawTextIcon("Reload Config"), hs.reload)
        )
        deck4page:start()

        deck4encodersController = EncodersController:newPlus(deck4Plus)
        deck4encodersController:addEncoders(
            Encoder:new(1, deck, hsIcon("test-svgs/hanging-96.png")),
            Encoder:new(2, deck, hsIcon("test-svgs/saggy-64.png")),
            Encoder:new(3, deck, hsIcon("test-svgs/stick.svg")),
            Encoder:new(4, deck, hsIcon("test-svgs/purple-pink-128.png"))
        )
        deck4encodersController:start()
    else
        error("Unknown device: " .. name)
    end
end

local observer = nil
local currentApp = hs.application.frontmostApplication()

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
    log.v("staticTextElement:", hs.inspect(staticTextElement))
    log.v("  value:", staticTextElement:attributeValue("AXValue"))
    log.v(" identifier:", staticTextElement:attributeValue("AXIdentifier"))
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

onAppActivated(currentApp, currentApp:title())

-- FYI could have a set of buttons that are dynamic that show open apps (app switcher)
-- TODO move to an AppNameButton class (if I want to keep it)
local function updateAppNameButton(hsApp, appName)
    if deck1XL then
        deck1XL:setButtonImage(9, drawTextIcon(appName))
    end
    onAppActivated(hsApp, appName)
end

-- updateAppNameButton(currentApp, currentApp:title()) -- TODO need to do this once the deck is connected, not here
hs.application.watcher.new(function(appName, eventType, hsApp)
    if eventType == hs.application.watcher.activated then
        updateAppNameButton(hsApp, appName)
    end
end):start()



-- * REMINDERS
-- local imageSize = deck:imageSize()
-- XL => { h = 96.0, w = 96.0 }
-- +  => { h = 120.0, w = 120.0 }
--
-- local htmlFileType = hs.image.iconForFileType("html")
-- ? should I bother with checking for new firmware updates? I can always just use elgato's app to check manually
--

-- *** COMMANDPOST ***
--   OH YEAH BABY... they're right up my alley... or I'm right up theirs
--      https://github.com/CommandPost/CommandPost/blob/develop/src/extensions/cp/apple/finalcutpro/inspector/Inspector.lua#L127
--   yup, they memoize... "cache" https://github.com/CommandPost/CommandPost/blob/develop/src/extensions/cp/apple/finalcutpro/inspector/BasePanel.lua#L28
--   here is how they locate the title I've been working on too:
--      https://github.com/CommandPost/CommandPost/blob/develop/src/extensions/cp/apple/finalcutpro/inspector/Inspector.lua#L187
-- FYI! GO FIGURE... commandpost is a FORK of Hammerspoon!!! (I knew it smelled familiar!)
--   https://commandpost.io/developer/introduction/#what-is-hammerspoon
--   CommandPost-App => fork of Hammerspoon
--     https://github.com/CommandPost/CommandPost-App
--   CommandPost repo => lua scripts
--     https://github.com/CommandPost/CommandPost
--      TODO! review their lua models (seems like they build what I am thinking of building, can I reuse or at least be inspired by?)
--
-- * BENEFITS over elgato app:
--   don't need a black png for text only buttons! SHEESH what a PITA
--   not limited to only changing when apps change or if I impl a plugin (even then not sure how much things can change)
--   terrible button designer is BYE BYE!
--
-- * NOTES
-- - only use devices after connect
-- - hammerspoon crashes if you call discoveryCallback first (w/o init first)
-- - operations:
--   - when I restart hammerspoon they appear to be turned off or smth?
--
-- - streamdeck module:
--   - code to create type of deck:
--     - https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/streamdeck/HSStreamDeckManager.m#L256
