require("helpers.all")

local M = {}

function M.streamStdout()
    -- TODO what is this debug hook?
    -- debug.sethook(function(event, line)
    --     print("Debug hook triggered: " .. event .. " on line " .. tostring(line))
    -- end, "c")
    --
    -- ! keep around as a good example of streaming from a command's output (instead of http response used for ask-openai)... both are useful to recall (and this concept is somewhat novel in my automations so I don't wanna let it slip my mind)

    local function streamingHandler(_task, stdout, stderr)
        paste_text(stdout)
        -- paste_text("...")
        return true
    end
    --
    -- https://www.hammerspoon.org/docs/hs.task.html
    local task = hs.task.new("/opt/homebrew/bin/fish", function(exitCode)
        print("Task finished with exit code: " .. exitCode)
        return true
    end, streamingHandler, { "-c for i in (seq 1 10); echo -n $i;sleep 0.5; end" }) -- Arguments as a table

    task:start()
end

return M
