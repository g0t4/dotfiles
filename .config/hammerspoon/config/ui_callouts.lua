local M = {}
M.last = {
    element = nil,
    tooltip = nil,
    callout = nil,
}

local function showTooltipForElement(element, frame)
    if not element then return end

    print("[NEXT]", hs.inspect(element:allAttributeValues()))

    -- Extract AX properties
    local role = element:attributeValue("AXRole") or "No Role"
    local title = element:attributeValue("AXTitle") or "No Title"
    local window = element:attributeValue("AXWindow")
    local windowTitle = window and window:attributeValue("AXTitle") or "No Window Title"

    -- Format tooltip text
    local text = string.format("Role: %s\nTitle: %s\nWindow: %s", role, title, windowTitle)

    -- Tooltip box size
    local tooltipHeight = 80
    local padding = 10
    -- find max width of text:
    local maxWidth = math.max(role:len(), title:len(), windowTitle:len())
    local tooltipWidth = maxWidth * 8 + 2 * padding

    -- Get screen bounds
    local screenFrame = hs.screen.mainScreen():frame() -- Gets the current screen dimensions

    -- considerations:
    -- - default tooltip position is below (could be above/left/right)
    -- - if below is off screen, then move above
    -- - TODO if above is off screen, then move INSIDE frame, on bottom? (i.e. select giant element like iTerm2 window)
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

M.mouse_debounced = nil
M.mouse_stop = nil
M.mouseMovesObservable = require("config.rx.mouse").mouseMovesObservable
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
    if not M.mouse_debounced then
        M.mouse_debounced, M.mouse_stop = M.mouseMovesObservable(50)
        M.mouse_debounced:subscribe(function(position)
            if not position then
                print("[NEXT] - FAILURE?", "nil position")
                return
            end
            -- print("[NEXT]", position.x .. "," .. position.y)
            highlightCurrentElement()
        end, function(error)
            print("[ERROR] TODO what to do here?", error)
            removeHighlight()
        end, function()
            print("[COMPLETE]")
            removeHighlight()
        end)
    else
        M.mouse_debounced = nil
        if M.mouse_stop then
            M.mouse_stop()
            M.mouse_stop = nil
        end
    end
end)

return M
