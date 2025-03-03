local f = require("config.helpers.underscore")
verbose = require("config.macros.streamdeck.helpers").verbose

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
    o.interAppWatcher = hs.application.watcher.new(function(appTitle, eventType, hsApp)
        if eventType == hs.application.watcher.activated then
            o:onAppActivated(appTitle, hsApp)
        elseif eventType == hs.application.watcher.deactivated then
            o:onAppDeactivated(appTitle, hsApp)
        end
    end)
    return o
end

--- only one at a time, so I can hand off all intra app observation and deck handling to the observer!
--- this App(s)Observer should focus only on inter app events (i.e. switching apps)
---@type AppObserver|nil
local activeObserver = nil
local defaultObserver = nil

---@param appTitle string
---@param _hsApp hs.application
function AppsObserver:onAppActivated(appTitle, _hsApp)
    -- Deactivate the previous observers
    if activeObserver then
        activeObserver:deactivate()
    end
    if defaultObserver then
        defaultObserver:deactivate()
    end
    print("\n\n") -- TMP TIMING ANALYSIS
    print("onAppActivated " .. appTitle) -- TMP TIMING ANALYSIS

    ---@type table<string, DeckController>
    local unclaimedDecks = self.decks.deckControllers

    -- Try to load the app-specific observer module
    local appModuleName = AppModuleName(appTitle)
    if appModuleName then
        local success, module = pcall(require, "config.macros.streamdeck.profiles." .. appModuleName)
        if success and module then
            activeObserver = module
            -- BTW this app specific observer is now active EVEN IF NO DECKS ARE CLAIMED BY IT
            --    and that's good b/c a new deck may be in the process of connecting!
            activeObserver:activate(unclaimedDecks)
            unclaimedDecks = f.whereValues(unclaimedDecks, function(deck)
                return not activeObserver.claimedDecks[deck.name]
            end)
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
        unclaimedDecks = f.whereValues(unclaimedDecks, function(deck)
            return not defaultObserver.claimedDecks[deck.name]
        end)
        if unclaimedDecks == {} then
            return
        end
    end

    -- reset any remaining unclaimed decks
    for _, deckController in pairs(unclaimedDecks) do
        deckController.buttons:resetButtons()
    end
end

---@param deck DeckController
function AppsObserver:onNewDeckConnected(deck)
    if activeObserver then
        local claimed = activeObserver:tryClaimNewDeck(deck)
        if claimed then
            print("  claimed by:", activeObserver.appTitle)
            return
        end
    end

    if defaultObserver then
        local claimed = defaultObserver:tryClaimNewDeck(deck)
        if claimed then
            return
        end
    end

    print("  new deck not claimed, resetting buttons")
    deck.buttons:resetButtons()
end

function AppsObserver:onAppDeactivated(appTitle, hsApp)
    -- verbose("app deactivated", appTitle)
    -- FYI happens after other app activates
end

function AppsObserver:start()
    -- on start we need to take current app and make its observer active
    local hsApp = hs.application.frontmostApplication()
    if not hsApp then return end
    self:onAppActivated(hsApp:title(), hsApp)
    self.interAppWatcher:start()
end

function AppsObserver:stop()
    self.interAppWatcher:stop()
end

return AppsObserver
