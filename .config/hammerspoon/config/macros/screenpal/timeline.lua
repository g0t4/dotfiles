---@class TimelineDetails
---@field timeline_frame { x: number, y: number, w: number, h: number }
---@field _playhead_window_frame { x: number, y: number, w: number, h: number }
---@field playhead_x number
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

    local playhead_x = _playhead_window_frame.x + _playhead_window_frame.w / 2
    local _playhead_relative_timeline_x = playhead_x - timeline_frame.x

    self.timeline_frame = timeline_frame
    self._playhead_window = playhead_window
    self._playhead_window_frame = _playhead_window_frame
    self.playhead_x = playhead_x
    self._playhead_relative_timeline_x = _playhead_relative_timeline_x
    self.time_string = time_string
    self.playhead_seconds = playhead_seconds
    if self.playhead_seconds == 0 then
        -- consumers of these values should handle case when nil
        if not ok_to_skip_pps then
            error(
                "ERROR... you are using timeline in a way that may fail due to "
                .. "missing pixels_per_second, review your use case and allow it "
                .. "ok_to_skip_pps after you make any adjustments for pixels_per_second being nil"
            )
        end
        self.pixels_per_second = nil
    else
        self.pixels_per_second = _playhead_relative_timeline_x / playhead_seconds
    end
    -- print(vim.inspect(self))
    return self
end

---@param self TimelineDetails
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
---@param self TimelineDetails
---@return boolean
local function _is_playhead_now_at_target(self, target_x)
    -- within one frame either way
    -- PRN make more precise later on if I know the target in terms of a frame value
    local new_x = _get_updated_playhead_x(self) -- in case we just moved the playhead
    print("  new_x", new_x, "target_x", target_x)
    local pixel_gap = math.abs(new_x - target_x)
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
---@param target_x number
---@param max_loops? integer
local function _wait_until_playhead_at(self, target_x, max_loops)
    max_loops = max_loops or 30
    start = get_time()
    for i = 1, max_loops do
        hs.timer.usleep(10000)

        print("  iteration " .. i)
        if _is_playhead_now_at_target(self, target_x) then
            break
        end
    end
    print_took("  _wait_until_playhead_at", start)
    -- FYI it is still possible you need some slight fixed delay
    --   i.e. if the window coords are updated ahead of something else
    --   that would intefere with typical next actions (i.e. typing 'c'to trigger cut)
    --   if so, add that here so everyone benefits from it
    --   if it's specific to a given automation then that fixed delay can live in consumer code
end

---@param self TimelineDetails
---@param screen_x number
local function _move_playhead_to_screen_x(self, screen_x)
    print("moving playhead to " .. screen_x)
    local hold_duration_ms = 10
    hs.eventtap.leftClick({
        x = screen_x,
        y = self.timeline_frame.y + self.timeline_frame.h / 2
    }, hold_duration_ms * 1000)
    -- PRN round to nearest frame? is that doable?
    _wait_until_playhead_at(self, screen_x)
end

---Do not need to add offset of timeline position!
---@param timeline_x number # x value _WITHIN_ the timeline (not screen)
function TimelineDetails:move_playhead_to(timeline_x)
    local screen_x = timeline_x + self.timeline_frame.x
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
        x = self.timeline_frame.x + self.timeline_frame.w - 1,
        y = self.timeline_frame.y,
    })
end

-- TODO move_to_video_start()
-- TODO move_to_video_end()

---@return number # 0 to 1
function TimelineDetails:get_position_percent()
    return (self.playhead_x - self.timeline_frame.x) / self.timeline_frame.w
end

---@param percent # 0 to 1
function TimelineDetails:move_playhead_to_position_percent(percent)
    -- +1 pixel stops leftward drift by 1 frame (good test is back to back reopen, albeit not a normal workflow)
    self:move_playhead_to(percent * self.timeline_frame.w + 1)
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
