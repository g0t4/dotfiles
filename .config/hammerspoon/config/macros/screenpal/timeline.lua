---@class TimelineDetails
---@field timeline_frame { x: number, y: number, w: number, h: number }
---@field _playhead_window_frame { x: number, y: number, w: number, h: number }
---@field _playhead_screen_x number
---@field _playhead_relative_timeline_x number
---@field playhead_seconds number
---@field pixels_per_second? number
local TimelineDetails = {}

---@param self TimelineDetails
function TimelineDetails:new(editor_window, ok_to_skip_pps)
    ok_to_skip_pps = ok_to_skip_pps or false

    local timeline_frame = editor_window._btn_position_slider:axFrame()

    local playhead_window = editor_window.windows:get_playhead_window_or_throw()
    -- DO NOT get frames until UI is stable, zoome din frame is different than zoomed out
    local _playhead_window_frame = playhead_window:axFrame()

    local time_text_field = playhead_window:textField(1)
    local time_string = time_text_field:axValue()
    time_string = time_string:gsub("\n", "")
    local playhead_seconds = parse_time_to_seconds(time_string)

    local playhead_screen_x = _playhead_window_frame.x + _playhead_window_frame.w / 2
    local _playhead_relative_timeline_x = playhead_screen_x - timeline_frame.x

    self.timeline_frame = timeline_frame
    self._playhead_window = playhead_window
    self._playhead_window_frame = _playhead_window_frame
    self._playhead_screen_x = playhead_screen_x
    self._playhead_relative_timeline_x = _playhead_relative_timeline_x
    self.time_string = time_string
    self.playhead_seconds = playhead_seconds
    if self.playhead_seconds == 0 then
        if not ok_to_skip_pps then
            print("WARNING = timeline details accessed w/o declaring it can handle nil PPS (ok_to_skip_pps)... review and adjust accordingly")
            -- NOT a failure, just a warning
        end
        -- consumers of these values should handle case when nil
        self.pixels_per_second = nil
    else
        self.pixels_per_second = _playhead_relative_timeline_x / playhead_seconds
    end
    -- print(vim.inspect(self))
    return self
end

---@param self TimelineDetails
---@return number
local function _get_current_playhead_screen_x(self)
    -- this behavior should not bleed into consumers!

    -- FYI ~0.1ms to get new axFrame()
    --   don't forget, attributes are copied when accessed, hence have to get new axFrame()
    --   BUT, axuielements are passed by reference, and thus reusable (assuming they are still valid / not destroyed)
    local current_playhead_window_frame = self._playhead_window:axFrame()
    local current_playhead_screen_x = current_playhead_window_frame.x + current_playhead_window_frame.w / 2
    return current_playhead_screen_x
    -- BTW, better to be explicit in names w.r.t. x values to avoid all confusion about what the purpose is
    --   the names are hidden away in this class, so who cares?
end

---@param desired_playhead_screen_x number
---@param self TimelineDetails
---@return boolean
local function _is_playhead_now_at_screen_x(self, desired_playhead_screen_x)
    -- within one frame either way
    -- PRN make more precise later on if I know the target in terms of a frame value
    local current_playhead_screen_x = _get_current_playhead_screen_x(self) -- in case we just moved the playhead
    print("  current_playhead_screen_x", current_playhead_screen_x, "desired_playhead_screen_x", desired_playhead_screen_x)
    local pixel_gap = math.abs(current_playhead_screen_x - desired_playhead_screen_x)
    if self.pixels_per_second == nil then
        -- * ONLY happens @0:00 on timeline + when trigger move of playhead
        --  and would only matter for a short jump of ~5 pixels which should be rare
        --  chose 6 b/c 3x zoom is 150 pixels/second => 150/25 = 6 pixels_per_frame at highest zoom
        --  this could cause issues with zoomed out view too if 6 is a long distance... again only from 0 starting
        print("WARNING - HAD TO GUESS PIXELS PER FRAME for pixel_gap b/c you're @0:00 on the timeline, avoid this by moving anywhere else on timeline")
        return pixel_gap <= 6
    else
        local pixels_per_frame = self.pixels_per_second / 25
        return pixel_gap <= pixels_per_frame
    end
end

