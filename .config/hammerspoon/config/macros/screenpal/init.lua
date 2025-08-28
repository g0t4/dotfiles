local mouse = require("hs.mouse")
local eventtap = require("hs.eventtap")
local timer = require("hs.timer")
local vim = require("config.libs.vim") -- reuse nvim lua modules in hammerspoon

-- * timeline scrollbar (only shows when zoomed)
-- app:window(4):scrollBar(4)
-- AXFocusedUIElement: AXScrollBar<hs.axuielement>
-- AXIndex: 0<number>
-- AXMaxValue: 219094<number>
-- AXMinValue: 0<number>
-- AXOrientation: AXHorizontalOrientation<string>
-- AXRoleDescription: scroll bar<string>
-- AXValue: 216820<number>

local function getScreenPalAppElementOrThrow()
    return getAppElementOrThrow("ScreenPal")
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

ScreenPalTimeline = {}
function ScreenPalTimeline:new()
    local timeline = {}
    setmetatable(timeline, self)
    self.__index = self
    -- PRN allow passing win if lookup is slow by just letting this class find it
    local win = getEditorWindowOrThrow()
    self.win = win -- for testing

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

    function timeline:isZoomed()
        return vim.iter(win:buttons())
            :any(function(button)
                -- if any of the zoom buttons are visible, then the timeline is zoomed
                return button:axDescription() == "Minimum Zoom"
            end)
    end

    local function getToggleZoomButtonOrThrow()
        local toggle_zoom_button = vim.iter(win:buttons())
            :filter(function(button)
                return button:axDescription() == "Toggle Magnify"
            end)[1]
        if not toggle_zoom_button then
            error("No toggle zoom button found, aborting...")
        end
        return toggle_zoom_button
    end

    function timeline:enable_zoom()
        if self:isZoomed() then return end
        getToggleZoomButtonOrThrow():performAction("AXPress")
    end

    function timeline:enable_unzoom()
        if not self:isZoomed() then return end
        getToggleZoomButtonOrThrow():performAction("AXPress")
    end

    function timeline:get_scrollbar_or_throw()
        -- PRN search for big AXMaxValues? that might uniquely identify it if I have issues in the future with other scrollbars visible
        local scrollbar = win:scrollBar(4)
        if not scrollbar then
            error("No timeline scrollbar found, aborting...")
        end
        return scrollbar
    end

    function timeline:get_timeline_slider_or_throw()
        local slider = vim.iter(win:buttons())
            :filter(function(button)
                -- AXDescription: Position Slider<string>
                -- AXHelp: This shows the current position of the animation.<string>
                -- AXIndex: 3<number>
                -- unique ref: app:window('ScreenPal - 3.19.4'):button(desc='Position Slider')
                return button:axDescription() == "Position Slider"
            end)
            :totable()[1]
        -- print("timeline: ", hs.inspect(slider))
        if not slider then
            error("No timeline slider found, aborting...")
        end
        -- print("Found slider!")
        return slider
    end

    function timeline:zoom1() end

    function timeline:zoom2() end

    function timeline:zoom3() end

    function timeline:jumpToStart() end

    function timeline:jumpToEnd() end

    return timeline
end

function StreamDeckScreenPalTimelineJumpToStart()
    local original_mouse_pos = mouse.absolutePosition()
    local timeline = ScreenPalTimeline:new()

    if timeline:isZoomed() then
        local timeline_scrollbar = timeline:get_scrollbar_or_throw()
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
    local slider = timeline:get_timeline_slider_or_throw()
    eventtap.leftClick({ x = slider:axFrame().x, y = slider:axFrame().y })

    mouse.absolutePosition(original_mouse_pos)
end

function StreamDeckScreenPalTimelineJumpToEnd()
    local original_mouse_pos = mouse.absolutePosition()
    local timeline = ScreenPalTimeline:new()

    if timeline:isZoomed() then
        local timeline_scrollbar = timeline:get_scrollbar_or_throw()
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
    local slider = timeline:get_timeline_slider_or_throw()
    local sframe = slider:axFrame()
    eventtap.leftClick({ x = sframe.x + sframe.w - 1, y = sframe.y })

    mouse.absolutePosition(original_mouse_pos)
end

-- * TODO! JUMP to Restore (attempt to click around until get there)
