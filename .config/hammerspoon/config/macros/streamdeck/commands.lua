-- FYI this is mostly a duplicate of the same module in the separate stremadeck controller repo
local log = require("config.logs").hammerspoons()

function runCommand(cmd)
    -- AVOID hs.execute and os.execute... PITA, can't see STDERR or not easily
    local handle = io.popen(cmd .. " 2>&1") -- Redirects STDERR to STDOUT
    if handle then
        local output = handle:read("*a")
        local succeeded, exitOrSignal, exitCode = handle:close()
        if not succeeded then
            log:error("command failed: ", exitOrSignal,
                "exit code: " .. exitCode,
                "output: ", output,
                "command:", cmd)
        end
        return output
    end
    log:error("command failed: could not open handle", cmd)
    return nil
end

---@param macro string @Name or UUID
---@param param string|nil
function runKMMacro(macro, param)
    -- FYI could use osascript too (pass applescript to hammerspoon?)
    local app = "/Applications/Keyboard\\ Maestro.app/Contents/MacOS/keyboardmaestro"
    local command = app .. " " .. macro
    if param then
        command = command .. " -p '" .. param .. "'"
    end
    log:info("exec KM: " .. command)

    runCommand(command)
end
