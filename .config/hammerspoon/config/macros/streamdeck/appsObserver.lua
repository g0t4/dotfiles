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

    -- TODO paralell? takes 70-100ms per deck, would ROCK to do in parallel
    --   TODO measure where bottleneck is... if it is file I/O then I might get speedups using background tasks to load image files..
    --   if it's crunching numbers => I can likely spin up a separate process per deck to load and set the deck buttons
    --   TODO also it might be smth trivial, in which case just fix it in-process!
    --   AFAICT there is no mechanism in hammerspoon to run concurrent tasks (short of using coroutines)?
    for deckName, deckController in pairs(self.decks.deckControllers) do
        self:tryLoadProfileForDeck(deckName, deckController, appName)
    end
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
        print("fcpx-require took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        selected = fcpx:getProfile(deckName)
        print("fcpx-getProfile took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
    elseif (appName == "iTerm2") then
        local insideStartTime = GetTime()
        local iterm = require("config.macros.streamdeck.profiles.iterm")
        print("iterm-require took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        selected = iterm:getProfile(deckName)
        print("iterm-getProfile took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
    end

    if selected == nil then
        local insideStartTime = GetTime()
        local fallback = require("config.macros.streamdeck.profiles.defaults")
        print("fallback-require took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        selected = fallback:getProfile(deckName)
        print("fallback-getProfile took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
    end

    if selected ~= nil then
        local insideStartTime = GetTime()
        -- verbose("applying", selected, "to", deckName)
        selected:applyTo(deckController)
        print("applyTo-alone took", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        print("FULL LOAD took", GetElapsedTimeInMilliseconds(startTime), "ms to apply", selected, "to", deckName)
        return
    end

    -- PRN revisit clear/reset... test any perf impact (if any)
    local clearStartTime = GetTime()
    -- TODO one adjustment, only clear buttons that had something applied to them...
    --   TODO or can I reset w/o the splashscreen showing?
    --   TODO as I suspected, setting the image is taking time...
    --     TODO see that code for timing... I bet if the image is sized appropriately, it's not as slow
    --       MY GUESS is resizing images is some of overhead
    --       ALSO, converting formats
    --       ALSO, is color button genreating an image, if so is that slow or?
    -- deckController.buttons:clearButtons() => 50 to 110ms!!!
    deckController.deck:reset() -- MUCH faster <1ms
    print("clearButtons-alone took", GetElapsedTimeInMilliseconds(clearStartTime), "ms to clear", deckName)
    print("FULL LOAD took", GetElapsedTimeInMilliseconds(startTime), "ms to clear", deckName)
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
