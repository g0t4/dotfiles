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

-- "preload" eventtap so I don't get load message in KM shell script call to `hs -c 'AskOpenAIStreaming()'` ... that way I can leave legit output messages to show in a window (unless I encounter other
-- annoyances in which case I should turn off showing output in KM macro's action)
-- TODO how about not show loaded modules over stdout?! OR hide it when I run KM macro STDOUT>/dev/null b/c I only care about STDERR me thinks
local _et = hs.eventtap
local _json = hs.json
local _http = hs.http
local _application = hs.application
local _alert = hs.alert
local _pasteboard = hs.pasteboard
local _task = hs.task

local streamStdout = require("config.tests.stream-stdout").streamStdout
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "S", streamStdout)

AskOpenAIStreaming = require("config.ask.ask").AskOpenAIStreaming

-- OMG I can return both the selection AND the value of the textbox... WITHOUT using the clipboard at FUCKING ALL
-- AND THIS APPEARS TO PERFORM at least somewhat well
--
function GetSelectedText()
    local socket = require("socket")
    local start_time = socket.gettime()

    local function print_elapsed(message)
        local elapsed_time = socket.gettime() - start_time
        print(string.format("%s: %.6f seconds", message, elapsed_time))
    end

    -- Access the currently focused UI element
    -- ~10ms first call
    --   then <1ms on back to back calls
    --   max was 25ms one time... still less than 30ms just to select text with keystroke!!!
    local focusedElement = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    print_elapsed("focusedElement")
    -- print("focusedElement", focusedElement)

    if focusedElement then
        local selectedText = focusedElement:attributeValue("AXSelectedText") -- < 0.4ms !!
        print_elapsed("AXSeelctedText")

        if selectedText and selectedText ~= "" then
            return selectedText
        else
            -- print("No selection or unsupported element.")
            local value = focusedElement:attributeValue("AXValue")
            print_elapsed("AXValue")
            return value
        end
    else
        return "No focused element."
    end
end

-- test w/ T
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
    local result = GetSelectedText()
    -- print("result", result)
end)
