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
    self:tryLoadProfileForDeck(deckName, deckController, currentAppName)
end

---@type hs.axuielement.observer|nil
local notificationObserver = nil

function AppsObserver:onAppActivated(appName, hsApp)
    -- STOP and START new NOTIFICATION OBSERVER
    if notificationObserver ~= nil then
        notificationObserver:stop()
    end
    local appElement = hs.axuielement.applicationElement(hsApp)
    notificationObserver = hs.axuielement.observer.new(hsApp:pid())
    assert(notificationObserver ~= nil)
    notificationObserver:addWatcher(appElement, "AXTitleChanged")
    notificationObserver:addWatcher(appElement, "AXFocusedWindowChanged")
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
                print("unexpected role: " .. role)
                return
            end
            if notification ~= "AXTitleChanged" and notification ~= "AXFocusedWindowChanged" then
                print("unexpected notification type: " .. notification)
                return
            end
            local appElem = element:attributeValue("AXParent")
            if appElem == nil then
                print("no parent, should never happen!")
                return
            end
            local focusedWindowElem = appElem:attributeValue("AXFocusedWindow")
            if focusedWindowElem == nil then
                print("no focused window, should never happen!")
                return
            end
            if focusedWindowElem ~= element then
                print("non-focused window title changed, skipping...")
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
        end
    )
    notificationObserver:start()


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
        if module == nil then
            print("Failed to load profiles module for app: " .. appModuleName)
            return nil
        end
        logMyTimes(appModuleName .. "-require took:", GetElapsedTimeInMilliseconds(insideStartTime), "ms")
        local pageNumber = pageSettings.getSavedPageNumber(deckName, appModuleName)
        -- print("Selected page: " .. pageNumber, "for deck: " .. deckName, "and app: " .. appModuleName)
        -- TODO cache for duration of app lifetime? -- measure impact before doing that
        local selected = module:getProfilePage(deckName, pageNumber)
        if selected == nil and pageNumber ~= 1 then
            print("WARNING: Failed to get page " .. pageNumber .. " for deck " .. deckName .. " and app " .. appModuleName, "trying page 1")
            -- try 1, can happen if page is removed and was set as current still
            selected = module:getProfilePage(deckName, 1)
        end
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
