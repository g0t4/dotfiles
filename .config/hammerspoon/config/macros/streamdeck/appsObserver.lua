require("config.macros.streamdeck.helpers")
require("config.helpers")

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
    o.decks.appsObserver = o
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
    -- verbose("app activated", appName)

    -- TODO can I do decks in parallel?
    --  I imagine w/ File I/O it might make a difference to load in parallel instead of series
    --  TODO measure timings
    for deckName, deckController in pairs(self.decks.deckControllers) do
        self:tryLoadProfileForDeck(deckName, deckController, appName)
    end
end

---@param deckName string
---@param deckController DeckController
---@param appName string
function AppsObserver:tryLoadProfileForDeck(deckName, deckController, appName)
    ---@type Profile
    local selected = nil
    if (appName == "Final Cut Pro") then
        local fcpx = require("config.macros.streamdeck.profiles.fcpx")
        selected = fcpx:getProfile(deckName)
    elseif (appName == "iTerm2") then
        local iterm = require("config.macros.streamdeck.profiles.iterm")
        selected = iterm:getProfile(deckName)
    end

    if selected == nil then
        local fallback = require("config.macros.streamdeck.profiles.defaults")
        selected = fallback:getProfile(deckName)
    end

    if selected ~= nil then
        -- verbose("applying", selected, "to", deckName)
        selected:applyTo(deckController)
        return
    end

    -- PRN revisit clear/reset... test any perf impact (if any)
    deckController.buttons:clearButtons()
end

function AppsObserver:onAppDeactivated(appName, hsApp)
    -- verbose("app deactivated", appName)
    -- FYI happens after other app activates
    -- TODO cleanup
end

---@param deck DeckController
function AppsObserver:loadCurrentAppForDeck(deck)
    -- when deck first connected, or for another reason...
    local currentApp = hs.application.frontmostApplication()
    -- verbose("  load: ", quote(currentApp:title()), "for", deck.name)
    self:tryLoadProfileForDeck(deck.name, deck, currentApp:title())
end

function AppsObserver:start()
    self.watcher:start()
end

function AppsObserver:stop()
    self.watcher:stop()
end

return AppsObserver
