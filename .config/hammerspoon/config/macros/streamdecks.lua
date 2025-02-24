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


-- TODO test dials on streamdeck plus
--   ALL/REGULAR:
--      :buttonCallback(fn)
--   PLUS touchscreen:
--      hs.streamdeck:screenCallback(fn)
--      pressed/released AND rotated (plus only, IIUC)
--
--
function dumpButtonInfo(deck, buttonNumber, pressedOrReleased)
    local buttonExtra = ""
    if deck:serialNumber():find("^CL") then
        -- nice for debugging
        local col = (buttonNumber - 1) % 8 + 1
        local row = math.ceil(buttonNumber / 8)
        buttonExtra = " (" .. row .. "," .. col .. ") "
    end

    print(
        getDeckName(deck)
        .. " btn " .. buttonNumber .. buttonExtra
        .. (pressedOrReleased and "pressed" or "released")
    )
end

function onButtonPressed(deck, buttonNumber, pressedOrReleased)
    local name = getDeckName(deck)
    dumpButtonInfo(deck, buttonNumber, pressedOrReleased)

    if name ~= "4+" then

    end
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
    elseif serial:find("A$") then
        return "4+"
    end
end

--
-- @param connected boolean
-- @param deck hs.streamdeck
local function onDeviceDiscovery(connected, deck)
    -- print(hs.inspect(getmetatable(deck)))
    -- print("Discovered streamdeck", hs.inspect(deck), "connected:", connected)
    print("serialNumber: ", deck:serialNumber())
    print("firmwareVersion: ", deck:firmwareVersion())
    -- use serialNumber to identify which device is which
    -- serial ends in "9","8","1" (all start with "CL" too)... PLUS starts wtih "A"
    local name = getDeckName(deck)
    local cols, rows = deck:buttonLayout()
    print("  cols:", cols, " rows:", rows)
    -- PRN deck:setBrightness(80) -- 0 to 100 (FYI persists across restarts of hammerspoon... IIAC only need to set this once when I wanna change it)

    deck:reset() -- TODO when do I need to call this? w/o this the buttonCallback doesn't reliably fire on config reload
    deck:buttonCallback(onButtonPressed)

    deck:setButtonColor(1, hs.drawing.color.x11.red)
    deck:setButtonColor(2, hs.drawing.color.x11.blue)
    deck:setButtonColor(3, hs.drawing.color.x11.yellow)

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

    if name == "1XL" then
    end
end

hs.streamdeck.init(onDeviceDiscovery) -- onDeviceConnected)

-- FYI at this point, there are no devices available, wait for them to connect (each one)

-- NOTES:
-- - hammerspoon crashes if you call discoveryCallback first (w/o init first)
-- - operations:
--   - when I restart hammerspoon they appear to be turned off or smth?
