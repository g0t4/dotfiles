local f = require("config.helpers.underscore")
-- https://www.hammerspoon.org/docs/hs.axuielement.observer.html


--- FYI!  this is for finding events to watch, just subscribes to everything
-- leave this as is (ALL EVENTS) so its a reminder of a good way to find events

-- TODO! find a way to subscribe to other app specific events not listed in hs.axuielement.observer.notifications constants


-- - FYI issue switching to hammerspoon console from observing app (and then back to it):
--   - subscribe to Brave Browser events, switch to Brave and then away (it breaks)
--   - especially when switch to hammerspoon console (click on that window)
--     - also might be rapid switching b/c now its any app randonmly
--   - FIX => reload hs config (or don't observe beyond span of one app in front)

local hsapp = hs.application.find(APPS.BraveBrowserBeta)
-- FYI  most of the following is just to get typing to provide completions (asserts/annotations)
print("  PID", hs.inspect(hsapp:pid()))
---@type hs.axuielement|nil
local appElement = hs.axuielement.applicationElement(hsapp)
assert(appElement ~= nil)
---@type hs.axuielement.observer|nil
local observer = hs.axuielement.observer.new(hsapp:pid())
assert(observer ~= nil)

-- -- ALL events (good way to find what is available)
f.each(hs.axuielement.observer.notifications, function(key, value)
    print(" " .. key .. " => " .. value)
    observer:addWatcher(appElement, value)
end)

-- TODO if it becomes an issue w/in using a single app (not swtiching apps bug).. then research why...
--   IIAC the OS decides to terminate observers for any # of reasons
--   probably is why you can ask for the current watchers() so you can restart missing ones
-- WHY THE F do they notices just stop coming? after switching apps a few times they stop firing...
--   my workaround is that I will make a new observer every time I change apps
--   so a fix for me (if i stops working intraapp which I haven't noticed yet, would be to switch apps quickly)
-- observer:addWatcher(appElement, "AXFocusedUIElementChanged")
-- open new tab, this fires
-- observer:addWatcher(appElement, "AXValueChanged") -- FYI CAN DIRECTLY OBSERVE FOR ENTIRE APP, DO NOT NEED TO SUBSCRIBE on each element
-- very chatty (every time you type in a text field anywhere! fires value changed!)

observer:callback(
---@param element hs.axuielement
    function(_observer, element, notification, _detailsTable)
        local value = element:attributeValue("AXValue")
        local title = element:attributeValue("AXTitle")
        local role = element:attributeValue("AXRole")
        local description = element:attributeValue("AXDescription")
        local message = "[N] " .. notification
        if role ~= nil then
            message = message .. " " .. role
        end
        if title ~= nil then
            message = message .. " " .. quote(title)
        end
        if description ~= nil then
            message = message .. " " .. quote(description)
        end
        if value ~= nil then
            message = message .. " " .. quote(value)
        end

        print(message)
    end
)

observer:start()

-- TODO! how can I find other events for a given app? dictionary? or?
-- hs.axuielement.observer.notifications
--
-- announcementRequested   AXAnnouncementRequested
-- applicationActivated    AXApplicationActivated *** (actually use your hs.application.watcher for this to ensure coordination and not double loading profiles when switching apps)
-- applicationDeactivated  AXApplicationDeactivated  *** in my experience, happens after Activated notification
-- applicationHidden       AXApplicationHidden
-- applicationShown        AXApplicationShown
-- created                 AXCreated
-- drawerCreated           AXDrawerCreated *** indicates a new window right?
-- elementBusyChanged      AXElementBusyChanged
-- focusedUIElementChanged AXFocusedUIElementChanged *** (for mods based on focused element)
-- focusedWindowChanged    AXFocusedWindowChanged ***
-- helpTagCreated          AXHelpTagCreated
-- layoutChanged           AXLayoutChanged *** maybe?
-- mainWindowChanged       AXMainWindowChanged *** maybe?
-- menuClosed              AXMenuClosed
-- menuItemSelected        AXMenuItemSelected
-- menuOpened              AXMenuOpened
-- moved                   AXMoved
-- resized                 AXResized *** for controls?
-- rowCollapsed            AXRowCollapsed
-- rowCountChanged         AXRowCountChanged  *** can I use this in TitleInspector for FCPX when timeline selection changes the inspector redraws and IIRC has rows?
-- rowExpanded             AXRowExpanded *** maybe?
-- selectedCellsChanged    AXSelectedCellsChanged
-- selectedChildrenChanged AXSelectedChildrenChanged
-- selectedChildrenMoved   AXSelectedChildrenMoved
-- selectedColumnsChanged  AXSelectedColumnsChanged
-- selectedRowsChanged     AXSelectedRowsChanged
-- selectedTextChanged     AXSelectedTextChanged
-- sheetCreated            AXSheetCreated
-- titleChanged            AXTitleChanged *** YES (window only?)
-- uIElementDestroyed      AXUIElementDestroyed
-- unitsChanged            AXUnitsChanged
-- valueChanged            AXValueChanged *** maybe?
-- windowCreated           AXWindowCreated
-- windowDeminiaturized    AXWindowDeminiaturized
-- windowMiniaturized      AXWindowMiniaturized
-- windowMoved             AXWindowMoved
-- windowResized           AXWindowResized
