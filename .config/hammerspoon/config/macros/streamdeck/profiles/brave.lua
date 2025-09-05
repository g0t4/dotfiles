local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local CommandButton = require("config.macros.streamdeck.commandButton")
local verbose = require("config.macros.streamdeck.helpers").verbose
local MenuButton = require("config.macros.streamdeck.menuButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
require("config.macros.streamdeck.iconHelpers")
local f = require("config.helpers.underscore")


local BraveObserver = AppObserver:new(APPS.BraveBrowserBeta)
-- PRN make BraveObserver into a full-fledged class?
local lastModSet = nil

local KM_GOOGLE_DOCS_PERFORM_MENU_ITEM = "B06C1815-51D0-4DD7-A22C-5A3C39C4D1E0"


local MOD_SETS = {
    UNMODIFIED = "UNMODIFIED",
    GOOGLE_DOCS = "GOOGLE-DOCS",
    CHATGPT_COM = "CHATGPT-COM",
}
function getModSetNumber(url)
    if url == nil then return MOD_SETS.UNMODIFIED end
    if url:find("^https://docs.google.com") then return MOD_SETS.GOOGLE_DOCS end
    if url:find("^https://chatgpt.com") then return MOD_SETS.CHATGPT_COM end
    return MOD_SETS.UNMODIFIED
end

---@param deck DeckController
---@return PushButton[] # empty if none, never nil
function deck3Page1Mods(deck)
    local url = getCurrentURL()
    if getModSetNumber(url) == MOD_SETS.GOOGLE_DOCS then
        return {
            -- FYI these are just examples to test dynamic profile mods...
            MaestroButton:new(31, deck, hsCircleIcon("#FFFF00", deck),
                KM_GOOGLE_DOCS_PERFORM_MENU_ITEM, "Highlight color yellow"),
            MaestroButton:new(32, deck, hsCircleIcon("#FF0000", deck),
                KM_GOOGLE_DOCS_PERFORM_MENU_ITEM, "Highlight color red"),
        }
    end
    if getModSetNumber(url) == MOD_SETS.CHATGPT_COM then
        return {
            KeyStrokeButton:new(31, deck, drawTextIcon("\nSTOP", deck, LargeText), { "ctrl", "shift" }, "s"),
        }
    end
    return {}
end

BraveObserver:addProfilePage(DECK_3XL, PAGE_1, function(_, deck)
    -- PRN before any optrimization ideas, need to find timing and when it would help:
    --   - it is not gonna be caching the entire button, now that I think about it... it's gonna be the image and that's it
    -- ! ALSO, I suspect benefits are limited to:
    --   - icon loading/rendering (I could easily add a cache for just this by memoizing calls to hsCircleIcon/hsIcon/etc)
    --   - icon display
    --
    --   *** MEASURE TIMING FIRST
    --
    local base = {
        MaestroButton:new(1, deck, hsCircleIcon("#FFFF00", deck),
            KM_GOOGLE_DOCS_PERFORM_MENU_ITEM, "Highlight color yellow"),

        -- #FCE5CD (highlight light orange 3) => increase saturation for button color: #FFC690
        MaestroButton:new(2, deck, hsCircleIcon("#FFC690", deck, "rec"),
            KM_GOOGLE_DOCS_PERFORM_MENU_ITEM, "highlight light orange 3"),

        -- "none" == remove highlight (background color)
        MaestroButton:new(3, deck, hsCircleIcon("#FFFFFF", deck, "none"),
            KM_GOOGLE_DOCS_PERFORM_MENU_ITEM, "highlight none"),

        -- changes text color (not highlight) => looks nice! (could be veritcal middle aligned but this is FINE for now)
        MaestroButton:new(9, deck, drawTextIcon("dark green 2", deck,
                { color = { hex = "#38761D" }, font = { size = 30 } }),
            KM_GOOGLE_DOCS_PERFORM_MENU_ITEM, "dark green 2"),

        KeyStrokeButton:new(5, deck, drawTextIcon("⇒", deck), {}, "⇒"),
    }
    local myMods = deck3Page1Mods(deck)
    if myMods == nil then
        return base
    else
        -- FYI works for now but clicking them will be broken (IIAC first button per # would get press event)
        f.each(myMods, function(_index, button)
            -- !!! TODO override, not just ADD
            base[#base + 1] = button
        end)
        return base
    end
end)


function BraveObserver:setupIntraAppObserver()
    if self.intraAppObserver ~= nil then
        -- just in case deactivate didn't do it's job (which it should've done for this)
        self.intraAppObserver:stop()
        self.intraAppObserver = nil
    end
    lastModSet = nil -- always reset when resuming app

    self.intraAppObserver = createNotificationObserver(self) -- self, getMyAppElement())
    self.intraAppObserver:start()
end

---@return hs.axuielement|nil, hs.application|nil
function getMyAppElement()
    ---@type hs.application
    local hsApp = hs.application.get(APPS.BraveBrowserBeta)
    if hsApp == nil then return end
    return hs.axuielement.applicationElement(hsApp), hsApp
end

function getCurrentURL()
    local appElement = getMyAppElement()
    if not appElement then return end

    ---@type hs.axuielement|nil
    local window = appElement:attributeValue("AXFocusedWindow")
    if not window then return end

    -- print("focused AXSubrole: " .. window:attributeValue("AXSubrole"))

    -- if not standard window then take first standard window
    -- TODO something isn't working if focus is in find box (but if url bar focused with find box open it works)
    -- !TODO lets see if intra app observing can fix this if I close find box at least, just curious if that is a temp workaround too
    --    when find box isn't focused it seems to be a group?! and a window when it is?!
    if window:attributeValue("AXSubrole") ~= "AXStandardWindow" then
        print("focused window is not standard window, trying to find standard window")
        -- FYI if search box (Cmd+F) is focused then URL box isn't found:
        --   b/c search box is window(1), and url box is window is not focused
        --   find window => AXTitle => starts with "Find in page", AXSubrole = "AXUnknown"
        --   AXSubrole ==> "AXStandardWindow" (for window I want)
        window = appElement:standardWindow(1)
    end
    if not window then return end
    -- print("found standard window: " .. window:attributeValue("AXTitle"))

    -- FYI issue is it appears that you cannot get to the text field when find box is open...
    --  MIGHT NOT BE POSSIBLE TO SWITCH PROFILES WHILE FIND BOX IS OPEN
    --    OR when find is open, how about trigger a profile change every time the title changes (not often)?
    local urlTextField = window:group(1):group(1):group(1):group(1):toolbar(1):group(1):textField(1)
    if not urlTextField then return end

    return urlTextField:attributeValue("AXValue")
end

---@param braveAppObserver AppObserver
function createNotificationObserver(braveAppObserver)
    local appElement, hsApp = getMyAppElement()

    local notificationObserver = hs.axuielement.observer.new(hsApp:pid())
    assert(notificationObserver ~= nil)
    notificationObserver:addWatcher(appElement, "AXTitleChanged")
    notificationObserver:addWatcher(appElement, "AXFocusedWindowChanged")
    notificationObserver:callback(
    ---@param _observer hs.axuielement.observer
    ---@param eventElement hs.axuielement
    ---@param notification string
    ---@param _detailsTable table
        function(_observer, eventElement, notification, _detailsTable)
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
            local role = eventElement:attributeValue("AXRole")
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
            local eventAppElement = eventElement:attributeValue("AXParent")
            if eventAppElement == nil then
                print("[WindowTitleChanges] no parent, should never happen!")
                return
            end
            local focusedWindowElem = eventAppElement:attributeValue("AXFocusedWindow")
            if focusedWindowElem == nil then
                print("[WindowTitleChanges] no focused window, should never happen!")
                return
            end
            if focusedWindowElem ~= eventElement then
                print("[WindowTitleChanges] non-focused window title changed, skipping...")
                return
            end

            local parts = {
                ax_title_quoted(eventElement),
                axDescriptionQuoted(eventElement),
                axValueQuoted(eventElement),
            }
            local message = table.concat(parts, " ")

            -- -- FYI! AXDocument is often stale
            -- local axDocument = element:attributeValue("AXDocument")
            -- if axDocument ~= nil then
            --     message = message .. "\n  (may be stale) URL: " .. axDocument
            -- end

            -- FYI! AXURL unfortunately turned out to not be for the current tab only nor updated...
            --    FYI - if open new tabs it has their URLs and seems stuck on them even if move back tabs... so no good!
            -- -- TODO don't I need to find first standard window? right now it looks like I always go off of focused and its working?
            -- --   it should fail if I have find open at all (it is always focused window)
            -- local axURL = focusedWindowElem:group(1):attributeValue("AXURL")
            -- local currentSite = nil
            -- if axURL ~= nil then
            --     -- first group of first standard window has AXURL (lua table, exposes NSURL)
            --
            --     print("found AXURL attribute: ", hs.inspect(axURL))
            --     -- 2025-03-03 14:35:22: found AXURL attribute: 	{
            --     --   __luaSkinType = "NSURL",
            --     --   url = "https://www.google.com/"
            --     -- }
            --
            --     -- it's a table!
            --     currentSite = axURL["url"]
            --     -- print("  parsed AXURL: ", url)
            --     message = message .. "\n  AXURL: " .. currentSite
            --     -- !!!! DING DING DING DING... IT WORKS!!!!
            --     -- !!!! DING DING DING it also works when FIND IS OPEN! in that case window(2):group(1):attributeValue("AXURL") has the URL... and my code above already works to find that standard window and get this
            -- end
            --

            local urlTextField = focusedWindowElem:group(1):group(1):group(1):group(1):toolbar(1):group(1):textField(1)
            local currentSite = nil
            if urlTextField ~= nil then
                currentSite = urlTextField:attributeValue("AXValue")
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
                message = message .. "\n  urlTextField: " .. currentSite
            end

            -- print(message)

            local newModeSet = getModSetNumber(currentSite)
            local modSetDiffers = newModeSet ~= lastModSet
            lastModSet = newModeSet
            if modSetDiffers then
                braveAppObserver:onModSetChanged()
            end
        end)




    return notificationObserver
end

return BraveObserver
