-- "preload" eventtap so I don't get load message in KM shell script call to `hs -c 'AskOpenAIStreaming()'` ... that way I can leave legit output messages to show in a window (unless I encounter other
-- annoyances in which case I should turn off showing output in KM macro's action)
-- TODO how about not show loaded modules over stdout?! OR hide it when I run KM macro STDOUT>/dev/null b/c I only care about STDERR me thinks

-- ALSO move all of these here so Console messages end up consolidated in one part (at top) of log, not scattered
-- local times = require("config.times")
-- times.set_start_time()
local _et = hs.eventtap
local _json = hs.json
local _http = hs.http
local _application = hs.application
local _alert = hs.alert
local _pasteboard = hs.pasteboard
local _task = hs.task
local _axuielement = hs.axuielement
-- times.print_elapsed("preloads") -- 10ms to preload these (though this is not the motivation for preload)
local _dockicon = hs.dockicon -- for show/hide in app switcher
local _fnutils = hs.fnutils
local _spoons = hs.spoons
local _logger = hs.logger
local _drawing = hs.drawing
local _image = hs.image
local _canvas = hs.canvas
local _fs = hs.fs
local _inspect = hs.inspect
local _pw = hs.pathwatcher
local _window = hs.window
local _sd = hs.streamdeck
local _console = hs.console

