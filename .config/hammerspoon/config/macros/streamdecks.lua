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
    -- use canvas for text on images on icons! COOL
    --   streamdeck works off of images only for the buttons, makes 100% sense
    local canvas = hs.canvas.new({ x = 0, y = 0, w = 72, h = 72 })
    canvas[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0, green = 0, blue = 0, alpha = 1 }, -- Background color
    }
    canvas[2] = {
        type = "text",
        text = text,
        textSize = 20,
        textColor = { red = 1, green = 1, blue = 1, alpha = 1 },
        frame = { x = 0, y = 20, w = 72, h = 32 }, -- Adjust positioning
    }
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
    print("serialNumber: ", serial)
    print("firmwareVersion: ", deck:firmwareVersion())

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

    local imageSize = deck:imageSize()
    print("imageSizes: ", hs.inspect(imageSize))
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


hs.application.watcher.new(function(appName, eventType, hsApp)
    if eventType == hs.application.watcher.activated then
        print("app activated: ", appName)
        if deck1XL then
            deck1XL:setButtonImage(9, drawTextIcon(appName))
        end
    end
end):start()
-- FYI at this point, there are no devices available, wait for them to connect (each one)

-- NOTES:
-- - hammerspoon crashes if you call discoveryCallback first (w/o init first)
-- - operations:
--   - when I restart hammerspoon they appear to be turned off or smth?
