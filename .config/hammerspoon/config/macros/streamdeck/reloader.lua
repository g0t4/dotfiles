local verbose = require("config.macros.streamdeck.helpers").verbose

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
    end)

    watcher:start()
    verbose("Auto-reload enabled for: " .. scriptPath)
end

-- side effect:
reloadOnMacrosChanges()
