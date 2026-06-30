-- print(package.path)
-- FYI already have hs config added to path (obviously):
-- local hs_config = os.getenv("WES_DOTFILES") .. "/.config/hammerspoon"
-- package.path = package.path .. ";" .. hs_config .. "/?.lua"

local log = require("config.logs").hammerspoons()
local editor_window = require("config.macros.screenpal.editor_window")
local AppWindows = require("config.macros.screenpal.app_windows")
-- log:info(ensure_in_coroutine)

-- local macros = require("config.macros")
-- StreamDeckKeyboardMaestroRunner("print('works to dispatch KM macro like streamdeck button press with logging + coroutine context!')") -- works
-- print("this is from print in hammerspoon (should end up in log file after removing float window in harness)", hs)

-- *** test new automations of screenpal w/o restart HS + trigger full actions (streamdeck button)!
-- PRN setup facade to get at controls in spal app
local app = get_app_element_or_throw("com.screenpal.app")
local wins = AppWindows.new(app)
-- wins:_refresh()
-- log:info(wins)
-- local tool_win = wins:get_tool_bar_window()
-- log:info(tool_win)

-- switch to screenpal
app:asHSApplication():activate()

-- -- -- * test v + mute => working fast and fine
-- -- -- type v key
-- hs.eventtap.keyStroke({}, "v") -- open volume tool in the silence under cursor... wow it works fast and good
-- -- --
-- local volume_menu = require("config.macros.screenpal.windows.volume_menu").new(wins)
-- log:info(volume_menu)
-- volume_menu:wait_for_volume_to_be_muted() -- TODO anything in here that would not wait appropriately to pull off the volume menu clicking to mute? .. i.e. skip waiting for submenu to appear and just rely on first access to work?

-- * test act_on_silence(MUTE_INWARD)
SPal_ActOnThisSilence('MUTE_INWARD') -- streamdeck button triggers this
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
