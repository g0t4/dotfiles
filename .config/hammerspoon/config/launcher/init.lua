local M = {}

-- File launcher using mdfind (Spotlight index)
local chooser = nil
local currentTask = nil
local currentSearchId = 0  -- Track current search across all searchers
local MAX_RESULTS = 30

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
    if query == "" then
        callback(searchId, {})
        return
    end

    -- Get all applications
    local allApps = hs.application.applicationsForBundleID() or {}
    local results = {}

    -- Search in /Applications and ~/Applications
    local appDirs = {"/Applications", os.getenv("HOME") .. "/Applications"}

    for _, dir in ipairs(appDirs) do
        local apps = hs.fs.dir(dir)
        if apps then
            for app in apps do
                if app:match("%.app$") and app:lower():find(query:lower(), 1, true) then
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

    -- Sort by name
    table.sort(results, function(a, b) return a.text < b.text end)

    callback(searchId, results)
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

    -- Handle application launch
    if choice.appPath then
        hs.execute(string.format('open "%s"', choice.appPath))
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
    print("  - Application mode: 'a <name>' (e.g., 'a safari', 'a terminal')")
    print("  - Calculator mode: 'c <expression>' (e.g., 'c 2+2', 'c math.sqrt(16)')")
    print("  - File mode: shift/cmd+enter to reveal, option+enter to copy path")
end

return M
