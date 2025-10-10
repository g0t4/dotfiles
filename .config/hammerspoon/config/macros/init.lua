local M = {}


---@type file*?
local log_file
local log_dir = os.getenv("HOME") .. "/.hammerspoon/logs"
local filepath = log_dir .. "/streamdeck_keyboardmaestro_runner.log"

---@return file*?
local function get_log_file()
    if not log_file then
        hs.fs.mkdir(log_dir)
        log_file = io.open(filepath, "w")
    end
    return log_file
end

--- idea => use log file for issues instead of print/STDOUT or persistent notification/alert
--- intended for use with KM macro that runs lua code by passing it as a parameter
--- this way I can leave benign prints in my code and not have them show up in KM STDOUT from running `hs` command
--- AND THEN for failures (uncaught errors) I can log them instead of print to STDOUT
--- that way I can keep using print w/o needing to see STDOUT on failures in KM + hs macro
---@param message string
function log_failure(message)
    local file = get_log_file()
    if not file then
        -- fallback to print (STDOUT) which will go to hs console and/or command output with `hs` command
        print("ERROR: failed to open log file for writing...\n  message: " .. message)
        return
    end

    file:write(message)
    file:flush()
end

function alert_and_log_failure(message)
    log_failure(message)
    message = message .. " Check " .. filepath
    -- this pokes me ON ERRORS ONLY... but doesn't stay up long!
    -- habituate then check my log file for more details (or longer than alert shows)
    -- BTW on a real error I want this to stay up briefly, not just flicker
    -- THIS IS NOT INTENDED TO BE FOR ALL PRINTS like notifications was doing
    -- SO 5 seconds for now, enough to remind me where the log file is
    --    log file will have stack trace (i.e. file path:line) I can copy out and use in telescope to jump to issue!)
    --      unlike notification in macOS where I cannot really interact with it b/c SHOW is a mess and the message isn't copyable (AFAIK)... and it truncates past a few short lines and no way to expand it - IOTW a terrible way to log failures)
    -- I will then fix issue and then it won't popup the annoying alert again!
    -- * ALSO, now you should TURN OFF STDOUT => notification in KM macro
    hs.alert.show(message, nil, nil, 5)
end

-- *** streamdeck Keyboard Maestro wrapper to catch errors and log them and rethrow for KM to show too ***
function StreamDeckKeyboardMaestroRunner(what)
    -- USED in KM Macros => look at kmsync file:
    --    plutil -p Keyboard\ Maestro\ Macros.kmsync  | grep "StreamDeckKeyboardMaestroRunner"

    -- FYI w/o this its easy to think unhandled exceptions are being swallowed
    --   when its just KM not showing errors
    --   (b/c you said ignore results, rightly so b/c results all the time are annoying)...
    --   AND `hs` CLI doesn't log STDOUT to hs console
    xpcall(function()
        -- keep all parsing inside too so I catch those errors and show in HS logs too
        local func = load(what)
        if func == nil then
            alert_and_log_failure("failed to load: " .. what)
            return
        end
        func()
    end, function(errorMsg)
        alert_and_log_failure("StreamDeckKeyboardMaestroRunner error: " .. tostring(errorMsg) .. "\n")
    end)
end

require("config.macros.brave")
require("config.macros.fcpx")
require("config.macros.iterm")
require("config.macros.google-docs")
require("config.macros.msft_office")
require("config.macros.screenpal")
require("config.macros.hammerspoon")
require("config.macros.iina")
require("config.macros.frontmost")
require("config.macros.sdeck_config_app")

return M
