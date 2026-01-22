local AppWindows = require("config.macros.screenpal.app_windows")
require("config.macros.screenpal.co")
local TimelineController = require('config.macros.screenpal.timeline')
require("config.macros.streamdeck.helpers")
require("config.macros.streamdeck.commands")
local inspect = require("hs.inspect")


local _200ms = 200000
local _100ms = 100000

---@return hs.axuielement app_element
local function get_screenpal_app_element_or_throw()
    return get_app_element_or_throw("com.screenpal.app") -- < 1 ms
end

---@class ScreenPalEditorWindow
---@field windows AppWindows
local ScreenPalEditorWindow = {}

function ScreenPalEditorWindow:new()
    ---@type ScreenPalEditorWindow
    local editor_window = {}
    setmetatable(editor_window, self)
    self.__index = self
    self:_force_refresh_windows()
    return editor_window
end

---@type hs.axuielement?
local _cached_editor_window = nil
function clear_cached_editor_window()
    _cached_editor_window = nil
end

function get_cached_editor_window()
    if not _cached_editor_window then
        _cached_editor_window = ScreenPalEditorWindow:new()
    end
    -- TODO add this here? might reduce need elsewhere?
    --   _cached_editor_window:ensure_cached_controls() -- TODO do this here?
    return _cached_editor_window
end

function ScreenPalEditorWindow:_force_refresh_windows()
    self.app = get_screenpal_app_element_or_throw()
    self.windows = AppWindows.new(self.app)
    self.win = self.windows:editor_window_or_throw()
end

--- make sure controls are valid, if not re-acquire references
function ScreenPalEditorWindow:ensure_cached_controls(force)
    -- print("window valid? A ", self.win:isValid()) -- NOTE this is not valid (nil) when need reload everything so do that instead
    if not self.win:isValid() then
        -- print("*** REFRESH WINDOWS *** - self.win is NOT VALID")
        self:_force_refresh_windows()
    end
    -- print("window valid? B ", self.win:isValid()) -- NOTE this is not valid (nil) when need reload everything so do that instead
    if not force and self._cached_buttons then
        if self._btn_minimum_zoom:isValid() then
            return
        end
        -- print("editor window cache invalidated")
    end
    -- print("building editor window")
    self:force_refresh_cached_controls()
end

function ScreenPalEditorWindow:force_refresh_cached_controls()
    self._scrollbars = {}
    self._btn_back_to_projects = nil
    self._btn_maximum_zoom = nil
    self._btn_medium_zoom = nil
    self._btn_minimum_zoom = nil
    self._btn_frame_zoom_preview = nil
    self._btn_position_slider = nil
    self._btn_toggle_magnify = nil
    self._btn_play_or_pause = nil
    self._btn_play_speed = nil
    self._textfield_title = nil

    local start = get_time()
    vim.iter(self.win:children())
        :each(
        ---@param ui_elem hs.axuielement
            function(ui_elem)
                local description = ui_elem:axDescription()
                local role = ui_elem:axRole()
                if role == "AXButton" then
                    if description == "Minimum Zoom" then
                        -- AXIndex: 3, #42 in array in my testing (could change)
                        self._btn_minimum_zoom = ui_elem
                        return -- continue early so I can add more complex checks below and avoid them when possible
                    elseif description == "Medium Zoom" then
                        self._btn_medium_zoom = ui_elem
                        return
                    elseif description == "Maximum Zoom" then
                        self._btn_maximum_zoom = ui_elem
                        return
                    elseif description == "Zoom Preview" then
                        self._btn_frame_zoom_preview = ui_elem
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
                    elseif description == "Play" or description == "Pause" then
                        -- can see Play only when paused, can see Pause only when playing
                        -- AXHelp: Play this animation<string>
                        -- AXHelp: Pause this animation<string>
                        self._btn_play_or_pause = ui_elem
                        return
                    elseif description == "Edit Playback Speed" then
                        -- only visible when playing
                        -- play/pause toggle will invalidate this too
                        self._btn_play_speed = ui_elem
                        -- AXDescription: Edit Playback Speed<string>
                        -- AXHelp: Use this slider to increase or decrease the rate of playback<string>
                        return
                    else
                        -- print(description)
                    end
                elseif role == "AXTextField" then
                    -- accessibility description => AXDescription in hs apis... is empty only for the title name field (upper left)
                    -- ALSO most of the time it will have an mX in it :)
                    if description == "" then
                        -- so far, the text input for the title on the edit video page is the only text field with no description!
                        --    by the way this maps to accessibility description IIUC in script debugger
                        self._textfield_title = ui_elem
                    end
                    -- AXRoleDescription: text field<string>
                    -- AXSelectedText: m1-02 Use Curly Braces to Deliniate the Parameter Name<string>
                    -- AXValue: m1-02 Use Curly Braces to Deliniate the Parameter Name<string>
                elseif role == "AXScrollBar" then
                    -- BTW matching on position
                    self._scrollbars = self._scrollbars or {}
                    table.insert(self._scrollbars, ui_elem)
                    return
                end
            end)
    self._cached_buttons = true
    -- print_took("building control CACHE took: ", start)
