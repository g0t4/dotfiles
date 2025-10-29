local vim = require("config.libs.vim") -- reuse nvim lua modules in hammerspoon
require("config.macros.screenpal.co")
local opencv = require("config.macros.screenpal.py.opencv")
local SilencesController = require('config.macros.screenpal.silences')
local ScreenPalEditorWindow = require('config.macros.screenpal.editor_window')
local test_button = require('config.macros.screenpal.experiments.test_button')
local VolumeMenu = require("config.macros.screenpal.windows.volume_menu")

local _200ms = 200000
local _300ms = 300000
local _100ms = 100000
local _50ms = 50000
local _10ms = 10000

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

            local x_start_left, x_start_right = timeline:calculate_frame_bounds(silence.x_start, timeline:get_current_playhead_timeline_relative_x())
            -- print("     x_start_left=" .. x_start_left .. " x_start_right=" .. x_start_right)
            local x_end_left, x_end_right = timeline:calculate_frame_bounds(silence.x_end, timeline:get_current_playhead_timeline_relative_x())
            -- print("     x_end_left=" .. x_end_left .. " x_end_right=" .. x_end_right)
            -- little boxes show left/right frame of start and end too
            table.insert(elements, {
                type = "rectangle",
                action = "fill",
                fillColor = { red = 1, green = 1, blue = 1, alpha = 0.3 },
                frame = { x = x_start_left, y = over_timeline_y, w = (x_start_right - x_start_left), h = timeline_frame.h }
            })
            table.insert(elements, {
                type = "rectangle",
                action = "fill",
                fillColor = { red = 1, green = 1, blue = 1, alpha = 0.3 },
                frame = { x = x_end_left, y = over_timeline_y, w = (x_end_right - x_end_left), h = timeline_frame.h }
            })
        end
    end

    local tool = silences.hack_detected.tool
    if tool and tool.x_end and tool.x_start then
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

_G.MUTE = 'MUTE'
_G.CUT_10 = 'CUT_10'
_G.CUT_15 = 'CUT_15'
_G.CUT_20 = 'CUT_20' -- consider in this case starting preview always?
-- start preview after marking cut, then if the user doesn't interrupt, accept the edit?
_G.CUT_20_OK = 'CUT_20_OK'
_G.CUT_30 = 'CUT_30'
_G.CUT_30_OK = 'CUT_30_OK'
_G.MUTE_RIGHT = 'MUTE_RIGHT' -- _OK too
_G.MUTE_INWARD = 'MUTE_INWARD' -- _OK too

