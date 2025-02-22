-- "preload" eventtap so I don't get load message in KM shell script call to `hs -c 'AskOpenAIStreaming()'` ... that way I can leave legit output messages to show in a window (unless I encounter other
-- annoyances in which case I should turn off showing output in KM macro's action)
-- TODO how about not show loaded modules over stdout?! OR hide it when I run KM macro STDOUT>/dev/null b/c I only care about STDERR me thinks

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
