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

-- local function typeText(text)
--     for char in text:gmatch(".") do
--         -- hs.eventtap.keyStroke({}, char, 0)
--         hs.eventtap.keyStrokes(char)
--         hs.timer.usleep(10000)
--         -- 1k is like almost instant
--         -- 5k looks like super fast typer
--         -- 10k looks like fast typer
--         -- 20k?
--     end
-- end

local function pasteText(text)
    -- TODO if need be, can I track the app that was active when triggering the ask-openai action... so I can make sure to pass it to type into it only... would allow me to switch apps (or more important, if some other app / window pops up... wouldn't steal typing focus)
    --     hs.eventtap.keyStrokes(text[, application])
    hs.eventtap.keyStrokes(text)
end

-- "preload" eventtap so I don't get load message in KM shell script call to `hs -c 'AskOpenAIStreaming()'` ... that way I can leave legit output messages to show in a window (unless I encounter other
-- annoyances in which case I should turn off showing output in KM macro's action)
local _et = hs.eventtap
local _json = hs.json
local _http = hs.http

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "S", function()
    -- TODO what is this debug hook?
    -- debug.sethook(function(event, line)
    --     print("Debug hook triggered: " .. event .. " on line " .. tostring(line))
    -- end, "c")

    local function streamingHandler(_task, stdout, stderr)
        pasteText(stdout)
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
    end, streamingHandler, { "-c for i in (seq 1 10); echo -n $i;sleep 0.1; end" }) -- Arguments as a table

    task:start()
end)

local function getApiKey(accountName, serviceName)
    -- TODO add try catch so I don't fubar loading my init.lua config?

    local command = string.format(
        'security find-generic-password -a %s -s %s -w 2>/dev/null',
        accountName,
        serviceName
    )

    local handle = io.popen(command)
    if not handle then
        print("Error: failed to get api key - handle is nil")
        return nil
    end
    local stdout = handle:read("*a")
    if not stdout then
        print("Error: failed to get api key - stdout is nil")
        return nil
    end
    handle:close()

    -- Trim surrounding whitespace (i.e. security output has newline)
    local trimmed = stdout:match("^%s*(.-)%s*$")
    if trimmed == "" then
        print("Error: failed to get api key - trimmed is empty")
        return nil
    end

    return trimmed
end

local apiKey = getApiKey("ask", "openai")

local model = "gpt-4o"

local prompt = "Tell me a very short joke"

function AskOpenAIStreaming()
    -- test smth

    if true then
        return
    end

    -- trigger select all =>
    hs.eventtap.keyStroke({ "cmd" }, "a")
    -- trigger copy
    hs.eventtap.keyStroke({ "cmd" }, "c")
end

function Remainder()
    -- run from CLI:
    -- hs -c 'AskOpenAIStreaming()'

    -- TODO lookup ask-open service from ~/.local/share/ask/service
    -- JUST cache it on startup, cuz I can always trigger reload config for ask-openai to switch it -- ZERO latency feels best and is the goal for this rewrite
    -- TODO with streaming, it feels like gpt-4o/opeani is as fast as groq.. so impressive (also somewhat due to lower overhead - preloaded API key, similar to benefit in my wes.py iterm2 impl)

    if apiKey == nil then
        hs.alert.show("Error: No API key for ask-openai")
        return
    end

    local url = "https://api.openai.com/v1/chat/completions"
    local headers = {
        ["Authorization"] = "Bearer " .. apiKey,
        ["Content-Type"] = "application/json",
    }

    local body = hs.json.encode({
        model = model,
        messages = {
            { role = "system", content = "You are a helpful assistant." },
            { role = "user",   content = prompt },
        },
        stream = true,
        max_tokens = 100,
    })

    hs.http.asyncPost(url, body, headers, function(status, response, _)
        if status ~= 200 then
            hs.alert.show("Error: " .. status)
            return
        end

        for chunk in response:gmatch("%b{}") do
            local parsed = hs.json.decode(chunk)
            if parsed and parsed.choices then
                local delta = parsed.choices[1].delta or {}
                local text = delta.content
                if text then
                    pasteText(text)
                end
            end
        end
    end)
end
