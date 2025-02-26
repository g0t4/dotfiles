--  I want dynamic keys based on context in a given app
--    i.e. FCPX when I select a shape (title)
--    light up the dials for adjusting its specific properties...
--  I can do this with an accessibility observer
local log = require("hs.logger").new("streamdeck", "verbose") -- set to "warning" or "error" when done developing this module
local DecksController = require("config.macros.streamdeck.decksController")
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
    end)

    watcher:start()
    verbose("Auto-reload enabled for: " .. scriptPath)
end

reloadOnMacrosChanges()

local decks = DecksController:new()
decks:init()
local apps = AppsObserver:new(decks)
apps:start()

-- deck:reset() -- FYI if smth goes wrong use reset one off when testing new configs... otherwise my resetButton that sets black background is AWESOME (no flashing logos)
-- PRN deck:setBrightness(80) -- 0 to 100 (FYI persists across restarts of hammerspoon... IIAC only need to set this once when I wanna change it)
-- TODO on hammerspon QUIT, reset the decks... right? sooo... do that on disconnect? or?

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
