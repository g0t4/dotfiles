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

do return end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "D", function()
    M.stopObserving()
    M.startObserving()
end)

M.startObserving = function()
    local app = hs.application.frontmostApplication()
    print("[AXObserver] Watching ax events for ask-openai for app:", app:name())
    local appPID = app:pid()
    local appElement = hs.axuielement.applicationElement(app)

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

    M.skip = false
    M.observer = hs.axuielement.observer.new(appPID)

    M.observer:callback(eventHandler)
    M.observer:addWatcher(appElement, "AXValueChanged")
    M.observer:start()
end

return M
