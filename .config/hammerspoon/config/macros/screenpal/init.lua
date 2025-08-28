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

function StreamDeckScreenPalTimelineJumpToStart()
    local win = getEditorWindowOrThrow()
    local original_mouse_pos = mouse.absolutePosition()
    --  mouse pos	{ __luaSkinType = "NSPoint", x = 1396.0, y = 877.10546875 }

    local is_timeline_zoomed = vim.iter(win:buttons())
        :any(function(button)
            -- if any of the zoom buttons are visible, then the timeline is zoomed
            return button:axDescription() == "Minimum Zoom"
        end)

    if is_timeline_zoomed then
        local timeline_scrollbar = win:scrollBar(4)
        if not timeline_scrollbar then
            print("No timeline scrollbar found, aborting...")
            return
        end

        local frame = timeline_scrollbar:axFrame()
        -- by the way AXFrame here returns { h = 50.0, w = 1839.0, x = 14.0, y = 814.0 }
        --   which is unlike AppleScript where the value is x_left/x_right, y_top/y_bottom

        local function clickUntilTimelineAtStart()
            local lastValue = nil
            while true do
                local value = timeline_scrollbar:axValue()
                -- print("Scroll bar value is now: " .. value)

                local numValue = tonumber(value)
                if not numValue then break end

                if numValue <= 0 then
                    break
                end

                if lastValue ~= nil and numValue == lastValue then
                    print("Value unchanged, stopping.")
                    break
                end

                lastValue = numValue

                eventtap.leftClick({ x = frame.x, y = frame.y + frame.h / 2 })
                -- eventtap.leftClick({ x = frame.x, y = frame.y + frame.h / 2 }) -- could click twice if value doesn't change
                -- timer.usleep(10000) -- don't need pause b/c hs seems to block while clicking
            end
        end

        clickUntilTimelineAtStart()
    end

    -- * move playhead to start (0) by clicking leftmost part of position slider (aka timeline)
    --   keep in mind, scrollbar below is like a pager, so it has to be all the way left, first
    --   PRN add delay if this is not registering, but use it first to figure that out
    vim.iter(win:buttons())
        :filter(function(button)
            -- AXDescription: Position Slider<string>
            -- AXHelp: This shows the current position of the animation.<string>
            -- AXIndex: 3<number>
            -- unique ref: app:window('ScreenPal - 3.19.4'):button(desc='Position Slider')
            return button:axDescription() == "Position Slider"
        end)
        :each(function(button)
            -- print("Found the position slider")
            eventtap.leftClick({ x = button:axFrame().x, y = button:axFrame().y })
            clickUntilTimelineAtStart()
        end)

    mouse.absolutePosition(original_mouse_pos)
end

-- * TODO! JUMP to END

-- * TODO! JUMP to Restore (attempt to click around until get there)