end

function ScreenPalEditorWindow:is_playing()
    if self._btn_play_or_pause == nil or not self._btn_play_or_pause:isValid() then
        self:force_refresh_cached_controls()
    end
    return self._btn_play_or_pause and self._btn_play_or_pause:axDescription() == "Pause"
end

function ScreenPalEditorWindow:is_paused()
    return not self:is_playing()
end

function ScreenPalEditorWindow:ensure_playing(is_tool_open)
    if self:is_playing() then
        return
    end
    if is_tool_open then
        -- "p" is for preview
        hs.eventtap.keyStroke({}, "p")
    else
        -- FYI AXPress doesn't work on this button
        hs.eventtap.keyStroke({}, hs.keycodes.map["space"])
        -- USE MOUSE if space is a problem, via hs.eventtap.leftClick
    end
end

---@return boolean|nil - nil means failure
function ScreenPalEditorWindow:is_zoomed()
    self:ensure_cached_controls()
    if not self._btn_minimum_zoom then
        error("No zoom button found, aborting...")
        return nil
    end
    -- AXPosition == 0,0 ==> not zoomed
    local position = self._btn_minimum_zoom:axPosition()
    return position.x > 0 and position.y > 0
end

function ScreenPalEditorWindow:zoom_on()
    if self:is_zoomed() then
        return
    end

    hs.eventtap.keyStroke({}, "m", 0, get_screenpal_app_element_or_throw())
    -- FYI only add delay if you have a scenario that's broken, don't prematurely add this
    -- TODO try waitUntil (see zoom_off example)
    -- hs.timer.usleep(_100ms)
end

function ScreenPalEditorWindow:zoom_off()
    if not self:is_zoomed() then
        return
    end

    -- local win = get_cached_editor_window()
    -- print("before min", hs.inspect(win._btn_minimum_zoom:axFrame()))
    -- print("med", hs.inspect(win._btn_minimum_zoom:axFrame()))
    -- print("max", hs.inspect(win._btn_minimum_zoom:axFrame()))

    hs.eventtap.keyStroke({}, "m", 0, get_screenpal_app_element_or_throw())
    -- FYI only add delay if you have a scenario that's broken, don't prematurely add this

    -- FYI whenever I check here, it's always 0,0 already... might be b/c zoom is fast... TODO need to find a way to verify if this is a legit test (for when zooming out/in is actually done)
    -- local win = get_cached_editor_window()
    -- print("min", hs.inspect(win._btn_minimum_zoom:axFrame()))
    -- print("med", hs.inspect(win._btn_minimum_zoom:axFrame()))
    -- print("max", hs.inspect(win._btn_minimum_zoom:axFrame()))
    --
    --
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
    -- end,
    --  -- ? would need an overall timeout (max checks or max time) so this doesn't run forever, indefinitely
    -- 0.05)
end

function ScreenPalEditorWindow:get_scrollbar_or_throw()
    -- PRN search for big AXMaxValues? that might uniquely identify it if I have issues in the future with other scrollbars visible
    -- OR by position on screen (toward bottom of window is telling)
    self:ensure_cached_controls()
    local scrollbar = self._scrollbars[4]
    if not scrollbar then
        error("No editor_window scrollbar found, aborting...")
    end
    return scrollbar
end

---@return hs.axuielement
function ScreenPalEditorWindow:get_timeline_slider_or_throw()
    self:ensure_cached_controls()
    if not self._btn_position_slider then
        error("No timeline slider found, aborting...")
    end
    return self._btn_position_slider
end

function ScreenPalEditorWindow:zoom1()
    self:ensure_cached_controls()
    if self:detect_zoom_level() == 1 then
        return
    end
    self:zoom_on()
    self._btn_minimum_zoom:performAction("AXPress")
end

function ScreenPalEditorWindow:zoom2()
    self:ensure_cached_controls()
    if self:detect_zoom_level() == 2 then
        return
    end
    self:zoom_on()
    self._btn_medium_zoom:performAction("AXPress")
