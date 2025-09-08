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
    -- PRN bind any other desired keys, they are all auto removed on stop
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "p", toggle_show_mouse_position)

function stop_showing_mouse_position()
    M.moves = nil
    M.subscription:unsubscribe() -- subscription cleanup is all... really can skip this here
    hide_mouse_position()

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

function show_current_mouse_position()
    hide_mouse_position()

    local mouse_pos = hs.mouse.absolutePosition()
    local width = 150
    local height = 30

    local canvas_frame = {
        x = mouse_pos.x - width,
        y = mouse_pos.y - height,
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
    local x_pos = round(mouse_pos.x, 1)
    local y_pos = round(mouse_pos.y, 1)
    canvas:appendElements({
        type = "text",
        text = "X: " .. x_pos .. ", Y: " .. y_pos,
        textSize = 16,
        textColor = { red = 1, green = 1, blue = 1, alpha = 1 },
        textAlignment = "center",
        frame = { x = 0, y = 0, w = width, h = height }
    })
    canvas:show()
end

return M
