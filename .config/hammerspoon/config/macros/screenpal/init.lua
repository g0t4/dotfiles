local vim = require("config.libs.vim") -- reuse nvim lua modules in hammerspoon
require("config.macros.screenpal.ui")
require('config.macros.screenpal.helpers')
require("config.macros.screenpal.co")
require("config.macros.screenpal.py.opencv")
local TimelineController = require('config.macros.screenpal.timeline')
local SilencesController = require('config.macros.screenpal.silences')

local _200ms = 200000
local _300ms = 300000
local _100ms = 100000
local _50ms = 50000
local _10ms = 10000

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

--- make sure controls are valid, if not re-aquire references
function ScreenPalEditorWindow:ensure_cached_controls()
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
    -- print_took("caching controls took: ", start)
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
        local playhead_percent = self:timeline_controller_ok_skip_pps():get_position_percent()

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
        self:timeline_controller_ok_skip_pps():move_playhead_to_position_percent(playhead_percent)

        if not current_zoomed then
            print("NOT zoomed before, skipping zoom restore")
            return
        end

        self:zoom2()
    end)
end

---@return TimelineController
function ScreenPalEditorWindow:timeline_controller()
    self:ensure_cached_controls() -- TODO review design of cache, confusing already
    return TimelineController:new(self)
end

---@return TimelineController
function ScreenPalEditorWindow:timeline_controller_ok_skip_pps()
    self:ensure_cached_controls() -- TODO review design of cache, confusing already
    return TimelineController:new(self, true)
end

function ScreenPalEditorWindow:get_time_string()
    self:ensure_cached_controls()
    return self:timeline_controller_ok_skip_pps().time_string
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

function ScreenPalEditorWindow:start_cut()
    -- PRN determine if in a diff edit and bail
    hs.eventtap.keyStroke({}, "c", 0, self.app)
    -- TODO find a way to detect when cut is open (tool popup?)

    -- PRN see below for notes about waiting until tool is open
    --  for now I am just going to use fixed wait time
    hs.timer.usleep(_50ms) -- FYI! 100ms is overkill in my initial testing

    -- ** closed (cut tool is not open) window, regular toolbar with "Tools" button is visible
    -- app:window(1)
    -- AXSections: [1: SectionObject: hs.axuielement: AXButton (0x60000020b438), SectionUniqueID: AXContent, SectionDescription: Content]

    -- start = get_time()
    -- -- FYI getting window anew (OR should I use cache?)
    -- -- 10 to 30ms to get window a new:
    -- -- local win = self.app:window('SOM-FloatingWindow-Type=edit2.addedit.toolbar.menu.window-ZOrder=1(Undefined+1)')
    -- print_took("get toolbar window", start)
    --
    -- FYI cached window object appears invalid (log shows invalid).. confirm that though
    -- print("windows: ", hs.inspect(self.windows.windows_by_title))
    -- local win_cached = self.windows.windows_by_title['SOM-FloatingWindow-Type=edit2.addedit.toolbar.menu.window-ZOrder=1(Undefined+1)']
    --
    -- -- if Tools button is gone, then assume cut is open
    -- -- app:window(2):button(1)
    -- -- AXDescription: Tools<string>
    --
    -- start_btn_tools = get_time()
    -- local btn = win:button(1) -- 22ms this way, plus 20ms for above... just use fixed wait?
    -- -- TODO is it faster to get to it via AXSections => SectionObject 1? (see win above AXSections when cut tool is closed)
    -- print_took("get tools btn", start_btn_tools)
    -- print('btnTools', hs.inspect(btn))

    -- ** once cut toolbar is open
    -- app:window(2)
    -- AXSections: [1: SectionObject: hs.axuielement: AXTextField (0x6000005a25f8), SectionUniqueID: AXContent, SectionDescription: Content]
    -- FYI first button has smth about help text
end

-- PRN events to detect playhead moving (and other UI changes) that might affect what to show for silences (or otherwise affect tooling automations)
-- require("config.macros.screenpal.observer")

