--  I want dynamic keys based on context in a given app
--    i.e. FCPX when I select a shape (title)
--    light up the dials for adjusting its specific properties...
--  I can do this with an accessibility observer


function reloadOnMacrosChanges(path)
    local scriptPath = path or "/Users/wesdemos/.hammerspoon/config/macros"

    -- local function hotReloadModule()
    --     package.loaded[scriptPath] = nil -- Unload from cache
    --     dofile(scriptPath) -- Reload the script
    --     hs.alert.show("Reloaded: " .. scriptPath)
    -- end

    local watcher = hs.pathwatcher.new(scriptPath, function(files, flagTables)
        -- for _, file in ipairs(files) do ... hot reload each? (FYI symlinks might not match if checking based on file name
        print("Reloading script: ", scriptPath)
        hs.reload() -- crude, reload config as a pseudo restart
        -- PRN setup hot reload type functionality? or at least module reload
    end)

    watcher:start()
    print("Auto-reload enabled for: " .. scriptPath)
end

-- TODO turn this into hot reload for just streamdeck lua scripts?
reloadOnMacrosChanges()


-- TODO test hs.streamdeck:screenCallback(fn)  - touch screen on PLUS
function dumpButtonInfo(deck, buttonNumber, pressedOrReleased)
    -- buttons on all decks (including XL and PLUS)
    --   NOT dials on PLUS
    --   NOT touchscreen dials on PLUS

    local buttonExtra = ""
    local cols, rows = deck:buttonLayout()
    print("  cols:", cols, " rows:", rows)

    -- nice for debugging
    local col = (buttonNumber - 1) % cols + 1
    local row = math.ceil(buttonNumber / cols)
    buttonExtra = " (" .. row .. "," .. col .. ") "

    local explainPressed = ""
    if pressedOrReleased ~= nil then
        explainPressed = (pressedOrReleased and "pressed" or "released")
    end

    print(
        getDeckName(deck) ..
        " btn " .. buttonNumber .. buttonExtra ..
        explainPressed
    )
end

function drawTextIcon(text)
    local width = 96
    local height = 96
    -- todo based on device button size (4+ has 120x120, XL has 96x96)
    -- use canvas for text on images on icons! COOL
    --   streamdeck works off of images only for the buttons, makes 100% sense
    local canvas = hs.canvas.new({ x = 0, y = 0, w = width, h = height })
    canvas[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0, green = 0, blue = 0, alpha = 1 }, -- Background color
    }
    -- TODO try hs.styledtext (instead of attrs below)
    --   TODO can it set vertical alignment?
    canvas[2] = {
        type = "text",
        text = text,
        -- textLineBreak =
        textSize = 24,
        textAlignment = "center",
        -- TODO vertical alignment?
        textColor = { red = 1, green = 1, blue = 1, alpha = 1 },
        frame = { x = 0, y = 0, w = width, h = height },
    }
    -- FYI https://www.hammerspoon.org/docs/hs.canvas.html#attributes
    return canvas:imageFromCanvas()
end

function onButtonPressed(deck, buttonNumber, pressedOrReleased)
    local name = getDeckName(deck)
    dumpButtonInfo(deck, buttonNumber, pressedOrReleased)

    if name == "3XL" then
        if buttonNumber == 7 then
            hs.openConsole()
        elseif buttonNumber == 8 then
            hs.console.clearConsole()
        elseif buttonNumber == 16 then
            hs.reload()
        end
    elseif name == "4+" then
        if buttonNumber == 1 then
            deck:setButtonImage(buttonNumber, drawTextIcon("Hello"))
        end
    end
end

function onEncoderPressed(deck, buttonNumber, pressedOrReleased, turnedLeft, turnedRight)
    -- TODO test dials on PLUS
    --      pressed/released AND rotated (plus only, IIUC)
    --
    -- dumpButtonInfo(deck, buttonNumber, pressedOrReleased)
    print("encoder pressed: ", buttonNumber, pressedOrReleased, turnedLeft, turnedRight)
end

function getDeckName(deck)
    -- CL start
    --  + 9 end => deck 1XL
    --  + 1 end => deck 2XL
    --  + 8 end => deck 3XL
    -- A start (also ends with 4) => deck 4+

    local serial = deck:serialNumber()
    if serial:find("9$") then
        return "1XL"
    elseif serial:find("1$") then
        return "2XL"
    elseif serial:find("8$") then
        return "3XL"
    elseif serial:find("^A") then
        return "4+"
    end
    return "unknown"
