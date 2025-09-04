local vim = require("config.libs.vim") -- reuse nvim lua modules in hammerspoon
require("config.macros.screenpal.ui")
require('config.macros.screenpal.helpers')

---@return hs.axuielement app_element
local function get_screenpal_app_element_or_throw()
    return get_app_element_or_throw("com.screenpal.app") -- < 1 ms
end

-- fix for vim.iter:totable() - IIUC with non-array tables
-- TODO FIX THIS missing maxn ELSEWHERE!!!!
-- hammerspoon uses lua 5.4 and that must not have table.maxn that you do have in vim w/ lua 5.1
table.maxn = function(t)
    -- TODO! lookup what else this might need to implement beyond the vim.iter use case
    local max = 0
    for k, v in pairs(t) do
        if k > max then max = k end
    end
    return max
end

---@class ScreenPalEditorWindow
---@field windows AppWindows
ScreenPalEditorWindow = {}
function ScreenPalEditorWindow:new()
    ---@type ScreenPalEditorWindow
    local editor_window = {}
    setmetatable(editor_window, self)
    self.__index = self
    self.app = get_screenpal_app_element_or_throw()
    self.windows = AppWindows:new(self.app)
    self.win = self.windows:editor_window_or_throw()

    local function ensure_cached_controls()
        if self._cached_buttons then
            if self._btn_minimum_zoom:isValid() then
                -- assume all controls are still valid, if you have issues with one control going in and out, don't destroy cache of everything for that one... add a special check in its code path and send in an override here to flush cache then
                return
            end
            print("editor window cache invalidated")
        end

        -- TODO! fully invalidate cache... rewrite so you can create a new cache object for the window
        self._scrollbars = {} -- fixes finding scrollbar when refresh cache
        self._btn_back_to_projects = nil
        self._btn_maximum_zoom = nil
        self._btn_medium_zoom = nil
        self._btn_minimum_zoom = nil
        self._btn_position_slider = nil
        self._btn_toggle_magnify = nil
        self._textfield_title = nil

        local start = get_time()
        -- enumerating all children and getting role and description is no diff than just buttons with description only...
        vim.iter(self.win:children())
            :each(function(ui_elem)
                -- one time hit, just cache all buttons when I have to find one of them
                -- not extra expensive to cache each one relative to time to enumerate / get description (has to be done to find even one button)
                local description = ui_elem:axDescription()
                local role = ui_elem:axRole()
                -- TODO! split out editor window class? with all controls there? this is bastardized here but is fine for now

                if role == "AXButton" then
                    if description == "Minimum Zoom" then
                        -- AXIndex: 3, #42 in array in my testing (could change)
                        self._btn_minimum_zoom = ui_elem
                        return -- continue early so I can add more complex checks below and avoid them when possible
                    elseif description == "Maximum Zoom" then
                        self._btn_maximum_zoom = ui_elem
                        return
                    elseif description == "Medium Zoom" then
                        self._btn_medium_zoom = ui_elem
                        return
                    elseif description == "Toggle Magnify" then
                        self._btn_toggle_magnify = ui_elem
                        return
                    elseif description == "Position Slider" then
                        self._btn_position_slider = ui_elem
                        return
                    elseif description == "Back to Video Projects" then
                        self._btn_back_to_projects = ui_elem
                        return
                    else
                        -- find new controls, uncomment this:
                        -- print(description)
                    end
                elseif role == "AXTextField" then
                    -- accessibility description => AXDescription in hs apis... is empty only for the title name field (upper left)
                    -- ALSO most of the time it will have an mX in it :)
                    --

                    if description == "" then
                        -- so far, the text input for the title on the edit video page is the only text field with no description!
                        --    by the way this maps to accessibility description IIUC in script debugger
                        self._textfield_title = ui_elem
                    end

                    -- PRN capture all text fields? or eliminate some and then pick the most liklely remaining?
                    -- print("ui_elem", hs.inspect({
                    --     description = description,
                    --     role = role,
                    --     value = ui_elem:axValue(),
                    --     frame = ui_elem:axFrame(),
                    --     roleDesc = ui_elem:axRoleDescription(),
                    -- }))

                    -- app:window(2):textField(11)
                    --
                    -- AXEdited: true<bool>
                    -- AXEnabled: true<bool>
                    -- AXFocused: true<bool>
                    -- AXFocusedUIElement: AXTextField<hs.axuielement>
                    -- AXIndex: 0<number>
                    -- AXMaxValue: 0<number>
                    -- AXMinValue: 0<number>
                    -- AXOrientation: AXUnknownOrientation<string>
                    -- AXRoleDescription: text field<string>
                    -- AXSelected: false<bool>
                    -- AXSelectedText: m1-02 Use Curly Braces to Deliniate the Parameter Name<string>
                    -- AXValue: m1-02 Use Curly Braces to Deliniate the Parameter Name<string>
                elseif role == "AXScrollBar" then
                    -- have to match on position...FML... I could use coords too I think
                    self._scrollbars = self._scrollbars or {}
                    table.insert(self._scrollbars, ui_elem)
                    -- BTW tracking these has nil impact... even if I use prints in here it's not material vs the 100ms overall to enumerate all ui elements of the window
                    return
                end
            end)
        self._cached_buttons = true
        print_took("caching controls took: ", start)
    end

    ---@return number percent
    function editor_window:playhead_position_percent()
        ensure_cached_controls()
        -- playhead's time field is a separate window, but treat it like a child control
        -- lookup as needed so it can be refreshed, but it is NOT expensive if cached!
        local time_window = self.windows:get_playhead_window_or_throw()
        local time_window_frame = time_window:axFrame()
        print("time_window_frame", vim.inspect(time_window_frame))

        -- AFAICT nothing differs on zoom level buttons...
        -- - thus cannot know which is clicked (zoomed)
        -- - NBD I mostly use 2 and can re-zoom myself (and I'll be using not zoomed to restore playhead position)
        --   print(vim.inspect(self._btn_medium_zoom:dumpAttributes()))
        self:zoom_off()

        local timeline_frame = self._btn_position_slider:axFrame()
        print("timeline_frame", vim.inspect(timeline_frame))
        -- use width and then position relative to sides to create restore point at least... assuming NO zoom
        -- then use time on playhead plus position to compute total clip time!
        --    from this... and given zooms AFAICT are fixed levels... I can likely compute where to click when zoomed too :)

        local time_window_x_center = time_window_frame.x + (time_window_frame.w / 2)
        local playhead_percent = (time_window_x_center - timeline_frame.x) / timeline_frame.w
        print("playhead_percent", playhead_percent)
        return playhead_percent
    end

    ---@param playhead_percent number
    function editor_window:restore_playhead_position(playhead_percent)
        ensure_cached_controls()
        ---@type hs.axuielement
        local time_window = self.windows:get_playhead_window_or_throw()
        local time_window_frame = time_window:axFrame()
        print("time_window_frame", vim.inspect(time_window_frame))

        self:zoom_off() -- do not restore when zoomed

        local timeline_frame = self._btn_position_slider:axFrame()
        print("timeline_frame", vim.inspect(timeline_frame))

        local time_window_x_center = timeline_frame.x + playhead_percent * timeline_frame.w

        local hold_down_before_release = 1000 -- default is 200ms, will matter if chaining more actions!
        -- I ran into trouble with 0ms hold delay
        hs.eventtap.leftClick({
            -- +1 pixel stops leftward drift by 1 frame (good test is back to back reopen, albeit not a normal workflow)
            x = time_window_x_center + 1,
            y = timeline_frame.y + timeline_frame.h / 2
        }, hold_down_before_release)
    end

    function editor_window:is_zoomed()
        ensure_cached_controls()
        if not self._btn_minimum_zoom then
            error("No zoom button found, aborting...")
        end
        -- AXPosition == 0,0 ==> not zoomed
        local position = self._btn_minimum_zoom:axPosition()
        return position.x > 0 and position.y > 0
    end

    function editor_window:zoom_on()
        if self:is_zoomed() then return end
        -- FYI typing m is faster now... must be b/c of the native Apple Silicon app
        hs.eventtap.keyStroke({}, "m", 0, get_screenpal_app_element_or_throw())
    end

    function editor_window:zoom_off()
        if not self:is_zoomed() then return end
        hs.eventtap.keyStroke({}, "m", 0, get_screenpal_app_element_or_throw())
    end

    function editor_window:get_scrollbar_or_throw()
        -- PRN search for big AXMaxValues? that might uniquely identify it if I have issues in the future with other scrollbars visible
        -- OR by position on screen (toward bottom of window is telling)
        ensure_cached_controls()
        local scrollbar = self._scrollbars[4]
        if not scrollbar then
            error("No editor_window scrollbar found, aborting...")
        end
        return scrollbar
    end

    function editor_window:get_timeline_slider_or_throw()
        ensure_cached_controls()
        if not self._btn_position_slider then
            error("No timeline slider found, aborting...")
        end
        return self._btn_position_slider
    end

    function editor_window:zoom1()
        ensure_cached_controls()
        self:zoom_on()
        self._btn_minimum_zoom:performAction("AXPress")
    end

    function editor_window:zoom2()
        ensure_cached_controls()
        self:zoom_on()
        self._btn_medium_zoom:performAction("AXPress")
    end

    function editor_window:zoom3()
        ensure_cached_controls()
        self:zoom_on()
        self._btn_maximum_zoom:performAction("AXPress")
    end

    function cache_project_view_controls()
        vim.iter(self.win:children())
            :each(function(ui_elem)
                -- one time hit, just cache all buttons when I have to find one of them
                -- not extra expensive to cache each one relative to time to enumerate / get description (has to be done to find even one button)
                local description = ui_elem:axDescription()
                local role = ui_elem:axRole()
                -- TODO! split out editor window class? with all controls there? this is bastardized here but is fine for now
                if role == "AXScrollArea" then
                    self._scrollarea_list = ui_elem -- s/b only scroll area in the scorll area
                    print("sa", hs.inspect(self._scrollarea_list))
                    print("sa.sa", hs.inspect(self._scrollarea_list:scrollAreas()[1]))
                    self._scrollarea_list = self._scrollarea_list:scrollAreas()[1]
                    -- PRN I could cache a list of the projects if that would be useful
                end
            end)
    end

    function editor_window:reopen_project()
        -- FYI keep prints so as I encounter issues I know where things are blowing up
        local win = get_cached_editor_window()
        local timeline_scrollbar = win:get_scrollbar_or_throw()
        print("timeline scroll", timeline_scrollbar)
        local current_zoom_scrollbar_position = timeline_scrollbar:axValue() -- current value
        print("zoom scrollbar position", current_zoom_scrollbar_position)
        local current_zoomed = win:is_zoomed()
        print("current_zoomed", current_zoomed)
        -- cannot find a way (yet) to save zoom level
        --   one idea, could store maxvalue of position_slider
        --   and compare to each zoom level (try 2 first, then 1/3) on restore
        --   until find match for maxvalue and then you know you found the level!
        self:zoom_off()
        -- PRN pause.. if have trouble reliably restoring same position
        -- TODO! use doAfter
        -- timer.usleep(100000)


        local playhead_percent = self:playhead_position_percent()

        if not self._textfield_title then
            error("No title found, aborting...")
        end
        local title = self._textfield_title:axValue()
        print("title: ", title)
        if not self._btn_back_to_projects then
            error("No back to projects button found, aborting...")
        end
        self._btn_back_to_projects:performAction("AXPress")

        local btn = wait_for_element(function()
            cache_project_view_controls()
            if not self._scrollarea_list then return end
            return vim.iter(self._scrollarea_list:buttons())
                :filter(function(button)
                    local desc = button:axDescription()
                    return desc == title
                end)
                :totable()[1]
        end, 100, 20)

        if not btn then
            error("cannot find project to re-open, aborting...")
        end

        btn:performAction("AXPress")
        -- TODO! use doAfter instead! this is blocking
        hs.timer.usleep(100000) -- TODO replace w/ wait_for_element

        -- restore playhead
        self:restore_playhead_position(playhead_percent)

        -- restore zoom / scroll bar position
        if not current_zoomed then
            print("NOT zoomed before, skipping zoom restore")
            return
        end

        self:zoom2()
        -- TODO! use doAfter
        -- timer.usleep(100000)
        -- StreamDeckScreenPalTimelineApproxRestorePosition(current_zoom_scrollbar_position)
    end

    function editor_window:estimate_time_per_pixel()
        function run_async(what)
            local co = coroutine.create(what)
            coroutine.resume(co)
        end

        function sleep_ms(ms)
            seconds = ms / 1000
            local _co = coroutine.running()
            hs.timer.doAfter(seconds, function()
                coroutine.resume(_co)
            end)
            coroutine.yield()
        end

        run_async(function()
            print("before sleep")
            sleep_ms(1000)
            print("after sleep")
        end)
    end

    function editor_window:estimate_time_per_pixel_()
        local playhead_window = self.windows:get_playhead_window_or_throw()
        local playhead_window_frame = playhead_window:axFrame()

        -- must be zoomed out, else cannot know that start of time line is 0 and end is the end of the video
        self:zoom_off() -- PRN modify logic internally to wait for zoom off? (NOT HERE, rather put it in zoom_off to be reusable, and only call if is zoomed)

        local time_text_field = playhead_window:textField(1)
        local time = time_text_field:axValue()
        time = time:gsub("\n", "")

        local playhead_seconds = parse_time_to_seconds(time)
        dump({ time = time, seconds = playhead_seconds, })

        -- possible issue => what if timeline stops part way when editing a short video? Is that even possible? if so this may not work well and OH well if I can't adjust in that rare case
        local timeline_frame = self._btn_position_slider:axFrame()

        local playhead_x = playhead_window_frame.x + playhead_window_frame.w / 2
        local playhead_relative_timeline_x = playhead_x - timeline_frame.x
        dump({
            playhead_window_frame = playhead_window_frame,
            playhead_x = playhead_x,
            playhead_relative_timeline_x = playhead_relative_timeline_x
        })
        -- - timeline_frame.x

        local pixels_per_second = playhead_relative_timeline_x / playhead_seconds
        local estimated_total_seconds = timeline_frame.w / pixels_per_second
        -- F!!! NAILED it for total seconds!!!
        dump({ estimated_total_seconds = estimated_total_seconds })


        local est_x_one_second = timeline_frame.x + pixels_per_second
        local pixels_per_frame = pixels_per_second / 25 -- spal uses 25 fps
        dump({
            est_x_one_second = est_x_one_second,
            pixels_per_frame = pixels_per_frame
        })

        local hold_down_before_release = 1000
        hs.eventtap.leftClick({
            -- +1 pixel stops leftward drift by 1 frame (good test is back to back reopen, albeit not a normal workflow)
            x = est_x_one_second + 1, -- for 1 sec its slightly off (NBD => could arrow over if consistently off))
            -- +1 => 1.04 sec (1 frame past), +0 => 0.92 sec (2 frames before)
            -- FYI I DO NOT NEED PRECISE! silence ranges for example will be paddeed anyways! can always padd an extra frame!
            y = timeline_frame.y + timeline_frame.h / 2
        }, hold_down_before_release)


        -- ***! attempt to click at 1 second mark!


        -- TODO!!! parse screen shots of position slider and find the silence ranges
        -- TODO!!!   to automate selecting them using my own padding!
        -- TODO!!!   and other cool helpers
        -- TODO      test w/ cmd+ctrl+alt + "p" hammerspoon shortcut that screencaps individual elements and then can use that to test with (i.e. pos slider capture)
        -- TODO      the color for silence is reliably showing up as this
        --              #21253B -- detected silence periods
        -- TODO         I confirmed this in both the running app and in my screencap
        -- TODO         !!! slice the top of the image off (or maybe 3 pixels down) b/c then you won't have any interference with waveform
        --              THEN move left to right through the pixels and look at the color
        --              OR do something more sophisticated (reliable)
        --   ! see config/macros/screenpal/py/timeline_detect_blocks.py for initial idea to find gray silence areas




        -- set posbar_window to first window of procSpal whose name starts with "SOM-FloatingWindow-Type=edit2.posbar-ZOrder"
        -- set playhead_time to value of text field 1 of item 1 of posbar_window
        -- -- TODO parse time as needed
        -- -- examples:
        -- -- "\n\r1:03.40" -- when pasted it shows \n\ then a new line... IIAC that is \r? so I added r... not sure but
        -- return playhead_time
    end

    -- PRN can I use a library to parse out pauses and add my own padding to them when cutting them?! that would ROCK

    return editor_window
