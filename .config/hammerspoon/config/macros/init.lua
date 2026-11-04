require("config._packages")
local debug = require("devtools.debug")
local log = require("config.logs").hammerspoons()
local ensure_in_coroutine = require("devtools.co.ensure_in_coroutine")

local M = {}
local openTasks = {}

---Open a filesystem path with its default handler, without shell parsing.
---@param path string Use literal spaces; ~/ expands to the current user's Home.
---@return boolean started
function StreamDeckOpen(path)
    if type(path) ~= "string" or path == "" then
        hs.alert.show("StreamDeckOpen needs a file or folder path")
        return false
    end
    if path == "~" then
        path = os.getenv("HOME")
    elseif path:sub(1, 2) == "~/" then
        path = os.getenv("HOME") .. path:sub(2)
    end
    local task
    task = hs.task.new("/usr/bin/open", function(code, _, stderr)
        openTasks[task] = nil
        if code ~= 0 then
            log:error("StreamDeckOpen failed:", path, stderr)
            hs.alert.show("Could not open path; see Hammerspoon log")
        end
    end, {"--", path})
    if task then
        openTasks[task] = true
        if task:start() then return true end
        openTasks[task] = nil
    end
    log:error("StreamDeckOpen could not start:", path)
    hs.alert.show("Could not start open")
    return false
end

---@param path? string Directory to open, or file to select; defaults to Home.
function StreamDeckPipRot(path)
    require("config.launcher.pip_rot").open(path)
end

function nudge_human_to_check_log()
    -- leave as black alert
    hs.alert.show("check " .. log.basename, nil, nil, 5)
end

local function red_alert(message)
    -- I routinely miss the black defaultStyle... so for important messages I should make it red!
    hs.alert.show(message, { fillColor = { red = 1, green = 0, blue = 0 } })
end

---@param lua_code_string string
function StreamDeckKeyboardMaestroRunner(lua_code_string)
    log:info("StreamDeckKeyboardMaestroRunner called with: " .. hs.inspect(lua_code_string)) -- FYI inspect is explicit here so a string is quoted in output
    -- USED in KM Macros => look at kmsync file:
    --    plutil -p Keyboard\ Maestro\ Macros.kmsync  | grep "StreamDeckKeyboardMaestroRunner"

    -- FYI easy to miss failures when using KM to call hs command
    -- - hs command echoes back to caller (not hs console)
    -- - info level prints become a nuissance
    -- - so I inevitably silence outputs in KM (b/c no good way to decide when and what to show)
    -- - THUS => use a log file, especially for info level logs
    -- - + egregious and unhandled exceptions poke the user (i.e. hs.alert.show)
    local is_empty = lua_code_string == nil or lua_code_string:match("^%s*$")
    if is_empty then
        local message = "no code provided to StreamDeckKeyboardMaestroRunner: " .. hs.inspect(lua_code_string)
        log:error(message)
        red_alert(message)
        return
    end

    ensure_in_coroutine(function()
        local context = lua_code_string
        local has_whitespace = context:find("%s")
        if has_whitespace then
            context = "`" .. context .. "`"
        end

        log:set_coroutine_context(context)
        log:divider("start")

        local ok, result = xpcall(
            function()
                local func, error_message = load(lua_code_string) -- load lua here so invalid lua code failures are logged too
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