end

local deck1XL = nil
local deck2XL = nil
local deck3XL = nil
local deck4Plus = nil
--
-- @param connected boolean
-- @param deck hs.streamdeck
local function onDeviceDiscovery(connected, deck)
    -- print(hs.inspect(getmetatable(deck)))
    -- print("Discovered streamdeck", hs.inspect(deck), "connected:", connected)
    local serial = deck:serialNumber()
    -- print("firmwareVersion: ", deck:firmwareVersion())

    local name = getDeckName(deck)
    -- PRN deck:setBrightness(80) -- 0 to 100 (FYI persists across restarts of hammerspoon... IIAC only need to set this once when I wanna change it)

    -- TODO on hammerspon QUIT, reset the decks... right? sooo... do that on disconnect? or?

    -- FYI now wth... reset isn't needed it seems... ... well ok maybe if something else sets the buttons... but I am reloading config w/o reset and it changes any button I explicitly set... and no flash this way!
    --    FOR NOW see if it works w/o reset
    --    OR, see if I can repor the issue w/o reset and button presses (which I just tested and are fine)
    --        could it be that I hadn't set any buttons yet and now that I have button clicks work w/o reset?
    -- deck:reset() -- TODO when do I need to call this? w/o this the buttonCallback doesn't reliably fire on config reload
    deck:encoderCallback(onEncoderPressed) -- don't need to limit to just PLUS... seems irrelevant on XLs
    deck:buttonCallback(onButtonPressed)

    --- WOW this is super fast too... in a flash they're all loaded (and that's with a reset in between)
    deck:setButtonColor(1, hs.drawing.color.x11.red)
    deck:setButtonColor(2, hs.drawing.color.x11.blue)
    deck:setButtonColor(3, hs.drawing.color.x11.yellow)
    deck:setButtonColor(9, hs.drawing.color.x11.red)
    deck:setButtonColor(10, hs.drawing.color.x11.blue)
    deck:setButtonColor(11, hs.drawing.color.x11.yellow)
    deck:setButtonColor(12, hs.drawing.color.x11.red)
    deck:setButtonColor(13, hs.drawing.color.x11.blue)
    deck:setButtonColor(14, hs.drawing.color.x11.yellow)
    deck:setButtonColor(17, hs.drawing.color.x11.red)
    deck:setButtonColor(18, hs.drawing.color.x11.blue)
    deck:setButtonColor(19, hs.drawing.color.x11.yellow)
    deck:setButtonColor(20, hs.drawing.color.x11.red)
    deck:setButtonColor(21, hs.drawing.color.x11.blue)
    deck:setButtonColor(22, hs.drawing.color.x11.yellow)
    deck:setButtonColor(23, hs.drawing.color.x11.red)
    deck:setButtonColor(24, hs.drawing.color.x11.blue)
    deck:setButtonColor(32, hs.drawing.color.x11.blue)

    -- TODO setScreenImage (when disconnected, right?)

    -- PRN capture deck image sizes for button image gen
    -- local imageSize = deck:imageSize()
    -- print("imageSizes: ", hs.inspect(imageSize))
    -- XL => { h = 96.0, w = 96.0 }
    -- +  => { h = 120.0, w = 120.0 }

    -- TODO try hs.image.imageFromAppBundle  -- get app icons!

    -- keep local copies of images!
    -- local testSvg = "https://img.icons8.com/?size=256w&id=jrkQk3VIHBgH&format=png"
    -- local image   = hs.image.imageFromURL(testSvg)

    local testSvg = "~/repos/github/g0t4/dotfiles/misc/hammerspoon-icons/test-svgs/machine-64.png"
    local image   = hs.image.imageFromPath(resolveHomePath(testSvg))
    deck:setButtonImage(4, image)

    local pngFileType = hs.image.iconForFileType("png")
    deck:setButtonImage(5, pngFileType)

    local htmlFileType = hs.image.iconForFileType("html")
    deck:setButtonImage(6, htmlFileType)

    -- /Applications/Hammerspoon.app/Contents/Resources/AppIcon.icns
    local hammerspoonAppIcon = hs.image.imageFromPath("/Applications/Hammerspoon.app/Contents/Resources/AppIcon.icns")
    deck:setButtonImage(7, hammerspoonAppIcon)

    deck:setButtonImage(8, drawTextIcon("Clear Console"))
    deck:setButtonImage(16, drawTextIcon("Reload Config"))

    if name == "1XL" then
        deck1XL = deck
    elseif name == "2XL" then
        deck2XL = deck
    elseif name == "3XL" then
        deck3XL = deck
    elseif name == "4+" then
        deck4Plus = deck
    end