end

local _cached_editor_window = nil
function get_cached_editor_window()
    if not _cached_editor_window then
        _cached_editor_window = ScreenPalEditorWindow:new()
    end
    return _cached_editor_window
end

function StreamDeckScreenPalTimelineZoomAndJumpToStart()
    local win = get_cached_editor_window()
    win:zoom_off() -- zoom out first means just click end and zoom in... no slider necessary!
    -- TODO! use doAfter
    timer.usleep(10000)
    StreamDeckScreenPalTimelineJumpToStart()
    -- zoom after so if I am initially not zoomed, I can move faster
    -- PRN zoom out before move and then zoom in when done?
    -- TODO! use doAfter
    timer.usleep(10000)
    win:zoom2()
end

function StreamDeckScreenPalTimelineZoomAndJumpToEnd()
    local win = get_cached_editor_window()
    win:zoom_off() -- zoom out first means just click end and zoom in... no slider necessary!
    -- TODO! use doAfter
    timer.usleep(10000)
    StreamDeckScreenPalTimelineJumpToEnd()
    -- TODO! use doAfter
    timer.usleep(10000)
    win:zoom2()
end

function StreamDeckScreenPalTimelineJumpToStart()
    -- local original_mouse_pos = hs.mouse.absolutePosition()
    local win = get_cached_editor_window()

    if win:is_zoomed() then
        local timeline_scrollbar = win:get_scrollbar_or_throw()
        local frame = timeline_scrollbar:axFrame()
        local min_value = timeline_scrollbar:axMinValue()

        local function click_until_timeline_at_end()
            local prior_value = nil
            while true do
                local value = timeline_scrollbar:axValue()
                local current_value = tonumber(value)
                if not current_value
                    or current_value <= min_value
                then
                    break
                end

                if prior_value ~= nil and current_value == prior_value then
                    print("Value unchanged, stopping.")
                    break
                end
                prior_value = current_value

                -- click left-most side of timeline's scrollbar to get to zero
                hs.eventtap.leftClick({ x = frame.x, y = frame.y + frame.h / 2 })
                -- hs.eventtap.leftClick({ x = frame.x, y = frame.y + frame.h / 2 }) -- could click twice if value doesn't change
                -- timer.usleep(10000) -- don't need pause b/c hs seems to block while clicking
            end
        end

        click_until_timeline_at_end()
    end

    -- * move playhead to start (0) by clicking leftmost part of position slider (aka timeline)
    --   keep in mind, scrollbar below is like a pager, so it has to be all the way left, first
    --   PRN add delay if this is not registering, but use it first to figure that out
    local slider = win:get_timeline_slider_or_throw()
    hs.eventtap.leftClick({ x = slider:axFrame().x, y = slider:axFrame().y })

    -- hs.mouse.absolutePosition(original_mouse_pos) -- umm I feel like I want to NOT restore so I can move mouse easily at start!
