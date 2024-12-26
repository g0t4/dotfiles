local M = {}

function M.getSecret(accountName, serviceName)
    -- TODO add try catch so I don't fubar loading my init.lua config?

    local command = string.format(
        'security find-generic-password -a %s -s %s -w 2>/dev/null',
        accountName,
        serviceName
    )

    local handle = io.popen(command)
    if not handle then
        print("Error: failed to get secret - handle is nil")
        return nil
    end
    local stdout = handle:read("*a")
    if not stdout then
        print("Error: failed to get secret - stdout is nil")
        return nil
    end
    handle:close()

    -- Trim surrounding whitespace (i.e. security output has newline)
    local trimmed = stdout:match("^%s*(.-)%s*$")
    if trimmed == "" then
        print("Error: failed to get secret - trimmed is empty")
        return nil
    end

    return trimmed
end

return M
