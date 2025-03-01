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
    -- TODO perf monitoring on various image sizes when setButtonImage is called,
    -- read code for Hammerspoon to guide image sizes
    -- or otherwise to try to optimize changing button images
    -- https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/streamdeck/HSStreamDeckDevice.m#L394
    -- StartProfiler()

    -- TODO add ability to switch pages
    --   TODO store current page across restarts?

    local startTime = GetTime()
    ---@type Profile
    local selected = nil
    local appLookup = {
        ["Final Cut Pro"] = "fcpx",
        ["Hammerspoon"] = "hammerspoon",
        ["Microsoft PowerPoint"] = "pptx",
        ["Finder"] = "finder",
        ["iTerm2"] = "iterm",
        ["Brave Browser Beta"] = "brave",
        ["Safari"] = "safari",
        ["Preview"] = "preview",
    }

    local moduleName = appLookup[appName]
    if moduleName == nil then
        moduleName = "defaults"
    end

    local insideStartTime = GetTime()
    local module = require("config.macros.streamdeck.profiles." .. moduleName)
    logMyTimes(moduleName .. "-require took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
    selected = module:getProfilePage(deckName, 1)
    logMyTimes(moduleName .. "-getProfile took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")

    if selected ~= nil then
        local insideStartTime = GetTime()
        deckController.hsdeck:reset() -- < 0.3ms
        -- FYI applyTo calls removeButtons too, so just need :reset here
        selected:applyTo(deckController)
        logMyTimes("applyTo-alone took", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        logMyTimes("FULL LOAD took", GetElapsedTimeInMilliseconds(startTime), "ms to apply", selected, "to", deckName)
        -- StopProfiler("streamdeck-bootstrap" .. startTime .. "." .. appName .. "." .. deckName .. ".txt")
        return
    end

    local clearStartTime = GetTime()
    deckController.buttons:resetButtons()
    logMyTimes("clearButtons-alone took", GetElapsedTimeInMilliseconds(clearStartTime), "ms to clear", deckName)
    logMyTimes("FULL LOAD took", GetElapsedTimeInMilliseconds(startTime), "ms to clear", deckName)

    -- StopProfiler("streamdeck-bootstrap" .. startTime .. "." .. appName .. "." .. deckName .. ".txt")
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