---@alias Silence {x_start: number, x_end: number}
---@alias DetectionResults { short_silences: Silence[], regular_silences: Silence[], tool: { type: string, x_start: number, x_end: number}}
local silences_canvas = nil
---@param win ScreenPalEditorWindow
---@param silences SilencesController
function show_silences(win, silences)
    -- example silences (also for testing):
    -- regular_silences = { { x_end = 1132, x_start = 1034 }, { x_end = 1372, x_start = 1223 }, { x_end = 1687, x_start = 1562 } }

    local timeline = win:timeline_controller()
    local timeline_frame = timeline:get_timeline_frame()
    local canvas_frame = {
        x = timeline_frame.x,
        w = timeline_frame.w,

        -- 3x the height of the timeline (basically three lanes, one above, one over, one below)
        y = timeline_frame.y - timeline_frame.h,
        h = timeline_frame.h * 3
    }
    local canvas = hs.canvas.new(canvas_frame)
    assert(canvas)
    canvas:show()
    local elements = {}

    local above_timeline_y = 0
    local over_timeline_y = timeline_frame.h
    local below_timeline_y = timeline_frame.h * 2

    for _, silence in ipairs(silences.all) do
        local width = silence.x_end - silence.x_start -- PRN move to silence DTO as new behavior (how did I do that for axuielemMT
        -- print("start=" .. silence.x_start .. " end=" .. silence.x_end)
        if width > 0 then
            local fill_color = { red = 1, green = 0, blue = 0, alpha = 0.3 }
            local border_color = { red = 1, green = 0, blue = 0, alpha = 1 }
            local is_after_playhead = timeline._playhead_timeline_relative_x ~= nil
                and silence.x_start > timeline._playhead_timeline_relative_x
            if is_after_playhead then
                fill_color = { red = 1, green = 1, blue = 0, alpha = 0.3 }
                border_color = { red = 1, green = 1, blue = 0, alpha = 1 }
            end

            table.insert(elements, {
                type = "rectangle",
                action = "fill",
                fillColor = fill_color,
                frame = { x = silence.x_start, y = below_timeline_y, w = width, h = timeline_frame.h }
            })
            table.insert(elements, {
                type = "rectangle",
                action = "stroke",
                strokeColor = border_color,
                frame = { x = silence.x_start, y = below_timeline_y, w = width, h = timeline_frame.h }
            })
        end
    end

    local tool = silences.hack_detected.tool
    if tool and tool.type then
        local tool_width = tool.x_end - tool.x_start
        if tool_width > 0 then
            local tool_fill_color = { red = 0, green = 1, blue = 0, alpha = 0.3 }
            local tool_border_color = { red = 0, green = 1, blue = 0, alpha = 1 }
            -- PRN show color to match tool's color
            table.insert(elements, {
                type = "rectangle",
                action = "fill",
                fillColor = tool_fill_color,
                frame = { x = tool.x_start, y = above_timeline_y, w = tool_width, h = timeline_frame.h }
            })
            table.insert(elements, {
                type = "rectangle",
                action = "stroke",
                strokeColor = tool_border_color,
                frame = { x = tool.x_start, y = above_timeline_y, w = tool_width, h = timeline_frame.h }
            })
        end
    end


    canvas:appendElements(elements)
    silences_canvas = canvas
end

_G.MUTE = 'v'
_G.CUT = 'c'

---@param win ScreenPalEditorWindow
---@param silence? Silence
---@param action_keystroke string
--- PRN @param padding?
function act_on_silence(win, silence, action_keystroke)
    if not silence then
        -- might be easier to check here, in one spot, than in all the callers
        print("no silence to act on")
        return
    end

    -- set padding and what not AS YOU EDIT

    local timeline_relative_x = silence.x_start
    if action_keystroke == CUT then
        if silence.x_start ~= 0 then
            timeline_relative_x = timeline_relative_x + 20
        end
    end
    local timeline = win:timeline_controller_ok_skip_pps()
    timeline:move_playhead_to(timeline_relative_x)

    hs.eventtap.keyStroke({}, action_keystroke, 0, win.app)
    hs.timer.usleep(_100ms)

    hs.eventtap.keyStroke({}, "s", 0, win.app)
    hs.timer.usleep(_100ms)

    timeline_relative_x = silence.x_end -- - 10
    if action_keystroke == CUT then
        if silence.x_start ~= 0 then
            timeline_relative_x = timeline_relative_x - 20
        end
    end
    timeline:move_playhead_to(timeline_relative_x)
    hs.eventtap.keyStroke({}, "e", 0, win.app)
    -- PRN add pause? so far ok w/o it

    if action_keystroke == CUT and silence.x_start == 0 then
        -- * pull back 2 frames from end to avoid cutting into starting audio
        hs.eventtap.keyStroke({}, "left", 0, win.app)
        hs.timer.usleep(_10ms)
        -- FYI 2 frame reduction is b/c insert pause always blends away 1 frame in waveform (not sure effects audio, just to be safe do two)
        hs.eventtap.keyStroke({}, "left", 0, win.app)
        hs.timer.usleep(_200ms)
        hs.eventtap.keyStroke({}, "Return") -- or click OK?
        hs.timer.usleep(_300ms) -- bigger?

        -- * insert pause auto-approved
        hs.eventtap.keyStroke({}, "i", 0, win.app)
        hs.timer.usleep(_10ms)
        hs.eventtap.keyStroke({}, "p", 0, win.app)
        hs.timer.usleep(_200ms)
        hs.eventtap.keyStroke({}, "Return") -- or click OK?
        hs.timer.usleep(_300ms) -- only needed if chain smth else after, set to 300ms b/c it changes the timeline so leave a buffer until otherwise tested (or wait_until_element is setup)
    end

    -- TODO check if mute button is muted icon? or w/e else to determine if I should click mute the first time?
end

---@param callback fun(win: ScreenPalEditorWindow, silences SilencesController)
local function detect_silences(callback)
    run_async(function()
        local win = get_cached_editor_window()

        local timeline_element = win:get_timeline_slider_or_throw()
        local image_tag = "trash_me_silence_detect"
        local where_to = syncify(capture_this_element, timeline_element, image_tag)

        local detected = syncify(detect_silence, where_to)

        local timeline = win:timeline_controller_ok_skip_pps()
        local silences = SilencesController:new(detected, timeline)
        callback(win, silences)
    end)
end

---@param win ScreenPalEditorWindow
local function move_playhead_to_silence(win, silence)
    local timeline_relative_x = silence.x_start
    local timeline = win:timeline_controller_ok_skip_pps()
    timeline:move_playhead_to(timeline_relative_x)
end

function StreamDeck_ScreenPal_JumpThisSilence()
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_this_silence()
        move_playhead_to_silence(win, silence)
    end)
