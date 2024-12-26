local M = {}

function M.streamingRequest(url, method, headers, body, streamingCallback, completeCallback)
    local args = { "-fsSL", "--no-buffer", "-X", method, url }

    for key, value in pairs(headers or {}) do
        table.insert(args, "-H")
        table.insert(args, string.format("%s: %s", key, value))
    end

    if body then
        table.insert(args, "-d")
        table.insert(args, body)
    end

    local task = hs.task.new("/usr/bin/curl", completeCallback, streamingCallback, args)

    task:start()
end

return M