end

function ScreenPalEditorWindow:zoom3()
    self:ensure_cached_controls()
    if self:detect_zoom_level() == 3 then
        return
    end
    self:zoom_on()
    self._btn_maximum_zoom:performAction("AXPress")
end

function ScreenPalEditorWindow:toggle_frame_zoom()
    self:ensure_cached_controls()
    self._btn_frame_zoom_preview:performAction("AXPress")
end

function ScreenPalEditorWindow:cache_project_view_controls()
    vim.iter(self.win:children())
        :each(function(ui_elem)
            -- one time hit, just cache all buttons when I have to find one of them
            -- not extra expensive to cache each one relative to time to enumerate / get description (has to be done to find even one button)
            local description = ui_elem:axDescription()
            local role = ui_elem:axRole()
            if role == "AXScrollArea" then
                self._scrollarea_list = ui_elem -- s/b only scroll area in the scorll area
                -- print("sa", hs.inspect(self._scrollarea_list))
                -- print("sa.sa", hs.inspect(self._scrollarea_list:scrollAreas()[1]))
                self._scrollarea_list = self._scrollarea_list:scrollAreas()[1]
            end
        end)
end

---@param restart? boolean -- instead of just close project, restart ScreenPal, then resume where you left off!
function ScreenPalEditorWindow:reopen_project(restart)
    restart = restart or false

    run_async(function()
        local win = get_cached_editor_window()
        local original_zoom_level = self:timeline_controller():zoom_level()

        self:zoom_off()

        -- * capture position
        -- use percent, that way if the width changes, it's still the same timecode
        local playhead_percent = self:timeline_controller():get_position_percent()
        -- DO NOT reuse timeline controller after changes like zoom, IIRC need latest state always
        --   TODO maybe rename timeline controller to hint at the lifespan/applicability of it?

        if not self._textfield_title then
            error("No title found, aborting...")
        end
        local title = self._textfield_title:axValue()
        -- print("title: ", title)

        if restart then
            -- most issues are fixed w/ project close/reopen
            -- but, repeated playhead seizures are a sign of app open too long...
            -- bugs seem to trigger faster the longer I've had ScreePal open, so restart it _too_
            runKMMacro("20E96F61-EC87-4BE3-9422-F9B41C7502DC") -- restart macro (handles several niceties)
            -- FYI delays in the KM macro factor in, like old code that killed tray icon that I don't need, it had 5 second wait! I disabled that!
            --  PRN make macro specific to this HS action if need be... restart and repoen s/b fast and then I can use it way more often to wipe memory leaks, bugs, etc!
            -- sleep_ms(5000) -- not needed so far
        else
            if not self._btn_back_to_projects then
                error("No back to projects button found, aborting...")
            end
            self._btn_back_to_projects:performAction("AXPress")
        end

        local btn_reopen_project = wait_for_element(function()
            print("attempting to re-acquire the editor window...")
            clear_cached_editor_window() -- must clear b/c old instance won't work, that _cached_ window is gone!
            local win = get_cached_editor_window()
            self:cache_project_view_controls()
            if not self._scrollarea_list then return end
            return vim.iter(self._scrollarea_list:buttons())
                :filter(function(button)
                    -- look for the project open button to re-open, wait until find this
                    local desc = button:axDescription()
                    return desc == title
                end)
                :totable()[1]
        end, 100, 200) -- 200 cycles × 100 ms/cycle = 20 000 ms → 20 seconds (for restart to complete and find and reopen project)

        if not btn_reopen_project then
            error("cannot find project to re-open, aborting...")
        end

        btn_reopen_project:performAction("AXPress")
        sleep_ms(100) -- PRN if possible, and useful, replace w/ wait_for_element, which one to look for?

        -- * restore position
        self:zoom_off()
        self:timeline_controller():move_playhead_to_position_percent(playhead_percent)

        -- * restore zoom level
        self:set_zoom_level(original_zoom_level)

        -- after reopen previous cached window is always invalid, no noticeable hit to refresh for that here!
        self:force_refresh_cached_controls()
    end)
end

---@return TimelineController
function ScreenPalEditorWindow:timeline_controller()
    self:ensure_cached_controls()
    return TimelineController:new(self)
end

---@return number, string -- seconds and text values
function ScreenPalEditorWindow:get_current_time()
    self:ensure_cached_controls()
    local t = self:timeline_controller()
    -- PRN combine two times into one object?
    return t.time_seconds, t.time_string
end

