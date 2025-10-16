local AppWindows = require("config.macros.screenpal.app_windows")
require("config.macros.screenpal.co")
local TimelineController = require('config.macros.screenpal.timeline')

local _200ms = 200000

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

local _cached_editor_window = nil
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
    -- PRN rewrite to fully clear the entire cached object? not sure I need it as stuff is marked invalid even if left behind
    self._scrollbars = {} -- fixes finding scrollbar when refresh cache
    self._btn_back_to_projects = nil
    self._btn_maximum_zoom = nil
    self._btn_medium_zoom = nil
    self._btn_minimum_zoom = nil
    self._btn_position_slider = nil
    self._btn_toggle_magnify = nil
    self._btn_play_or_pause = nil
    self._btn_play_speed = nil
    self._textfield_title = nil

    local start = get_time()
    -- enumerating all children and getting role and description is no diff than just buttons with description only...
    vim.iter(self.win:children())
        :each(
        ---@param ui_elem hs.axuielement
            function(ui_elem)
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
                    elseif description == "Medium Zoom" then
                        self._btn_medium_zoom = ui_elem
                        return
                    elseif description == "Maximum Zoom" then
                        self._btn_maximum_zoom = ui_elem
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
                        -- even if these are not same butt, it's convenient to put them together into one, for now
                        -- FYI clicking play/pause will invalidate the current button, so it is possible they are changed
                        -- can see Play only when paused, can see Pause only when playing
                        -- also coudl check AXHelp:
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
    -- TODO! <10ms often (20ms was biggest in testing)... DO I WANT TO STOP CACHING or ADD MORE CHECKS TO DO SOONER?
    --   TODO! however checking a isValid() (copies the attribute) might be as expensive
    --     TODO! so maybe just let consumers cache this by holding an instance of it?
    print_took("building control CACHE took: ", start)
end

function ScreenPalEditorWindow:is_playing()
    -- FYI selectively refresh if the controls I need are invalid here
    --  BTW in my testing it was taking < 7ms to refresh all buttons (in loop above)
    --    so, should be fine to do this every time instead of selective
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
        -- "p" is for preview (so you can hear what it sounds like with the tool applied
        -- it is possible I'll want to hear again w/o the tool in which case for now I will have to trigger that myself
        hs.eventtap.keyStroke({}, "p")
    else
        -- FYI AXPress doesn't work on this button
        hs.eventtap.keyStroke({}, hs.keycodes.map["space"])
        -- FYI USE MOUSE if space is a problem, via hs.eventtap.leftClick
    end
end

function ScreenPalEditorWindow:is_zoomed()
    self:ensure_cached_controls()
    if not self._btn_minimum_zoom then
        error("No zoom button found, aborting...")
    end
    -- AXPosition == 0,0 ==> not zoomed
    local position = self._btn_minimum_zoom:axPosition()
    return position.x > 0 and position.y > 0
end

function ScreenPalEditorWindow:zoom_on()
    if self:is_zoomed() then
        return
    end

    -- FYI typing m is faster now... must be b/c of the native Apple Silicon app
    hs.eventtap.keyStroke({}, "m", 0, get_screenpal_app_element_or_throw())

    -- wait here so you don't want in consumers AND to NOT wait when already zoomed out
    -- hs.timer.waitUntil -- TODO try waitUntil!
    hs.timer.usleep(_200ms)
end

function ScreenPalEditorWindow:zoom_off()
    if not self:is_zoomed() then
        return
    end

    hs.eventtap.keyStroke({}, "m", 0, get_screenpal_app_element_or_throw())

    -- wait here so you don't want in consumers AND to NOT wait when already zoomed out
    hs.timer.usleep(_200ms)
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
    self:zoom_on()
    self._btn_minimum_zoom:performAction("AXPress")
end

function ScreenPalEditorWindow:zoom2()
    self:ensure_cached_controls()
    self:zoom_on()
    self._btn_medium_zoom:performAction("AXPress")
end

function ScreenPalEditorWindow:zoom3()
    self:ensure_cached_controls()
    self:zoom_on()
    self._btn_maximum_zoom:performAction("AXPress")
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

function ScreenPalEditorWindow:reopen_project()
    run_async(function()
        local win = get_cached_editor_window()
        local current_zoomed = win:is_zoomed()
        -- cannot find a way (yet) to determine zoom level
        --   one idea, could store maxvalue of position_slider
        --   and compare to each zoom level (try 2 first, then 1/3) on restore
        --   until find match for maxvalue and then you know you found the level!
        self:zoom_off()


        -- * capture position
        -- use percent, that way if the width changes, it's still the same timecode
        local playhead_percent = self:timeline_controller():get_position_percent()

        if not self._textfield_title then
            error("No title found, aborting...")
        end
        local title = self._textfield_title:axValue()
        -- print("title: ", title)
        if not self._btn_back_to_projects then
            error("No back to projects button found, aborting...")
        end
        self._btn_back_to_projects:performAction("AXPress")

        local btn_reopen_project = wait_for_element(function()
            self:cache_project_view_controls()
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

        -- * restore position
        self:zoom_off()
        self:timeline_controller():move_playhead_to_position_percent(playhead_percent)

        if not current_zoomed then
            print("NOT zoomed before, skipping zoom restore")
            return
        end

        self:zoom2()

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

---@return integer? level -- 1,2,3 or nil if not found
function ScreenPalEditorWindow:detect_bar_level()
    local Timer = require("config.macros.screenpal.experiments.timer")
    local timer = Timer.new()

    if not self:is_zoomed() then
        print("zoom not active - cannot detect zoom level")
        return nil
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
        timer:capture("color check for bar level: " .. bar.level)

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