end

function StreamDeckScreenPalTimelineJumpToEnd()
    -- local original_mouse_pos = hs.mouse.absolutePosition()
    local win = get_cached_editor_window()

    if win:is_zoomed() then
        local timeline_scrollbar = win:get_scrollbar_or_throw()
        local frame = timeline_scrollbar:axFrame()
        local max_value = timeline_scrollbar:axMaxValue()

        local function clickUntilTimelineAtEnd()
            local prior_value = nil
            while true do
                local value = timeline_scrollbar:axValue()
                local current_value = tonumber(value)
                if not current_value
                    or current_value >= max_value
                then
                    break
                end

                if prior_value ~= nil and current_value == prior_value then
                    print("Value unchanged, stopping.")
                    break
                end
                prior_value = current_value

                -- click right‑most side of the scrollbar to advance toward the end
                hs.eventtap.leftClick({ x = frame.x + frame.w - 1, y = frame.y + frame.h / 2 })
            end
        end

        clickUntilTimelineAtEnd()
    end

    -- move playhead to end by clicking the right‑most part of the timeline slider
    local slider = win:get_timeline_slider_or_throw()
    local sframe = slider:axFrame()
    hs.eventtap.leftClick({ x = sframe.x + sframe.w - 1, y = sframe.y })

    -- hs.mouse.absolutePosition(original_mouse_pos) -- try not restoring, might be better!