---@param win ScreenPalEditorWindow
---@param silence? Silence
---@param action string
--- PRN @param padding?
function act_on_silence(win, silence, action)
    if not silence then
        -- might be easier to check here, in one spot, than in all the callers
        print("no silence to act on")
        return
    end
    local original_mouse_pos = hs.mouse.absolutePosition() -- first one can be expensive 100ms, cheap (0 to 1ms max) thereafter

    print("act_on_silence: '" .. tostring(action) .. "' on '" .. hs.inspect(silence) .. "'")

    -- perhaps add more params to act_on_silence?
    local is_cut = action:find("CUT_") -- keep trailing _ so it is easier to search for CUT_
    local is_mute = action:find("MUTE")
    local is_auto_approve = action:find("_OK")
    if not (is_cut or is_mute) then
        hs.alert.show("UNDEFINED action: " .. tostring(action))
        return
    end

    -- * calculate padding
    local timeline_relative_x_start = silence.x_start
    local timeline_relative_x_end = silence.x_end -- - 10
    local START_SILENCE_X_START = 1 -- treat silence as starting silence IF it starts before this threshold (pixels)
    if silence.x_start > START_SILENCE_X_START then
        if is_cut then
            local pixel_width = action:match("CUT_(%d*)%.*")
            -- print("pixel_width: " .. tostring(pixel_width) .. " for action " .. action)
            timeline_relative_x_start = silence.x_start + pixel_width
            timeline_relative_x_end = silence.x_end - pixel_width
        end
    end

    local timeline = win:timeline_controller()

    if is_mute then
        -- a few ideas (only try if need arises in many mute edits)
        --
        -- MUTE_LEFT shift both ends left: ← ← (default)
        -- ~ alternatives:
        --   MUTE_RIGHT shift both ends right: → → (often useful too)
        --   MUTE_INWARD shift both ends inward: → ← (often useful)
        --   some videos _RIGHT works best, others _INWARD... not usually both in the same video though
        -- MUTE_OUTWARD shift both ends outward: ← → (not yet encountered need for this)
        --   by default I mean rounding defaults to the frame left of both ends
        if action == 'MUTE_RIGHT' then
            local pixels_per_frame = timeline:pixels_per_frame() or 1
            timeline_relative_x_start = silence.x_start + pixels_per_frame
            timeline_relative_x_end = silence.x_end + pixels_per_frame
        elseif action == 'MUTE_INWARD' then
            local pixels_per_frame = timeline:pixels_per_frame() or 1
            timeline_relative_x_start = silence.x_start + pixels_per_frame
            timeline_relative_x_end = silence.x_end - pixels_per_frame + 1 -- don't add a full frame, we only want to round leftward
            -- TODO lookup why things are rounding the way they are, for now I think I like + 1 here to keep inward's right side the same as leftward's right side
            --   OTHERWISE inward's right side is a whole frame less than just leftward (when they should be the same, both round left)
        end
    end

    -- * set tool start
    timeline:move_playhead_to(timeline_relative_x_start)

    -- * activate tool
    local start_tool_key = ''
    if is_cut then
        start_tool_key = 'c'
    elseif is_mute then
        start_tool_key = 'v'
    end
    hs.eventtap.keyStroke({}, start_tool_key, 0, win.app)
    win.windows:get_tool_window():wait_for_cancel_or_ok_button()

    -- * set tool start
    hs.eventtap.keyStroke({}, "s", 0, win.app)
    -- PRN could wait for time_string to change and/or OK to show (if cancel was first) but neither of these are slam dunk... fine with 100ms here too
    hs.timer.usleep(_100ms)

    -- * set tool end
    timeline:move_playhead_to(timeline_relative_x_end)
    hs.eventtap.keyStroke({}, "e", 0, win.app)
    -- FYI never needed a wait here previously:
    win.windows:get_tool_window():wait_for_ok_button() -- by now we have a range, so the OK button should be visible

    if is_mute then
        local menu = VolumeMenu.new(win.windows)
        menu:wait_for_volume_to_be_mute()
    end

    -- print("silence " .. vim.inspect(silence))
    if silence.x_start <= START_SILENCE_X_START and is_cut then
        -- sometimes regular silences start at 1, probably due to a border around the silence box...
        -- special behavior for cutting  start of video (add fixed padding)

        -- * pull back 2 frames from end to avoid cutting into starting audio
        local before_time = win:get_current_time()
        hs.eventtap.keyStroke({}, "left", 0, win.app)
        win:wait_until_time_changes(before_time)

        -- FYI 2 frame reduction is b/c insert pause always blends away 1 frame in waveform (not sure effects audio, just to be safe do two)
        before_time = win:get_current_time()
        hs.eventtap.keyStroke({}, "left", 0, win.app)
        win:wait_until_time_changes(before_time)

        -- restore mouse position fixes issue with mouse over timeline triggering insert below mouse (randomly)
        -- PRN move restore to move_playhead_to()? part of me feels like I have enjoyed it for subseuqent edits, to have it move to the current edit location
        hs.mouse.absolutePosition(original_mouse_pos) -- 0.2ms
        hs.timer.usleep(_10ms)

        win.windows:get_tool_window():wait_for_ok_button_then_press_it()

        -- * insert pause auto-approved
        hs.eventtap.keyStroke({}, "i", 0, win.app)
        hs.timer.usleep(_10ms)
        hs.eventtap.keyStroke({}, "p", 0, win.app)
        hs.timer.usleep(_200ms)
        win.windows:get_tool_window():wait_for_ok_button_then_press_it()
        return
    end

    if is_auto_approve then
        -- PRN wait to make sure OK is visible (sometimes there is a lag and at least with volume tool, hitting Enter before will be accepted but will disappear the edit!)
        win.windows:get_tool_window():wait_for_ok_button_then_press_it()
    end

    -- TODO check if mute button is muted icon? or w/e else to determine if I should click mute the first time?
