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

--- only one at a time, so I can hand off all intra app observation and deck handling to the observer!
--- this App(s)Observer should focus only on inter app events (i.e. switching apps)
---@type AppsObserver|nil
local activeObserver = nil

function AppsObserver:onPageNumberChanged(deckName, appModuleName, pageNumber)
    -- TODO push into appObserver (it should be able to detect its own page change and handle it there)
    --   TODO see appObserver.setSavedPageNumber and pageSettings.getSavedPageNumber (s/b able to remove coupling in page settings!)

    -- Delegate to the active observer if appropriate
    if activeObserver and activeObserver:getModuleName() == appModuleName then
        activeObserver:handlePageChange(deckName, pageNumber)
    end
end

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
    -- This function can be simplified since the activeObserver now handles profile loading
    local appModuleName = appModuleLookupByAppName[appName]

    if activeObserver and activeObserver:getModuleName() == (appModuleName or "") then
        -- TODO when would this happen? do I even need this here or can it be simplified?
        --    TODO INTRA APP events is only time I could think that the app wouldn't change here

        -- Let the active observer handle it
        if activeObserver:loadProfileForDeck(deck) then
            return
        end
    end

    -- Try to load default profile if app-specific profile failed
    if appModuleName == nil or activeObserver == nil then
        local success, defaultsModule = pcall(require, "config.macros.streamdeck.profiles.defaults")
        if success and defaultsModule then
            local tempObserver = defaultsModule
            if tempObserver:loadProfileForDeck(deck) then
                return
            end
        end
    end

    -- No profile available, reset the deck
    deck.buttons:resetButtons()
end

function AppsObserver:onAppDeactivated(appName, hsApp)
    -- verbose("app deactivated", appName)
    -- FYI happens after other app activates
end

---@param deck DeckController
function AppsObserver:loadCurrentAppForDeck(deck)
    -- TODO can I remove this extra layer too? seems vestigial possibly for old integration point
    local currentApp = hs.application.frontmostApplication()
    if currentApp then
        self:tryLoadProfileForDeck(deck, currentApp:title())
    end
end

function AppsObserver:start()
    self.watcher:start()
end

function AppsObserver:stop()
    self.watcher:stop()
end

return AppsObserver
