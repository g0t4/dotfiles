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
function onButtonPressed(deck, buttonNumber, pressedOrReleased)
    print("button " .. buttonNumber .. ": "
        .. (pressedOrReleased and "pressed" or "released")
        .. " on button " .. getDeckName(deck))
end

function getDeckName(deck)
    -- CL start
    --  + 9 end => deck 1XL
    --  + 1 end => deck 2XL
    --  + 8 end => deck 3XL
    -- A start (also ends with 4) => deck 4+

    local serial = deck:serialNumber()
    if serial:find("9$") then
        return "deck #1"
    elseif serial:find("1$") then
        return "deck #2"
    elseif serial:find("8$") then
        return "deck #3"
    elseif serial:find("A$") then
        return "deck #4"
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
    local cols, rows = deck:buttonLayout()
    print("  cols:", cols, " rows:", rows)
    -- PRN deck:setBrightness(80) -- 0 to 100 (FYI persists across restarts of hammerspoon... IIAC only need to set this once when I wanna change it)

    deck:reset() -- TODO when do I need to call this? w/o this the buttonCallback doesn't reliably fire on config reload
    deck:buttonCallback(onButtonPressed)
end

hs.streamdeck.init(onDeviceDiscovery) -- onDeviceConnected)

-- FYI at this point, there are no devices available, wait for them to connect (each one)

-- NOTES:
-- - hammerspoon crashes if you call discoveryCallback first (w/o init first)
-- - operations:
--   - when I restart hammerspoon they appear to be turned off or smth?
