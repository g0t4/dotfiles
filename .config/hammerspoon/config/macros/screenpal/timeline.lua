---@class TimelineDetails
---@field timeline_frame { x: number, y: number, w: number, h: number }
---@field _playhead_window_frame { x: number, y: number, w: number, h: number }
---@field playhead_x number
---@field _playhead_relative_timeline_x number
---@field playhead_seconds number
---@field pixels_per_second number
---@field estimated_total_seconds number
local TimelineDetails = {}

---@param self TimelineDetails
function TimelineDetails:new(editor_window)
    local timeline_frame = editor_window._btn_position_slider:axFrame()

    local playhead_window = editor_window.windows:get_playhead_window_or_throw()
    -- DO NOT get frames until UI is stable, zoome din frame is different than zoomed out
    local _playhead_window_frame = playhead_window:axFrame()

    local time_text_field = playhead_window:textField(1)
    local time_string = time_text_field:axValue()
    time_string = time_string:gsub("\n", "")

    local playhead_seconds = parse_time_to_seconds(time_string)
    if playhead_seconds == 0 then
        -- TODO cannot estimate times from 0, so lets jump to 1?
        -- FYI cannot use move_playhead (based on PPS) yet
        -- hs.eventtap.keyStroke({}, hs.keycodes.map["right"]) -- right only (1 frame right)
        hs.eventtap.keyStroke({ "shift" }, hs.keycodes.map["right"]) -- nearest second to the right

        -- update for new position after moving right
        playhead_window = editor_window.windows:get_playhead_window_or_throw()
        -- DO NOT get frames until UI is stable, zoome din frame is different than zoomed out
        _playhead_window_frame = playhead_window:axFrame()
        time_string = time_text_field:axValue()
        time_string = time_string:gsub("\n", "")
        playhead_seconds = parse_time_to_seconds(time_string)

        -- PRN move back?
    end

    local playhead_x = _playhead_window_frame.x + _playhead_window_frame.w / 2
    local _playhead_relative_timeline_x = playhead_x - timeline_frame.x

    self.timeline_frame = timeline_frame
    self._playhead_window = playhead_window
    self._playhead_window_frame = _playhead_window_frame
    self.playhead_x = playhead_x
    self._playhead_relative_timeline_x = _playhead_relative_timeline_x
    self.time_string = time_string
    self.playhead_seconds = playhead_seconds
    self.pixels_per_second = _playhead_relative_timeline_x / playhead_seconds
    self.pixels_per_frame = self.pixels_per_second / 25
    self.estimated_total_seconds = timeline_frame.w / self.pixels_per_second
    -- print(vim.inspect(self))
    return self
end

---@param self table
---@param target_x number
function TimelineDetails:_move_playhead_to_x(target_x)
    print("moving playhead to " .. target_x)
    local hold_duration_ms = 10
    hs.eventtap.leftClick({
        x = target_x,
        y = self.timeline_frame.y + self.timeline_frame.h / 2
    }, hold_duration_ms * 1000)
    -- PRN round to nearest frame? is that doable?
    self:wait_until_playhead_at(target_x)
end

--- Do not need to add offset of timeline position!
---@param relative_target_x number # pixel value relative to timeline's position
function TimelineDetails:_move_playhead_to_relative(relative_target_x)
    local screen_x = relative_target_x + self.timeline_frame.x
    self:_move_playhead_to_x(screen_x)
end

---@param self TimelineDetails
---@param seconds number
function TimelineDetails:move_playhead_to_seconds(seconds)
    local playhead_x = self.timeline_frame.x + (seconds * self.pixels_per_second) + 1
    self:_move_playhead_to_x(playhead_x)
end

---@return number
local function _get_updated_playhead_x(self)
    -- keep hidden so I am not tempted to use it elsewhere
    --  should help me push needed functionality into this class
    --  also this specific behavior is a conern that should not bleed into consumers

    -- FYI 0.1ms typically to get new frame
    local new_playhead_window_frame = self._playhead_window:axFrame()
    return new_playhead_window_frame.x + new_playhead_window_frame.w / 2
end

---@param target_x number
---@return boolean
function TimelineDetails:is_playhead_now_at_target(target_x)
    -- within one frame either way
    -- PRN make more precise later on if I know the target in terms of a frame value
    local new_x = _get_updated_playhead_x(self) -- in case we just moved the playhead
    print("  new_x", new_x, "target_x", target_x)
    local pixel_gap = math.abs(new_x - target_x)
    return pixel_gap <= self.pixels_per_frame
end

---avoid fixed pauses!
---@param target_x number
---@param max_loops integer
function TimelineDetails:wait_until_playhead_at(target_x, max_loops)
    max_loops = max_loops or 30
    start = get_time()
    for i = 1, max_loops do
        hs.timer.usleep(10000)

        print("  iteration " .. i)
        if self:is_playhead_now_at_target(target_x) then
            break
        end
    end
    print_took("  wait_until_playhead_at", start)
    -- FYI it is still possible you need some slight fixed delay
    --   i.e. if the window coords are updated ahead of something else
    --   that would intefere with typical next actions (i.e. typing 'c'to trigger cut)
    --   if so, add that here so everyone benefits from it
    --   if it's specific to a given automation then that fixed delay can live in consumer code
end

return TimelineDetails
