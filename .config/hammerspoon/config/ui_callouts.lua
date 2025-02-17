local M = {}
M.last = {
    element = nil,
    tooltip = nil,
    callout = nil,
}

local function showTooltipForElement(element, frame)
    if not element then return end

    -- print("[NEXT]", hs.inspect(element:allAttributeValues()))

    -- Extract AX properties
    local role = element:attributeValue("AXRole") or "<none>"
    local title = element:attributeValue("AXTitle") or "<none>"
    local window = element:attributeValue("AXWindow")
    local windowTitle = window and window:attributeValue("AXTitle") or "<none>"

    -- Format tooltip text
    local text = string.format("Role: %s\nTitle: %s\nWindow: %s", role, title, windowTitle)

    -- Tooltip box size
    local tooltipHeight = 100
    local padding = 10
    -- find max width of text:
    local maxWidth = math.max(role:len(), title:len(), windowTitle:len())
    local tooltipWidth = maxWidth * 12 + 4 * padding

    -- Get screen bounds
    local screenFrame = hs.screen.mainScreen():frame() -- Gets the current screen dimensions

    -- Initial positioning (slightly below the element)
    local x = frame.x
    local y = frame.y + frame.h + 5 -- Below the element

    -- Ensure tooltip does not go off the right edge
    if x + tooltipWidth > screenFrame.x + screenFrame.w then
        x = screenFrame.x + screenFrame.w - tooltipWidth - 10 -- Shift left
        -- IIUC the box is positioned to right of element left side so I don't think I need to worry about x being shifted left of screen
    end

    -- Ensure tooltip does not go off the bottom edge
    if y + tooltipHeight > screenFrame.y + screenFrame.h then
        -- if it's off the bottom, then move it above the element
        y = frame.y - tooltipHeight - 5 -- Move above element
        if y < screenFrame.y then
            -- if above is also off screen, then shift it down, INSIDE the frame
            --   means it stays on top btw... could put it inside on bottom too
            y = screenFrame.y + 10 -- Shift up
        end
    end

    M.last.tooltip = hs.canvas.new({ x = x, y = y, w = tooltipWidth, h = tooltipHeight })
        :appendElements({
            -- Background box
            {
                type = "rectangle",
                action = "fill",
                frame = { x = 0, y = 0, w = tooltipWidth, h = tooltipHeight },
                fillColor = { white = 0, alpha = 0.8 }, -- Dark semi-transparent background
                roundedRectRadii = { xRadius = 8, yRadius = 8 }
            },
            -- Text
            {
                type = "text",
                text = text,
                textSize = 14,
                textColor = { white = 1 },
                frame = { x = padding, y = padding, w = tooltipWidth - 2 * padding, h = tooltipHeight - 2 * padding },
                textAlignment = "left"
            }
        })
        :show()
end

local function removeHighlight()
    if not M.last.element then
        return
    end
    if M.last.tooltip then
        M.last.tooltip:delete()
    end
    if M.last.callout then
        M.last.callout:delete()
    end
    M.last.element = nil
    M.last.tooltip = nil
    M.last.callout = nil
end

local function highlightCurrentElement()
    assert(M.last ~= nil)
    removeHighlight()

    local pos = hs.mouse.absolutePosition()
    local element = hs.axuielement.systemElementAtPosition(pos)
    if element == M.last.element then
        -- skip if same element
        return
    end

    M.last.element = element
    local frame = element:attributeValue("AXFrame")
    -- sometimes the frame is off screen... like a scrolled window (i.e. hammerspoon console)...
    --   would I cap its border with the boundaries of a parent element?

    local canvas = require("hs.canvas")
    M.last.callout = canvas.new(frame)
        :appendElements({
            action = "stroke",
            padding = 0,
            type = "rectangle",
            fillColor = { red = 1, blue = 0, green = 0 },
            strokeColor = { red = 1, blue = 0, green = 0, alpha = 0.5 },
            strokeWidth = 4,
        }):show()

    showTooltipForElement(element, frame)
end

M.moves = nil
M.stop_event_source = nil
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
    if not M.moves then
        -- I would prefer a throttle here not debounce... I wanna immediately show the callout/tooltip and then not do it again until a small period of time has elapsed
        M.moves, M.stop_event_source = require("config.rx.mouse").mouseMovesObservable()
        M.subscription = M.moves:subscribe(
            function()
                -- stream is just move alert not position
                highlightCurrentElement()
            end
        -- function(error)
        --     -- right now my sources don't levearge error (nor complete) events... so just ignore
        --     print("[ERROR] what to do here?", error)
        -- end,
        -- function()
        --     print("[COMPLETE] what to do here?")
        -- end
        )
    else
        M.moves = nil
        M.subscription:unsubscribe() -- subscription cleanup is all... really can skip this here
        removeHighlight() -- clear the callout/tooltips
        if M.stop_event_source then
            -- separately need to stop the upstream event source (do not comingle unsub w/ stop source, usually you might have multiple subs and would want to separately control the subs vs source)
            M.stop_event_source()
            M.stop_event_source = nil
        end
    end
end)

return M