end

---@param callback fun(win: ScreenPalEditorWindow, silences: SilencesController)
local function detect_silences(callback)
    run_async(function()
        local win = get_cached_editor_window()

        local timeline_element = win:get_timeline_slider_or_throw()
        local frame = timeline_element:axFrame()
        local where_to = syncify(capture_region, frame)

        local detected = syncify(opencv.detect_silence, where_to)

        local timeline = win:timeline_controller()
        local silences = SilencesController:new(detected, timeline)
        callback(win, silences)
    end)
end

---@param win ScreenPalEditorWindow
local function move_playhead_to_silence(win, silence)
    local timeline_relative_x = silence.x_start
    local timeline = win:timeline_controller()
    timeline:move_playhead_to(timeline_relative_x)
end

function SPal_JumpThisSilence()
    -- FYI! don't forget you added keymap Ctrl+Shift+left/right to jump silences
    --   habituate using this instead of jumping one second at a time and then when close arrowing around to get to silence
    --   what you're doing now is terrible workflow, but understandable not wanting to reach for a streamdeck button for every jump
    --   that's why this keyboard shortcut should help
    --   PRN jump to and start a mute edit on next silence?
    --     observe what you are doing now and figure out what is most useful
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_this_silence()
        move_playhead_to_silence(win, silence)
    end)
end

function SPal_JumpPrevSilence()
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_prev_silence()
        move_playhead_to_silence(win, silence)
    end)
end

function SPal_JumpNextSilence()
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

function SPal_PlayNextSilence()
    -- TODO PLAY THIS, NEXT, PREV silence helpers
    -- when done jump back to start of that position or silence?
end

function SPal_ActOnThisSilence_ThruStart(action_keystroke)
    -- TODO figure out if I have a use for this
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_this_silence()
        local timeline = win:timeline_controller()
        silence = {
            -- PRN make silence ctor? and use it with data returned from detection (hydrate into it)
            x_start = silence.x_start,
            x_end = timeline:get_current_playhead_timeline_relative_x(),
        }
        act_on_silence(win, silence, action_keystroke)
    end)
end

function SPal_ActOnThisSilence(action_keystroke)
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_this_silence()
        act_on_silence(win, silence, action_keystroke)
    end)
end

function SPal_ActOnThisSilence_ThruEnd(action_keystroke)
    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local silence = silences:get_this_silence()
        local timeline = win:timeline_controller()
        silence = {
            -- PRN make silence ctor? and use it with data returned from detection (hydrate into it)
            x_start = timeline:get_current_playhead_timeline_relative_x(),
            x_end = silence.x_end,
        }
        act_on_silence(win, silence, action_keystroke)
    end)
end

local START = "start"
local END = "end"
local OTHER = "other"
local LEFT = "left"
local RIGHT = "right"

---@param text string
---@return boolean pasted_text
function pasted_text_in_textfield(text)
    if text then
        -- I added this part b/c I am using some keystrokes that override letters (h/l/o/S/E ... and if I am in a text box I want to type those instead)
        local win = get_cached_editor_window()
        local focused = win.app:attributeValue("AXFocusedUIElement")
        -- print("focused", focused)
        if focused ~= nil and focused:isValid() then
            -- for attr_name, attr_value in pairs(focused) do
            --     print(attr_name, attr_value)
            -- end
            local role = focused:axRole()
            if role == "AXTextField" then
                -- caller passes text value based on shortcut assigned, that way caller can change it and not need to update this part
                hs.pasteboard.setContents(text)
                hs.eventtap.keyStroke({ "cmd" }, "v", 0) -- Cmd+V to paste since I can't type it, would put me in a loop (at best)
                return true
            end
        end
    end
    return false
