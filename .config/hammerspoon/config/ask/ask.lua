local M = {}

local security = require("config.ask.security")
local helpers = require("config.helpers")

local apiKey = security.getSecret("ask", "openai")

local model = "gpt-4o"

function M.AskOpenAIStreaming()
    -- docs: https://www.hammerspoon.org/docs/hs.application.html#name
    -- run from CLI:
    -- hs -c 'AskOpenAIStreaming()'
    local socket = require("socket")
    local start_time = socket.gettime()

    local function print_elapsed(message)
        local elapsed_time = socket.gettime() - start_time
        print(string.format("%s: %.6f seconds", message, elapsed_time))
    end

    local app = hs.application.frontmostApplication()
    -- print_elapsed("frontmost") -- < 0.5ms
    -- todo use this to decide how to copy the current context... i.e. in AppleScript context I expect to already copy the relevant question part... whereas in devtools I just wanna grab the full command line and so I don't wanna have to select it myself...
    -- ALSO use app to select prompt!
    -- MAYBE even use context of the app (i.e. in devtools) to decide what prompt to use
    --    COULD also have diff prmopts tied to streamdeck buttons (app specific) if I find it useful to control the prompt instead of trying to guess it based on current app... (app by app basis that I care to do this for)
    -- CAREFUL NOT TO INTRODUCE A TON OF OVERHEAD HERE in app detection

    if app:name() == "iTerm2" then
        hs.alert.show("use iterm specific shortcut for ask-openai")
        return
    end
    -- print_elapsed("appname") -- < 0.5ms

    -- TODO pass app as last arg to keyStroke? does it matter for timing?
    local keystrokeDelay = 30000 -- worked: 100ms, 50ms,30m (works, can try lower)... wow we're good at even 25ms/20ms IMO
    -- FYI make sure to remove all print statements when testing delays b/c that adds overhead between keystrokes (if used) and will not be there in reality
    -- FYI 5ms sometimes worked then other times failed... 20 is NBD
    -- https://www.hammerspoon.org/docs/hs.eventtap.html#keyStroke (200ms is default keystroke delay)
    --
    -- trigger select all:
    hs.eventtap.keyStroke({ "cmd" }, "a", keystrokeDelay)
    -- trigger copy:
    hs.eventtap.keyStroke({ "cmd" }, "c", keystrokeDelay)

    -- HOW else can I copy faster? or get the text?!
    -- FYI can try applescript but I dont think that's necessary, unless issuing keystrokes is also slow, the 200 ms is artificial (potentially)
    -- can system events select all and copy for the front most app faster?


    local prompt = hs.pasteboard.getContents() -- < 0.6ms
    -- print("Prompt:", prompt)

    -- if true then
    --     return
    -- end

    -- TODO lookup ask-open service from ~/.local/share/ask/service
    -- JUST cache it on startup, cuz I can always trigger reload config for ask-openai to switch it -- ZERO latency feels best and is the goal for this rewrite
    -- TODO with streaming, it feels like gpt-4o/opeani is as fast as groq.. so impressive (also somewhat due to lower overhead - preloaded API key, similar to benefit in my wes.py iterm2 impl)

    -- start_time = socket.gettime()

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
    -- print_elapsed("json encode") -- < 0.2ms (from right before apiKey=nil check to here)

    -- print("body", body)
    -- if true then
    --     return
    -- end

    local function processChunk(chunk)
        -- TODO gmatch here in case a chunk has multiple data lines (multiple chunks)
        -- each data line is a json object
        -- TODO logic for failure to parse json?

        for data_line in chunk:gmatch("%b{}") do
            local parsed = hs.json.decode(data_line)
            if parsed and parsed.choices then
                local delta = parsed.choices[1].delta or {}
                local text = delta.content
                if text then
                    helpers.pasteText(text)
                end
            end
        end
    end

    local streamingRequest = require("config.ask.streaming_curl").streamingRequest

    start_time = socket.gettime()

    streamingRequest(url, "POST", headers, body, function(success, chunk, exitCode)
        print_elapsed("streaming request")
        -- openai takes about 280ms until first chunk (FAST!)
        -- depends on length but done by 420ms for one small test case
        if not success then
            hs.alert.show("Error in streaming request: " .. exitCode)
            print("Error:", chunk, "Exit Code:", exitCode)
        else
            print("Chunk received:", chunk)
            processChunk(chunk)
        end
        return true
    end)

    -- THIS IS NOT STREAMING the result back ... hrm does the http client not support that? or is it too fast or?
    -- if status ~= 200 then
    --     hs.alert.show("Error: " .. status)
    --     -- FYI prints just fine! shows json dump of each chunk
    --     print("Response:", response)
    --     return
    -- end
end

return M