---@param before_seconds number
function ScreenPalEditorWindow:wait_until_time_changes(before_seconds)
    wait_until(function()
        -- PRN could check for specific amount of time change
        local now_seconds = self:get_current_time()
        return before_seconds ~= now_seconds
    end)
end

function ScreenPalEditorWindow:toggle_AXEnhancedUserInterface()
    self:ensure_cached_controls()
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

---@param level integer|nil -- 0, 1, 2, 3 -- nil|0 means disable zoom
function ScreenPalEditorWindow:set_zoom_level(level)
    if level == nil or level == 0 then
        self:zoom_off()
    elseif level == 1 then
        self:zoom1()
    elseif level == 2 then
        self:zoom2()
    elseif level == 3 then
        self:zoom3()
    else
        print("Invalid zoom level " .. tostring(level))
    end
end

function ScreenPalEditorWindow:zoom_in()
    local current_level = self:detect_zoom_level() or 0
    if current_level >= 3 then
        return
    end
    self:set_zoom_level(current_level + 1)
end

function ScreenPalEditorWindow:zoom_out()
    local current_level = self:detect_zoom_level() or 0
    if current_level <= 0 then
        return
    end
    self:set_zoom_level(current_level - 1)
end

---@return integer? level -- 0(not zoomed),1,2,3 or nil(failure)
function ScreenPalEditorWindow:detect_zoom_level()
    local Timer = require("config.macros.screenpal.experiments.timer")
    local timer = Timer.new()

    if not self:is_zoomed() then
        return 0 -- 0 means NOT zoomed!
    end
    timer:capture("is_zoomed")

    -- FYI coordinates will be (x,y)=(0,0) if not zoomed (only way to tell from these controls alone)
    local min_frame = self._btn_minimum_zoom:axFrame()
    local max_frame = self._btn_maximum_zoom:axFrame()

    --
    -- FYI: sizes (regardless which is selected, I tested all zoom levels to be sure)
    -- 1080p:
    -- min:{ h = 16.0, w = 12.0, x = 1853.0, y = 1033.0 }
    -- medium:{ h = 16.0, w = 12.0, x = 1865.0, y = 1033.0 }
    -- max:{ h = 16.0, w = 13.0, x = 1877.0, y = 1033.0 }

    local frame = {
        x = min_frame.x,
        w = max_frame.w + (max_frame.x - min_frame.x),
        y = min_frame.y, -- all have same Y
        h = min_frame.h -- go with the smaller two, don't need extra two pixels from max height
    }
    timer:capture("get frame")

    local screen = hs.screen.mainScreen()
    timer:capture("get screen")

    -- PRN add unit tests that use pre-captured sample images .../py/samples/zoom/zoom{1,2,3,-none}.png
    --   this would be the seam to split, and then call and pass in images
    --   would need hammerspoon APIs to get hs.image APIs

    ---@type hs.image?
    local image = screen:snapshot(frame) -- 30ms typical for snapshot
    timer:capture("snapshot")
    -- image:saveToFile("snapshot.png") -- CWD == ~/.hammerspoon usually
    if image == nil then
        print("image snapshot failed for finding zoom level")
        return nil
    end
    -- use image size so retina vs non doesn't matter
    ---@type NSSize?
    local img_size = image:size()
    -- print("image size: " .. hs.inspect(img_size))
    timer:capture("get image size")

    local bar_regions = {
        -- bars are verticall split into three sections, take middle of each bar (1/6 == middle)
        { x = img_size.w * 0.17, level = 1 }, -- 0/3+1/6
        { x = img_size.w * 0.50, level = 2 }, -- 1/3+1/6
        { x = img_size.w * 0.83, level = 3 }, -- 2/3+1/6
    }

    local y_sample = math.floor(img_size.h * 0.95)
    for _, bar in ipairs(bar_regions) do
        timer:capture("color check for bar level: " .. tostring(bar.level))

        local x_sample = math.floor(bar.x)
        ---@type NSColor?
        local color = image:colorAt({ x = x_sample, y = y_sample })
        -- print("  color", hs.inspect(color))

        if color then
            local red, green, blue = color.red * 255, color.green * 255, color.blue * 255
            local tolerance = 2
            -- array([225., 191., 180.]) # BGR (gray) inactive zoom bar
            -- array([255., 157.,  37.]) # BGR (light blue) current zoom bar
            if math.abs(blue - 255) <= tolerance and
                math.abs(green - 157) <= tolerance and
                math.abs(red - 37) <= tolerance then
                -- active bar
                -- timer:print_timing()
                return bar.level
            end
        end
    end
    timer:print_timing()
    return nil
end

return ScreenPalEditorWindow
