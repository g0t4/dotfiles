local M = {}

-- File launcher using mdfind (Spotlight index)
local chooser = nil
local currentTask = nil
local currentSearchId = 0  -- Track current search across all searchers
local MAX_RESULTS = 30

-- LLM server configuration
local LLM_SERVER = "http://build21.lan:8013"

-- Helper to get just filename from path for display
local function getFilename(path)
    return path:match("^.+/(.+)$") or path
end

-- Helper to get parent directory for subtext
local function getDirectory(path)
    return path:match("^(.+)/[^/]+$") or ""
end

-- Perform mdfind search
local function searchFiles(query, searchId, callback)
    if query == "" or query == nil then
        callback(searchId, {})
        return
    end

    -- Build mdfind command
    -- Full Spotlight search (faster than -name in practice)
    -- Use stdbuf to force unbuffered output so we get results as they're found
    local cmd = "/opt/homebrew/bin/stdbuf"
    local args = {"-o0", "/usr/bin/mdfind", query}
    print("Starting new mdfind for query:", query, "searchId:", searchId)

    local results = {}
    local buffer = ""

    currentTask = hs.task.new(cmd, function(exitCode, _, stdErr)
        -- Ignore if this isn't the current search anymore
        if searchId ~= currentSearchId then
            print("Ignoring old search", searchId)
            return
        end

        currentTask = nil

        if exitCode ~= 0 and exitCode ~= 15 then  -- 15 is SIGTERM (expected when we terminate)
            print("mdfind error:", stdErr)
        end

        -- Final callback with results we've accumulated
        callback(searchId, results)
    end, function(_, stdOut, _)
        -- Ignore if this isn't the current search anymore
        if searchId ~= currentSearchId then
            return true
        end

        -- Accumulate partial line in buffer
        buffer = buffer .. stdOut

        -- Process complete lines
        while true do
            local line, rest = buffer:match("([^\r\n]+)[\r\n](.*)")
            if not line then
                break
            end
            buffer = rest

            -- Skip hidden files/directories (those with /. in path)
            if not line:match("/%.[^/]") then
                table.insert(results, {
                    text = getFilename(line),
                    subText = getDirectory(line),
                    path = line,
                    image = hs.image.iconForFile(line),
                })

                -- Update UI with partial results
                callback(searchId, results)

                -- Terminate if we have enough results
                if #results >= MAX_RESULTS then
                    if currentTask then
                        currentTask:terminate()
                        currentTask = nil
                    end
                    return false  -- Stop streaming
                end
            end
        end

        return true  -- Continue streaming
    end, args)

    currentTask:start()
end

-- Application search mode
local function searchApplications(query, searchId, callback)
    local results = {}

    -- Search in /Applications and ~/Applications
    local appDirs = {"/Applications", os.getenv("HOME") .. "/Applications"}

    for _, dir in ipairs(appDirs) do
        -- Check if directory exists
        local attrs = hs.fs.attributes(dir)
        if attrs and attrs.mode == "directory" then
            for app in hs.fs.dir(dir) do
                if app ~= "." and app ~= ".." and app:match("%.app$") then
                    -- If query is empty, show all apps; otherwise filter by query
                    if query == "" or app:lower():find(query:lower(), 1, true) then
                        local appPath = dir .. "/" .. app
                        local appName = app:gsub("%.app$", "")
                        table.insert(results, {
                            text = appName,
                            subText = appPath,
                            appPath = appPath,
                            image = hs.image.iconForFile(appPath),
                        })
                    end
                end
            end
        end
    end

    -- Sort by name
    table.sort(results, function(a, b) return a.text < b.text end)

    -- Limit results to MAX_RESULTS
    if #results > MAX_RESULTS then
        local limited = {}
        for i = 1, MAX_RESULTS do
            limited[i] = results[i]
        end
        results = limited
    end

    callback(searchId, results)
end

-- LLM completion mode
local function handleLLM(query, searchId, callback)
    if query == "" then
        callback(searchId, {})
        return
    end

    -- Build the prompt
    local prompt = string.format([[You are a helpful AI assistant. The user is typing: "%s"

Provide a helpful, concise response or completion. Be brief and practical.]], query)

    -- Build curl command for streaming completion
    local jsonPayload = hs.json.encode({
        prompt = prompt,
        stream = true,
        temperature = 0.7,
        max_tokens = 150
    })

    local cmd = "/usr/bin/curl"
    local args = {
        "-s",
        "-X", "POST",
        LLM_SERVER .. "/v1/completions",
        "-H", "Content-Type: application/json",
        "-d", jsonPayload
    }

    local results = {}
    local buffer = ""
    local fullResponse = ""

    print("Starting LLM request for query:", query, "searchId:", searchId)

    currentTask = hs.task.new(cmd, function(exitCode, stdOut, stdErr)
        -- Ignore if this isn't the current search anymore
        if searchId ~= currentSearchId then
            print("Ignoring old LLM search", searchId)
            return
        end

        currentTask = nil

        if exitCode ~= 0 then
            print("LLM error:", stdErr)
            callback(searchId, {{
                text = "Error connecting to LLM server",
                subText = stdErr or "Unknown error",
            }})
        end
    end, function(_, stdOut, _)
        -- Ignore if this isn't the current search anymore
        if searchId ~= currentSearchId then
            return true
        end

        buffer = buffer .. stdOut

        -- Process SSE events (data: prefix for streaming)
        while true do
            local line, rest = buffer:match("([^\r\n]+)[\r\n](.*)")
            if not line then
                break
            end
            buffer = rest

            -- Parse SSE data lines
            local data = line:match("^data: (.+)$")
            if data and data ~= "[DONE]" then
                local success, json = pcall(hs.json.decode, data)
                if success and json.choices and json.choices[1] and json.choices[1].text then
                    fullResponse = fullResponse .. json.choices[1].text

                    -- Update UI with streaming response
                    callback(searchId, {{
                        text = fullResponse,
                        subText = query,
                        llmResponse = fullResponse,
                        image = hs.image.imageFromName("NSInfo"),
                    }})
                end
            end
        end

        return true  -- Continue streaming
    end, args)

    currentTask:start()
