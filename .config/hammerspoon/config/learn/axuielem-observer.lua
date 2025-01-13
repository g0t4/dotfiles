local axuielement = require("hs.axuielement")
local observer = axuielement.observer
-- Dump("observer", observer)
-- observer.new():start()
--
-- *** constants ***
-- Dump("notifications", observer.notifications)
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


local pptHsApp = hs.application.find("PowerPoint")
local pptAppElem = axuielement.applicationElement(pptHsApp)
-- Dump(pptAppElem:pid())
DumpAXEverything(pptAppElem)
-- pptAppElem:activate()
-- local focusedWin = pptAppElem:focusedWindow()
local mainWin = pptAppElem:asHSApplication():mainWindow()
local mainWinElem = axuielement.windowElement(mainWin)
DumpAXEverything(mainWinElem)

--
-- local winObserver = observer.new(pptAppElem:pid())
-- winObserver:addWatcher(mainWinElem, "AXMoved")
-- -- acObserver:addWatcher(mainWinElem, "AXResized")
-- -- acObserver:addWatcher(mainWinElem, "AXMiniaturized")
-- -- acObserver:addWatcher(mainWinElem, "AXDeminiaturized")
-- -- acObserver:addWatcher(mainWinElem, "AXTitleChanged")
-- -- acObserver:addWatcher(mainWinElem, "AXValueChanged")
-- -- acObserver:addWatcher(mainWinElem, "AXCreated")
-- -- acObserver:addWatcher(mainWinElem, "AXDestroyed")
-- winObserver:callback(function(_observer, elem, notification)
--     Dump("cb", _observer, elem, notification)
-- end)
-- winObserver:start()
--
--
