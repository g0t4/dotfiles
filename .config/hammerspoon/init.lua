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

local function pasteText(text)
    hs.eventtap.keyStrokes(text)
end

-- local function typeText(text)
--     for char in text:gmatch(".") do
--         hs.eventtap.keyStroke({}, char, 0)
--         -- hs.timer.usleep(50000) -- Small delay to simulate human typing (~20 characters per second)
--     end
-- end


-- run from CLI:
-- hs -c 'askOpenAIStreaming()'
function askOpenAIStreaming()
    -- hs.alert.show("Hello from the CLI!")
    pasteText("Hellofoo")
end


hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "S", function()
    -- hs.alert.show("Streaming pastes...")
    -- log starting:
    -- debug.sethook(function(event, line)
    --     print("Debug hook triggered: " .. event .. " on line " .. tostring(line))
    -- end, "c")

    local function streamingHandler(_task, stdout, stderr)
        typeText(stdout)
        -- TODO stderr?
        -- if stdout and stdout ~= "" then
        --     print("STDOUT: " .. stdout)
        -- end
        -- if stderr and stderr ~= "" then
        --     print("STDERR: " .. stderr)
        -- end
        return true
    end
    --
    -- https://www.hammerspoon.org/docs/hs.task.html
    local task = hs.task.new("/opt/homebrew/bin/fish", function(exitCode)
        print("Task finished with exit code: " .. exitCode)
        return true
    end, streamingHandler, { "-c for i in (seq 1 10); echo $i;sleep 1; end" }) -- Arguments as a table

    task:start()

    -- local file = io.popen("ls")
    -- for line in file:lines() do
    --     -- print(line)
    --     -- hs.eventtap.keyStrokes(line)
    -- end
    -- file:close()
end)



-- FYI moved to just streamdeck button for this so I don't take up a hotkey
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
--     hs.reload()
-- end)
