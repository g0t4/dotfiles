verbose = require("config.macros.streamdeck.helpers").verbose
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

    -- TODO paralell? takes 70-100ms per deck, would ROCK to do in parallel
    --   TODO measure where bottleneck is... if it is file I/O then I might get speedups using background tasks to load image files..
    --   if it's crunching numbers => I can likely spin up a separate process per deck to load and set the deck buttons
    --   TODO also it might be smth trivial, in which case just fix it in-process!
    --   AFAICT there is no mechanism in hammerspoon to run concurrent tasks (short of using coroutines)?
    for deckName, deckController in pairs(self.decks.deckControllers) do
        self:tryLoadProfileForDeck(deckName, deckController, appName)
    end
end

local function logMyTimes(...)
    -- verbose(...)
    -- print(...)
end

---@param deckName string
---@param deckController DeckController
---@param appName string
function AppsObserver:tryLoadProfileForDeck(deckName, deckController, appName)
    local startTime = GetTime()
    ---@type Profile
    local selected = nil
    if (appName == "Final Cut Pro") then
        local insideStartTime = GetTime()
        local fcpx = require("config.macros.streamdeck.profiles.fcpx")
        logMyTimes("fcpx-require took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        selected = fcpx:getProfile(deckName)
        logMyTimes("fcpx-getProfile took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
    elseif (appName == "iTerm2") then
        local insideStartTime = GetTime()
        local iterm = require("config.macros.streamdeck.profiles.iterm")
        logMyTimes("iterm-require took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        selected = iterm:getProfile(deckName)
        logMyTimes("iterm-getProfile took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
    end

    if selected == nil then
        local insideStartTime = GetTime()
        local fallback = require("config.macros.streamdeck.profiles.defaults")
        logMyTimes("fallback-require took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        selected = fallback:getProfile(deckName)
        logMyTimes("fallback-getProfile took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
    end

    if selected ~= nil then
        local insideStartTime = GetTime()
        deckController.deck:reset() -- < 0.3ms
        -- FYI applyTo calls removeButtons too, so just need :reset here
        selected:applyTo(deckController)
        logMyTimes("applyTo-alone took", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        logMyTimes("FULL LOAD took", GetElapsedTimeInMilliseconds(startTime), "ms to apply", selected, "to", deckName)
        return
    end

    local clearStartTime = GetTime()
    deckController.buttons:resetButtons()
    logMyTimes("clearButtons-alone took", GetElapsedTimeInMilliseconds(clearStartTime), "ms to clear", deckName)
    logMyTimes("FULL LOAD took", GetElapsedTimeInMilliseconds(startTime), "ms to clear", deckName)
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
