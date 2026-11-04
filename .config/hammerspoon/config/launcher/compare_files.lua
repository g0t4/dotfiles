-- Byte comparison, without diff output, clipboard writes, or blocking the UI.
local M = {}
local tasks = {}

function M.compare(paths, context)
    if #paths ~= 2 then return end
    for _, path in ipairs(paths) do
        if hs.fs.attributes(path, "mode") ~= "file" then
            hs.alert.show("Select exactly two regular files")
            return
        end
    end
    local task
    task = hs.task.new("/usr/bin/cmp", function(code, _, stderr)
        tasks[task] = nil
        local message = code == 0 and "Files are identical" or
            (code == 1 and "Files differ" or "Could not compare files")
        local warning = code ~= 0
        if code > 1 then require("config.logs").launcher():error(message, stderr) end
        if context and context.source == "pip-rot" then
            local directory = os.getenv("HOME") .. "/.local/state/pip-rot/"
            local live = hs.json.read(directory .. "context-" .. context.pid .. ".json")
            local statusSupported = false
            for _, capability in ipairs(live and live.capabilities or {}) do
                if capability == "status" then statusSupported = true end
            end
            if statusSupported and live.pid == context.pid and hs.application.applicationForPID(context.pid) then
                local filename = directory .. "status-" .. context.pid .. ".json"
                local temporary = filename .. ".tmp"
                local file = io.open(temporary, "w")
                if file then
                    file:write(hs.json.encode({version=1, pid=context.pid, message=message, warning=warning}))
                    file:close()
                    if os.rename(temporary, filename) then return end
                    os.remove(temporary)
                end
            end
        end
        hs.alert.show(message)
    end, {"-s", paths[1], paths[2]})
    if not task then hs.alert.show("Could not start file comparison"); return end
    tasks[task] = true
    if not task:start() then
        tasks[task] = nil
        hs.alert.show("Could not start file comparison")
    end
end

return M
