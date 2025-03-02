local verbose = require("config.macros.streamdeck.helpers").verbose

function runCommand(cmd)
    -- AVOID hs.execute and os.execute... PITA, can't see STDERR or not easily
    local handle = io.popen(cmd .. " 2>&1") -- Redirects STDERR to STDOUT
    if handle then
        local output = handle:read("*a")
        local succeeded, reason, exitCode = handle:close()
        if not succeeded then
            print("command failed: " .. reason .. " (exit code: " .. exitCode, "output: ", output, "command:", cmd)
        end
        return output
    end
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
    verbose("exec KM: " .. command)

    runCommand(command)
end
