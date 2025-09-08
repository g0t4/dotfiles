local M = {}

---@type hs.hotkey[]
M.bindings = {}
---@type hs.canvas?
M.canvas = nil
---@type Subject?
M.moves = nil
---@type fun?
M.stop_event_source = nil
---@type Subscription?
M.subscription = nil
---@type boolean
M.relative = false
---@type hs.axuielement?
M.relative_to = nil
---@type hs.canvas?
M.relative_border = nil

function toggle_show_mouse_position()
    -- alert.closeAll()
    if not M.moves then
        start_showing_mouse_position()
        show_current_mouse_position() -- immediately show, don't wait for mouse to move
    else
        stop_showing_mouse_position()
    end
end

function hide_mouse_position()
    if not M.canvas then
        -- nothing to hide
        return
    end
    M.canvas:hide()
    M.canvas = nil
end

function start_showing_mouse_position()
    M.moves, M.stop_event_source =
        require("config.rx.mouse").mouseMovesThrottledObservable(50)
    M.subscription = M.moves:subscribe(show_current_mouse_position)
    table.insert(M.bindings, hs.hotkey.bind({}, "escape", stop_showing_mouse_position))
    table.insert(M.bindings, hs.hotkey.bind({}, "r", toggle_relative_to_element))
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "p", toggle_show_mouse_position)

function stop_showing_mouse_position()
    M.moves = nil
    M.subscription:unsubscribe() -- subscription cleanup is all... really can skip this here
    hide_mouse_position()
    hide_relative_to_border()

    if M.stop_event_source then
        -- separately need to stop the upstream event source (do not comingle unsub w/ stop source, usually you might have multiple subs and would want to separately control the subs vs source)
        M.stop_event_source()
        M.stop_event_source = nil
    end

    for _, binding in pairs(M.bindings) do
        binding:delete()
    end
    M.bindings = {}
end

function hide_relative_to_border()
    if M.relative_border then
        M.relative_border:delete()
        M.relative_border = nil
    end
    M.relative_to = nil
end

function toggle_relative_to_element()
    -- FYI double tap r to move the relative to element, when already in relative mode
    M.relative = not M.relative
    if not M.relative then
        hide_relative_to_border()
        show_current_mouse_position()
        return
    end

    local pos = hs.mouse.absolutePosition()
    ---@type hs.axuielement?
    M.relative_to = hs.axuielement.systemElementAtPosition(pos)
    if M.relative_to == nil then
        M.relative = false
        print("no current element to get coordinates relative to")
        show_current_mouse_position()
        return
    end

    local frame = M.relative_to:axFrame()
    if not frame then
        show_current_mouse_position()
        return
    end

    local canvas = hs.canvas.new({
        x = frame.x,
        y = frame.y,
        w = frame.w,
        h = frame.h
    })
    M.relative_border = canvas
    if not canvas then
        print("failed to create canvas around relative_to element for a border callout")
        show_current_mouse_position()
        return
    end

    canvas:appendElements({
        type = "rectangle",
        action = "stroke",
        strokeColor = { red = 1, green = 0, blue = 0 },
        strokeWidth = 2,
        frame = { x = 0, y = 0, w = frame.w, h = frame.h }
    })

    canvas:show()
    show_current_mouse_position()
end

function show_current_mouse_position()
    hide_mouse_position()

    local mouse_pos = hs.mouse.absolutePosition()

    local width = 150
    local height = 25

    local x_pos = mouse_pos.x
    local y_pos = mouse_pos.y
    local x_display = x_pos
    local y_display = y_pos

    if M.relative_to then
        local relative_pos = M.relative_to:axPosition()
        if relative_pos then
            x_display = mouse_pos.x - relative_pos.x
            y_display = mouse_pos.y - relative_pos.y
        else
            print("no relative position for relative_to element, using screen position")
        end
    end

    local canvas_x = x_pos - width
    local canvas_y = y_pos - height

    -- * make sure the canvas is on screen
    local screen_frame = hs.screen.mainScreen():frame()
    if canvas_x < screen_frame.x then
        canvas_x = screen_frame.x + 10
    end
    if canvas_y < screen_frame.y then
        canvas_y = screen_frame.y + 10
    end
    if canvas_x + width > screen_frame.x + screen_frame.w then
        canvas_x = screen_frame.x + screen_frame.w - width - 10
    end
    if canvas_y + height > screen_frame.y + screen_frame.h then
        canvas_y = screen_frame.y + screen_frame.h - height - 10
    end

    local canvas_frame = {
        x = canvas_x,
        y = canvas_y - 5, -- shift slighlty up so not covering mouse pointer position... ignore in calcs above
        w = width,
        h = height,
    }

    ---@type hs.canvas?
    local canvas = hs.canvas.new(canvas_frame)
    if not canvas then
        print("failed to create canvas for mouse position")
        return
    end
    M.canvas = canvas
    canvas:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0, green = 0, blue = 0, alpha = 0.7 }
    })
    local x_display = round(x_display, 1)
    local y_display = round(y_display, 1)
    canvas:appendElements({
        type = "text",
        text = "X: " .. x_display .. ", Y: " .. y_display,
        textSize = 16,
        textColor = { red = 1, green = 1, blue = 1, alpha = 1 },
        textAlignment = "center",
        frame = { x = 0, y = 0, w = width, h = height }
    })
    canvas:show()
end

return M
