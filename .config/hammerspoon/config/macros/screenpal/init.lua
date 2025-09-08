local vim = require("config.libs.vim") -- reuse nvim lua modules in hammerspoon
require("config.macros.screenpal.ui")
require('config.macros.screenpal.helpers')
require("config.macros.screenpal.co")
require("config.macros.screenpal.py.boxes")
local TimelineDetails = require('config.macros.screenpal.timeline')

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

        -- AFAICT nothing differs on zoom level buttons...
        -- - thus cannot know which is clicked (zoomed)
        -- - NBD I mostly use 2 and can re-zoom myself (and I'll be using not zoomed to restore playhead position)
        self:zoom_off()

        local details = self:_timeline_details()

        -- TODO move percent calculation to _timeline_details
        local playhead_percent = (details.playhead_x - details.timeline_frame.x) / details.timeline_frame.w
        print("playhead_percent", playhead_percent)
        return playhead_percent
    end

    ---@param playhead_percent number
    function editor_window:restore_playhead_position(playhead_percent)
        ensure_cached_controls()

        self:zoom_off() -- do not restore when zoomed

        local details = self:_timeline_details()

        -- TODO _timeline_details():move_playhead_to_percent(percent)
        local time_window_x_center = details.timeline_frame.x + playhead_percent * details.timeline_frame.w

        local hold_down_before_release = 10000 -- default is 200ms, will matter if chaining more actions!
        hs.eventtap.leftClick({
            -- +1 pixel stops leftward drift by 1 frame (good test is back to back reopen, albeit not a normal workflow)
            x = time_window_x_center + 1,
            y = details.timeline_frame.y + details.timeline_frame.h / 2
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
        if self:is_zoomed() then
            return
        end

        -- FYI typing m is faster now... must be b/c of the native Apple Silicon app
        hs.eventtap.keyStroke({}, "m", 0, get_screenpal_app_element_or_throw())

        -- wait here so you don't want in consumers AND to NOT wait when already zoomed out
        -- hs.timer.waitUntil -- TODO try waitUntil!
        hs.timer.usleep(200000)
    end

    function editor_window:zoom_off()
        if not self:is_zoomed() then
            return
        end

        hs.eventtap.keyStroke({}, "m", 0, get_screenpal_app_element_or_throw())

        -- wait here so you don't want in consumers AND to NOT wait when already zoomed out
        hs.timer.usleep(200000)
        -- TODO I do not think waitUntil is blocking either so it would let consumer code keep running, right?
        -- PRN loop on usleep and poll something useful to tell you when you can be ready to click in the UI
        -- -- FYI waitUntil is always already 0,0 on first run, so I would need a diff test  to use this
        -- print("waitUNTIL")
        -- hs.timer.waitUntil(function()
        --     print("tick")
        --     if self._btn_minimum_zoom then
        --         local frame = self._btn_minimum_zoom:axFrame()
        --         print("  frame", hs.inspect(frame))
        --         return frame.x == 0 and frame.y == 0
        --     end
        --     return false
        -- end, function()
        --     print("DONE")
        -- end, 0.05)
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
        run_async(function()
            local win = get_cached_editor_window()
            local current_zoomed = win:is_zoomed()
            -- cannot find a way (yet) to determine zoom level
            --   one idea, could store maxvalue of position_slider
            --   and compare to each zoom level (try 2 first, then 1/3) on restore
            --   until find match for maxvalue and then you know you found the level!
            self:zoom_off()


            -- use percent, that way if the width changes, it's still the same timecode
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

            local btn_reopen_project = wait_for_element(function()
                cache_project_view_controls()
                if not self._scrollarea_list then return end
                return vim.iter(self._scrollarea_list:buttons())
                    :filter(function(button)
                        -- look for the project open button to re-open, wait until find this
                        local desc = button:axDescription()
                        return desc == title
                    end)
                    :totable()[1]
            end, 100, 20)

            if not btn_reopen_project then
                error("cannot find project to re-open, aborting...")
            end

            btn_reopen_project:performAction("AXPress")
            sleep_ms(100) -- PRN if possible, and useful, replace w/ wait_for_element, which one to look for?

            self:restore_playhead_position(playhead_percent)

            if not current_zoomed then
                print("NOT zoomed before, skipping zoom restore")
                return
            end

            self:zoom2()
        end)
    end

    ---@return TimelineDetails
    function editor_window:_timeline_details()
        -- PRN move ensure_cached_controls() here?
        return TimelineDetails:new(self)
    end

    function editor_window:get_time_string()
        ensure_cached_controls()
        local details = self:_timeline_details()
        return details.time_string
    end

    function editor_window:figure_out_zoom2_fixed_pixels_per_second()
        ensure_cached_controls()

        -- FYI! KEEP IN MIND, zoom levels are FIXED # seconds/frames regardless of video length... so when zoom 2 you know exactly where to click to move over 1 second relative to current position... or to move to X seconds along from start/end of the visible timeline
        --  eyeballing => roughly 43 pixels per second on zoom 2 => ~23 seconds visible in timeline... and not quite full width of screen (est 1000 px) => 1000/23 ~+ 43 pixels per second?

        -- TODO break apart functions out of the other get time function below
        --   i.e. get_playhead_time

        local details = self:_timeline_details()
        details:move_playhead_to_seconds(2)

        -- *** PIXELS PER SECOND for each ZOOM level (fixed for each level)
        print(details.pixels_per_second)
        -- FYI make sure time left side of timeline is still at 0 else will be off
        --   jump to a specific timecode and measure the time from there
        --   should be more reliable than clicking any spot and doing it from there which maybe cursor is in the middle between actual frames and so its slightly off b/c it says time as of a few pixels left/right
        --   repeatedly push the jump to 3 (or w/e value) an
        --
        --   change width of screen (timeline) and confirm PPS remains the same
        --   MAKE SURE 0 is on left, sometimes it shifts slightly off screen, that will cause issues in the PPS
        --   SLIGHT discrepency when clicking on a spot is fractions of a pixel in the calc... IOTW I don't have ultra precise fractions but 25/75/150 are correct parts
        -- zoom1 => 25.164473684211 PPS
        -- zoom2 => 75.166666666667 PPS
        -- zoom3 => 150.16666666667 PPS
    end

    function editor_window:toggle_AXEnhancedUserInterface()
        ensure_cached_controls()
        local primary_window = self.win

        -- FYI alternative to using Voice Over, theoretically, to trigger showing more controls (if the app supports it)
        -- FYI first pass I am not seeing any new direct descendents of edtior_window (64 before and after)...

        -- PRN, click / focus any controls?
        -- TODO try:
        --  print(hs.axuielement.parameterizedAttributeNames(el)) -- might have hidden values  when not enhanced moe
        --  press items (AXPress)
        --  focus (right arrow?)

        --  do I need to set AXEnhancedUserInterface on other (child) objects or just the app?
        -- self.app:dumpAttributes()
        print("before - app.AXEnhancedUserInterface:", self.app.AXEnhancedUserInterface)
        self.app.AXEnhancedUserInterface = not self.app.AXEnhancedUserInterface
        print("after - app.AXEnhancedUserInterface:", self.app.AXEnhancedUserInterface)

        do return end

        local children = primary_window:children()
        -- ?? try allDescendantElements + callback to avoid navigating manualy

        -- local app = hs.appfinder.appFromName("YourJavaApp")
        -- local ax = hs.axuielement.applicationElement(app)
        -- if ax:isAttributeSettable("AXEnhancedUserInterface") then
        --   ax:setAttributeValue("AXEnhancedUserInterface", true)
        -- end
        --

        for i, child in ipairs(children) do
            print(hs.inspect(child))
        end
    end

    function editor_window:test_select_range()
        ensure_cached_controls()

        self:zoom_on() -- assume is m2-02 for now

        local details = self:_timeline_details()
        local timeline_frame = details.timeline_frame

        function click_at(reading)
            local rel_click_x = reading / 2 -- divide by 2 for 4k resolution of screencaps, b/c screen cords are 1080p... THIS WORKS! SPOT ON
            local click_x = timeline_frame.x + rel_click_x

            local hold_duration_ms = 10000
            hs.eventtap.leftClick({
                -- +1 pixel stops leftward drift by 1 frame (good test is back to back reopen, albeit not a normal workflow)
                x = click_x + 1, -- for 1 sec its slightly off (NBD => could arrow over if consistently off))
                -- +1 => 1.04 sec (1 frame past), +0 => 0.92 sec (2 frames before)
                -- FYI I DO NOT NEED PRECISE! silence ranges for example will be paddeed anyways! can always padd an extra frame!
                -- FYI for round numbers, i.e. 2 seconds, I can read playhead after move and if within a second I can use Shift+Arrow to jump w/e distance
                y = timeline_frame.y + timeline_frame.h / 2
            }, hold_duration_ms)
        end

        -- READINGS from 4k screencap coordinates of first major silence period
        click_at(692 + 20)
        hs.eventtap.keyStroke({}, "c", 0, get_screenpal_app_element_or_throw()) -- alone selects the cut region! I can then pull back each side
        -- FYI I could also have it scan for the red selection and use that to pull back the current selection (pad it or expand it)
        hs.timer.usleep(100000)
        hs.eventtap.keyStroke({}, "s", 0, get_screenpal_app_element_or_throw()) -- OPTIONAL TO FORCE START AT clicked point for auto selected cuts
        hs.timer.usleep(100000)
        click_at(845 - 20)
        hs.timer.usleep(100000)
        hs.eventtap.keyStroke({}, "e", 0, get_screenpal_app_element_or_throw())
    end

    function editor_window:estimate_time_per_pixel()
        ensure_cached_controls() -- prn do I need this early on here?

        print("min zoom frame", hs.inspect(self._btn_minimum_zoom:axFrame())) -- (x,y) == (0,0) == not zoomed
        -- must be zoomed out, else cannot know that start of time line is 0 and end is the end of the video
        self:zoom_off()
        print("min zoom frame", hs.inspect(self._btn_minimum_zoom:axFrame()))

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

function StreamDeck_ScreenPal_GetSilenceRegions()
    local sample_image = os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/.config/hammerspoon/config/macros/screenpal/py/timeline03a.png"
    detect_silence_boxes(sample_image, function(result)
        print("silence regions: " .. hs.inspect(result))
    end)
end

function StreamDeckScreenPalTimelineZoomAndJumpToStart()
    -- FYI using run_async (coroutines under hood) to avoid blocking (i.e. during sleep calls)
    run_async(function()
        local win = get_cached_editor_window()
        win:zoom_off() -- zoom out first means just click end and zoom in... no slider necessary!
        sleep_ms(10)

        -- StreamDeckScreenPalTimelineScrollOrJumpToStart()
        local slider = win:get_timeline_slider_or_throw()
        local sframe = slider:axFrame()
        -- move playhead to end by clicking the left‑most part of the timeline slider
        hs.eventtap.leftClick({ x = sframe.x, y = sframe.y })

        sleep_ms(10)
        win:zoom2()
    end)
end

function StreamDeckScreenPalTimelineZoomAndJumpToEnd()
    run_async(function()
        local win = get_cached_editor_window()
        win:zoom_off()
        sleep_ms(10)

        -- StreamDeckScreenPalTimelineScrollOrJumpToEnd()
        local slider = win:get_timeline_slider_or_throw()
        local sframe = slider:axFrame()
        -- move playhead to end by clicking the right‑most part of the timeline slider
        hs.eventtap.leftClick({ x = sframe.x + sframe.w - 1, y = sframe.y })

        sleep_ms(10)
        win:zoom2()
    end)
end

function StreamDeck_ScreenPal_CopyPlayheadTimeText()
    local win = get_cached_editor_window()
    local time_string = win:get_time_string()
    hs.pasteboard.setContents(time_string)
end

function RETIRED_StreamDeckScreenPalTimelineScrollOrJumpToStart()
    -- local original_mouse_pos = hs.mouse.absolutePosition()
    local win = get_cached_editor_window()

    if win:is_zoomed() then
        -- if zoomed, and wanna keep zoom then can use scroll, but really no reason to do that anymore
        function scroll_to_end(win)
            local timeline_scrollbar = win:get_scrollbar_or_throw()
            local frame = timeline_scrollbar:axFrame()
            local min_value = timeline_scrollbar:axMinValue()

            local function click_until_timeline_at_start()
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
                    -- hs.timer.usleep(10000) -- don't need pause b/c hs seems to block while clicking
                end
            end

            click_until_timeline_at_start()
        end

        scroll_to_end(win)
    end

    -- * move playhead to start (0) by clicking leftmost part of position slider (aka timeline)
    --   keep in mind, scrollbar below is like a pager, so it has to be all the way left, first
    --   PRN add delay if this is not registering, but use it first to figure that out
    local slider = win:get_timeline_slider_or_throw()
    hs.eventtap.leftClick({ x = slider:axFrame().x, y = slider:axFrame().y })

    -- hs.mouse.absolutePosition(original_mouse_pos) -- umm I feel like I want to NOT restore so I can move mouse easily at start!
end

function RETIRED_StreamDeckScreenPalTimelineScrollOrJumpToEnd()
    -- local original_mouse_pos = hs.mouse.absolutePosition()
    local win = get_cached_editor_window()

    if win:is_zoomed() then
        -- if zoomed, and wanna keep zoom then can use scroll, but really no reason to do that anymore
        function scroll_to_end(win)
            local timeline_scrollbar = win:get_scrollbar_or_throw()
            local frame = timeline_scrollbar:axFrame()
            local max_value = timeline_scrollbar:axMaxValue()

            local function click_until_timeline_at_end()
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

            click_until_timeline_at_end()
        end

        scroll_to_end(win)
    end

    -- move playhead to end by clicking the right‑most part of the timeline slider
    local slider = win:get_timeline_slider_or_throw()
    local sframe = slider:axFrame()
    hs.eventtap.leftClick({ x = sframe.x + sframe.w - 1, y = sframe.y })

    -- hs.mouse.absolutePosition(original_mouse_pos) -- try not restoring, might be better!
end

function RETIRED_StreamDeckScreenPalTimelineApproxRestorePosition(restore_position_value)
    -- TODO do I even need this anymore?
    --   I am zooming out to get overall playhead position now in full clip
    --   and restoring that on reopen, so I don't think I need (nor want) to use zoomed in scrolling to restore

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
