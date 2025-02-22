--
-- *** ESSENTIAL DOCS: https://www.hammerspoon.org/docs/
-- FYI it doesn't seem like the API for hs and its extensions were built with any sort of discoverability in mind, the LS can't find most everything (even if I add the path to the extensions to the coc config... so just forget about using that)... i.e. look at require("hs.console") and go to the module and it has like 2 things and no wonder the LS doesn't find anything... it's all globals built on hs.* which is gah
-- TLDR => hs.* was not built for LS to work, you just have to know what to use (or look at docs)
-- JUST PUT hs global into lua LS config and be done with that
local start_time = hs.timer.secondsSinceEpoch()

--     hs -c 'hs.console.clearConsole()'
--     hs -c 'hs.alert.show("Hello, Stream Deck!")'
hs.ipc.cli = true -- early so hs CLI always works


require("config.helpers")


-- local streamStdout = require("config.tests.stream-stdout").streamStdout
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "S", streamStdout)

AskOpenAIStreaming = require("config.ask.ask").AskOpenAIStreaming

-- test w/ T
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
--     local result = require("config.ask.selection").getSelectedText()
--     print("result:\n ", result)
-- end)

require("config.spoons")
require("config.windows")
require("config.screencaps")
-- require("config.appKeys") -- was not working lately, TODO find out why later on

require("config.uielements")
require("config.ui_callouts")
require("config.observer")
local end_time = hs.timer.secondsSinceEpoch()
print("init.lua took", end_time - start_time, "seconds")

-- *** insignificant config last so it doesn't slow down critical startup config
--
-- FYI be careful with overhead to call every time
function ensureBool(func, value)
    -- check first, in most cases takes <1ms to check before setting
    if func() ~= value then func(value) end
end

ensureBool(hs.console.darkMode, true)
ensureBool(hs.preferencesDarkMode, true)
-- menu icon => hide to declutter menu bar, also b/c I use streamdeck button to show console
ensureBool(hs.menuIcon, true)
-- dock icon true => shows in APP SWITCHER TOO
--   set true when changing config and want to quickly change in app switcher.. then set false again when it annoys you :)
--
-- don't set this on every startup... otherwise, if I reload config w/ Hammerspoon Console window open...
--    then this hides the dock icon, thus breaking my KM macros specific to HS app
--    BTW this value is persisted and used by default when I restart Hammerspoon
--      I just don't want it to reset on reload hammerspoon config
-- ensureBool(hs.dockIcon, false) -- FYI this one is 1-2ms to check, 3+ to set ... unlike others where its fast to check (and slow to set, even if not changing the actual value)
--
-- hs.console.titleVisibility("hidden") -- hide title, but doesn't save space b/c buttons still show... why is there a fat border too below title/button bar?!
-- hs.dockIcon(false) -- hide dock icon (default false) - also shows in app switcher if true) - REMINDER ONLY... uncomment to toggle but do not set every time (nor check every time) b/c that takes 2/4ms respectively
hs.window.animationDuration = 0 -- default is 0.2 (FYI this means window layout changes don't animate, which I prefer)


-- TODO comment out when done in learning so dont slow down config otherwise
require("config.learn.axuielem") -- WIP
-- require("config.learn.coroutines")
-- require("config.learn.axuielem-observer") -- WIP
-- DONE for now: -- require("config.learn.hsapp")
-- require("config.learn.uielem")
-- require("config.learn.webview")
--

require("config.macros.init")
