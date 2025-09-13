local app = get_app_element_or_throw("com.screenpal.app")
print("app", app)
local pid = app:pid()
local observer = hs.axuielement.observer.new(pid)
local types = hs.axuielement.observer.notifications

--- *** EASILY DETECT playhead moving =>
---    triggers AXWindowMoved, AXWindowCreated, AXMoved
---      AXWindowResized, AXResized
---      created (AXWindow - new window for new position)
---      uIElementDestroyed (old window presumably)
---      titleChanged too (new title, not an actual change)
---    USE THIS to refresh window for accessing timeline?
-- -2025-09-09 15:16:31: destroyed:	hs.axuielement: *element invalid* (0x6000006a4f78)
-- 2025-09-09 15:16:31: { "cb", <userdata 1> -- hs.axuielement.observer: (0x6000006a29b8), <userdata 2> -- hs.axuielement: AXWindow (0x6000006a3238), "AXMoved", {} }
-- 2025-09-09 15:16:31: { "cb", <userdata 1> -- hs.axuielement.observer: (0x6000006a4eb8), <userdata 2> -- hs.axuielement: AXWindow (0x6000006a74f8), "AXWindowMoved", {} }
-- 2025-09-09 15:16:31: { "cb", <userdata 1> -- hs.axuielement.observer: (0x6000006a76b8), <userdata 2> -- hs.axuielement: AXWindow (0x6000006a6fb8), "AXResized", {} }
-- 2025-09-09 15:16:31: { "cb", <userdata 1> -- hs.axuielement.observer: (0x6000006a09b8), <userdata 2> -- hs.axuielement: AXWindow (0x6000006a3778), "AXWindowResized", {} }
-- 2025-09-09 15:16:31: { "cb", <userdata 1> -- hs.axuielement.observer: (0x6000006a4d38), <userdata 2> -- hs.axuielement: AXWindow (0x6000006a6c78), "AXMoved", {} }
-- 2025-09-09 15:16:31: { "cb", <userdata 1> -- hs.axuielement.observer: (0x60000067a538), <userdata 2> -- hs.axuielement: AXWindow (0x600000679238), "AXWindowMoved", {} }
-- 2025-09-09 15:16:31: created:	hs.axuielement: AXWindow (0x6000006531f8)
-- 2025-09-09 15:16:31: { "cb", <userdata 1> -- hs.axuielement.observer: (0x600000653ab8), <userdata 2> -- hs.axuielement: AXWindow (0x600000651978), "AXWindowCreated", {} }
-- 2025-09-09 15:16:31: { "cb", <userdata 1> -- hs.axuielement.observer: (0x600000679d38), <userdata 2> -- hs.axuielement: *element invalid* (0x6000006787f8), "AXFocusedUIElementChanged", {} }
-- 2025-09-09 15:16:31: destroyed:	hs.axuielement: *element invalid* (0x60000064dd38)
-- 2025-09-09 15:16:31: titleChanged:	SOM-FloatingWindow-Type=edit2.overlayfloat-ZOrder=1(Undefined+1)--
---
---
---    seems like one of the easiest things to observe in the app!
---
--- AXApplicationActivated / AXApplicationDeactivated
---   use deactivated to unsub?

---@param element hs.axuielement object
function on_notification(_observer, element, event_type, event_details)
    -- if not element then return end

    -- if notification == types.focusedUIElementChanged
    --     and element:axValue() ~= nil then
    --     local desc = element:axTitle()
    --         or element:axDescription()
    --         or element:axRoleDescription()
    --         or element:axValue()
    --
    --     desc = element:axRole() .. ": " .. tostring(desc)
    --
    --     print("Focused element:", desc)
    --     observer:addWatcher(element, types.valueChanged)
    -- end

    if event_type == types.titleChanged then
        print("titleChanged:", element:axTitle())
    elseif event_type == types.created then
        print("created:", element)
    elseif event_type == types.uIElementDestroyed then
        print("destroyed:", element)
    elseif event_type == types.valueChanged then
        local value = element:axValue()

        -- \nAuto Saved
        local is_auto_save_spam = value:find("Auto Saved") -- FYI NOT A space, its an nbsp between words (0xC2)

        if is_auto_save_spam then
            -- skip, its one of the chattiest elements! drowns out everything
            return
        end
        print("Value changed: '" .. tostring(value) .. "'", element)
    else
        dump("cb", _observer, element, event_type, event_details)
    end
end

observer:callback(on_notification)

-- When focus changes, reattach to the newly focused element
print("Entire system:", app)
-- observer:addWatcher(app, types.valueChanged)
-- observer:addWatcher(app, types.created)
-- observer:addWatcher(app, types.uIElementDestroyed)
-- observer:addWatcher(app, types.focusedUIElementChanged)
-- observer:addWatcher(app, types.valueChanged)
-- observer:addWatcher(app, types.layoutChanged)
-- observer:addWatcher(app, types.mainWindowChanged)
-- observer:addWatcher(app, types.titleChanged)
-- observer:addWatcher(app, types.unitsChanged)
-- observer:addWatcher(app, types.resized)

-- all events in notifications list (there are more than this)
-- TODO prune to only what you need
observer:addWatcher(app, types.announcementRequested)
observer:addWatcher(app, types.applicationActivated)
observer:addWatcher(app, types.applicationDeactivated)
observer:addWatcher(app, types.applicationHidden)
observer:addWatcher(app, types.applicationShown)
observer:addWatcher(app, types.created)
observer:addWatcher(app, types.drawerCreated)
observer:addWatcher(app, types.elementBusyChanged)
observer:addWatcher(app, types.focusedUIElementChanged)
observer:addWatcher(app, types.focusedWindowChanged)
observer:addWatcher(app, types.helpTagCreated)
observer:addWatcher(app, types.layoutChanged)
observer:addWatcher(app, types.mainWindowChanged)
observer:addWatcher(app, types.menuClosed)
observer:addWatcher(app, types.menuItemSelected)
observer:addWatcher(app, types.menuOpened)
observer:addWatcher(app, types.moved)
observer:addWatcher(app, types.resized)
observer:addWatcher(app, types.rowCollapsed)
observer:addWatcher(app, types.rowCountChanged)
observer:addWatcher(app, types.rowExpanded)
observer:addWatcher(app, types.selectedCellsChanged)
observer:addWatcher(app, types.selectedChildrenChanged)
observer:addWatcher(app, types.selectedChildrenMoved)
observer:addWatcher(app, types.selectedColumnsChanged)
observer:addWatcher(app, types.selectedRowsChanged)
observer:addWatcher(app, types.selectedTextChanged)
observer:addWatcher(app, types.sheetCreated)
observer:addWatcher(app, types.titleChanged)
observer:addWatcher(app, types.uIElementDestroyed)
observer:addWatcher(app, types.unitsChanged)
observer:addWatcher(app, types.valueChanged)
observer:addWatcher(app, types.windowCreated)
observer:addWatcher(app, types.windowDeminiaturized)
observer:addWatcher(app, types.windowMiniaturized)
observer:addWatcher(app, types.windowMoved)
observer:addWatcher(app, types.windowResized)


-- observer:addWatcher(app, types.)
-- PRN would want to limit to just controls I want to see value changed on
--   maybe observe creating a control, look at type and if its the timecode on playhead then subscribe to it
--   then can I unsub when a control is destroyed?
-- observer:addWatcher(app, types.valueChanged or types.focusedUIElementChanged)

observer:start()

-- On config reload, remember to stop:
hs.shutdownCallback = function() pcall(function() observer:stop() end) end
