local M = {}
local prompts = require("config.ask.prompts")
local services = require("config.ask.services")
local service = services.getService()
-- FYI need to restart HS if I wanna change services (rare so thats fine), good thing is the service is cached and not more overhead per use of ask!

local inspect = require("hs.inspect")
print("service", inspect(services.logSafeService(service)))


local selection = require("config.ask.selection")

function M.AskOpenAIStreaming()
    local app = hs.application.frontmostApplication() -- < 0.5ms
    -- MAYBE even use context of the app (i.e. in devtools) to decide what prompt to use
    --    COULD also have diff prmopts tied to streamdeck buttons (app specific) if I find it useful to control the prompt instead of trying to guess it based on current app... (app by app basis that I care to do this for)

    if app:name() == "iTerm2" then
        -- app:name() is < 0.5ms
        hs.alert.show("use iterm specific shortcut for ask-openai")
        return
    end
    -- TODO use app to select prompt!
    -- TODO "Script Debugger"
    -- TODO "Script Editor"
    -- TODO "Microsoft Excel"

    local prompt = selection.getSelectedText()
    if prompt == "" then
        hs.alert.show("No selection found, try again...")
        return
    end

    -- if true then
    --     return
    -- end

    if service == nil or service.api_key == nil then
        hs.alert.show("Error: No API key for ask-openai, or service config is invalid")
        return
    end

    local url = service.base_url

    local headers = {
        ["Authorization"] = "Bearer " .. service.api_key,
        ["Content-Type"] = "application/json",
    }

    local body = hs.json.encode({
        model = service.model,
        messages = {
            { role = "system", content = prompts.getPrompt(app) },
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
                    hs.eventtap.keyStrokes(text, app) -- app param is optional
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
