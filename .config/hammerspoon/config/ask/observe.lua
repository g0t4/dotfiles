-- local events = {
--     "AXUIElementCreated",
--     "AXWindowCreated",
--     "AXWindowMoved",
--     "AXWindowResized",
--     "AXFocusedUIElementChanged",
--     "AXValueChanged",
--     "AXMenuOpened",
--     "AXMenuClosed",
--     "AXRowExpanded",
--     "AXRowCollapsed",
--     "AXSelectedTextChanged",
--     "AXTitleChanged",
--     "AXSheetCreated",
--     "AXSheetDismissed",
--     "AXMenuItemSelected",
--     "AXLiveRegionChanged",
--     "AXElementBusyChanged",
--     "AXNotification",
-- }

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "D", function()
    if _G.observer then
        _G.observer:stop()
        _G.observer = nil
        return
    end

    -- EACH key stroke triggers to value changed events (two sep objects)... this might be a good way to capture the element involved in devtools!
    --    one of these must be a backing field for the other?
    --
    --    webArea('DevTools')
    --    textArea(desc='Console prompt')
    --
    -- [AX EVENT] app:window(1):group(1):group(1):group(1):group(1):scrollArea(1):webArea(1):group(1):group(1):group(1):group(1):group(1)
    --   :group(1):group(1):group(1):group(2):group(1):group(1):group(2):group(1):group(1):group(1):group(1):group(1):group(1)
    --   :group(1):group(1):group(2):group(2):group(1):group(1):group(1):group(2):textArea(1) test this outs,ss - AXValueChanged
    --   {
    --   AXTextChangeElement = <userdata 1> -- hs.axuielement: AXTextArea (0x600010745e78),
    --   AXTextChangeValues = { {
    --       AXTextChangeValue = "s",
    --       AXTextChangeValueLength = 1,
    --       AXTextChangeValueStartMarker = <userdata 2> -- hs.axuielement.axtextmarker: (0x600010745f38),
    --       AXTextEditType = 3
    --     } },
    --   AXTextStateChangeType = 1
    -- }
    -- [AX EVENT] app:window(1):group(1):group(1):group(1):group(1):scrollArea(1):webArea(1)  - AXValueChanged
    --   {
    --   AXTextChangeElement = <userdata 1> -- hs.axuielement: AXTextArea (0x60000c2a6f38),
    --   AXTextChangeValues = { {
    --       AXTextChangeValue = "s",
    --       AXTextChangeValueLength = 1,
    --       AXTextChangeValueStartMarker = <userdata 2> -- hs.axuielement.axtextmarker: (0x60000c2a6ef8),
    --       AXTextEditType = 3
    --     } },
    --   AXTextStateChangeType = 1
    -- }

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
            -- PrintAttributes(element)
            --AXDescription	"Console prompt"
            if element:attributeValue("AXDescription") == "Console prompt" then
                print("console prompt value changed", element)
            end
        end
        -- if event_info == {} then
        --     print(string.format("[AX EVENT] %s - %s", text, event))
        -- else
        --     print(string.format("[AX EVENT] %s - %s\n  %s", text, event, hs.inspect(event_info)))
        -- end
    end

    _G.observer = hs.axuielement.observer.new(appPID)

    _G.observer:callback(eventHandler)
    _G.observer:addWatcher(appElement, "AXValueChanged")
    _G.observer:start()
end)
