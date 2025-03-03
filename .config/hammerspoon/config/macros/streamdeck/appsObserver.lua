local f = require("config.helpers.underscore")
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
---@type AppObserver|nil
local activeObserver = nil
local defaultObserver = nil

function AppsObserver:onPageNumberChanged(deckName, appModuleName, pageNumber)
    -- TODO push into appObserver (it should be able to detect its own page change and handle it there)
    --   TODO see appObserver.setSavedPageNumber and pageSettings.getSavedPageNumber (s/b able to remove coupling in page settings!)

    -- Delegate to the active observer if appropriate
    if activeObserver and activeObserver:getModuleName() == appModuleName then
        activeObserver:handlePageChange(deckName, pageNumber)
    end
end

---@param appName string
---@param hsApp hs.application
function AppsObserver:onAppActivated(appName, hsApp)
    -- Deactivate the previous observers
    if activeObserver then
        activeObserver:deactivate()
    end
    if defaultObserver then
        defaultObserver:deactivate()
    end

    ---@type table<string, DeckController>
    local unclaimedDecks = f.shallowCopyTable(self.decks.deckControllers)

    -- Try to load the app-specific observer module
    local appModuleName = appModuleLookupByAppName[appName]
    if appModuleName then
        local success, module = pcall(require, "config.macros.streamdeck.profiles." .. appModuleName)
        if success and module then
            activeObserver = module
            activeObserver:activate(unclaimedDecks)
            unclaimedDecks = f.where(unclaimedDecks, function(deck)
                return not activeObserver.claimedDecks[deck.name]
            end)
            print("app observer claimed:", hs.inspect(f.keys(activeObserver.claimedDecks)))
            print("  unclaimed decks:", hs.inspect(f.keys(unclaimedDecks)))
            if unclaimedDecks == {} then
                return
            end
        end
    end

    -- Fall back to default profiles for unclaimed decks
    if not defaultObserver then
        -- load default observer (if not already loaded)
        local success, defaultsModule = pcall(require, "config.macros.streamdeck.profiles.defaults")
        if success and defaultsModule then
            defaultObserver = defaultsModule
        end
    end

    if defaultObserver then
        defaultObserver:activate(unclaimedDecks)
        unclaimedDecks = f.where(unclaimedDecks, function(deck)
            return not defaultObserver.claimedDecks[deck.name]
        end)
        print("default observer claimed:", hs.inspect(f.keys(defaultObserver.claimedDecks)))
        if unclaimedDecks == {} then
            return
        end
    end
    print("  unclaimed decks (resetting):", hs.inspect(f.keys(unclaimedDecks)))

    -- reset any remaining unclaimed decks
    for _, deckController in pairs(unclaimedDecks) do
        deckController.buttons:resetButtons()
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
        -- COUlD happen if deck connects (i.e. reconnectts, or new)

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
