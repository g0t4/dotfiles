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

-- Dictionary mode - look up word definitions
local function handleDictionary(word, searchId, callback)
    if word == "" then
        callback(searchId, {})
        return
    end

    -- Just show the word and indicate it will open Dictionary.app
    callback(searchId, {{
        text = "Look up: " .. word,
        subText = "Press Enter to open in Dictionary.app",
        dictionaryWord = word,
        image = hs.image.imageFromName("NSBookmarkTemplate"),
    }})
end

-- Google/web search mode
local function handleWebSearch(query, searchId, callback)
    if query == "" then
        callback(searchId, {})
        return
    end

    local encodedQuery = hs.http.encodeForQuery(query)
    local url = "https://www.google.com/search?q=" .. encodedQuery

    callback(searchId, {{
        text = "Search Google: " .. query,
        subText = url,
        webSearchUrl = url,
        image = hs.image.imageFromName("NSNetwork"),
    }})
end

-- Path browsing mode - browse filesystem
local function handlePathBrowsing(path, searchId, callback)
    if path == "" then
        -- Show common starting points
        callback(searchId, {
            {text = "~", subText = os.getenv("HOME"), browsePath = os.getenv("HOME")},
            {text = "/", subText = "Root directory", browsePath = "/"},
            {text = "~/Desktop", subText = os.getenv("HOME") .. "/Desktop", browsePath = os.getenv("HOME") .. "/Desktop"},
            {text = "~/Downloads", subText = os.getenv("HOME") .. "/Downloads", browsePath = os.getenv("HOME") .. "/Downloads"},
        })
        return
    end

    -- Expand ~ to home directory
    local expandedPath = path:gsub("^~", os.getenv("HOME"))

    -- Check if path exists
    local attrs = hs.fs.attributes(expandedPath)
    if not attrs then
        callback(searchId, {{
            text = "Path not found: " .. path,
            subText = "Check spelling or permissions",
        }})
        return
    end

    local results = {}

    -- If it's a directory, list contents
    if attrs.mode == "directory" then
        for item in hs.fs.dir(expandedPath) do
            if item ~= "." and item ~= ".." then
                local itemPath = expandedPath .. "/" .. item
                local itemAttrs = hs.fs.attributes(itemPath)
                if itemAttrs then
                    table.insert(results, {
                        text = item,
                        subText = itemPath,
                        path = itemPath,
                        browsePath = itemPath,
                        image = hs.image.iconForFile(itemPath),
                    })
                end
            end
        end

        -- Sort: directories first, then files
        table.sort(results, function(a, b)
            local aIsDir = hs.fs.attributes(a.path).mode == "directory"
            local bIsDir = hs.fs.attributes(b.path).mode == "directory"
            if aIsDir ~= bIsDir then
                return aIsDir
            end
            return a.text < b.text
        end)

        -- Limit results
        if #results > MAX_RESULTS then
            local limited = {}
            for i = 1, MAX_RESULTS do
                limited[i] = results[i]
            end
            results = limited
        end
    else
        -- It's a file, show it
        table.insert(results, {
            text = getFilename(expandedPath),
            subText = expandedPath,
            path = expandedPath,
            image = hs.image.iconForFile(expandedPath),
        })
    end

    callback(searchId, results)
end

-- Commands mode - run predefined commands
local function handleCommands(query, searchId, callback)
    -- Define some useful commands
    local commands = {
        {name = "reload", desc = "Reload Hammerspoon config", cmd = function() hs.reload() end},
        {name = "console", desc = "Open Hammerspoon console", cmd = function() hs.openConsole() end},
        {name = "sleep", desc = "Put computer to sleep", cmd = function() hs.caffeinate.systemSleep() end},
        {name = "lock", desc = "Lock screen", cmd = function() hs.caffeinate.lockScreen() end},
        {name = "dark", desc = "Toggle dark mode", cmd = function()
            hs.osascript.applescript('tell app "System Events" to tell appearance preferences to set dark mode to not dark mode')
        end},
    }

    local results = {}

    -- Filter commands by query
    for _, cmd in ipairs(commands) do
        if query == "" or cmd.name:lower():find(query:lower(), 1, true) or cmd.desc:lower():find(query:lower(), 1, true) then
            table.insert(results, {
                text = cmd.name,
                subText = cmd.desc,
                command = cmd.cmd,
                image = hs.image.imageFromName("NSActionTemplate"),
            })
        end
    end

    callback(searchId, results)
end

-- Lua calculator mode - evaluate Lua expression (moved from "c ")
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
            text = "c <query>",
            subText = "Commands (e.g., 'c reload', 'c lock', 'c sleep')",
            image = hs.image.imageFromName("NSActionTemplate"),
        },
        {
            text = "d <word>",
            subText = "Dictionary lookup (e.g., 'd recursion', 'd algorithm')",
            image = hs.image.imageFromName("NSBookmarkTemplate"),
        },
        {
            text = "g <query>",
            subText = "Google search (e.g., 'g hammerspoon docs')",
            image = hs.image.imageFromName("NSNetwork"),
        },
        {
            text = "l <expression>",
            subText = "Lua calculator (e.g., 'l 2+2', 'l math.sqrt(16)')",
            image = hs.image.imageFromName("NSCalculator"),
        },
        {
            text = "o <prompt>",
            subText = "LLM completion (e.g., 'o what is lua', 'o explain recursion')",
            image = hs.image.imageFromName("NSInfo"),
        },
        {
            text = "/<path>",
            subText = "Browse filesystem (e.g., '/~', '/~/Desktop')",
            image = hs.image.imageFromName("NSFolder"),
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

    -- Check for commands mode
    if query:match("^c ") then
        local cmdQuery = query:sub(3)  -- Remove "c " prefix
        handleCommands(cmdQuery, thisSearchId, handleResults)
        return
    end

    -- Check for dictionary mode
    if query:match("^d ") then
        local word = query:sub(3)  -- Remove "d " prefix
        handleDictionary(word, thisSearchId, handleResults)
        return
    end

    -- Check for Google search mode
    if query:match("^g ") then
        local searchQuery = query:sub(3)  -- Remove "g " prefix
        handleWebSearch(searchQuery, thisSearchId, handleResults)
        return
    end

    -- Check for Lua calculator mode
    if query:match("^l ") then
        local expression = query:sub(3)  -- Remove "l " prefix
        handleCalculator(expression, thisSearchId, handleResults)
        return
    end

    -- Check for LLM mode
    if query:match("^o ") then
        local llmQuery = query:sub(3)  -- Remove "o " prefix
        handleLLM(llmQuery, thisSearchId, handleResults)
        return
    end

    -- Check for path browsing mode
    if query:match("^/") then
        local path = query:sub(2)  -- Remove "/" prefix
        handlePathBrowsing(path, thisSearchId, handleResults)
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

    -- Handle dictionary lookup
    if choice.dictionaryWord then
        hs.execute(string.format('open dict://%s', choice.dictionaryWord))
        return
    end

    -- Handle web search
    if choice.webSearchUrl then
        hs.execute(string.format('open "%s"', choice.webSearchUrl))
        return
    end

    -- Handle command execution
    if choice.command then
        choice.command()
        return
    end

    -- Handle path browsing - if browsePath exists, update query to browse that path
    if choice.browsePath then
        -- For path browsing, open the file/folder
        if choice.path then
            if modifiers.cmd or modifiers.shift then
                -- Reveal in Finder
                hs.execute(string.format('open -R "%s"', choice.path))
            else
                -- Open with default app
                hs.execute(string.format('open "%s"', choice.path))
            end
        end
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