end

-- Calculator mode - evaluate Lua expression
local function handleCalculator(expression, searchId, callback)
    if expression == "" then
        callback(searchId, {})
        return
    end

    -- Try to evaluate the expression
    local func, err = load("return " .. expression)
    if not func then
        -- Return error as result
        callback(searchId, {{
            text = "Error: " .. err,
            subText = expression,
            result = nil,
        }})
        return
    end

    local success, result = pcall(func)
    if not success then
        callback(searchId, {{
            text = "Error: " .. result,
            subText = expression,
            result = nil,
        }})
        return
    end

    -- Return the result
    callback(searchId, {{
        text = tostring(result),
        subText = expression .. " = " .. tostring(result),
        result = tostring(result),
        image = hs.image.imageFromName("NSCalculator"),
    }})
end

-- Show available modes
local function showModes()
    return {
        {
            text = "a <name>",
            subText = "Search applications (e.g., 'a safari', 'a terminal')",
            image = hs.image.imageFromName("NSApplicationIcon"),
        },
        {
            text = "c <expression>",
            subText = "Calculator (e.g., 'c 2+2', 'c math.sqrt(16)')",
            image = hs.image.imageFromName("NSCalculator"),
        },
        {
            text = "o <prompt>",
            subText = "LLM completion (e.g., 'o what is lua', 'o explain recursion')",
            image = hs.image.imageFromName("NSInfo"),
        },
        {
            text = "<search>",
            subText = "File search using mdfind (Spotlight)",
            image = hs.image.imageFromName("NSFolder"),
        },
    }
end

-- Search handler - cancels previous search on every keystroke
local function onQueryChange(query)
    -- Cancel any existing search task
    if currentTask then
        print("Terminating previous search task...")
        currentTask:terminate()
        currentTask = nil
    end

    -- Increment search ID to invalidate any in-flight searches
    currentSearchId = currentSearchId + 1
    local thisSearchId = currentSearchId

    -- Callback that checks if results are still current
    local function handleResults(searchId, results)
        -- Ignore results from old searches
        if searchId ~= currentSearchId then
            print("Ignoring results from old search", searchId)
            return
        end

        if chooser then
            chooser:choices(results)
        end
    end

    -- Show available modes when query is empty
    if query == "" or query == nil then
        handleResults(thisSearchId, showModes())
        return
    end

    -- Check for application mode
    if query:match("^a ") then
        local appQuery = query:sub(3)  -- Remove "a " prefix
        searchApplications(appQuery, thisSearchId, handleResults)
        return
    end

    -- Check for calculator mode
    if query:match("^c ") then
        local expression = query:sub(3)  -- Remove "c " prefix
        handleCalculator(expression, thisSearchId, handleResults)
        return
    end

    -- Check for LLM mode
    if query:match("^o ") then
        local llmQuery = query:sub(3)  -- Remove "o " prefix
        handleLLM(llmQuery, thisSearchId, handleResults)
        return
    end

    -- Default to file search
    searchFiles(query, thisSearchId, handleResults)
end

-- Handle file selection
local function onChoice(choice)
    -- Log for debugging
    print("=== onChoice callback ===")
    print("choice:", hs.inspect(choice))
    local modifiers = hs.eventtap.checkKeyboardModifiers()
    print("modifiers:", hs.inspect(modifiers))
    print("========================")

    if not choice then
        return
    end

    -- Handle calculator result
    if choice.result then
        hs.pasteboard.setContents(choice.result)
        hs.alert.show("Copied: " .. choice.result)
        return
    end

    -- Handle LLM response
    if choice.llmResponse then
        hs.pasteboard.setContents(choice.llmResponse)
        hs.alert.show("Copied LLM response")
        return
    end

    -- Handle application launch
    if choice.appPath then
        hs.execute(string.format('open "%s"', choice.appPath))
        return
    end

    -- Ignore if it's just a help item (no path)
    if not choice.path then
        return
    end

    -- Check modifiers for different actions
    if modifiers.alt then
        -- Copy path to clipboard
        hs.pasteboard.setContents(choice.path)
        hs.alert.show("Path copied: " .. choice.text)
    elseif modifiers.cmd or modifiers.shift then
        -- Reveal in Finder
        hs.execute(string.format('open -R "%s"', choice.path))
    else
        -- Open with default app
        hs.execute(string.format('open "%s"', choice.path))
    end
end

-- Create and show the launcher
function M.show()
    if not chooser then
        chooser = hs.chooser.new(onChoice)
        chooser:queryChangedCallback(onQueryChange)
        chooser:searchSubText(true) -- Allow searching in subtext (directory path)
        chooser:choices({}) -- Start with empty choices

        -- Styling
        chooser:bgDark(true) -- Use dark appearance
        chooser:fgColor({red=1.0, green=1.0, blue=1.0}) -- White text
        chooser:subTextColor({red=0.6, green=0.6, blue=0.6}) -- Gray subtext
        chooser:width(60) -- 60% of screen width (default is 40%)
    end

    chooser:show()
end

-- Hide the launcher
function M.hide()
    if chooser then
        chooser:hide()
    end
end

-- Setup keybinding
function M.init()
    hs.hotkey.bind({"alt"}, "space", function()
        M.show()
    end)

    print("File launcher initialized (alt+space)")
end

return M