end

local LEFT = "left"
local RIGHT = "right"

function SPal_KeyMap(action, text)
    -- ** insert text if in a textbox
    if pasted_text_in_textfield(text) then
        return
    end

    local win = get_cached_editor_window()
    if action == LEFT then
        hs.eventtap.keyStroke({}, LEFT, 0, win.app)
    elseif action == RIGHT then
        hs.eventtap.keyStroke({}, RIGHT, 0, win.app)
    end
end

-- FYI constnats added globally to simplify streamdeck button lua code snippets (where escaping of quotes is a PITA)
_G.SELECTION_BEFORE_START = "SELECTION_BEFORE_START"
_G.SELECTION_BEFORE_END = "SELECTION_BEFORE_END"
_G.SELCTION_BEFORE_OPPOSITE = "SELCTION_BEFORE_OPPOSITE"
_G.SELECTION_AT_START = "SELECTION_AT_START"
_G.SELECTION_AT_END = "SELECTION_AT_END"

function SPal_Play(play_what, text)
    -- TODO could add other play scenarios / tools to this

    -- ** if text triggered this, then paste it if in a text box (effectively bypass shortcut for textfields)
    if pasted_text_in_textfield(text) then
        return
    end

    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local timeline = win:timeline_controller()

        local play_from_x = nil

        ---called range b/c we need x_start/x_end to derive playback (either from tool, or silence, or smth else in the future)
        ---@type Tool|Silence?
        local range = silences.hack_detected.tool
        if not range or not range.x_end then
            -- * no tool open, then look at silences and use one of them as a "virtual tool" (think "virtual selection")
            -- find and preview the closest silence (start/end)

            local playhead_x = timeline:get_current_playhead_timeline_relative_x()
            local current_silence = silences:get_this_silence()

            if not current_silence then
                -- no current silence => find nearest (either side)
                local next = silences:get_next_silence()
                local prev = silences:get_prev_silence()
                local closest_silence = nil
                if not prev and not next then
                    print("no silences found on either side! aborting play... SHOULD NOT HAPPEN unless a video has NO silenes visible in which case why you asking to play one!!")
                    return
                elseif not next then
                    closest_silence = prev
                elseif not prev then
                    closest_silence = next
                else
                    -- which is closer?
                    local prev_distance = playhead_x - prev.x_end
                    local next_distance = next.x_start - playhead_x
                    if prev_distance < next_distance then
                        closest_silence = prev
                    else
                        closest_silence = next
                    end
                end
                range = closest_silence
            else
                range = current_silence
            end
        end

        -- * move w.r.t. range before playback
        if play_what == SELECTION_AT_START then
            play_from_x = range.x_start
        elseif play_what == SELECTION_AT_END then
            play_from_x = range.x_end
        elseif play_what == SELECTION_BEFORE_START then
            play_from_x = range.x_start - 20
        elseif play_what == SELECTION_BEFORE_END then
            play_from_x = range.x_end - 20
        elseif play_what == SELCTION_BEFORE_OPPOSITE then
            -- TODO remove if not being used, when I added this I wasn't sure if I'd use it
            local playhead_x = timeline:get_current_playhead_timeline_relative_x()
            if playhead_x < range:x_middle() then
                play_from_x = range.x_end - 20
            else
                play_from_x = range.x_start - 20
            end
        end

        if not play_from_x then
            print("play_from_x is not set, skipping playback")
            return
        end

        local is_tool_open = range == silences.hack_detected.tool
        timeline:move_playhead_to(play_from_x)
        win:ensure_playing(is_tool_open)
        if is_tool_open then
            -- b/c p shifts the cursor back too :(
            --  no idea of a way to trigger preview other than p
            timeline:move_playhead_to(play_from_x)
        end
    end)
end

