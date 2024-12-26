local M = {}

local helpers = require("config.helpers")

local services = require("config.ask.services")
local service = services.getService()
local inspect = require("hs.inspect")
print("service", inspect(service))

function M.AskOpenAIStreaming()
    -- docs: https://www.hammerspoon.org/docs/hs.application.html#name
    -- run from CLI:
    -- hs -c 'AskOpenAIStreaming()'

    -- local socket = require("socket")
    -- local start_time = socket.gettime()
    --
    -- local function print_elapsed(message)
    --     local elapsed_time = socket.gettime() - start_time
    --     print(string.format("%s: %.6f seconds", message, elapsed_time))
    -- end

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
    -- TODO why not clear clipboard and wait for it to be set, instead of fixed delay? do this if you further want to optimize timing
    -- trigger select all:
    hs.eventtap.keyStroke({ "cmd" }, "a", keystrokeDelay)
    -- trigger cut: (feels much faster b/c of change in screen contents) static screen contents is gonna feel slower (even if its not)...
    --    might also be faster to paste w/o having selection... PRN time it to see if initial paste is net faster w/ cut vs copy
    -- FYI cut vs copy requires double undo to get back to original prompt to retry, NBD but a slight downside
    hs.eventtap.keyStroke({ "cmd" }, "x", keystrokeDelay)

    local prompt = hs.pasteboard.getContents() -- < 0.6ms
    -- print("Prompt:", prompt)

    -- if true then
    --     return
    -- end

    -- TODO lookup ask-open service from ~/.local/share/ask/service
    -- JUST cache it on startup, cuz I can always trigger reload config for ask-openai to switch it -- ZERO latency feels best and is the goal for this rewrite
    -- TODO with streaming, it feels like gpt-4o/opeani is as fast as groq.. so impressive (also somewhat due to lower overhead - preloaded API key, similar to benefit in my wes.py iterm2 impl)

    -- start_time = socket.gettime()

    if service == nil or service.api_key == nil then
        hs.alert.show("Error: No API key for ask-openai, or service config is invalid")
        return
    end

    local url = service.base_url

    local headers = {
        ["Authorization"] = "Bearer " .. service.api_key,
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
        model = service.model,
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

    -- start_time = socket.gettime()
    local function completeCallback(exitCode, stdout, stderr)
        if exitCode ~= 0 then
            -- test this: ollama set invalid url (delete c in completion)... then curl w/ -fsSL will use STDERR to print error and that is detected here! ... fyi non-zero exit code is also picked up in complete callback which is fine (shown twice, NBD)
            -- print_elapsed("complete callback")
            -- GOOD TEST CASE use ollama and make sure its not running! works nicely as is:
            hs.alert.show("Error in streaming request: " .. exitCode .. " see hammerspoon console logs")
            if stderr ~= "" then
                print("completeCallback - STDERR: ", stderr)
            end
            if stdout ~= "" then
                print("completeCallback - STDOUT: ", stdout)
            end
            print("completeCallback - Exit Code:", exitCode)
        end
        -- TODO if STDERR not empty?
        -- should all output go to streaming callback unless I return false in it?
        return true
    end

    local function streamingCallback(task, stdout, stderr)
        if stderr ~= "" then
            -- print_elapsed("streaming callback")
            -- GOOD TEST CASE use ollama and make sure its not running! works nicely as is:
            hs.alert.show("Error in streaming request: " .. stderr .. " see hammerspoon console logs")
            if stdout ~= "" then
                print("streamingCallback - STDOUT: ", stdout)
            end
            if stderr ~= "" then
                print("streamingCallback - STDERR: ", stderr)
            end

            -- TODO should I still try to process the chunk?
            return false
        end

        -- print("Chunk received:", chunk)
        --
        -- interesting that at this point, the prints don't get routed to the KM window that pops up...
        processChunk(stdout)

        -- FTR when I wasn't checking stderr and not passing -fsSL to curl, there was a stdout error object for ollama API if model is invalid, might want to parse that too or instead of stderr/-fsSL (-fsS part causes diff error handling)...
        -- {"error":{"message":"model \"llama-3.2:3b\" not found, try pulling it first","type":"api_error","param":null,"code":null}}
        --   IS THIS A UNIFORM FORMAT (assuming request itself doesn't fail)?


        return true -- continue streaming, false would result in rest going to final callback (IIUC)
    end

    streamingRequest(url, "POST", headers, body, streamingCallback, completeCallback)

    -- THIS IS NOT STREAMING the result back ... hrm does the http client not support that? or is it too fast or?
    -- if status ~= 200 then
    --     hs.alert.show("Error: " .. status)
    --     -- FYI prints just fine! shows json dump of each chunk
    --     print("Response:", response)
    --     return
    -- end
end

return M
