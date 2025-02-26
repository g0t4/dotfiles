---@class AppsObserver
---@field watcher hs.application.watcher
---@field decks DecksController
local AppsObserver = {}
AppsObserver.__index = AppsObserver

---@return AppsObserver
---@param decks DecksController
function AppsObserver:new(decks)
    local o = setmetatable({}, AppsObserver)
    o.decks = decks
    o.watcher = hs.application.watcher.new(function(appName, eventType, hsApp)
        if eventType == hs.application.watcher.activated then
            o:onAppActivated(appName, hsApp)
        elseif eventType == hs.application.watcher.deactivated then
            o:onAppDeactivated(appName, hsApp)
        end
    end)
    return o
end

function AppsObserver:onAppActivated(appName, hsApp)
    print("app activated", appName)
    local deckNames = self.decks:getDeckNames()
    if (appName == "com.apple.FinalCut") then
        local fcpx = require("config.macros.streamdeck.profiles.fcpx")
    end
end

function AppsObserver:onAppDeactivated(appName, hsApp)
    -- print("app deactivated", appName)
    -- FYI happens after other app activates
    -- TODO cleanup
end

function AppsObserver:start()
    self.watcher:start()
end

function AppsObserver:stop()
    self.watcher:stop()
end

return AppsObserver
