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
local acObserver = observer.new(pptAppElem:pid())
DumpAXEverything(pptAppElem)
-- pptAppElem:activate()
-- local focusedWin = pptAppElem:focusedWindow()
local mainWin = pptAppElem:asHSApplication():mainWindow()
-- Dump("mainWin", mainWin)
local mainWinElem = axuielement.windowElement(mainWin)
-- Dump("mainWinElem", mainWinElem)
-- DumpAXEverything(mainWinElem)
acObserver:addWatcher(mainWinElem, "AXMoved")
-- acObserver:addWatcher(mainWinElem, "AXResized")
-- acObserver:addWatcher(mainWinElem, "AXMiniaturized")
-- acObserver:addWatcher(mainWinElem, "AXDeminiaturized")
-- acObserver:addWatcher(mainWinElem, "AXTitleChanged")
-- acObserver:addWatcher(mainWinElem, "AXValueChanged")
-- acObserver:addWatcher(mainWinElem, "AXCreated")
-- acObserver:addWatcher(mainWinElem, "AXDestroyed")

acObserver:callback(function(evt)
    Dump("cb", evt)
end)
acObserver:start()
