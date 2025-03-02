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

function AppsObserver:onAppActivated(appName, hsApp)
    -- verbose("app activated", appName)
    self:testBraveNotificationObserver(appName, hsApp)

    -- parallel could help, but so could optimizing switching button images
    for _deckName, deckController in pairs(self.decks.deckControllers) do
        self:tryLoadProfileForDeck(deckController, appName)
    end
end

---@type hs.axuielement.observer|nil
local notificationObserver = nil
local tmpDeck3HasButtonMods = nil
function AppsObserver:testBraveNotificationObserver(appName, hsApp)
    -- STOP and START new NOTIFICATION OBSERVER
    if notificationObserver ~= nil then
        notificationObserver:stop()
    end

    local thisAppsObserver = self
    local appElement = hs.axuielement.applicationElement(hsApp)
    if appName ~= APPS.BraveBrowserBeta then
        print("ONLY DOING DYNAMIC PROFILES For BRAVE CURRENTLY")
    else
        -- FIRST PASS OF INTRA APP CHANGING BUTTONS (working, now migrating to profilepages)
        notificationObserver = hs.axuielement.observer.new(hsApp:pid())
        assert(notificationObserver ~= nil)
        notificationObserver:addWatcher(appElement, "AXTitleChanged")
        notificationObserver:addWatcher(appElement, "AXFocusedWindowChanged")
        -- FYI app changed trigger (to browser window w/ current tab on docs...) that will be handled by current AppsObserver app switch monitoring (when merged with this logic)
        --   OR... I could fire this after app changes and go that route if this is best kept separate
        -- ! FOR NOW DO NOT TEST WITH SWITCHING TO/FROM BRAVE w/ google docs in focused window (that will come with final integration into page loading)
        notificationObserver:callback(
        ---@param _observer hs.axuielement.observer
        ---@param element hs.axuielement
        ---@param notification string
        ---@param _detailsTable table
            function(_observer, element, notification, _detailsTable)
                -- brave browser nav slashdot - new tab - nav digg (AXWindow events only):
                --   AXTitleChanged AXWindow 'Slashdot: News for nerds, stuff that matters - Brave Beta - wes private'
                --   AXTitleChanged AXWindow 'New Tab - Brave Beta - wes private'
                --   AXCreated AXWindow ''
                --   AXWindowCreated AXWindow ''
                --   AXResized AXWindow ''
                --   AXWindowResized AXWindow ''
                --   AXTitleChanged AX  Window 'News and Trending Stories Around the Internet | Digg - Brave Beta - wes private'
                --
                --   AXWindow title changed covers:
                --     1. new addy into omnibox (submitted)
                --     2. change tabs
                --     3. open new tab
                --     4. NOT switch windows
                --
                --   AXFocusedWindowChanged covers:
                --     1. switch windows
                --     2. open new window

                -- pick filters based on rarity of events (cursory testing)
                --   esp make sure any expensive checks are last
                local role = element:attributeValue("AXRole")
                if role ~= "AXWindow" then
                    -- ignore non-window events
                    -- technically ignore role entirely for title changed events
                    --   and for focus window changed events that s/b AXWindow always
                    --   not important to distinguish for now
                    return
                end
                if notification ~= "AXTitleChanged" and notification ~= "AXFocusedWindowChanged" then
                    -- technically shouldn't happen unless I expand the list of notifications
                    print("[WindowTitleChanges]unexpected notification type (did you add a notification type?): " .. notification)
                    return
                end
                local appElement = element:attributeValue("AXParent")
                if appElement == nil then
                    print("[WindowTitleChanges] no parent, should never happen!")
                    return
                end
                local focusedWindowElem = appElement:attributeValue("AXFocusedWindow")
                if focusedWindowElem == nil then
                    print("[WindowTitleChanges] no focused window, should never happen!")
                    return
                end
                if focusedWindowElem ~= element then
                    print("[WindowTitleChanges] non-focused window title changed, skipping...")
                    return
                end

                local parts = {
                    axTitleQuoted(element),
                    axDescriptionQuoted(element),
                    axValueQuoted(element),
                }
                local message = table.concat(parts, " ")

                -- -- FYI! AXDocument is often stale
                -- local axDocument = element:attributeValue("AXDocument")
                -- if axDocument ~= nil then
                --     message = message .. "\n  (may be stale) URL: " .. axDocument
                -- end

                local urlTextField = focusedWindowElem:group(1):group(1):group(1):group(1):toolbar(1):group(1):textField(1)
                if urlTextField ~= nil then
                    local value = urlTextField:attributeValue("AXValue")
                    -- YAY... I am reliably finding the URL text field and it's correct even when AXDocument is stale
                    --
                    -- textbox for URL bar:
                    --   app:window(1):group(1):group(1):group(1):group(1):toolbar(1):group(1):textField(1)
                    --
                    -- noteworthy attributes:
                    --   AXDescription = "Address and search bar"
                    --   AXPlaceholderValue = "Search Brave or type a URL"
                    --   AXKeyShortcutsValue = "⌘L"
                    --   AXValue = "https://www.reddit.com"
                    --   ChromeAXNodeId = "1028"
                    --
                    --   hierarchy of this attr, super helpful if I have to go the search route in the future or have other issues!
                    --   AXDOMClassList = {1="BraveOmniboxViewViews"} textField(1) [THIS IS THE URL BOX]
                    --     AXDOMClassList = {1="BraveLocationBarView"} group(1)
                    --       AXDOMClassList = {1="BraveToolbarView"} toolbar(1)
                    --         AXDOMClassList = {1="BraveBrowserView"} group(1)
                    --           AXDOMClassList = {1="BrowserNonClientFrameView"} group(1)
                    --             AXDOMClassList = {1="NonClientView"} group(1)
                    --               AXDOMClassList = {1="BraveBrowserRootView"} group(1)
                    --                 window(1)
                    --                   app
                    message = message .. "\n  urlTextField: " .. value
                end
                print(message)

                do return end -- !!! STOP THIS FIRST TEST for NOW... its moved to profile page!
                -- ! Get rid of following once I am happy with profile page approach
                --    LEAVE AS EXAMPLE UNTIL THEN

                -- TODO move elsewhere once I smoothout any issues with swapping buttons on top of the profile buttons
                --   TODO I will want a addProfilePageMods(...) method of some sort that registers modifications
                --      including events to observe and handler that returns list of buttons!
                --      don't make it generic just yet, do that after I have multiple apps w/ real use cases...
                --      for now this is just a POC...
                --      and really I don't need this until I have more browser buttons (only a few for google docs currently)
                --       I suspect I will make many more though with site based profiles/mods
                --      ultimately will generate multiple sets of buttons all in one go so we don't have to call it 4 times (1 per deck)
                --
                local deckName = DECK_3XL
                local pageNumber = PAGE_1
                local km_docs_menu_item = "B06C1815-51D0-4DD7-A22C-5A3C39C4D1E0"


                if urlTextField == nil then
                    print("no urlTextField, skipping...")
                    return
                end

                local deck = thisAppsObserver.decks.deckControllers[deckName]
                local MaestroButton = require("config.macros.streamdeck.maestroButton")
                local buttons = {
                    MaestroButton:new(31, deck, hsCircleIcon("#FFFF00", deck),
                        km_docs_menu_item, "Highlight color yellow"),
                    MaestroButton:new(32, deck, hsCircleIcon("#FF0000", deck),
                        km_docs_menu_item, "Highlight color red"),
                }


                local value = urlTextField:attributeValue("AXValue")

                tmpDeck3HasButtonMods = value
                local isNowGoogle = value:find("https://docs.google.com")
                if tmpDeck3HasButtonMods or isNowGoogle then
                    -- reset if leaving mods page, or set if entering mods page
                    --   otherwise don't reset if not to/from mods (needless flickering)
                    -- PRN would be nice to track if google_docs => google_docs and also not reload in this case
                    --   however these conditions are not absolutely essential... if I am working on Google Docs..
                    --     i won't be changing sites rapidly enough to care about the flicker
                    -- in the ideal world, I would track individual buttons and for mods only change the ones that need it for intra app events
                    -- wait.. if I kept track of button mods from last profile change (app change)...
                    --   had profile page and mods stored.. I could use that for intra app changes to
                    --   only change the buttons that differ... hrm!

                    thisAppsObserver:loadCurrentAppForDeck(deck)
                    -- TODO setButtons or updateButtons? addButtons is kinda misleading
                    if isNowGoogle then
                        deck.buttons:addButtons(buttons)
                    end
                    -- TODO any issues calling start a 2nd time? i.e. clock button? if so that button should cache if it is running
                    deck:start()
                    tmpDeck3HasButtonMods = true
                else
                    tmpDeck3HasButtonMods = false
                end
                -- * ultimately I think it makes sense to have profile loader handle the mods too
                --   b/c it has to check the current window title when switching apps
                --   so if it does it all for a given profile I can just trigger it and let it do the rest
                --   I can still have special event that doesn't reload profiles UNLESS mods to make
                --   then for mods why not just apply it after reloading the deck's profile
                --   that way I never have to "put back" buttons from underlying profile

                -- TODO make sure current app still matches? another reason to push most logic into profile loader so buttons are consistently selected

                -- Consider rapid fire events
                -- - Print warnings every # in Y short period of time?
                --     might be obvious though when stuff locks up :)
                -- - if rapid app changes causes issues => use debouncing (on 2nd+)
                --   first event after long duration X, handle immediately (no debouncing)
                --   second (within Y short duration of first), then debounce it and the rest
                --     until quiet enough that hopefully events have stopped
                --     think of a triggered debounce (if that makes sense)
                --     probably could even do this for 50-100ms and not notice...
                --       but only do this if you need a rapid fire event
                --       ideally rare events for dynamic profile changes
                -- - BTW the reason why I don't want the first one throttled is b/c
                --     most of the time it's only the first one that shows up!
                --     so, don't delay it too unless second arrives in which case first is useless
                -- - or, maybe think of it as cancel on next event
                --     so, if processing first event is not complete
                --       when a second event arrives
                --       cancel first immediatley
                --       immediately start second
                --     effectively debouncing (with duration based on handler duration)
                --       a dynamic duration
                --       think of auto-complete copilot tools... they work like this
                --         immediately request completion
                --         cancel if user types something else
                --     might want a longer duration, in which case use debounce as described above
                --
            end
        )
        notificationObserver:start()
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