end

hs.streamdeck.init(onDeviceDiscovery) -- onDeviceConnected)

local observer = nil
local currentApp = hs.application.frontmostApplication()

-- ! TODO look into CommandPost and what it does for UI automation in FCPX, IIAC it uses that w/ its own lua fwk
-- https://github.com/CommandPost/CommandPost?tab=readme-ov-file
--   OH YEAH BABY... they're right up my alley... or I'm right up theirs
--      https://github.com/CommandPost/CommandPost/blob/develop/src/extensions/cp/apple/finalcutpro/inspector/Inspector.lua#L127

function onAppActivated(hsApp, appName)
    if observer then
        observer:stop()
    end
    print("app activated: ", appName)
    if appName ~= "Final Cut Pro" then
        return
    end
    -- set _group to group 2 of group 2 of splitter group 1 of ¬ window "Final Cut Pro" of application process "Final Cut Pro"
    local window = hs.axuielement.windowElement(hsApp:mainWindow())
    assert(window ~= nil, "window is nil")
    local headerGroup = window:splitGroup(1):group(2):group(2)
    assert(headerGroup ~= nil, "headerGroup is nil")
    local staticTextElement = headerGroup:staticText(1)
    print("staticTextElement:", hs.inspect(staticTextElement))
    print("  value:", staticTextElement:attributeValue("AXValue"))
    print(" identifier:", staticTextElement:attributeValue("AXIdentifier"))
    -- FYI does have AXIdentifier _NS:84  -  AXRoleDescription: text    -    AXDescription: text
    --    TODO have a strategy set for finding any given element, go through it in order and then cache the strategy until (if) it fails, and/or cache the object
    --       two ways I've seen to find the Title Inspector checkbox so I could code up both into a class and defer to it
    --          and 3rd fallback can be search!
    --    probably need to find it relative to the buttons next to it (Title Inspector)... as nothing is likely to uniquely identify this element

    observer = hs.axuielement.observer.new(hsApp:pid())
    -- local elem = hs.axuielement.applicationElement(hsApp:pid())
    -- exammple notification types:   hs.axuielement.observer.notifications
    assert(observer ~= nil, "observer is nil")
    observer:callback(function(_observer, element, notification, infoTable)
        local value = element:attributeValue("AXValue")
        local text = notification
        if value then
            text = text .. " '" .. value .. "'"
        end
        local luaScript = BuildHammerspoonLuaTo(element)
        print("AXValueChanged: ", hs.inspect(element), text, hs.inspect(infoTable), luaScript)
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
    -- print("test:", hs.inspect(test))
    -- local watchElement = test
    -- local watchElement = appElement
    -- local watchElement = appElement:childrenWithRole("AXWindow")[2]:childrenWithRole("AXSplitGroup")[1]:childrenWithRole("AXGroup")[2]:childrenWithRole("AXGroup")[2]:childrenWithRole("AXStaticText")[1]
    local watchElement = appElement:childrenWithRole("AXWindow")[2]:childrenWithRole("AXSplitGroup")[1]
        :childrenWithRole("AXGroup")[2]:childrenWithRole("AXGroup")[2]:childrenWithRole("AXStaticText")[2]

    observer:addWatcher(watchElement, "AXValueChanged")
    observer:start()
end

onAppActivated(currentApp) -- currentApp:title()?

hs.application.watcher.new(function(appName, eventType, hsApp)
    if eventType == hs.application.watcher.activated then
        print("app activated: ", appName)
        if deck1XL then
            deck1XL:setButtonImage(9, drawTextIcon(appName))
        end
        onAppActivated(hsApp, appName)
    end
end):start()
-- FYI at this point, there are no devices available, wait for them to connect (each one)

-- NOTES:
-- - hammerspoon crashes if you call discoveryCallback first (w/o init first)
-- - operations:
--   - when I restart hammerspoon they appear to be turned off or smth?
