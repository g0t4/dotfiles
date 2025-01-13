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
if true then return end
local focusedWin = pptAppElem:focusedWindow()
acObserver:addWatcher(focusedWin, "AXMoved")

acObserver:callback(function(evt)
    Dump("evt", evt)
end)
acObserver:start()
