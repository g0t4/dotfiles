-- List of accessibility events to observe
local events = {
    "AXUIElementCreated",
    "AXWindowCreated",
    "AXWindowMoved",
    "AXWindowResized",
    "AXFocusedUIElementChanged",
    "AXValueChanged",
    "AXMenuOpened",
    "AXMenuClosed",
    "AXRowExpanded",
    "AXRowCollapsed",
    "AXSelectedTextChanged",
    "AXTitleChanged",
    "AXSheetCreated",
    "AXSheetDismissed",
    "AXMenuItemSelected",
    "AXLiveRegionChanged",
    "AXElementBusyChanged",
    "AXNotification",
}

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "O", function()
    if _G.observer then
        _G.observer:stop()
        _G.observer = nil
        return
    end

    local app = hs.application.frontmostApplication()
    print("[AXObserver] Watching accessibility events for:", app:name())
    local appPID = app:pid()
    local appElement = hs.axuielement.applicationElement(app)

    local function eventHandler(observer, element, event, event_info)
        -- TODO consider a mode to dump entire script instead of just the element specifier
        local text = BuildHammerspoonLuaTo(element)
        if event == "AXValueChanged" then
            text = text .. " " .. (element:attributeValue("AXValue") or "")
            -- PRN add more event type info dumps
        end
        if event_info == {} then
            print(string.format("[AX EVENT] %s - %s", text, event))
        else
            print(string.format("[AX EVENT] %s - %s\n  %s", text, event, hs.inspect(event_info)))
        end
    end

    _G.observer = hs.axuielement.observer.new(appPID)

    _G.observer:callback(eventHandler)
    for _, event in ipairs(events) do
        _G.observer:addWatcher(appElement, event)
    end

    _G.observer:start()
end)
