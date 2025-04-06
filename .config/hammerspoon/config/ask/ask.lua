local M = {}
local prompts = require("config.ask.prompts")
local services = require("config.ask.services")
local service = services.getService()
-- FYI need to restart HS if I wanna change services (rare so thats fine), good thing is the service is cached and not more overhead per use of ask!

-- print("service", hs.inspect(services.logSafeService(service)))

require("config.ask.preloads") -- optional

local selection = require("config.ask.selection")

function M.AskOpenAIStreaming()
    local app = hs.application.frontmostApplication() -- < 0.5ms
    -- MAYBE even use context of the app (i.e. in devtools) to decide what prompt to use
    --    COULD also have diff prmopts tied to streamdeck buttons (app specific) if I find it useful to control the prompt instead of trying to guess it based on current app... (app by app basis that I care to do this for)

    if app:name() == APPS.iTerm then
        -- app:name() is < 0.5ms
        hs.alert.show("use iterm specific shortcut for ask-openai")
        return
    end

    selection.getSelectedTextThen(function(selectedText)
        foundUserPrompt(selectedText, app)
    end)
end

local box = nil
local boxBindings = {}

local function removeBox()
    if not box then
        return
    end
    box:delete()
    box = nil
end

local function stopBox()
    removeBox()
    for _, binding in pairs(boxBindings) do
        binding:delete()
    end
    boxBindings = {}
end

function AskOpenAICompletionBox()
    local app = hs.application.frontmostApplication() -- < 0.5ms

    selection.getSelectedTextThen(function(selectedText, element)
        local entireResponse = ""
        foundUserPrompt(selectedText, app, function(textChunk)
            entireResponse = entireResponse .. textChunk

            if element then
                local frame = element:axFrame()
                local screenFrame = hs.screen.mainScreen():frame()

                local styledResponseText = hs.styledtext.new(entireResponse, {
                    font = {
                        name = "SauceCodePro Nerd Font",
                        size = 16
                    },
                    color = { white = 1 },
                })
                ---@type { w: number, h: number } | nil
                local specifierSize = hs.drawing.getTextDrawingSize(styledResponseText)

                -- add padding (don't subtract it from needed width/height)
                local padding = 5
                local tooltipWidth = math.max(specifierSize.w) + 2 * padding
                local tooltipHeight = specifierSize.h + 2 * padding
                -- TODO min width/height so its not jerky?
                --   base min width on width of focused control?

                -- Initial positioning (slightly below the element)
                local x = frame.x
                local y = frame.y + frame.h + 5 -- Below the element

                -- Ensure tooltip does not go off the right edge
                if x + tooltipWidth > screenFrame.x + screenFrame.w then
                    x = screenFrame.x + screenFrame.w - tooltipWidth - 10 -- Shift left
                    -- IIUC the box is positioned to right of element left side so I don't think I need to worry about x being shifted left of screen
                end

                -- Ensure tooltip does not go off the bottom edge
                if y + tooltipHeight > screenFrame.y + screenFrame.h then
                    -- if it's off the bottom, then move it above the element
                    y = frame.y - tooltipHeight - 5 -- Move above element
                    if y < screenFrame.y then
                        -- if above is also off screen, then shift it down, INSIDE the frame
                        --   means it stays on top btw... could put it inside on bottom too
                        y = screenFrame.y + 10 -- Shift up
                    end
                end

                if box then box:delete() end
                box = hs.canvas
                    .new({ x = x, y = y, w = tooltipWidth, h = tooltipHeight, })

                box:appendElements({
                    {
                        type = "rectangle",
                        -- todo round cornders
                        roundedRectRadii = { xRadius = 5, yRadius = 5 },
                        frame = { x = 0, y = 0, w = tooltipWidth, h = tooltipHeight },
                        fillColor = { hex = "#002040" },
                        strokeColor = nil,
                    },
                    {
                        type = "text",
                        text = styledResponseText,
                        frame = { x = padding, y = padding, w = tooltipWidth - 2 * padding, h = specifierSize.h },
                    },
                })
                box:show()

                table.insert(boxBindings, hs.hotkey.bind({}, "escape", stopBox))
                -- PRN add other bindings, i.e. to refresh or get new response ... need that to be on keystroke :)
                -- oh holy crap... I can have it open on a button and then on every keystroke it will refersh! using this right here binding
            end
        end)
    end)
end

