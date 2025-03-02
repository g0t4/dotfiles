verbose = require("config.macros.streamdeck.helpers").verbose
pageSettings = require("config.macros.streamdeck.settings.page")

local appModuleLookupByAppName = {
    [APPS.FinalCutPro] = "fcpx",
    [APPS.Hammerspoon] = "hammerspoon",
    [APPS.MicrosoftPowerPoint] = "pptx",
    [APPS.Finder] = "finder",
    [APPS.iTerm] = "iterm",
    [APPS.BraveBrowserBeta] = "brave",
    -- [APPS.Safari] = "safari",
    -- [APPS.Preview] = "preview",
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
    -- TODO this is an intra-app event too (the page change is specific to the app!...  unless its a default page but lets deal with that later)
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
    self:tryLoadProfileForDeck(deckController, currentAppName)
end

--- only one at a time, so I can hand off all intra app observation and deck handling to the observer!
--- this App(s)Observer should focus only on inter app events (i.e. switching apps)
---@type AppsObserver|nil
local activeObserver = nil

function AppsObserver:onAppActivated(appName, hsApp)
    -- Deactivate the previous observer if it exists
    if activeObserver then
        activeObserver:deactivate()
    end

    -- Try to load the app-specific observer module
    local appModuleName = appModuleLookupByAppName[appName]
    if appModuleName then
        local success, module = pcall(require, "config.macros.streamdeck.profiles." .. appModuleName)
        if success and module then
            activeObserver = module
            activeObserver:activate(self.decks)
            return
        end
    end

    -- TODO mesh logic for default within appObserver so we can reuse one or more pages while having app specific pages, IIUC right now its default or app but not some of both
    -- Fall back to default profiles if no specific observer exists
    local success, defaultsModule = pcall(require, "config.macros.streamdeck.profiles.defaults")
    if success and defaultsModule then
        activeObserver = defaultsModule
        activeObserver:activate(self.decks)
    else
        -- No observer available, reset all decks
        for _, deckController in pairs(self.decks.deckControllers) do
            deckController.buttons:resetButtons()
        end
    end
end

---@param deck DeckController
---@param appName string
function AppsObserver:tryLoadProfileForDeck(deck, appName)
    -- TODO perf monitoring on various image sizes when setButtonImage is called,
    -- read code for Hammerspoon to guide image sizes
    -- or otherwise to try to optimize changing button images
    -- https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/streamdeck/HSStreamDeckDevice.m#L394
    -- StartProfiler()

    local deckName = deck.name

    ---@param appModuleName string
    ---@return Profile|nil
    function getProfile(appModuleName)
        if appModuleName == nil then
            return nil
        end
        ---@type AppObserver|nil
        local module = require("config.macros.streamdeck.profiles." .. appModuleName)
        if module == nil then
            print("Failed to load profiles module for app: " .. appModuleName)
            return nil
        end
        local pageNumber = pageSettings.getSavedPageNumber(deckName, appModuleName)
        local selected = module:getProfilePage(deck, pageNumber)
        if selected == nil and pageNumber ~= 1 then
            print("WARNING: Failed to get page " .. pageNumber .. " for deck " .. deckName .. " and app " .. appModuleName, "trying page 1")
            -- try 1, can happen if page is removed and was set as current still
            pageSettings.clearSavedPageNumber(deckName, appModuleName) -- clear so doesn't happen again
            selected = module:getProfilePage(deck, 1)
        end
        return selected
    end

    local appModuleName = appModuleLookupByAppName[appName]
    local selected = getProfile(appModuleName)
    if selected == nil then
        selected = getProfile("defaults")
    end

    if selected ~= nil then
        deck.hsdeck:reset() -- < 0.3ms
        selected:applyTo(deck)
        return
    end

    -- no profile page to show
    deck.buttons:resetButtons()
end

function AppsObserver:onAppDeactivated(appName, hsApp)
    -- verbose("app deactivated", appName)
    -- FYI happens after other app activates
end

---@param deck DeckController
function AppsObserver:loadCurrentAppForDeck(deck)
    -- when deck first connected, or for another reason...
    local currentApp = hs.application.frontmostApplication()
    -- verbose("  load: ", quote(currentApp:title()), "for", deck.name)
    self:tryLoadProfileForDeck(deck, currentApp:title())
end

function AppsObserver:start()
    self.watcher:start()
end

function AppsObserver:stop()
    self.watcher:stop()
end

return AppsObserver
