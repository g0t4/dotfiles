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

-- *** test new automations of screenpal w/o restart HS + trigger full actions (streamdeck button)!
-- PRN setup facade to get at controls in spal app
app = get_app_element_or_throw("com.screenpal.app")
wins = AppWindows.new(app)
wins:_refresh()
log:info(wins)
tool_win = wins:get_tool_window()
log:info(tool_win)
