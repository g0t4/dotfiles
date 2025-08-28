local eventtap = require("hs.eventtap")
local timer = require("hs.timer")
local vim = require("config.libs.vim") -- reuse nvim lua modules in hammerspoon

-- * timeline scrollbar (only when zoomed)
-- app:window(4):scrollBar(4)
--
-- AXEnabled: true<bool>
-- AXFocused: false<bool>
-- AXFocusedUIElement: AXScrollBar<hs.axuielement>
-- AXIndex: 0<number>
-- AXMaxValue: 219094<number>
-- AXMinValue: 0<number>
-- AXOrientation: AXHorizontalOrientation<string>
-- AXRoleDescription: scroll bar<string>
-- AXSelected: false<bool>
-- AXValue: 216820<number>
--
-- AXChildren:
-- AXButton: desc:'zero button'
-- AXButton: desc:'zero button'
--
-- unique ref: app:window('ScreenPal - 3.19.4')

local function getScreenPalAppElement()
    -- TODO disable warning about hs.application.enableSpotlightForNameSearches
    return expectAppElement("ScreenPal")
end

local function getEditorWindow()
    local app = getScreenPalAppElement()

    -- print("windows", hs.inspect(app:windows()))
    for _, win in ipairs(app:windows()) do
        if win:axTitle():match("^ScreenPal -") then
            -- print("Found window", win:axTitle())
            return win
        end
    end
end

function StreamDeckScreenPalTimelineJumpToStart()
    -- TODO check if zoomed, won't work otherwise (or if doesn't find scrollbar for timeline)
    local win = getEditorWindow()
    if not win then
        print("No ScreenPal window found, aborting...")
        return
    end

    local timeline_scrollbar = win:scrollBar(4)
    if not timeline_scrollbar then
        print("No timeline scrollbar found, aborting...")
        return
    end
    -- btw, AXOrientation is AXHorizontalOrientation

    local frame = timeline_scrollbar:axFrame()
    -- by the way AXFrame here returns { h = 50.0, w = 1839.0, x = 14.0, y = 814.0 }
    --   which is unlike AppleScript where the value is x_left/x_right, y_top/y_bottom
    print(hs.inspect(frame))

    local mouse = require("hs.mouse")
    local original_mouse_pos = mouse.absolutePosition()
    -- print("mouse pos", hs.inspect(pos))
    --  mouse pos	{ __luaSkinType = "NSPoint", x = 1396.0, y = 877.10546875 }

    local function clickUntilZero()
        while true do
            local value = timeline_scrollbar:axValue()
            print("Scroll bar value is now: " .. value)

            if tonumber(value) <= 0 then
                break
            end

            eventtap.leftClick({ x = frame.x, y = frame.y + frame.h / 2 })
            timer.usleep(100000) -- 0.1 s pause to let UI update
        end
    end

    clickUntilZero()



    -- y position 1/3 of the way down
    -- local y_click = frame.y + frame.h / 3
end

-- * TODO! JUMP to END

-- * TODO! JUMP to Restore (attempt to click around until get there)