---avoid fixed pauses!
---@param self TimelineDetails
---@param desired_playhead_screen_x number
---@param max_loops? integer
local function _wait_until_playhead_at_screen_x(self, desired_playhead_screen_x, max_loops)
    max_loops = max_loops or 30
    start = get_time()
    for i = 1, max_loops do
        hs.timer.usleep(10000)

        print("  iteration " .. i)
        if _is_playhead_now_at_screen_x(self, desired_playhead_screen_x) then
            break
        end
    end
    print_took("  wait for playhead to move", start)
    -- FYI it is still possible you need some slight fixed delay
    --   i.e. if the window coords are updated ahead of something else
    --   that would intefere with typical next actions (i.e. typing 'c'to trigger cut)
    --   if so, add that here so everyone benefits from it
    --   if it's specific to a given automation then that fixed delay can live in consumer code
end

---@param self TimelineDetails
---@param playhead_screen_x number
local function _move_playhead_to_screen_x(self, playhead_screen_x)
    print("moving playhead to screen_x=" .. tostring(playhead_screen_x))
    local hold_duration_ms = 10
    hs.eventtap.leftClick({
        x = playhead_screen_x,
        y = self.timeline_frame.y + self.timeline_frame.h / 2
    }, hold_duration_ms * 1000)
    _wait_until_playhead_at_screen_x(self, playhead_screen_x)
end

--- RELATIVE to the TIMELINE (not the screen)
---@param timeline_relative_x number # x value _WITHIN_ the timeline (not screen_x)
function TimelineDetails:move_playhead_to(timeline_relative_x)
    local screen_x = timeline_relative_x + self.timeline_frame.x
    _move_playhead_to_screen_x(self, screen_x)
end

--- jump to start of CURRENT view (not entire timeline)
function TimelineDetails:move_to_timeline_start()
    hs.eventtap.leftClick({
        -- click the left‑most part of the timeline slider
        --  NOT necessarily the video start unless timeline is not zoomed
        x = self.timeline_frame.x,
        y = self.timeline_frame.y,
    })
end

--- jump to end of CURRENT view (not entire timeline)
function TimelineDetails:move_to_timeline_end()
    hs.eventtap.leftClick({
        -- click the rightmost part of the timeline slider
        -- -1 works best for the end (in my testing)
        x = self.timeline_frame.x + self.timeline_frame.w - 1,
        y = self.timeline_frame.y,
    })
end

-- TODO move_to_video_start()
-- TODO move_to_video_end()

---@return number ratio # 0 to 1, "percent" is a terrible name b/c it's not 0 to 100% ... not sure what I like better
function TimelineDetails:get_position_percent()
    local timeline_relative_x = self._playhead_screen_x - self.timeline_frame.x
    return timeline_relative_x / self.timeline_frame.w
end

---@param ratio number # 0 to 1, "percent" is a terrible name b/c it's not 0 to 100% ... not sure what I like better
function TimelineDetails:move_playhead_to_position_percent(ratio)
    -- +1 pixel stops leftward drift by 1 frame (good test is back to back reopen, albeit not a normal workflow)
    local timeline_relative_x = ratio * self.timeline_frame.w + 1
    self:move_playhead_to(timeline_relative_x)
end

return TimelineDetails


-- FYI zoom levels and pixels per second (calculated just so I can refer to them)
--  right now I am not using this for any automations
--  and a few reasons why I can't use these (at least not yet):
--  - I cannot determine zoom1 vs zoom2 vs zoom3
--  - Can only tell zoomed vs not zoomed
--  - Therefore these are mostly for reasoning about scale
--
--  I am using PPS for checking if the playhead is moved to the new spot yet
--  - because it will move nearby (closest frame)
--  - so I use PPS as a tolerance (within one frame either way)
--
--  BTW I can calculate PPS in every case EXCEPT when playhead is at time 0
--
-- *** PIXELS PER SECOND for each ZOOM level (fixed for each level)
-- Calculation:
-- 1 Move timeline to start of video, left side must be 0
-- 2 Move to nearby second mark (left side of timeline must remain at 0)
-- 3 pixels_apart / time_in_seconds = PPS
--   zoom1 => 25.164473684211 PPS
--   zoom2 => 75.166666666667 PPS
--   zoom3 => 150.16666666667 PPS
--
--   * KEEP IN MIND, zoom levels are FIXED # seconds/frames regardless of video length...
--   so when zoom 2 you know exactly where to click to move over 1 second relative to current position...
--   or to move to X seconds along from start/end of the visible timeline