function SPal_AdjustSelection(side, num_frames, text)
    -- ** if text triggered this, then paste it if in a text box (effectively bypass shortcut for textfields)
    if pasted_text_in_textfield(text) then
        return
    end

    run_async(function()
        ---@type ScreenPalEditorWindow, SilencesController
        local win, silences = syncify(detect_silences)
        local timeline = win:timeline_controller()

        local tool = silences.hack_detected.tool
        if not tool or not tool.x_end then
            -- TODO split out function
            -- no tool open, try using current silence
            -- move to other side of current silence
            -- obviously, no selection adjustment (b/c no selection is open)

            local playhead_x = timeline:get_current_playhead_timeline_relative_x()
            local silence = silences:get_this_silence()

            if not silence then
                -- PRN do I care about PRN in here? should I jump to S/E sides if those are used?
                -- I mostly added this with O in mind but S/E should work too and maybe I want those ends and not the [O]pposite?

                -- no current silence => find nearest (either side)
                local next = silences:get_next_silence()
                local prev = silences:get_prev_silence()
                if not prev and not next then
                    -- very unlikely!
                    return
                end
                if not next then
                    silence = prev
                elseif not prev then
                    silence = next
                else
                    -- which is closer?
                    local prev_distance = playhead_x - prev.x_end
                    local next_distance = next.x_start - playhead_x
                    if prev_distance < next_distance then
                        silence = prev
                    else
                        silence = next
                    end
                end
            end
            if not silence then return end

            local playhead_closer_to_start = playhead_x < silence:x_middle()
            if playhead_closer_to_start then
                timeline:move_playhead_to(silence.x_end)
            else
                timeline:move_playhead_to(silence.x_start)
            end

            return
        end

        if side == START then
            timeline:move_playhead_to(tool.x_start)
            if num_frames > 0 then
                -- expand
                hs.eventtap.keyStroke({}, LEFT, 0, win.app)
            elseif num_frames < 0 then
                -- shink
                hs.eventtap.keyStroke({}, RIGHT, 0, win.app)
            end
            -- 0 == JUMP to start only
        elseif side == END then
            -- FYI this works on end to expand (click right of end), just not to shrink (click left of end)
            -- -- 6 == 2*3 (3 pixels in 1080p per frame at zoom2)
            -- local num_pixels = 6 * num_frames
            -- if num_frames < 0 then
            --     num_pixels = -12
            -- end
            -- print("adjusting by num_pixels: " .. tostring(num_pixels) .. " frames: " .. tostring(num_frames))
            -- next_frame_x_guess_zoom2 = tool.x_end + num_pixels
            -- extend selection to current playhead position
            -- timeline:move_playhead_to(next_frame_x_guess_zoom2)
            -- hs.eventtap.keyStroke({}, "e", 0, win.app)

            -- move cursor to end of selection
            timeline:move_playhead_to(tool.x_end)
            -- arrow left/right to move one frame w/o calculating x pixel value and without issues going back with cursor
            if num_frames > 0 then
                hs.eventtap.keyStroke({}, RIGHT, 0, win.app) -- expand
            elseif num_frames < 0 then
                hs.eventtap.keyStroke({}, LEFT, 0, win.app) -- shrink
            end
            -- 0 == JUMP to end only
        elseif side == OTHER then
            -- just flip to other side!
            local playhead_x = timeline:get_current_playhead_timeline_relative_x()
            local x_middle = tool.x_start + (tool.x_end - tool.x_start) / 2
            local playhead_closer_to_start = playhead_x < x_middle
            if playhead_closer_to_start then
                timeline:move_playhead_to(tool.x_end)
            else
                timeline:move_playhead_to(tool.x_start)
            end
        end
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

function SPal_ShowSilenceRegions()
    run_async(function()
        if silences_are_visible() then
            hide_silences()
            return
        end

        local win, silences = syncify(detect_silences)
        show_silences(win, silences)
    end)
end

---@param number integer - button # left to right
function SPal_OpenThisEdit(number)
    number = number or 1
    local win = get_cached_editor_window()
    local tool_window = win.windows:get_tool_window()

    -- * assume open edit == targeted edit
    if tool_window:get_ok_accept_this_edit_button() then
        return
        -- would be unlikely I know what number to open if I have one open already!
        -- PRN could see a need to step through edit by edit looking for which edit to change.. that can be a special, separate button
    end

    -- * open edit by number (left to right)
    local edit_button = tool_window:get_edits_buttons()[number]
    edit_button:axPress() -- PRN make tool_window:open_edit(number)
    tool_window:wait_for_ok_button() -- ? make func like wait_for_edit_to_be_open() ?
end

function SPal_PreviewThisEdit(number)
    number = number or 1

    SPal_OpenThisEdit(number)

    -- * assume open edit == the edit to preview
    local win = get_cached_editor_window()
    local tool_window = win.windows:get_tool_window()

    -- * click preview
    local preview_button = tool_window:get_preview_this_edit_button()
    if preview_button then
        preview_button:axPress()
        tool_window:wait_for_tools_button()
        return
    end
end

function SPal_RemoveThisEdit(number)
    number = number or 1

    SPal_OpenThisEdit(number)

    -- * assume open edit == the edit to remove
    local win = get_cached_editor_window()
    local tool_window = win.windows:get_tool_window()

    -- * click copy overlay
    local remove_button = tool_window:get_remove_this_edit_button()
    if remove_button then
        remove_button:axPress()
        tool_window:wait_for_tools_button()
        return
    end
end

function SPal_CopyThisEdit(number)
    number = number or 1

    -- FYI AFAICT copy only applies to Overlay edits - shapes, arrows, images,
    --   should I ignore other edits when indexing (number)?
    --   careful, open has to operate on all button positions

    SPal_OpenThisEdit(number)

    -- * assume open edit == the edit to copy
    local win = get_cached_editor_window()
    local tool_window = win.windows:get_tool_window()


    -- * click copy overlay
    local copy_overlay = tool_window:get_copy_this_edit_button()
    if copy_overlay then
        copy_overlay:axPress()
        tool_window:wait_for_tools_button()
        return
    end

    -- 	previously I would click paste overlay after copy finishes (closes toolbar)... let's not add that until I know I need it
    --  property btnPasteOverlay : a reference to (first button of my toolbar whose description starts with "Paste Overlay")
    -- 	delayUntilExists(btnPasteOverlay)
    -- 	clickIfExists(btnPasteOverlay)
end

function SPal_Timeline_ZoomAndJumpToStart()
    -- FYI using run_async (coroutines under hood) to avoid blocking (i.e. during sleep calls)
    run_async(function()
        local win = get_cached_editor_window()
        -- TODO move zoom controls to timeline class?
        -- TODO then can add move_to_video_start() for this, to the timeline too
        win:zoom_off() -- zoom out so start is visible w/o scrolling
        sleep_ms(10)

        -- FYI jumping to start/end unzoomed doesn't need PPS:
        win:timeline_controller():move_playhead_to_timeline_start()

        sleep_ms(10)
        win:zoom2()
    end)
end

function SPal_Timeline_ZoomAndJumpToEnd()
    run_async(function()
        local win = get_cached_editor_window()
        win:zoom_off()
        sleep_ms(10)

        win:timeline_controller():move_playhead_to_timeline_end()

        sleep_ms(10)
        win:zoom2()
    end)
end

function SPal_SetZoomLevel(level)
    local win = get_cached_editor_window()
    win:set_zoom_level(level)
end

function SPal_ZoomIn()
    local win = get_cached_editor_window()
    win:zoom_in()
end

function SPal_ZoomOut()
    local win = get_cached_editor_window()
    win:zoom_out()
end

function SPal_ToggleFrameZoom()
    local win = get_cached_editor_window()
    win:toggle_frame_zoom()
end

function SPal_CopyPlayheadTimeText()
    local win = get_cached_editor_window()
    local _, time_string = win:get_current_time()
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

function SPal_ReopenProject()
    get_cached_editor_window():reopen_project()
end
