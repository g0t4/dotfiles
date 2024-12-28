--
-- *** ESSENTIAL DOCS: https://www.hammerspoon.org/docs/
-- FYI it doesn't seem like the API for hs and its extensions were built with any sort of discoverability in mind, the LS can't find most everything (even if I add the path to the extensions to the coc config... so just forget about using that)... i.e. look at require("hs.console") and go to the module and it has like 2 things and no wonder the LS doesn't find anything... it's all globals built on hs.* which is gah
-- TLDR => hs.* was not built for LS to work, you just have to know what to use (or look at docs)
-- JUST PUT hs global into lua LS config and be done with that
local start_time = os.clock()

-- config console:
-- https://www.hammerspoon.org/docs/hs.console.html
hs.console.darkMode(true)
-- hs.console.titleVisibility("hidden") -- hide title, but doesn't save space b/c buttons still show... why is there a fat border too below title/button bar?!

-- ensure IPC so `hs` cli works
--     hs -c 'hs.console.clearConsole()'
--     hs -c 'hs.alert.show("Hello, Stream Deck!")'
hs.ipc.cli = true

local streamStdout = require("config.tests.stream-stdout").streamStdout
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "S", streamStdout)

AskOpenAIStreaming = require("config.ask.ask").AskOpenAIStreaming

-- test w/ T
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
    local result = require("config.ask.selection").getSelectedText()
    print("result:\n ", result)
end)

local inspect = require("hs.inspect")





hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "W", function()
    -- https://www.hammerspoon.org/docs/hs.window.html
    local window = hs.window.focusedWindow()
    -- window:focus()
    -- window:maximize()
    print("window", inspect(window:topLeft().x))
    if (window:topLeft().x == 0 and window:topLeft().y == 0) then
        window:setTopLeft({ x = 400, y = 400 })
    else
        window:setTopLeft({ x = 0, y = 0 })
    end
end)



hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", function()
    local mouse = require("hs.mouse")
    local pos = mouse.absolutePosition()
    print("mouse pos", inspect(pos))

    local canvas = require("hs.canvas")
    local width = 50
    local rect = canvas.new({ x = pos.x - width / 2, y = pos.y - width / 2, w = width, h = width })
        :appendElements({
            action = "stroke",
            padding = 0,
            type = "rectangle",
            fillColor = { red = 1, blue = 0, green = 0 },
            strokeColor = { red = 1, blue = 0, green = 0 },
            strokeWidth = 8,
        }):show()

    -- local timer = hs.timer.doAfter(3, function()
    --     rect:delete()
    --     print("rect deleted")
    -- end)
    -- timer:start()
end)

-- *** load spoons from the repo so I can clone and update it using git and not one by one "install"
--    alternatively use spoonInstall?
--    I did a diff of AClock and Source/AClock.spoon and it matched, maybe others won't?
local spoons_repo = os.getenv("HOME") .. "/repos/github/Hammerspoon/Spoons/Source/?.spoon/init.lua"
package.path = package.path .. ";" .. spoons_repo

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "C", function()
    hs.loadSpoon("AClock")
    spoon.AClock:toggleShow()
end)

require("config.windows")

-- hs.loadSpoon("HSearch")
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "F", function()
--     spoon.HSearch:toggleShow()
-- end)

require("config.appKeys")

local end_time = os.clock()
print("init.lua took", end_time - start_time, "seconds")