end

function StreamDeck_ScreenPal_JumpPrevSilence()
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_prev_silence()
        move_playhead_to_silence(win, silence)
    end)
end

function StreamDeck_ScreenPal_JumpNextSilence()
    -- TODO if last jump was to this silence, then make next pass it
    --    else can get stuck
    --
    --  can happen if playhead goes to frame before silence starts
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_next_silence()
        move_playhead_to_silence(win, silence)
        --
        --
        -- actually I think I am liking how it moves right to front most frame even if slightly before silence... it is catching clicks! leave this
        -- local current_playhead_x = timeline:get_current_playhead_timeline_relative_x()
        -- print("jumped playhead_x to " .. current_playhead_x
        --     .. " w.r.t. silence: " .. hs.inspect(silence))
        -- -- yup in one case playhead ends up just left of silence start (by 0.5), rounding might fix some of these too
        -- if current_playhead_x < silence.x_start then
        --     print("PLAYHEAD LANDED BEFORE SILENCE, COULD ARROW OVER TO FIX THIS")
        -- end
    end)
end

function StreamDeck_ScreenPal_PlayNextSilence()
    -- TODO PLAY THIS, NEXT, PREV silence helpers
    -- when done jump back to start of that position or silence?
end

function StreamDeck_ScreenPal_ActOnPrevSilence(action_keystroke)
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_prev_silence()
        act_on_silence(win, silence, action_keystroke)
    end)
