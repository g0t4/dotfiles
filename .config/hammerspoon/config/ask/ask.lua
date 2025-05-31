local M = {}
local prompts = require("config.ask.prompts")
local services = require("config.ask.services")
local observe = require("config.ask.observe") -- side effects
local service = services.getService()
-- FYI need to restart HS if I wanna change services (rare so thats fine), good thing is the service is cached and not more overhead per use of ask!

-- print("service", hs.inspect(services.logSafeService(service)))

require("config.ask.preloads") -- optional

--- mostly push this under a rug to keep the notes together for alternatives
--- nothing wrong w/ inlining one approach if that makes it easier to avoid bugs with neighboring code
local function selectTextToReplaceIt()
    -- IDEA: if you have timing issues, use a doLater/setTimeout style delay for subsequent steps to ensure event loop clears in between

    --
    -- FYI both methods (cmd+a,menu)are deferred, IOTW cannot rely on the text to be selected until later
    --   after the current callstack runs to completion
    hs.eventtap.keyStroke({ "cmd" }, "a", 0) -- 0ms delay b/c by the time we get any response will be way long enoughk

    -- alternative (pass app for this):
    -- local selected = app:selectMenuItem({ "Edit", "Select All" })
    -- if (not selected) then
    --     print("failed to select all")
    --     return
    -- end


    -- FYI might be an approach to immediately change selection... if not readonly:
    -- appElem_FocusedUIElement.AXSelectedTextRange = { 0, #appElem_FocusedUIElement.AXValue }
    -- it didn't error but it didnt do it yet either... and I don't need this now so I am stopping for now
end

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

    selection.getSelectedTextThen(function(selectedText, focusedElem)
        askAbout(selectedText, app, focusedElem)
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
    observe.stopObserving()
    removeBox()
    for _, binding in pairs(boxBindings) do
        binding:delete()
    end
    boxBindings = {}
end

function adjustBoxElement(focusedElement, app, callback)
    if APPS.BraveBrowserBeta ~= app:name() then
        callback(focusedElement)
        return
    end
    if focusedElement:attributeValue("AXDescription") == "Console prompt" then
        -- print("FYI you didn't need adjustBoxElement... do you ever use it?")
        -- FYI if this is working here... then get rid of all of this "adjustBoxElement" code...
        -- already have what I need
        callback(focusedElement)
        return
    end
    hs.alert.show("using adjustBoxElement, heads up cuz I suspect I won't need this code anymore")

    -- FYI this works for Brave right now, it's a hack hack hack but I dont give a F

    -- FYI AXTextArea worked to get closer! ... now if I can combine with checkElem to ensure its the right one
    local criteriaFirstTextAreaSeemsToBeDumbLuck = { attribute = "AXRole", value = "AXTextArea" }
    local appElem = hs.axuielement.applicationElement(app)

    function isFirstTextArea_ThisWorks(cElem)
        -- FYI I bet I could optimize this by moving it to c? look at what searchCriteriaFunction factory method does with criteria object
        --
        if cElem:attributeValue("AXRole") ~= "AXTextArea" then
            return false
        end
        -- hrm this found AXTextArea really fast... I wonder if order is somehow based on focused elements and that is why?
        --    also wondering if restart pooches this pathway :) as it took 22s to do the same but I might not have been focused then
        -- PrintAttributes(cElem)
        -- attrs from the one that matches right now... in case I need to find it in future:

        -- *** devtools input control that I directly want to target!!!
        -- TODO! try targeting in selection.lua instead of DevTools intermediate!!! can fallback to DevTools if say this one isn't findable?
        -- app:window(1):group(1):group(1):group(1):group(1):scrollArea(1):webArea(1):group(1):group(1):group(1):group(1):group(1)
        --   :group(1):group(1):group(1):group(2):group(1):group(1):group(2):group(1):group(1):group(1):group(1):group(1):group(1)
        --   :group(1):group(1):group(2):group(2):group(1):group(1):group(1):group(2):textArea(1)
        --
        -- AXBlockQuoteLevel: 0<number>
        -- AXDOMClassList: [
        --   1: cm-content<string>
        --   2: cm-lineWrapping<string>
        -- ]
        -- AXDescription: Console prompt<string>
        -- AXEditableAncestor: AXTextArea '' - Console prompt<hs.axuielement>
        -- AXElementBusy: false<bool>
        -- AXEnabled: true<bool>
        -- AXEndTextMarker: <hs.axuielement.axtextmarker>
        -- AXFocusableAncestor: AXTextArea '' - Console prompt<hs.axuielement>
        -- AXFocused: true<bool>
        -- AXHighestEditableAncestor: AXTextArea '' - Console prompt<hs.axuielement>
        -- AXInvalid: false<string>
        -- AXLinkedUIElements: []
        -- AXRequired: false<bool>
        -- AXRoleDescription: text entry area<string>
        -- AXSelected: false<bool>
        -- AXSelectedRows: []
        -- AXSelectedTextMarkerRange: <hs.axuielement.axtextmarkerrange>
        -- AXStartTextMarker: <hs.axuielement.axtextmarker>
        -- AXValue: print foo<string>
        -- AXValueAutofillAvailable: false<bool>
        -- AXVisited: false<bool>
        -- ChromeAXNodeId: 448101<string>
        --
        -- unique ref: app:window('DevTools - www.hammerspoon.org/docs/ - wes private')
        --   :group('DevTools - www.hammerspoon.org/docs/ - wes private'):group(''):group(''):group(''):scrollArea('')
        --   :webArea('DevTools'):group('')
        --
        -- AXSelectedTextRanges	{ { length = 9, location = 0 } }
        if cElem:attributeValue("AXDescription") ~= "Console prompt" then
            return false
        end

        return true
    end

    -- TODO s/b using focusedElement to narrow search... but using app is like 10x faster, must b/c smth to do with the focused input box?!
    --   anyways for now leave it, it works using app to find right next to the input box and I'm cool with that
    --   FYI if you dont find exactly the textarea you want or nearby enough, check what you do find for Editable attribute refs that might point at the text box from this first one
    FindOneElement(appElem, isFirstTextArea_ThisWorks, function(_message, results, numResults)
        if not results then
            callback(focusedElement)
            return
        end
        callback(results[1])
    end)

    -- TODO I could be doing this in the background while the response is starting...
    --   show box once it is found AND have at least one chunk of text in response
    --   then join and wait on both finishing
end

function AskOpenAICompletionBox()
    local app = hs.application.frontmostApplication() -- < 0.5ms

    selection.getSelectedTextThen(function(selectedText, focusedElem)
        adjustBoxElement(focusedElem, app, function(element)
            local entireResponse = ""
            askAbout(selectedText, app, focusedElem, function(textChunk)
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

                    if #boxBindings == 0 then
                        function acceptBox()
                            -- Stop subscription too (and resume after?)
                            observe.skip = true
                            print("accepting")
                            selectTextToReplaceIt()
                            hs.eventtap.keyStrokes(entireResponse)
                            observe.skip = false
                        end

                        table.insert(boxBindings, hs.hotkey.bind({}, "escape", stopBox))
                        table.insert(boxBindings, hs.hotkey.bind({ "cmd", "alt", "ctrl" }, hs.keycodes.map["return"], acceptBox))
                        -- TODO enable observer mode :) use AXObserver and real time complete it!
                        -- oh holy crap... I can have it open on a button and then on every keystroke it will refersh! using this right here binding
                    end
                end
            end)
        end)
    end)
