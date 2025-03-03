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
_G.APP_MODULE_LOOKUP_BY_APP_NAME = appModuleLookupByAppName

---@class AppsObserver
---@field interAppWatcher hs.application.watcher
---@field decks DecksController
local AppsObserver = {}
AppsObserver.__index = AppsObserver

---@return AppsObserver
---@param decks DecksController
function AppsObserver:new(decks)
    local o = setmetatable({}, AppsObserver)
    o.decks = decks
    o.decks.appsObserver = o
    o.interAppWatcher = hs.application.watcher.new(function(appName, eventType, hsApp)
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

function AppsObserver:onPageNumberChanged(deckName, appNameAsSettingsKey, pageNumber)
    -- TODO push into appObserver (it should be able to detect its own page change and handle it there)
    --   TODO see appObserver.setSavedPageNumber and pageSettings.getSavedPageNumber (s/b able to remove coupling in page settings!)


    -- TODO MOVE appNameAsSettingsKey =>  back to AppModule that it should've been in the first place...
    -- Delegate to the active observer if appropriate
    if activeObserver and activeObserver:appNameSettingsKey() == appNameAsSettingsKey then
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
function AppsObserver:onNewDeckConnected(deck)
    -- FYI! ONLY USED BY DECK CONNECTED HANDLER... so let's clean this up..
    --    AND IT DOESN'T EVEN SEEM TO WORK ON CONFIG RELOAD :)
    local hsApp = hs.application.frontmostApplication()
    if not hsApp then return end
    print("loading current app for deck", deck.name, quote(hsApp:title()))

    -- TODO This function can be simplified since the activeObserver now handles profile loading

    local appName = hsApp:title()
    if not appName then return end

    if activeObserver and activeObserver.appName == appName then
        if activeObserver:loadProfileForDeck(deck) then
            print("  loaded profile with activeObserver")
            return
        end
        -- TODO issue is addProfilePage call happens w/o the new decks so pages are not loaded so then we have to trigger activate below
        --    TODO fix adding a new deck to an existing observer...
        --       TODO need to impl the logic to gracefully add it in so we don't refresh all decks 4x on every config reload!
        --    then if I fake fire an app activate in bootrstrap then the observer will be ready and only flash that deck one time
        --      TODO add fake app activate to bootstrap.lua (before starting this apps observer)
        print("  could not load profile with activeObserver")
    end

    print("  trigger fake app activated to add deck")
    self:onAppActivated(appName, hsApp)
end

function AppsObserver:onAppDeactivated(appName, hsApp)
    -- verbose("app deactivated", appName)
    -- FYI happens after other app activates
end

function AppsObserver:start()
    self.interAppWatcher:start()
end

function AppsObserver:stop()
    self.interAppWatcher:stop()
end

return AppsObserver
