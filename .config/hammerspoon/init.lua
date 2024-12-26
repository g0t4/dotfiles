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

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "S", function()
    -- TODO what is this debug hook?
    -- debug.sethook(function(event, line)
    --     print("Debug hook triggered: " .. event .. " on line " .. tostring(line))
    -- end, "c")
    --
    -- ! keep around as a good example of streaming from a command's output (instead of http response used for ask-openai)... both are useful to recall (and this concept is somewhat novel in my automations so I don't wanna let it slip my mind)

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

local security = require("config.ask.security")
local helpers = require("config.helpers")

local apiKey = security.getSecret("ask", "openai")

local model = "gpt-4o"

function AskOpenAIStreaming()
    -- docs: https://www.hammerspoon.org/docs/hs.application.html#name
    -- run from CLI:
    -- hs -c 'AskOpenAIStreaming()'


    local app = hs.application.frontmostApplication()
    -- todo use this to decide how to copy the current context... i.e. in AppleScript context I expect to already copy the relevant question part... whereas in devtools I just wanna grab the full command line and so I don't wanna have to select it myself...
    -- ALSO use app to select prompt!
    -- MAYBE even use context of the app (i.e. in devtools) to decide what prompt to use
    --    COULD also have diff prmopts tied to streamdeck buttons (app specific) if I find it useful to control the prompt instead of trying to guess it based on current app... (app by app basis that I care to do this for)

    if app:name() == "iTerm2" then
        hs.alert.show("use iterm specific shortcut for ask-openai")
        return
    end

    -- if true then
    --     return
    -- end

    -- trigger select all =>
    hs.eventtap.keyStroke({ "cmd" }, "a")
    -- trigger copy
    hs.eventtap.keyStroke({ "cmd" }, "c")
    -- get prompt from clipboard:
    local prompt = hs.pasteboard.getContents()

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

    local system_message = [[
You are a chrome devtools expert.
The user is working in the devtools Console in the Brave Beta Browser.
The user needs help completing a javascript command.
Whatever they have typed into the Console's command line will be provided to you.
They might also have a free-form question included, i.e. in a comment (after //).
Respond with a single, valid javascript command line. Their command line will be replaced with your response. So they can review and execute it.
No explanation. No markdown. No markdown with backticks ` nor ```.

An example of a command line could be `find the first div on the page` and a valid response would be `document.querySelector('div')`
]]

    local body = hs.json.encode({
        model = model,
        messages = {
            { role = "system", content = system_message },
            { role = "user",   content = prompt },
        },
        stream = true,
        max_tokens = 200,
    })

    -- print("body", body)
    -- if true then
    --     return
    -- end


    hs.http.asyncPost(url, body, headers, function(status, response, _)
        if status ~= 200 then
            hs.alert.show("Error: " .. status)
            -- FYI prints just fine! shows json dump of each chunk
            print("Response:", response)
            return
        end

        -- TODO is it necessary to gmatch here... IIRC each chunk is its own line.. maybe this callback is invoked with multiple lines in some cases... if so, then it makes sense to do this (also doesn't appear to hurt, thus far)
        for chunk in response:gmatch("%b{}") do
            local parsed = hs.json.decode(chunk)
            if parsed and parsed.choices then
                local delta = parsed.choices[1].delta or {}
                local text = delta.content
                if text then
                    helpers.pasteText(text)
                end
            end
        end
    end)
end
