-- https://www.hammerspoon.org/docs/hs.axuielement.observer.html

--- TODO! TRY hs.uielement.watcher if I have issues with axuielement.observer

-- FYI ISSUES:
-- - when I subscribe to all events for Brave Browser, if I switch to Brave and away (before triggering any other events)... the callback no longer fires
--   - if I open a new tab/changes website/etc and more notifications fire... then when I switch away and come back events still work...
--   - fortunately I'll be using an observer only for the duration of the app staying on top... and I haven't noticed the issue in that case
--

local braveApp = hs.application.find("Brave Browser Beta")

-- FYI  most of the following is just to get typing to provide completions (asserts/annotations)
print("  PID", hs.inspect(braveApp:pid()))
---@type hs.axuielement|nil
local braveAppElement = hs.axuielement.applicationElement(braveApp)
assert(braveAppElement ~= nil)
---@type hs.axuielement.observer|nil
local braveObserver = hs.axuielement.observer.new(braveApp:pid())
assert(braveObserver ~= nil)

_.each(hs.axuielement.observer.notifications, function(key, value)
    print(" " .. key .. " => " .. value)
    braveObserver:addWatcher(braveAppElement, value)
end)

braveObserver:callback(
---@param element hs.axuielement
    function(_observer, element, notification, _detailsTable)
        print("[OBSERVER] " .. notification, hs.inspect(element))
    end
)

-- focusedObserver:addWatcher(textObserverAppElem, "AXFocusedUIElementChanged")
-- focusedObserver:addWatcher(textObserverAppElem, "AXValueChanged") -- FYI CAN DIRECTLY OBSERVE FOR ENTIRE APP, DO NOT NEED TO SUBSCRIBE on each element

braveObserver:start()

-- TODO! how can I find other events for a given app? dictionary? or?
--
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
