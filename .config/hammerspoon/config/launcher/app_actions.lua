-- App-specific lifecycle handlers; no generic kill/relaunch fallback.
local M = {}
local log = require("config.logs").hammerspoons()
local powerpointBundleID = "com.microsoft.Powerpoint"
local pendingRestarts = {}

local function canRestart(context)
    if not context or (context.source ~= "pip-rot" and context.source ~= "powerpoint") then return false end
    for _, capability in ipairs(context.capabilities or {}) do
        if capability == "restart" then return true end
    end
    return false
end

function M.choices(context)
    if not canRestart(context) then return {} end
    local description = context.source == "powerpoint"
        and "PowerPoint · quit and relaunch; reopen your presentation afterward"
        or "Pip Rot · restore tabs and current directory"
    return {{text = "Restart App", subText = description,
        action = "restart_app", app_context = context,
        image = hs.image.imageFromName("NSRefreshTemplate")}}
end

function M.restart(context)
    if not canRestart(context) then return false end
    if context.source == "powerpoint" then
        local app = hs.application.applicationForPID(context.pid)
        if not app or app:bundleID() ~= powerpointBundleID then
            hs.alert.show("PowerPoint is no longer available")
            return false
        end
        if pendingRestarts[context.pid] then return false end
        -- Graceful quit preserves PowerPoint's save/cancel prompts. Never force quit.
        -- Relaunch only after this exact process exits; document restoration comes later.
        local attempts = 0
        local timer
        timer = hs.timer.doEvery(0.2, function()
            attempts = attempts + 1
            if not hs.application.applicationForPID(context.pid) then
                timer:stop()
                pendingRestarts[context.pid] = nil
                if not hs.application.launchOrFocusByBundleID(powerpointBundleID) then
                    hs.alert.show("Could not relaunch PowerPoint")
                end
            elseif attempts >= 300 then
                timer:stop()
                pendingRestarts[context.pid] = nil
                hs.alert.show("PowerPoint restart stopped: quit was canceled or is still pending")
            end
        end)
        pendingRestarts[context.pid] = timer
        app:kill()
        return true
    end
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
