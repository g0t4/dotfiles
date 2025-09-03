local axuielement = require("hs.axuielement")
local observer = axuielement.observer
-- dump("observer", observer)
-- observer.new():start()
--
-- *** constants ***
dump("notifications", observer.notifications)
-- interesting: applicationActivated, applicationDeactivated
--    applicationHidden, applicationShown
--    created, drawerCreated
--    elementBusyChanged,
--    focusedUIElementChanged, focusedWindowChanged, mainWindowChanged
--    layoutChanged
--    menuOpened/Closed/ItemSelected
--    moved, resized
--    titleChanged
--    uIElementDestroyed
--    valueChanged
--    windowCreated/Moved/Resized/Miniaturized/Deminiaturized
--
-- TODO can I use systemwide element for focusedElement and detect when it changes and use that to trigger an accessbility inspector like tool?
--



local pptHsApp = hs.application.find("PowerPoint")
local pptAppElem = axuielement.applicationElement(pptHsApp)
-- dump(pptAppElem:pid())
-- pptAppElem:activate()
-- local focusedWin = pptAppElem:focusedWindow()
local mainWin = pptAppElem:asHSApplication():mainWindow()
local mainWinElem = axuielement.windowElement(mainWin)

--
-- local winObserver = observer.new(pptAppElem:pid())
-- winObserver:addWatcher(mainWinElem, "AXMoved")
-- -- acObserver:addWatcher(mainWinElem, "XResized")
-- -- acObserver:addWatcher(mainWinElem, "AXMiniaturized")
-- -- acObserver:addWatcher(mainWinElem, "AXDeminiaturized")
-- -- acObserver:addWatcher(mainWinElem, "AXTitleChanged")
-- -- acObserver:addWatcher(mainWinElem, "AXValueChanged")
-- -- acObserver:addWatcher(mainWinElem, "AXCreated")
-- -- acObserver:addWatcher(mainWinElem, "AXDestroyed")
-- winObserver:callback(function(_observer, elem, notification, detailsTable)
--     dump("cb", _observer, elem, notification, detailsTable)
-- end)
-- winObserver:start()
--
--


-- PRN would like to know if I can subscribe to focus changed across all apps (akin to system wide element's focused element)... might have to first swap the focused app/window then element?
--    applicationActivated/Deactivated, focusedWindowChanged,focusedUIElementChanged ... and so I would change observer to most recent activate app as I switch apps
-- local systemWideElem = axuielement.systemWideElement()
-- dump("swElem", systemWideElem)
-- local focusedObserver = observer.new(pptAppElem:pid())
-- focusedObserver:addWatcher(pptAppElem, "AXFocusedUIElementChanged")
-- focusedObserver:callback(function(_observer, elem, notification, detailsTable)
--     dump("cb", _observer, elem, notification, detailsTable)
-- end)
-- focusedObserver:start()
-- can I capture typing into focused element?


if true then
    local scriptDebuggerAppElem = axuielement.applicationElement(hs.application.find("Script Debugger"))
    local textObserverAppElem = scriptDebuggerAppElem
    -- local textObserver = observer.new(textObserverAppElem:pid())
    -- textObserver:callback(function(_observer, elem, notification, detailsTable)
    --     dump("textObserver", _observer, elem, notification, detailsTable)
    -- end)
    -- textObserver:start()
    --
    -- *** observe text entry changes => I could add AI auto complete to anything with this!
    --    would need to narrow down to text input elements only...
    local focusedObserver = observer.new(textObserverAppElem:pid())
    focusedObserver:addWatcher(textObserverAppElem, "AXFocusedUIElementChanged")
    focusedObserver:addWatcher(textObserverAppElem, "AXValueChanged") -- FYI CAN DIRECTLY OBSERVE FOR ENTIRE APP, DO NOT NEED TO SUBSCRIBE on each element
    focusedObserver:callback(function(_observer, elem, notification, detailsTable)
        dump("fObs", _observer, elem, notification, detailsTable)
        -- for elem, notifications in pairs(textObserver:watching()) do
        --     print(elem, notifications)
        --     for _, notificationString in pairs(notifications) do
        --         print("-- removing --- ", elem, notificationString)
        --         textObserver:removeWatcher(elem, notificationString)
        --     end
        --     -- FYI elem remains associated w/ observer... w/ empty notifications table after remove all its watchers (notificaitons) (until addWatcher is called for it again in future)
        -- end
        -- textObserver:addWatcher(elem, "AXValueChanged")
    end)
    focusedObserver:start()
end
