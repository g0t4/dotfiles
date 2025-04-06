local M = {}

M.lastTask = nil

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

    lastTask = hs.task.new("/usr/bin/curl", completeCallback, streamingCallback, args)

    lastTask:start()
end

return M
