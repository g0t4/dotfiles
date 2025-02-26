---@class AppsObserver
---@field watcher hs.application.watcher
local AppsObserver = {}
AppsObserver.__index = AppsObserver

---@return AppsObserver
function AppsObserver:new()
    local o = setmetatable({}, AppsObserver)
    o.watcher = hs.application.watcher.new(function(appName, eventType, hsApp)
        -- btw this wrapper func exists b/c lua won't let me do new(o:onAppEvent)
        --   and I don't want the logic buried in here
        o:onAppEvent(appName, eventType, hsApp)
    end)
    return o
end

function AppsObserver:onAppEvent(appName, eventType, hsApp)
    if eventType == hs.application.watcher.activated then
        print("app activated", appName)
    elseif eventType == hs.application.watcher.deactivated then
        print("app deactivated", appName)
    end
end

function AppsObserver:start()
    self.watcher:start()
end

function AppsObserver:stop()
    self.watcher:stop()
end

return AppsObserver
