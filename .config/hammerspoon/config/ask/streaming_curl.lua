local M = {}

function M.streamingRequest(url, method, headers, body, callback)
    local args = { "--no-buffer", "-X", method, url }

    for key, value in pairs(headers or {}) do
        table.insert(args, "-H")
        table.insert(args, string.format("%s: %s", key, value))
    end

    if body then
        table.insert(args, "-d")
        table.insert(args, body)
    end

    local task = hs.task.new("/usr/bin/curl",
        function(exitCode, stdOut, stdErr)
            if exitCode ~= 0 then
                return callback(false, stdErr, exitCode)
            else
                return callback(true, stdOut, exitCode)
            end
        end,
        function(task, chunk)
            return callback(true, chunk)
        end,
        args
    )

    task:start()
end

return M
