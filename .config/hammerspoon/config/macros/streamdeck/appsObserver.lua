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

    for deckName, deckController in pairs(self.decks.deckControllers) do
        print("  considering:", deckController)

        ---@type Profile
        local selected = nil
        if (appName == "Final Cut Pro") then
            local fcpx = require("config.macros.streamdeck.profiles.fcpx")
            selected = fcpx:getProfile(deckName)
        else
            print("  TODO default profile fallback logic")
        end
        -- TODO iterm2 next
        print("  selected:", selected)

        if selected ~= nil then
            print("applying", selected, "to", deckName)
            selected:applyTo(deckController)
            return
        end
        -- CLEAR BUTTONS? OR would calling stop previously do that?
        deckController.buttons:clearButtons()
    end
end

function AppsObserver:onAppDeactivated(appName, hsApp)
    -- print("app deactivated", appName)
    -- FYI happens after other app activates
    -- TODO cleanup
end

function AppsObserver:start()
    self.watcher:start()

    -- activate for current app
    local currentApp = hs.application.frontmostApplication()
    self:onAppActivated(currentApp:title(), currentApp)
end

function AppsObserver:stop()
    self.watcher:stop()
end

return AppsObserver
