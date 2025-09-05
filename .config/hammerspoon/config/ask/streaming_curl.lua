local M = {}

---@type hs.task
M.last_task = nil

function M.streamingRequest(url, method, headers, body, streaming_callback, complete_callback)
    if last_task and last_task:isRunning() then
        -- TODO stop handlers from reporting errors after terminated
        --   PROBABLY should return back the task and let the caller track its status
        last_task:terminate()
        last_task = nil
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

    last_task = hs.task.new("/usr/bin/curl", complete_callback, streaming_callback, args)

    last_task:start()
    return last_task
end

return M
