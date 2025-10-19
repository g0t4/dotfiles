local VolumeMenu = require('config.macros.screenpal.windows.volume_menu')
local ToolBarWindow = require('config.macros.screenpal.windows.tools_window')

local M = {}

-- EXPERIMENTS via test button
--   can leave code to reuse later here

local function DONE_test_click_rounding()
    local original_mouse_pos = hs.mouse.absolutePosition()

    -- go back and forth
    local timeline = get_cached_editor_window():timeline_controller()
    local playhead_x = timeline:get_current_playhead_timeline_relative_x()
    local start_x = 816.5

    run_async(function()
        -- *** TAKEAWAY, be at least 0.5 to the right of the frame you want to land on
        --   and that makes sense...
        --   frames are landing on fraction of a pixel, i.e. 816.5
        --   => clicking at 816.5 is probably akin to clicking at 816 with rounding somewhere? floor?
        --   => clicking at 817 works to land on 816.5 then (that equivalent frame)
        for i = 1, 30 do
            start_x = start_x + 0.5
            timeline:move_playhead_to(start_x)
            sleep_ms(150)
            hs.mouse.absolutePosition(original_mouse_pos) -- 0.2ms
            sleep_ms(250)
        end
    end)
end

local function WIP_OpenMuteTool()
    -- TODO finish and integrate with act_on_silence when action=MUTE* (i.e. don't open if sub menu if tool already muted)
    -- assume this is done in silence where it will open the tool right away b/c both ends are auto selected
    hs.eventtap.keyStroke({}, "v", 0) -- Cmd+V to paste since I can't type it, would put me in a loop (at best)
    local win = get_cached_editor_window()
    local menu = VolumeMenu.new(win.windows)
    menu:wait_for_volume_to_be_mute()
end

function SPal_Test()
    local win = get_cached_editor_window()
    local tool_window = win.windows:get_tool_window()
    local buttons = tool_window:get_edits_buttons()
    print("found buttons:")
    print(hs.inspect(buttons))
end

return M
