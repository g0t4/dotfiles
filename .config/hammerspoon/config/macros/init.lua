require("config._packages")
local logger = require("devtools.logs.logger")

local km_run_lua = logger.create("km_run_lua.log")

local M = {}

function nudge_human()
    hs.alert.show("check " .. km_run_lua.basename, nil, nil, 5)
end

function StreamDeckKeyboardMaestroRunner(what)
    -- USED in KM Macros => look at kmsync file:
    --    plutil -p Keyboard\ Maestro\ Macros.kmsync  | grep "StreamDeckKeyboardMaestroRunner"

    -- FYI easy to miss failures when using KM to call hs command
    -- - hs command echoes back to caller (not hs console)
    -- - info level prints become a nuissance
    -- - so I inevitably silence outputs in KM (b/c no good way to decide when and what to show)
    -- - THUS => use a log file, especially for info level logs
    -- - + egregious and unhandled exceptions poke the user (i.e. hs.alert.show)

    km_run_lua:with_context("km `" .. what .. "`",
        function()
            local func, error_message = load(what) -- load lua here so invalid lua code failures are logged too
            if error_message then
                km_run_lua:error("load lua code failed", error_message)
                nudge_human()
                return
            end
            func()
        end,
        nudge_human
    )
end

require("config.macros.brave")
require("config.macros.fcpx")
require("config.macros.iterm")
require("config.macros.google-docs")
require("config.macros.msft_office")
require("config.macros.screenpal")
require("config.macros.parallels")
require("config.macros.hammerspoon")
require("config.macros.iina")
require("config.macros.frontmost")
require("config.macros.sdeck_config_app")
require("config.macros.macos")
require("config.macros.lights")

return M
