require("config._packages")
local logger = require("devtools.logs.logger")

local km_run_lua = logger.create("km_run_lua.log")

local M = {}

---@param message string
function poke_human(log_context, message)
    km_run_lua:error(log_context, message)
    -- file:flush() -- TODO flush? equivalent?

    -- => temporary alert to nudge checking log file
    --  would be neat if I could check if I am tailing log file and if so then not nudge!
    poke = "poke... check " .. km_run_lua.basename
    hs.alert.show(poke, nil, nil, 5)
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
    local log_context = "km `" .. what .. "`"
    xpcall(function()
        km_run_lua:info(log_context, "starting")
        -- keep parsing inside too so logs get it all
        local func = load(what)
        if func == nil then
            poke_human(log_context, "failed to load")
            return
        end
        func()
    end, function(errorMsg)
        poke_human(log_context, "error: " .. tostring(errorMsg))
    end)
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
