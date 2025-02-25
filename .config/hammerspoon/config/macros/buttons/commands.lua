function runCommand(cmd)
    -- AVOID hs.execute and os.execute... PITA, can't see STDERR or not easily
    local handle = io.popen(cmd .. " 2>&1") -- Redirects STDERR to STDOUT
    if handle then
        local output = handle:read("*a")
        handle:close()
        return output
    end
    return nil
end

---@param macro string
---@param param string|nil
function runKMMacro(macro, param)
    local app = "/Applications/Keyboard\\ Maestro.app/Contents/MacOS/keyboardmaestro"
    local command = app .. " " .. macro
    if param then
        command = command .. " -p " .. param
    end
    verbose("exec KM: " .. command)

    local output = runCommand(command)
    verbose("output: ", output)
end
