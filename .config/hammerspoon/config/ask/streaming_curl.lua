local M = {}

---@type hs.task
M.lastTask = nil

function M.streamingRequest(url, method, headers, body, streamingCallback, completeCallback)
    if lastTask and lastTask:isRunning() then
        -- TODO stop handlers from reporting errors after terminated
        --   PROBABLY should return back the task and let the caller track its status
        lastTask:terminate()
        lastTask = nil
    end

    local args = { "--fail-with-body", "-sSL", "--no-buffer", "-X", method, url }

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
    return lastTask
end

return M
