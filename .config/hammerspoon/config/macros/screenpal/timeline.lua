---@class TimelineController
---@field _timeline_frame AXFrame
---@field _playhead_window_frame AXFrame
---@field _playhead_screen_x number
---@field _playhead_timeline_relative_x? number -- TODO make this public? a few uses externally that seem fine (i.e. showing detected silence ranges)
local TimelineController = {}

---@param app_windows AppWindows
---@return hs.axuielement? editor_window -- None means the playhead is off-screen
local function get_playhead_window(app_windows)
    -- app:window(2)
    -- AXRoleDescription: window<string>
    -- AXTitle: SOM-FloatingWindow-Type=edit2.posbar-ZOrder=1(Undefined+1)<string>
    return app_windows:get_window_by_title_pattern("^SOM%-FloatingWindow%-Type=edit2.posbar%-ZOrder=1")
end

---@param editor_window ScreenPalEditorWindow
---@param self TimelineController
function TimelineController:new(editor_window, ok_to_skip_pps)
    ok_to_skip_pps = ok_to_skip_pps or false

    local _timeline_frame = editor_window._btn_position_slider:axFrame()
    self._timeline_frame = _timeline_frame

    -- FYI right now if playhead is off screen, this blows up intentionally... which is fine b/c
    --  I don't see much of a need to edit w/o playhead on-screen... most I could do is move it on screen if its off
    local _playhead_window = get_playhead_window(editor_window.windows)
    if _playhead_window == nil then
        -- TODO revisit playhead fields and mark as appropriate (nil-able)
        -- FYI downstream logic will break...  but this warning should be sufficient
        print("WARNING: PLAYHEAD IS NOT ON-SCREEN")
        return self
    end
    -- DO NOT get frames until UI is stable, zoome din frame is different than zoomed out
    local _playhead_window_frame = _playhead_window:axFrame()

    local _playhead_screen_x = _playhead_window_frame.x + _playhead_window_frame.w / 2
    local _playhead_timeline_relative_x = _playhead_screen_x - _timeline_frame.x

    self._playhead_window = _playhead_window
    self._playhead_window_frame = _playhead_window_frame
    self._playhead_screen_x = _playhead_screen_x
    self._playhead_timeline_relative_x = _playhead_timeline_relative_x

    local time_string = _playhead_window:textField(1)
        :axValue()
        :gsub("\n", "")
    local _playhead_seconds = parse_time_to_seconds(time_string)
    self.time_string = time_string
    -- print(vim.inspect(self))
    return self
end

---@param self TimelineController
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

--- Get UPDATED position, right now, relative to start of timeline
function TimelineController:get_current_playhead_timeline_relative_x()
    local current_playhead_screen_x = _get_current_playhead_screen_x(self)
    return current_playhead_screen_x - self._timeline_frame.x
end

---@param desired_playhead_screen_x number
---@param self TimelineController
---@return boolean
local function _is_playhead_now_at_screen_x(self, desired_playhead_screen_x)
    local current_playhead_screen_x = _get_current_playhead_screen_x(self) -- in case we just moved the playhead
    -- print("  current_playhead_screen_x", current_playhead_screen_x, "desired_playhead_screen_x", desired_playhead_screen_x)
    local pixel_gap = math.abs(current_playhead_screen_x - desired_playhead_screen_x)
    -- print("  pixel_gap", pixel_gap)

    -- * within ~ one frame
    --  OK so I cannot calculate pixels per frame on the fly but I know:
    --  unzoomed => depends on video length
    --  zoom1 => ? smaller than zoom2's
    --  zoom2 => 75 pixels/frame (1080p) => 75/25 = 3 pixels/second (1080p) => 6 pixels/second (4k)
    --  zoom3 => 150 pixels/frame => 6 pixels/second (1080p) => 12 pixels/second (4k)
    --
    --  chose 6 b/c that will work mostly for zoom2 and that is the zoom I almost exclusively edit with
    -- TODO ALTERNATIVE => see if it changed vs original value?
    --    ALTERNATIVE => OR, see if it changed by 90% of the target gap (old-desired = desired_gap, old-current = moved_gap...  is moved_gap/desired_gap > 0.9 ? )
    return pixel_gap <= 6
end

local _10ms = 10 * 1000

---avoid fixed pauses!
---@param self TimelineController
---@param desired_playhead_screen_x number
---@param max_loops? integer
local function _wait_until_playhead_at_screen_x(self, desired_playhead_screen_x, max_loops)
    max_loops = max_loops or 30
    start = get_time()
    for iteration = 1, max_loops do
        -- print("  iteration " .. i)
        hs.timer.usleep(_10ms)

        if _is_playhead_now_at_screen_x(self, desired_playhead_screen_x) then
            -- print("  after " .. iteration .. " iterations")
            break
        end
    end
    log_if_slower_than_100ms("  wait for playhead move", start)
end

---@param self TimelineController
---@param playhead_screen_x number
local function _move_playhead_to_screen_x(self, playhead_screen_x)
    -- print("moving playhead to screen_x=" .. tostring(playhead_screen_x))
    local hold_duration_ms = 10
    hs.eventtap.leftClick({
        x = playhead_screen_x,
        y = self._timeline_frame.y + self._timeline_frame.h / 2
    }, hold_duration_ms * 1000)
    _wait_until_playhead_at_screen_x(self, playhead_screen_x)
end

--- RELATIVE to the TIMELINE (not the screen)
---@param timeline_relative_x number # x value _WITHIN_ the timeline (not screen_x)
function TimelineController:move_playhead_to(timeline_relative_x)
    local screen_x = timeline_relative_x + self._timeline_frame.x
    _move_playhead_to_screen_x(self, screen_x)
end

--- jump to start of CURRENT view (not entire timeline)
function TimelineController:move_playhead_to_timeline_start()
    hs.eventtap.leftClick({
        -- click the left‑most part of the timeline slider
        --  NOT necessarily the video start unless timeline is not zoomed
        x = self._timeline_frame.x,
        y = self._timeline_frame.y,
    })
end

--- jump to end of CURRENT view (not entire timeline)
function TimelineController:move_playhead_to_timeline_end()
    hs.eventtap.leftClick({
        -- click the rightmost part of the timeline slider
        -- -1 works best for the end (in my testing)
        x = self._timeline_frame.x + self._timeline_frame.w - 1,
        y = self._timeline_frame.y,
    })
end

-- TODO move_to_video_start()
-- TODO move_to_video_end()

---@return number ratio # 0 to 1, "percent" is a terrible name b/c it's not 0 to 100% ... not sure what I like better
function TimelineController:get_position_percent()
    local timeline_relative_x = self._playhead_screen_x - self._timeline_frame.x
    return timeline_relative_x / self._timeline_frame.w
end

---@param ratio number # 0 to 1, "percent" is a terrible name b/c it's not 0 to 100% ... not sure what I like better
function TimelineController:move_playhead_to_position_percent(ratio)
    -- +1 pixel stops leftward drift by 1 frame (good test is back to back reopen, albeit not a normal workflow)
    local timeline_relative_x = ratio * self._timeline_frame.w + 1
    self:move_playhead_to(timeline_relative_x)
end

--- bounding box (frame) around timeline
---@return AXFrame
function TimelineController:get_timeline_frame()
    -- this accessor makes it easier to see external usage
    -- AND I can now make the storage private (and can change it too)
    return self._timeline_frame
end

return TimelineController


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
