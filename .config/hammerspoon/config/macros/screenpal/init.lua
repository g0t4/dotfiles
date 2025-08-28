local mouse = require("hs.mouse")
local eventtap = require("hs.eventtap")
local timer = require("hs.timer")
local vim = require("config.libs.vim") -- reuse nvim lua modules in hammerspoon

local function getScreenPalAppElementOrThrow()
    return getAppElementOrThrow("com.screenpal.app") -- < 1 ms
end

local function getEditorWindowOrThrow()
    local app = getScreenPalAppElementOrThrow()
    -- print("windows", hs.inspect(app:windows()))
    for _, win in ipairs(app:windows()) do
        if win:axTitle():match("^ScreenPal -") then
            return win
        end
    end
    error("No ScreenPal editor window found, aborting...")
end

ScreenPalEditorWindow = {}
function ScreenPalEditorWindow:new()
    local editor_window = {}
    setmetatable(editor_window, self)
    self.__index = self
    self.win = getEditorWindowOrThrow()

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

        local start = GetTime()
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
                        print(description)
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
        PrintTook("caching controls took: ", start)
    end

    function editor_window:isZoomed()
        ensure_cached_controls()
        if not self._btn_minimum_zoom then
            error("No zoom button found, aborting...")
        end
        -- AXPosition == 0,0 ==> not zoomed
        local position = self._btn_minimum_zoom:axPosition()
        return position.x > 0 and position.y > 0
    end

    function editor_window:zoom_in()
        if self:isZoomed() then return end
        -- FYI typing m is faster now... must be b/c of the native Apple Silicon app
        eventtap.keyStroke({}, "m", 0, getScreenPalAppElementOrThrow())
    end

    function editor_window:zoom_out()
        if not self:isZoomed() then return end
        eventtap.keyStroke({}, "m", 0, getScreenPalAppElementOrThrow())
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
        self:zoom_in()
        self._btn_minimum_zoom:performAction("AXPress")
    end

    function editor_window:zoom2()
        ensure_cached_controls()
        self:zoom_in()
        self._btn_medium_zoom:performAction("AXPress")
    end

    function editor_window:zoom3()
        ensure_cached_controls()
        self:zoom_in()
        self._btn_maximum_zoom:performAction("AXPress")
    end

    function ensure_cached_controls_for_project_list_view()
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

    function editor_window:back_to_projects()
        ensure_cached_controls()
        if not self._textfield_title then
            error("No title found, aborting...")
        end
        local title = self._textfield_title:axValue()
        print("title: ", title)
        if not self._btn_back_to_projects then
            error("No back to projects button found, aborting...")
        end
        self._btn_back_to_projects:performAction("AXPress")
        timer.usleep(10000) -- slight delay else won't find scroll area / list of projects

        -- TODO check if went back?
        -- FYI ok to take a hit here to find controls and not use cachehd scroll area of clips?
        ensure_cached_controls_for_project_list_view() -- run again for main editor?
        local btn = vim.iter(self._scrollarea_list:buttons())
            :filter(function(button)
                print("  btn", hs.inspect(button))
                local desc = button:axDescription()
                return desc == title
            end)
            :totable()[1]
        if not btn then
            error("cannot find project to re-open, aborting...")
        end
        btn:performAction("AXPress")
    end

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
    win:zoom_out() -- zoom out first means just click end and zoom in... no slider necessary!
    timer.usleep(10000)
    StreamDeckScreenPalTimelineJumpToStart()
    -- zoom after so if I am initially not zoomed, I can move faster
    -- PRN zoom out before move and then zoom in when done?
    timer.usleep(10000)
    win:zoom2()
end

function StreamDeckScreenPalTimelineZoomAndJumpToEnd()
    local win = get_cached_editor_window()
    win:zoom_out() -- zoom out first means just click end and zoom in... no slider necessary!
    timer.usleep(10000)
    StreamDeckScreenPalTimelineJumpToEnd()
    timer.usleep(10000)
    win:zoom2()
