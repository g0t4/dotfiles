-- App-specific lifecycle handlers; no generic kill/relaunch fallback.
local M = {}
local log = require("config.logs").hammerspoons()

local function canRestart(context)
    if not context or context.source ~= "pip-rot" then return false end
    for _, capability in ipairs(context.capabilities or {}) do
        if capability == "restart" then return true end
    end
    return false
end

function M.choices(context)
    if not canRestart(context) then return {} end
    return {{text = "Restart App", subText = "Pip Rot · restore tabs and current directory",
        action = "restart_app", app_context = context,
        image = hs.image.imageFromName("NSRefreshTemplate")}}
end

function M.restart(context)
    if not canRestart(context) then return false end
    local directory = os.getenv("HOME") .. "/.local/state/pip-rot/"
    local live = hs.json.read(directory .. "context-" .. context.pid .. ".json")
    if not canRestart(live) or live.pid ~= context.pid or not hs.application.applicationForPID(context.pid) then
        hs.alert.show("Pip Rot is no longer available")
        return false
    end
    local filename = directory .. "request-" .. context.pid .. ".json"
    local temporary = filename .. ".tmp"
    local file, err = io.open(temporary, "w")
    if file then
        file:write(hs.json.encode({version = 1, pid = context.pid, command = "restart"}))
        file:close()
        local ok
        ok, err = os.rename(temporary, filename)
        if ok then
            log:info("Requested Pip Rot restart:", context.pid)
            return true
        end
        os.remove(temporary)
    end
    log:error("Could not request restart:", err)
    hs.alert.show("Could not request Pip Rot restart")
    return false
end

return M
