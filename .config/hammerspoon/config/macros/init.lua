require("config._packages")
local debug = require("devtools.debug")
local log = require("config.logs").hammerspoons()

local M = {}

function nudge_human_to_check_log()
    -- leave as black alert
    hs.alert.show("check " .. log.basename, nil, nil, 5)
end

local function red_alert(message)
    -- I routinely miss the black defaultStyle... so for important messages I should make it red!
    hs.alert.show(message, { fillColor = { red = 1, green = 0, blue = 0 } })
end

---@param what string
function StreamDeckKeyboardMaestroRunner(what)
    -- USED in KM Macros => look at kmsync file:
    --    plutil -p Keyboard\ Maestro\ Macros.kmsync  | grep "StreamDeckKeyboardMaestroRunner"

    -- FYI easy to miss failures when using KM to call hs command
    -- - hs command echoes back to caller (not hs console)
    -- - info level prints become a nuissance
    -- - so I inevitably silence outputs in KM (b/c no good way to decide when and what to show)
    -- - THUS => use a log file, especially for info level logs
    -- - + egregious and unhandled exceptions poke the user (i.e. hs.alert.show)

    local no_code = what == nil or what:gmatch("^%s*$")
    if no_code then
        log:error("StreamDeckKeyboardMaestroRunner called without lua code! what=", vim.inspect(what))
        local message = "no code provided to StreamDeckKeyboardMaestroRunner"
        red_alert(message)
        return
    end

    ensure_in_coroutine(function()
        local context = what
        local has_whitespace = context:find("%s")
        if has_whitespace then
            context = "`" .. context .. "`"
        end

        log:set_coroutine_context(context)
        log:info("start")

        local ok, result = xpcall(
            function()
                local func, error_message = load(what) -- load lua here so invalid lua code failures are logged too
                if error_message then
                    log:error("load lua code failed", error_message)
                    nudge_human_to_check_log()
                    return
                end
                func()
            end,
            full_traceback_xpcall
        )
        if ok then
            return
        end
        nudge_human_to_check_log()
        log:error("StreamDeckKeyboardMaestroRunner unhandled error", result)
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
