local log = require("config.logs").hammerspoons()
local ScreenPalEditorWindow = require('config.macros.screenpal.editor_window')
local AppWindows = require("config.macros.screenpal.app_windows")
local ToolOptionWindows = require("config.macros.screenpal.windows.tool_options")
local Timer = require("devtools.logs.timer")
-- log:info(ensure_in_coroutine)

-- local macros = require("config.macros")
-- StreamDeckKeyboardMaestroRunner("print('works to dispatch KM macro like streamdeck button press with logging + coroutine context!')") -- works
-- print("this is from print in hammerspoon (should end up in log file after removing float window in harness)", hs)

-- *** test new automations of screenpal w/o restart HS + trigger full actions (streamdeck button)!
-- PRN setup facade to get at controls in spal app
local app = get_app_element_or_throw("com.screenpal.app")
local wins = AppWindows.new(app)
-- list windows:
wins:_refresh()
log:info(wins.windows_by_title)

-- app:asHSApplication():activate()

local editor_window = get_cached_editor_window()
log:info("editor_window", editor_window)
local zoom = editor_window:detect_zoom_level()
log:info("zoom", zoom)

do return end

local tool_win = wins:get_tool_bar_window()
-- tool_win:dump_tool_bar_controls()
-- log:info(tool_win:get_edits_buttons())

-- copy = tool_win:wait_for_copy_edit_button()
-- log:info("copy",copy)
-- local edits = tool_win:get_edits_buttons()
-- edits[1]:axPress()
-- local btn = tool_win:wait_for_ok_button()
-- log:info("is_an_edit_tool_open", tool_win:is_an_edit_tool_open())

local fails = require("devtools.logs.fails")
fails.load_to_quickfix()
-- -- -- start cut tool
-- -- hs.eventtap.keyStroke({}, 'c', 0, app)
-- -- local options = ToolOptionWindows.new(wins)
-- Timer.time_this(function()
--     -- FYI if I don't activate ScrenPal this takes 10-20ms but if I activate it.. it can be upwards of 150ms?!
--     local posbar = wins:get_window_by_title_pattern("^SOM%-FloatingWindow%-Type=edit2.posbar%-ZOrder=1")
--     local time = posbar:textField(1):axValue():gsub("\n", "") -- trim leading \n
--     log:info("time", time)
--     -- AXValue:
--     -- 1:45.88<string>
--     -- unique ref: app:window('SOM-FloatingWindow-Type=edit2.posbar-ZOrder=1(Undefined+1)'):textField()
--     -- TODO! is get_current_time() slow and inefficent? b/c of cached controls? if so rewrite to go right to window and get control instead?
-- end, "time", log)
-- do return end


-- -- -- * test v + mute => working fast and fine
-- -- -- type v key
-- hs.eventtap.keyStroke({}, "v") -- open volume tool in the silence under cursor... wow it works fast and good
-- -- --
-- local volume_menu = require("config.macros.screenpal.windows.volume_menu").new(wins)
-- log:info(volume_menu)
-- volume_menu:wait_for_volume_to_be_muted() -- TODO anything in here that would not wait appropriately to pull off the volume menu clicking to mute? .. i.e. skip waiting for submenu to appear and just rely on first access to work?

-- * test act_on_silence(MUTE_INWARD)
-- SPal_ActOnThisSilence('MUTE_INWARD') -- streamdeck button triggers this





-- -- SPal_ActOnThisSilence('CUT_20_OK') -- streamdeck button triggers this
-- --
-- hs.eventtap.keyStroke({}, 'c', 0, app)
-- hs.eventtap.keyStroke({}, 's', 0, app)
-- local ToolOptionWindows = require("config.macros.screenpal.windows.tool_options").new(wins)
-- local tool_options = ToolOptionWindows.new(wins)
-- local range_win = tool_options:wait_for_range_selection_toolbar_window()
-- log:info('range_win', range_win)
-- local btn1 = range_win:button(1)
-- log:info('btn1', btn1) -- help page is button1
-- -- btn1:dumpAttributes() -- logs the attributes!! very cool (love the logs now)
-- --
-- local start_button = range_win:button_by_description_matching("start")
-- -- AXDescription => "Select everything from this point to the start of the video"
-- log:info("start_button", start_button)
-- -- start_button:axPress()
-- -- start_button:dumpAttributes()
-- --
-- local end_button = range_win:button_by_description_matching("end")
-- -- AXDescription "Select everything from this point to the end of the video"
-- log:info("end_button", end_button)
-- end_button:axPress()
-- end_button:dumpAttributes()
-- FYI I MUCH PREFER THIS METHOD (along with my inspector) to build out APIs around UI interactions!



-- btn1:axPress()
--
-- ensure_in_coroutine(function()
--     local win, silences = syncify(detect_silences)
--     local silence = silences:get_this_silence()
--     act_on_silence(win, silence, "MUTE_INWARD")
--     -- TODO wait for this to be slow again... right now mute is super fast even though I haven't accepted a mute edit so the mute button has to be changed every time... and all are curently fast ... will see if delays creep up later
-- end)
--

-- TODO! just use this script style for now is FINE!


-- FYI I just copied busted.lua module and modified it instead of using as-is
-- FYI! busted style test running is not yet working... NBD right now as I don't need it... I just want script running like above
-- local plenary_nvim = os.getenv("HOME") .. "/.local/share/nvim/lazy/plenary.nvim"
-- package.path = package.path .. ";" .. plenary_nvim .. "/lua/?.lua"

-- require("config.hs_harness.busted").run(os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/.config/hammerspoon/config/macros/screenpal/windows/busted.hs.test.lua")
-- -- vim.api.nvim_list_uis ... ok so I won't easily run plenary busted runner here... NBD I can make my own test fwk if I really want that
-- --   FOR NOW I am fine with just running scripts... not sure I intend to do tests yet
-- --  PERHAPS have a <leader>hs for scripts and <leader>ht for tests ? or just detect based on contents of current file? or heck have describe/it work w/o anything else so they work as-is as a test runner