end

function StreamDeck_ScreenPal_ActOnThisSilence_ThruStart(action_keystroke)
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_this_silence()
        local timeline = win:timeline_controller_ok_skip_pps()
        silence = {
            -- PRN make silence ctor? and use it with data returned from detection (hydrate into it)
            x_start = silence.x_start,
            x_end = timeline:get_current_playhead_timeline_relative_x(),
        }
        act_on_silence(win, silence, action_keystroke)
    end)
end

function StreamDeck_ScreenPal_ActOnThisSilence(action_keystroke)
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_this_silence()
        act_on_silence(win, silence, action_keystroke)
    end)
end

function StreamDeck_ScreenPal_ActOnThisSilence_ThruEnd(action_keystroke)
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_this_silence()
        local timeline = win:timeline_controller_ok_skip_pps()
        silence = {
            -- PRN make silence ctor? and use it with data returned from detection (hydrate into it)
            x_start = timeline:get_current_playhead_timeline_relative_x(),
            x_end = silence.x_end,
        }
        act_on_silence(win, silence, action_keystroke)
    end)
end

function StreamDeck_ScreenPal_ActOnNextSilence(action_keystroke)
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_next_silence()
        act_on_silence(win, silence, action_keystroke)
    end)
end

function StreamDeck_ScreenPal_AdjustSelectionEnd(num_frames)
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_next_silence()
        local tool = silences.hack_detected.tool
        if not tool or not tool.x_end then return end


        -- CANNOT CLICK left of end by one frame! it's min 2 frames, but I can reliably get one after (expand)...
        -- 6 == 2*3 (3 pixels in 1080p per frame at zoom2)
        local num_pixels = 6 * num_frames
        if num_frames < 0 then
            num_pixels = -12
        end
        print("adjusting by num_pixels: " .. tostring(num_pixels) .. " frames: " .. tostring(num_frames))



        next_frame_x_guess_zoom2 = tool.x_end + num_pixels

        local timeline = win:timeline_controller_ok_skip_pps()
        timeline:move_playhead_to(next_frame_x_guess_zoom2)
        hs.eventtap.keyStroke({}, "e", 0, win.app)
    end)
end

local function hide_silences()
    if silences_canvas == nil then return end

    silences_canvas:delete()
    silences_canvas = nil
end

---@return boolean
local function silences_are_visible()
    return silences_canvas ~= nil
end

function StreamDeck_ScreenPal_ShowSilenceRegions()
    run_async(function()
        if silences_are_visible() then
            hide_silences()
            return
        end

        local win, silences = syncify(detect_silences)
        show_silences(win, silences)
    end)
end

function StreamDeck_ScreenPal_Timeline_ZoomAndJumpToStart()
    -- FYI using run_async (coroutines under hood) to avoid blocking (i.e. during sleep calls)
    run_async(function()
        local win = get_cached_editor_window()
        -- TODO move zoom controls to timeline class?
        -- TODO then can add move_to_video_start() for this, to the timeline too
        win:zoom_off() -- zoom out so start is visible w/o scrolling
        sleep_ms(10)

        -- FYI jumping to start/end unzoomed doesn't need PPS:
        win:timeline_controller_ok_skip_pps():move_playhead_to_timeline_start()

        sleep_ms(10)
        win:zoom2()
    end)
end

function StreamDeck_ScreenPal_Timeline_ZoomAndJumpToEnd()
    run_async(function()
        local win = get_cached_editor_window()
        win:zoom_off()
        sleep_ms(10)

        win:timeline_controller_ok_skip_pps():move_playhead_to_timeline_end()

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
                    -- hs.timer.usleep(_10ms) -- don't need pause b/c hs seems to block while clicking
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

function StreamDeck_ScreenPal_ReopenProject()
    get_cached_editor_window():reopen_project()
end
