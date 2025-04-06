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
local M = {}
M.skip = false
M.observer = nil

M.stopObserving = function()
    if not M.observer then
        return
    end
    M.skip = false
    M.observer:stop()
    M.observer = nil
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "D", function()
    M.stopObserving()

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
    M.skip = false

    local function eventHandler(observer, element, event, event_info)
        if M.skip then
            return
        end
        if event ~= "AXValueChanged" then
            return
        end

        -- confirmed Brave and Excel, the focused element is marked True
        local focused = element:attributeValue("AXFocused")
        if not focused then
            return
        end

        -- PRN could pass value too, only if it helps with timing though when typing which is possible (can skip reading it)
        -- local value = element:attributeValue("AXValue")
        AskOpenAICompletionBox()
    end

    M.observer = hs.axuielement.observer.new(appPID)

    M.observer:callback(eventHandler)
    M.observer:addWatcher(appElement, "AXValueChanged")
    M.observer:start()
end)

return M
