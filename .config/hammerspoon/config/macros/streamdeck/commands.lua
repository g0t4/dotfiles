local verbose = require("config.macros.streamdeck.helpers").verbose

-- Activate Parallels Desktop Control Center menu item
-- Uses hs.application to find Parallels Desktop and selects the "Control Center" menu item.
function ParallelsX_control_center()
    local app = hs.application.get("Parallels Desktop")
    if not app then
        verbose("Parallels Desktop not running")
        return
    end
    -- Find the menu path; typical menu item is under the app's menu bar: "Window" -> "Control Center"
    local menuPath = {"Window", "Control Center"}
    local success = app:selectMenuItem(menuPath)
    if not success then
        verbose("Failed to select Control Center menu item")
    end
end

function runCommand(cmd)
    -- AVOID hs.execute and os.execute... PITA, can't see STDERR or not easily
    local handle = io.popen(cmd .. " 2>&1") -- Redirects STDERR to STDOUT
    if handle then
        local output = handle:read("*a")
        local succeeded, exitOrSignal, exitCode = handle:close()
        if not succeeded then
            print("command failed: ", exitOrSignal,
                "exit code: " .. exitCode,
                "output: ", output,
                "command:", cmd)
        end
        return output
    end
    print("command failed: could not open handle", cmd)
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