function foundUserPrompt(userPrompt, app, appendChunk)
    if userPrompt == "" then
        hs.alert.show("No selection found, try again...")
        return
    end

    if service == nil or service.api_key == nil then
        hs.alert.show("Error: No API key for ask-openai, or service config is invalid")
        return
    end

    local headers = {
        ["Authorization"] = "Bearer " .. service.api_key,
        ["Content-Type"] = "application/json",
    }

    local appParameters = prompts.getPrompt(app)
    if appParameters == nil then
        print("Error: unknown app - no prompt available: " .. app:name())
        hs.alert.show("Error: unknown app - no prompt available: " .. app:name())
        return
    end

    local body = hs.json.encode({
        model = service.model,
        messages = {
            { role = "system", content = appParameters.systemMessage },
            { role = "user",   content = userPrompt },
        },
        stream = true,
        max_tokens = appParameters.max_tokens,
    })

    local IS_LOGGING = false
    local chunkLog = nil
    if IS_LOGGING then
        chunkLog = io.open(os.getenv("HOME") .. "/.hammerspoon/tmp/ask-openai-streaming-chunk-log.txt", "w")
    end

    local function logMessage(message)
        if chunkLog then
            chunkLog:write(message)
            chunkLog:flush()
        end
    end

    local function logClose()
        if chunkLog then
            chunkLog:close()
        end
    end
    -- FYI double check logged lines with:
    --    cat ask-openai-streaming-chunk-log.txt | grep '^\s*data:' | cut -c7- | jq ".choices[] | .delta.content " -r
    --      make sure to log only once and with matching data: prefix

    appendChunk = appendChunk or function(textChunk)
        hs.eventtap.keyStrokes(textChunk, app) -- app param is optional
    end

    local function processChunk(chunk)
        -- stream response is data only SSEs:
        --   https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#event_stream_format
        --   https://cookbook.openai.com/examples/how_to_stream_completions
        --   message == event
        --   messages separated by \n\n
        --   `data: ` prefix on each message
        --   `:` for comments are part of format, but no mention of using those in the docs

        -- so, each chunk can have 0+ data messages
        -- TODO is last message always followed by \n\n? (of each chunk and last of response?)
        for dataMessage in chunk:gmatch("data:.-\n\n") do
            -- strip data: prefix to extract data value
            local dataValue = dataMessage:gsub("data: ", "")

            -- check if it starts with data: [DONE], use regex to ignore whitespace diffs
            if dataValue:match("^%s*%[DONE%]%s*$") then
                -- IIUC this is openai specific? not sure why but it's coming back at end of response
                if IS_LOGGING then
                    print("DONE detected")
                end
                break
            end

            local sse = hs.json.decode(dataValue)
            if sse and sse.choices then
                local delta = sse.choices[1].delta or {}
                local text = delta.content
                if text then
                    appendChunk(text)
                end

                -- TODO
                -- handle:       "finish_reason":"stop"}
                --     this is on choices (need to set a flag and stop processing the rest?)
                --     currently parses ok but no choices, effectively ignored...
                -- handle:       data: [DONE]
                --     this comes after stop reason (at least from openai)
                --     no idea why this would be returned, it's not valid JSON?
            else
                print("Error: failed to parse json (or no choices) for dataMessage", dataMessage)
            end
        end
        -- PRN find a library to do this OR split out a testable lib of my own

        -- PROMPTS:
        -- - complex response w/ curly braces:
        --     how can I write an async function with await and sleep 2 seconds
        -- - simple:
        --     what is my user agent?
    end

    local streamingRequest = require("config.ask.streaming_curl").streamingRequest

    -- start_time = socket.gettime()
    local function completeCallback(exitCode, stdout, stderr)
        logMessage("## completeCallback\n")
        logMessage("exitCode: " .. exitCode .. "\n")
        logMessage("stdout:\n" .. stdout .. "\n")
        logMessage("stderr:\n" .. stderr .. "\n")
        logMessage("## end completeCallback\n")
        logClose()

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
        logMessage("## streamingCallback\n")
        logMessage("stdout:\n" .. stdout .. "\n")
        logMessage("stderr:\n" .. stderr .. "\n")
        logMessage("## end streamingCallback\n")

        if stderr ~= "" then
            -- print_elapsed("streaming callback")
            -- GOOD TEST CASE use ollama and make sure its not running!
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

        processChunk(stdout)

        -- FTR when I wasn't checking stderr and not passing -fsSL to curl, there was a stdout error object for ollama API if model is invalid, might want to parse that too or instead of stderr/-fsSL (-fsS part causes diff error handling)...
        -- {"error":{"message":"model \"llama-3.2:3b\" not found, try pulling it first","type":"api_error","param":null,"code":null}}

        return true -- continue streaming, false would result in rest going to final callback (IIUC)
    end

    streamingRequest(service.url, "POST", headers, body, streamingCallback, completeCallback)
end

return M
