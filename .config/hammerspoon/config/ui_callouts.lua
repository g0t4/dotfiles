local function showTooltipForElement(element, frame)
    if not element then return end

    -- Extract AX properties
    local role = element:attributeValue("AXRole") or "No Role"
    local title = element:attributeValue("AXTitle") or "No Title"
    local window = element:attributeValue("AXWindow")
    local windowTitle = window and window:attributeValue("AXTitle") or "No Window Title"

    -- Format tooltip text
    local text = string.format("Role: %s\nTitle: %s\nWindow: %s", role, title, windowTitle)

    -- Tooltip box size
    local tooltipWidth, tooltipHeight = 300, 80
    local padding = 10

    -- Positioning (slightly below the element)
    local x = frame.x
    local y = frame.y + frame.h + 5 -- Position below the element

    -- Create the canvas tooltip
    local tooltip = hs.canvas.new({ x = x, y = y, w = tooltipWidth, h = tooltipHeight })
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

local function mouse_remove_last_highlight_element()
    if not _G.mouse_last_highlight then
        return
    end
    _G.mouse_last_highlight:delete()
    _G.mouse_last_highlight = nil
    _G.mouse_last_element = nil
end

local function mouse_highlight_element()
    mouse_remove_last_highlight_element()

    local pos = hs.mouse.absolutePosition()
    local element = hs.axuielement.systemElementAtPosition(pos)
    if element == _G.mouse_last_element then
        -- skip if same element
        return
    end
    _G.mouse_last_element = element
    local frame = element:attributeValue("AXFrame")
    -- sometimes the frame is off screen... like a scrolled window (i.e. hammerspoon console)...
    --   would I cap its border with the boundaries of a parent element?

    local canvas = require("hs.canvas")
    _G.mouse_last_highlight = canvas.new(frame)
        :appendElements({
            action = "stroke",
            padding = 0,
            type = "rectangle",
            fillColor = { red = 1, blue = 0, green = 0 },
            strokeColor = { red = 1, blue = 0, green = 0, alpha = 0.5 },
            strokeWidth = 4,
        }):show()


    -- later when move mouse then move shape too
    -- later add some brief info about object in a window or tooltip of some sort
end

_G.mouse_last_highlight = nil
_G.mouse_debounced = nil
_G.mouse_stop = nil
_G.mouseMovesObservable = require("config.rx.mouse").mouseMovesObservable
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
    if not _G.mouse_debounced then
        _G.mouse_debounced, _G.mouse_stop = _G.mouseMovesObservable(400)
        _G.mouse_debounced:subscribe(function(position)
            if not position then
                print("[NEXT] - FAILURE?", "nil position")
                return
            end
            -- print("[NEXT]", position.x .. "," .. position.y)
            mouse_highlight_element()
        end, function(error)
            print("[ERROR] TODO what to do here?", error)
            mouse_remove_last_highlight_element()
        end, function()
            print("[COMPLETE]")
            mouse_remove_last_highlight_element()
        end)
    else
        _G.mouse_debounced = nil
        if _G.mouse_stop then
            _G.mouse_stop()
            _G.mouse_stop = nil
        end
    end
end)
