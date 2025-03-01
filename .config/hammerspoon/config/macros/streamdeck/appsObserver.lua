verbose = require("config.macros.streamdeck.helpers").verbose
pageSettings = require("config.macros.streamdeck.settings.page")
require("config.helpers")

local appModuleLookupByAppName = {
    ["Final Cut Pro"] = "fcpx",
    ["Hammerspoon"] = "hammerspoon",
    ["Microsoft PowerPoint"] = "pptx",
    ["Finder"] = "finder",
    ["iTerm2"] = "iterm",
    ["Brave Browser Beta"] = "brave",
    ["Safari"] = "safari",
    ["Preview"] = "preview",
}

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
    pageSettings.setAppsObserver(o)
    return o
end

function AppsObserver:onPageNumberChanged(deckName, appModuleName, _pageNumber)
    local deckController = self.decks.deckControllers[deckName]
    if deckController == nil then
        return
    end
    -- if the page changed for a different app then we don't need to do anything
    local currentApp = hs.application.frontmostApplication()
    if currentApp == nil then
        print("onPageNumberChanged: no current app")
        return
    end
    local currentAppName = currentApp:name()
    local currentAppModuleName = appModuleLookupByAppName[currentAppName]
    if currentAppName == nil or currentAppModuleName ~= appModuleName then
        print("onPageNumberChanged: current app module name (" .. currentAppModuleName .. ") does not match changed module name (" .. appModuleName .. ")")
        return
    end
    -- BTW it will lookup the page number so we don't need to pass that
    self:tryLoadProfileForDeck(deckName, deckController, currentAppName)
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

    local startTime = GetTime()

    function getProfile(appModuleName)
        if appModuleName == nil then
            return nil
        end
        local insideStartTime = GetTime()
        local module = require("config.macros.streamdeck.profiles." .. appModuleName)
        logMyTimes(appModuleName .. "-require took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        local pageNumber = pageSettings.getSavedPageNumber(deckName, appModuleName)
        -- TODO cache for duration of app lifetime? -- measure impact before doing that
        local selected = module:getProfilePage(deckName, pageNumber)
        logMyTimes(appModuleName .. "-getProfile took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        return selected
    end

    local appModuleName = appModuleLookupByAppName[appName]
    local selected = getProfile(appModuleName)
    if selected == nil then
        selected = getProfile("defaults")
    end

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