end

function askAbout(userText, app, focusedElem, appendChunk)
    if userText == "" then
        hs.alert.show("No user text found...")
        return
    end

    if service == nil or service.api_key == nil then
        hs.alert.show("Error: missing service config and/or API key")
        return
    end

    local headers = {
        ["Authorization"] = "Bearer " .. service.api_key,
        ["Content-Type"] = "application/json",
    }

    local params = prompts.getAppSpecificParams(app, focusedElem)
    if params == nil then
        -- PRN automatic params? build system prompt off of app:name() and name of input box and then formulate a generic prompt?
        --   and treat getAppSpecificPromptAndParameters as an override?
        print("Error: unknown app - no prompt available: " .. app:name())
        hs.alert.show("Error: unknown app - no prompt available: " .. app:name())
        return
    end

    local body = hs.json.encode({
        model = service.model,
        messages = {
            { role = "system", content = params.systemMessage },
            { role = "user",   content = userText },
        },
        stream = true,
        max_tokens = params.max_tokens,
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

    -- TODO review prompts for when an extra end appears (i.e. in AppleScript, and/or extra/missing ) in JavaScript... must be smth in my prompt that's confusing)
    logMessage(body)

    if appendChunk == nil then
        -- TODO rewrite this to be a pre-handler of sorts? or move it out of this spot?
        selectTextToReplaceIt()
    end

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
            if sse and sse.choices and sse.choices[1] then
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

    ---@type hs.task|nil
    local myTask = nil

    -- start_time = socket.gettime()
    local function completeCallback(exitCode, stdout, stderr)
        if myTask and myTask:terminationStatus() then
            -- bail if terminated
            return true
        end

        logMessage("## completeCallback\n")
        logMessage("exitCode: " .. exitCode .. "\n")
        logMessage("stdout:\n" .. stdout .. "\n")
        logMessage("stderr:\n" .. stderr .. "\n")
        logMessage("## end completeCallback\n")
        logClose()

        if exitCode ~= 0 then
            -- test this: ollama set invalid url (delete c in completion)... then curl with --fail-with-body and see if can capture the error
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
        if myTask and myTask:terminationStatus() then
            -- bail if terminated
            return true
        end

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

        -- FTR when I wasn't checking stderr there was a stdout error object for ollama API if model is invalid, might want to parse that too, esp now that I am using --fail-with-body instead of -f
        -- {"error":{"message":"model \"llama-3.2:3b\" not found, try pulling it first","type":"api_error","param":null,"code":null}}

        return true -- continue streaming, false would result in rest going to final callback (IIUC)
    end

    myTask = streamingRequest(service.url, "POST", headers, body, streamingCallback, completeCallback)
end

return M