end

function StreamDeckScreenPalTimelineApproxRestorePosition(restore_position_value)
    -- approximate restore
    -- can only click timeline before/after the slider's bar... so this won't be precise unless I find a way to move it exactly

    -- PRN turn this into precise calculations:
    --   how far does the value move after first click
    --   divide pixels by that value and estimate where to click for closer next step
    -- OR... how about zoom out, click to move playhead, then zoom back in?
    --    can read time of playhead (confirmed)
    --    can I read start/end times? if so I can know range and just do maths for any time to jump to

    local win = get_cached_editor_window()
    if not win:is_zoomed() then
        return -- nothing to do, yet
    end

    local timeline_scrollbar = win:get_scrollbar_or_throw()
    local frame = timeline_scrollbar:axFrame()
    local min_value = timeline_scrollbar:axMinValue()

    local limit_count = 0

    while limit_count < 50 do
        limit_count = limit_count + 1 -- just in case approx isn't working :) in some edge case
        local value = timeline_scrollbar:axValue()
        local current_value = tonumber(value)
        if not current_value
            or current_value == restore_position_value
        then
            break
        end

        if current_value < restore_position_value then
            -- click right‑most side of the scrollbar to advance toward the end
            hs.eventtap.leftClick({ x = frame.x + frame.w - 1, y = frame.y + frame.h / 2 })
            -- once I blow past the value, stop
            current_value = tonumber(timeline_scrollbar:axValue())
            if current_value >= restore_position_value then
                break
            end
        else
            -- click left‑most side of the scrollbar to advance toward the end
            hs.eventtap.leftClick({ x = frame.x, y = frame.y + frame.h / 2 })
            -- once I blow past the value, stop
            current_value = tonumber(timeline_scrollbar:axValue())
            if current_value <= restore_position_value then
                break
            end
        end
    end
end

function StreamDeckScreenPalReopenProject()
    local win = get_cached_editor_window()
    win:reopen_project()
    -- -- local title = win._textfield_title:axValue()
    -- win._btn_back_to_projects:performAction("AXPress")
end
