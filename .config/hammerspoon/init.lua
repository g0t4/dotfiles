--
-- *** ESSENTIAL DOCS: https://www.hammerspoon.org/docs/
-- FYI it doesn't seem like the API for hs and its extensions were built with any sort of discoverability in mind, the LS can't find most everything (even if I add the path to the extensions to the coc config... so just forget about using that)... i.e. look at require("hs.console") and go to the module and it has like 2 things and no wonder the LS doesn't find anything... it's all globals built on hs.* which is gah
-- TLDR => hs.* was not built for LS to work, you just have to know what to use (or look at docs)
-- JUST PUT hs global into lua LS config and be done with that

-- config console:
-- https://www.hammerspoon.org/docs/hs.console.html
hs.console.darkMode(true)

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


hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "C", function()
    hs.loadSpoon("AClock")
    spoon.AClock:toggleShow()
end)

hs.loadSpoon("WinWin")
hs.hotkey.bind({ "cmd", "shift", "ctrl" }, "Right", function()
    spoon.WinWin:moveToScreen("right")
end)
hs.hotkey.bind({ "cmd", "shift", "ctrl" }, "Left", function()
    -- now I can do left too (bettersnap only had cycle displays key)
    spoon.WinWin:moveToScreen("left")
end)

hs.loadSpoon("WindowHalfsAndThirds")
spoon.WindowHalfsAndThirds:bindHotkeys({

    -- TODO use diff win spoon for move to diff monitor/display
    -- https://www.hammerspoon.org/Spoons/WinWin.html

    -- TOGGLES max / restore!!! YES
    max_toggle = {
        { "cmd", "alt", "ctrl" },
        -- up
        "Up",
    },

    -- *** HABITUATE
    -- revert window change!!
    undo = {
        { "cmd", "alt", "ctrl" },
        "Z",
    },

    -- halves:
    left_half = {
        { "cmd", "shift" },
        "Left",
    },
    right_half = {
        { "cmd", "shift" },
        "Right",
    },
    top_half = {
        { "cmd", "shift" },
        "Up",
    },
    bottom_half = {
        { "cmd", "shift" },
        "Down",
    },

    -- quarters:
    top_left = {
        { "cmd", "shift", "ctrl" },
        "Pad7",
    },
    top_right = {
        { "cmd", "shift", "ctrl" },
        "Pad8",
    },
    bottom_left = {
        { "cmd", "shift", "ctrl" },
        "Pad4",
    },
    bottom_right = {
        { "cmd", "shift", "ctrl" },
        "Pad5",
    },

    -- For now, I don't think I will need these, esp b/c left/right above has three sizes each to adjust and that sounds good enough for what I might use thirds for
    --
    -- -- thirds:
    -- left_third = {
    --     { "cmd", "shift", "ctrl" },
    --     "Pad1",
    -- },
    -- right_third = {
    --     { "cmd", "shift", "ctrl" },
    --     "Pad2",
    -- },
    -- FYI I do not see a middle third binding?

})

hs.loadSpoon("Emojis")
spoon.Emojis:bindHotkeys({
    toggle = {
        { "cmd", "alt", "ctrl" },
        "E",
    }
})


-- hs.loadSpoon("HSearch")
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "F", function()
--     spoon.HSearch:toggleShow()
-- end)