end

function StreamDeckScreenPalTimelineJumpToStart()
    -- local original_mouse_pos = mouse.absolutePosition()
    local win = get_cached_editor_window()

    if win:isZoomed() then
        local timeline_scrollbar = win:get_scrollbar_or_throw()
        local frame = timeline_scrollbar:axFrame()
        local min_value = timeline_scrollbar:axMinValue()

        local function clickUntilTimelineAtEnd()
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
                eventtap.leftClick({ x = frame.x, y = frame.y + frame.h / 2 })
                -- eventtap.leftClick({ x = frame.x, y = frame.y + frame.h / 2 }) -- could click twice if value doesn't change
                -- timer.usleep(10000) -- don't need pause b/c hs seems to block while clicking
            end
        end

        clickUntilTimelineAtEnd()
    end

    -- * move playhead to start (0) by clicking leftmost part of position slider (aka timeline)
    --   keep in mind, scrollbar below is like a pager, so it has to be all the way left, first
    --   PRN add delay if this is not registering, but use it first to figure that out
    local slider = win:get_timeline_slider_or_throw()
    eventtap.leftClick({ x = slider:axFrame().x, y = slider:axFrame().y })

    -- mouse.absolutePosition(original_mouse_pos) -- umm I feel like I want to NOT restore so I can move mouse easily at start!
end

function StreamDeckScreenPalTimelineJumpToEnd()
    -- local original_mouse_pos = mouse.absolutePosition()
    local win = get_cached_editor_window()

    if win:isZoomed() then
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
                eventtap.leftClick({ x = frame.x + frame.w - 1, y = frame.y + frame.h / 2 })
            end
        end

        clickUntilTimelineAtEnd()
    end

    -- move playhead to end by clicking the right‑most part of the timeline slider
    local slider = win:get_timeline_slider_or_throw()
    local sframe = slider:axFrame()
    eventtap.leftClick({ x = sframe.x + sframe.w - 1, y = sframe.y })

    -- mouse.absolutePosition(original_mouse_pos) -- try not restoring, might be better!
end

function StreamDeckScreenPalTimelineRestorePosition()
    -- approximate restore
    -- can only click timeline before/after the slider's bar... so this won't be precise unless I find a way to move it exactly

    local win = get_cached_editor_window()
    if not win:isZoomed() then
        return -- nothing to do, yet
    end

    local timeline_scrollbar = win:get_scrollbar_or_throw()
    local frame = timeline_scrollbar:axFrame()
    local min_value = timeline_scrollbar:axMinValue()

    local target_value = 126938 -- of 185454 for m1-02
    local limit_count = 0

    while limit_count > 50 -- save me if smth goes awry in my maths :)
    do
        local value = timeline_scrollbar:axValue()
        local current_value = tonumber(value)
        if not current_value
            or current_value == target_value
        then
            break
        end

        if current_value < target_value then
            -- click right‑most side of the scrollbar to advance toward the end
            eventtap.leftClick({ x = frame.x + frame.w - 1, y = frame.y + frame.h / 2 })
            -- once I blow past the value, stop
            current_value = tonumber(timeline_scrollbar:axValue())
            if current_value >= target_value then
                break
            end
        else
            -- click left‑most side of the scrollbar to advance toward the end
            eventtap.leftClick({ x = frame.x, y = frame.y + frame.h / 2 })
            -- once I blow past the value, stop
            current_value = tonumber(timeline_scrollbar:axValue())
            if current_value <= target_value then
                break
            end
        end

        -- eventtap.leftClick({ x = frame.x + frame.w - 1, y = frame.y + frame.h / 2 })
    end
end

function StreamDeckScreenPalReopenProject()
    local win = get_cached_editor_window()
    win:back_to_projects()
    -- -- local title = win._textfield_title:axValue()
    -- win._btn_back_to_projects:performAction("AXPress")
end
