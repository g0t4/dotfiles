local M = {}

-- File launcher using mdfind (Spotlight index)
local chooser = nil
local currentCancelFunc = nil  -- Function to cancel current search
local currentSearchId = 0  -- Track current search across all searchers
local MAX_RESULTS = 30

-- LLM server configuration
local LLM_SERVER = "http://build21.lan:8013"

-- Emoji data configuration
local EMOJI_CACHE_DIR = os.getenv("HOME") .. "/.local/share/hammerspoon"
local EMOJI_CACHE_FILE = EMOJI_CACHE_DIR .. "/emoji-data.json"
local EMOJI_DATA_URL = "https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/en/annotations.json"
local EMOJI_CACHE_MAX_AGE = 30 * 24 * 60 * 60  -- 30 days in seconds
local emojiData = nil  -- Cached parsed emoji data

-- Helper to get just filename from path for display
local function getFilename(path)
    return path:match("^.+/(.+)$") or path
end

-- Helper to get parent directory for subtext
local function getDirectory(path)
    return path:match("^(.+)/[^/]+$") or ""
end

-- Directory-only search using mdfind
-- Returns a cancel function
local function searchDirectories(query, searchId, callback)
    if query == "" or query == nil then
        callback(searchId, {})
        return function() end  -- No-op cancel
    end

    -- Build mdfind command using metadata query for better matching
    -- kMDItemFSName with wildcards for substring matching (case-insensitive with 'c' flag)
    -- Escape single quotes in query for shell safety
    local escaped_query = query:gsub("'", "'\\''")
    local mdfind_query = string.format("kMDItemFSName == '*%s*'c && kMDItemContentType == 'public.folder'", escaped_query)

    local cmd = "/opt/homebrew/bin/stdbuf"
    local args = {"-o0", "/usr/bin/mdfind", mdfind_query}
    print("Starting new directory search for query:", query, "searchId:", searchId)
    print("mdfind query:", mdfind_query)

    local results = {}
    local buffer = ""
    local task = nil

    task = hs.task.new(cmd, function(exitCode, _, stdErr)
        -- Ignore if this isn't the current search anymore
        if searchId ~= currentSearchId then
            print("Ignoring old directory search", searchId)
            return
        end

        if exitCode ~= 0 and exitCode ~= 15 then  -- 15 is SIGTERM (expected when we terminate)
            print("mdfind directory search error:", stdErr)
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
                -- Verify it's actually a directory
                local attrs = hs.fs.attributes(line)
                if attrs and attrs.mode == "directory" then
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
                        if task then
                            task:terminate()
                            task = nil
                        end
                        return false  -- Stop streaming
                    end
                end
            end
        end

        return true  -- Continue streaming
    end, args)

    task:start()

    -- Return cancel function
    return function()
        if task then
            print("Canceling directory search", searchId)
            task:terminate()
            task = nil
        end
    end
end

-- Perform mdfind search
-- Returns a cancel function
local function searchFiles(query, searchId, callback)
    if query == "" or query == nil then
        callback(searchId, {})
        return function() end  -- No-op cancel
    end

    -- Build mdfind command
    -- Full Spotlight search (faster than -name in practice)
    -- Use stdbuf to force unbuffered output so we get results as they're found
    local cmd = "/opt/homebrew/bin/stdbuf"
    local args = {"-o0", "/usr/bin/mdfind", query}
    print("Starting new mdfind for query:", query, "searchId:", searchId)

    local results = {}
    local buffer = ""
    local task = nil

    task = hs.task.new(cmd, function(exitCode, _, stdErr)
        -- Ignore if this isn't the current search anymore
        if searchId ~= currentSearchId then
            print("Ignoring old search", searchId)
            return
        end

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
                    if task then
                        task:terminate()
                        task = nil
                    end
                    return false  -- Stop streaming
                end
            end
        end

        return true  -- Continue streaming
    end, args)

    task:start()

    -- Return cancel function
    return function()
        if task then
            print("Canceling mdfind search", searchId)
            task:terminate()
            task = nil
        end
    end
end

-- Application search mode
-- Returns a cancel function
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
    return function() end  -- No-op cancel for synchronous search
end

-- LLM completion mode with chat completions API
-- Returns a cancel function
local function handleLLM(query, searchId, callback)
    if query == "" then
        callback(searchId, {})
        return function() end  -- No-op cancel
    end

    -- Immediately clear old results when starting new search
    callback(searchId, {})

    -- Build the user message
    local userMessage = string.format([[You are a helpful AI assistant. The user is typing: "%s"

Provide a helpful, concise response or completion. Be brief and practical.]], query)

    print("=== LLM Request ===")
    print("Query:", query)
    print("User message:", userMessage)
    print("SearchId:", searchId)

    -- Build curl command for streaming chat completion
    local jsonPayload = hs.json.encode({
        messages = {
            {role = "user", content = userMessage}
        },
        stream = true,
        temperature = 0.7,
        max_tokens = 1000
    })

    local cmd = "/usr/bin/curl"
    local args = {
        "-s",
        "-X", "POST",
        LLM_SERVER .. "/v1/chat/completions",
        "-H", "Content-Type: application/json",
        "-d", jsonPayload
    }

    local buffer = ""
    local thinkingContent = ""
    local responseContent = ""
    local isThinking = false
    local thinkingFrame = 1
    local thinkingSpinner = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
    local timingStats = nil
    local task = nil

    print("Starting LLM request for query:", query, "searchId:", searchId)

    task = hs.task.new(cmd, function(exitCode, stdOut, stdErr)
        -- Ignore if this isn't the current search anymore
        if searchId ~= currentSearchId then
            print("Ignoring old LLM search completion", searchId, "current:", currentSearchId)
            return
        end

        print("=== LLM Complete ===")
        print("Exit code:", exitCode)
        print("Thinking:", thinkingContent)
        print("Response:", responseContent)
        print("Timing stats:", hs.inspect(timingStats))

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
            print("Ignoring old LLM chunk, searchId:", searchId, "current:", currentSearchId)
            return false  -- Stop streaming for old searches
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
                if success then
                    -- Check for timing stats (llama-server specific)
                    if json.timings then
                        timingStats = json.timings
                        print("=== LLM Timing Stats ===")
                        print("Prompt tokens:", timingStats.prompt_n)
                        print("Predicted tokens:", timingStats.predicted_n)
                        print("Prompt TPS:", timingStats.prompt_per_second)
                        print("Predicted TPS:", timingStats.predicted_per_second)
                    end

                    -- Parse content from chat completions format
                    if json.choices and json.choices[1] and json.choices[1].delta then
                        local delta = json.choices[1].delta

                        -- Check for reasoning_content (thinking)
                        if delta.reasoning_content then
                            thinkingContent = thinkingContent .. delta.reasoning_content
                            isThinking = true
                        end

                        -- Check for regular content (response)
                        if delta.content and delta.content ~= "" then
                            responseContent = responseContent .. delta.content
                            isThinking = false
                        end

                        print("=== LLM Chunk ===")
                        print("Thinking chunk:", delta.reasoning_content or "")
                        print("Content chunk:", delta.content or "")
                        print("Is thinking:", isThinking)

                        -- Build display text
                        local displayText = ""
                        local subText = query

                        if isThinking or (responseContent == "" and thinkingContent ~= "") then
                            -- Show thinking animation
                            thinkingFrame = (thinkingFrame % #thinkingSpinner) + 1
                            displayText = thinkingSpinner[thinkingFrame] .. " Thinking..."
                            subText = query .. " (reasoning)"
                        elseif responseContent ~= "" then
                            -- Show response
                            displayText = responseContent

                            -- Add timing stats if available
                            if timingStats then
                                local statsText = string.format("↓%d@%.0ftps ↑%d@%.0ftps",
                                    timingStats.predicted_n or 0,
                                    timingStats.predicted_per_second or 0,
                                    timingStats.prompt_n or 0,
                                    timingStats.prompt_per_second or 0)
                                if timingStats.cache_n and timingStats.cache_n > 0 then
                                    statsText = statsText .. string.format(" ⚡%d", timingStats.cache_n)
                                end
                                subText = statsText
                            end
                        end

                        -- Update UI with streaming response
                        callback(searchId, {{
                            text = displayText,
                            subText = subText,
                            llmResponse = responseContent,  -- Only copy the content, not thinking
                            llmThinking = thinkingContent,
                            llmStats = timingStats,
                            image = hs.image.imageFromName("NSInfo"),
                        }})
                    end
                end
            end
        end

        return true  -- Continue streaming
    end, args)

    task:start()

    -- Return cancel function that kills the curl process
    return function()
        if task then
            print("Canceling LLM request", searchId)
            task:terminate()
            task = nil
        end
    end
end

-- Find words matching prefix from system word list
local function findMatchingWords(prefix, maxResults)
    local matches = {}
    local prefixLower = prefix:lower()

    local file = io.open("/usr/share/dict/words", "r")
    if not file then
        return matches
    end

    for line in file:lines() do
        local word = line:gsub("%s+$", "")
        if word:lower():sub(1, #prefixLower) == prefixLower then
            table.insert(matches, word)
            if #matches >= maxResults then
                break
            end
        end
    end

    file:close()
    return matches
end

-- Dictionary mode with prefix matching
local function handleDictionary(query, searchId, callback)
    if query == "" then
        callback(searchId, {})
        return function() end
    end

    -- Find matching words
    local matchingWords = findMatchingWords(query, 8)

    if #matchingWords == 0 then
        callback(searchId, {{
            text = "No words found matching: " .. query,
            subText = "Try a different prefix",
            image = hs.image.imageFromName("NSBookmarkTemplate"),
        }})
        return function() end
    end

    -- State for parallel lookups
    local results = {}
    local tasks = {}
    local cancelled = false

    print("=== Dictionary Prefix Search ===")
    print("Query:", query)
    print("Matches:", table.concat(matchingWords, ", "))
    print("================================")

    -- Initialize placeholder results
    for i, word in ipairs(matchingWords) do
        results[i] = {
            text = word,
            subText = "Loading...",
            dictionaryWord = word,
            image = hs.image.imageFromName("NSBookmarkTemplate"),
        }
    end

    -- Update UI with current results
    local function updateResults()
        if cancelled or searchId ~= currentSearchId then
            return
        end

        -- Filter out nil entries (removed placeholders with no definition)
        local filtered = {}
        for _, result in ipairs(results) do
            if result then
                table.insert(filtered, result)
            end
        end

        callback(searchId, filtered)
    end

    -- Show initial placeholders
    updateResults()

    -- Look up each word in parallel
    for i, word in ipairs(matchingWords) do
        local pythonScript = string.format([[
from DictionaryServices import DCSCopyTextDefinition
from CoreFoundation import CFRange
word = %q
definition = DCSCopyTextDefinition(None, word, CFRange(0, len(word)))
if definition:
    text = str(definition).strip()
    text = ' '.join(text.split())
    print(text[:120] + '...' if len(text) > 120 else text)
else:
    print("")
]], word)

        local tmpfile = string.format("/tmp/hammerspoon-dict-%d-%d.py", searchId, i)
        local file = io.open(tmpfile, "w")
        file:write(pythonScript)
        file:close()

        local output = ""
        local task = hs.task.new("/Users/wesdemos/repos/github/g0t4/dotfiles/.venv/bin/python",
            function(exitCode, _, _)  -- completion callback
                if cancelled or searchId ~= currentSearchId then
                    os.remove(tmpfile)
                    return
                end

                os.remove(tmpfile)

                local definition = output:gsub("%s+$", "")
                if definition ~= "" then
                    -- Update placeholder with definition
                    results[i] = {
                        text = word .. ": " .. definition,
                        subText = "Select to open in Dictionary.app",
                        dictionaryWord = word,
                        dictionaryDefinition = definition,
                        image = hs.image.imageFromName("NSBookmarkTemplate"),
                    }
                else
                    -- Remove placeholder if no definition found
                    results[i] = nil
                end

                updateResults()
            end,
            function(_, stdOut, _)  -- streaming callback
                if cancelled or searchId ~= currentSearchId then
                    return false
                end
                output = output .. stdOut
                return true
            end,
            {tmpfile}
        )

        task:start()
        table.insert(tasks, {task = task, tmpfile = tmpfile})
    end

    -- Return cancel function
    return function()
        cancelled = true
        for _, taskInfo in ipairs(tasks) do
            if taskInfo.task then
                taskInfo.task:terminate()
            end
            os.remove(taskInfo.tmpfile)
        end
    end
end

-- Google/web search mode
-- Returns a cancel function
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
    return function() end  -- No-op cancel
end

-- Path browsing mode - browse filesystem
-- Returns a cancel function
local function handlePathBrowsing(path, searchId, callback)
    -- Handle just "/" - show root contents
    if path == "/" then
        path = "/"
    -- Handle just "~" - show home directory
    elseif path == "~" then
        path = os.getenv("HOME")
    end

    -- Expand ~ to home directory
    local expandedPath = path:gsub("^~", os.getenv("HOME"))

    -- Split path into directory and basename for partial matching
    local dirname, basename
    if expandedPath:match("^/[^/]*$") then
        -- Special case: /xxx or / - browse root directory with optional filter
        dirname = "/"
        basename = expandedPath:sub(2) -- Everything after first /
    else
        dirname, basename = expandedPath:match("^(.+)/([^/]*)$")
        if not dirname then
            -- No slash found, treat whole thing as basename in current dir
            dirname = expandedPath
            basename = ""
        end
    end

    -- Check if directory exists
    local attrs = hs.fs.attributes(dirname)
    if not attrs or attrs.mode ~= "directory" then
        callback(searchId, {{
            text = "Path not found: " .. path,
            subText = "Check spelling or permissions",
        }})
        return
    end

    local results = {}

    -- List directory contents with optional basename filter
    for item in hs.fs.dir(dirname) do
        if item ~= "." and item ~= ".." then
            -- Filter by basename prefix if provided
            if basename == "" or item:lower():find("^" .. basename:lower():gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"), 1) then
                local itemPath = dirname .. "/" .. item
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

    callback(searchId, results)
    return function() end  -- No-op cancel
end

-- Fish shell command mode - run fish commands
-- Returns a cancel function
local function handleFishCommand(command, searchId, callback)
    if command == "" then
        callback(searchId, {{
            text = "f <command>",
            subText = "Type a fish shell command, then press Enter to execute",
            image = hs.image.imageFromName("NSActionTemplate"),
        }})
        return
    end

    callback(searchId, {{
        text = "Run: " .. command,
        subText = "Press Enter to execute in fish shell",
        fishCommand = command,
        image = hs.image.imageFromName("NSActionTemplate"),
    }})
    return function() end  -- No-op cancel
end

-- Ensure emoji cache directory exists
local function ensureEmojiCacheDir()
    local attrs = hs.fs.attributes(EMOJI_CACHE_DIR)
    if not attrs then
        hs.fs.mkdir(EMOJI_CACHE_DIR)
        print("Created emoji cache directory:", EMOJI_CACHE_DIR)
    end
end

-- Download emoji data from CLDR
local function downloadEmojiData(callback)
    print("Downloading emoji data from CLDR...")
    ensureEmojiCacheDir()

    -- Use curl to download
    local cmd = "/usr/bin/curl"
    local args = {"-s", "-L", "-o", EMOJI_CACHE_FILE, EMOJI_DATA_URL}

    hs.task.new(cmd, function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            print("Emoji data downloaded successfully")
            if callback then callback(true) end
        else
            print("Error downloading emoji data:", stdErr)
            if callback then callback(false) end
        end
    end, args):start()
end

-- Load and parse emoji data from cache file
local function loadEmojiData()
    if emojiData then
        return emojiData  -- Already cached in memory
    end

    local file = io.open(EMOJI_CACHE_FILE, "r")
    if not file then
        print("No emoji cache file found")
        return nil
    end

    local content = file:read("*all")
    file:close()

    local success, parsed = pcall(hs.json.decode, content)
    if success and parsed and parsed.annotations and parsed.annotations.annotations then
        -- CLDR format: {annotations: {annotations: {emoji: {default: [...], tts: [...]}}}}
        emojiData = parsed.annotations.annotations
        print("Loaded emoji data:", hs.inspect.inspect(emojiData):sub(1, 200) .. "...")
        return emojiData
    else
        print("Error parsing emoji data")
        return nil
    end
end

-- Check if emoji cache needs update (runs in background)
local function checkEmojiCacheAge()
    local attrs = hs.fs.attributes(EMOJI_CACHE_FILE)
    if not attrs then
        return  -- No file, will download on first use
    end

    local age = os.time() - attrs.modification
    print("Emoji cache age:", age, "seconds")

    if age > EMOJI_CACHE_MAX_AGE then
        print("Emoji cache is old, updating in background...")
        downloadEmojiData(function(success)
            if success then
                -- Reload data in memory
                emojiData = nil
                loadEmojiData()
                print("Emoji cache updated in background")
            end
        end)
    end
end

-- Emoji picker mode
local function handleEmoji(query, searchId, callback)
    -- Try to load emoji data
    local data = loadEmojiData()

    if not data then
        -- No cache file, need to download
        callback(searchId, {{
            text = "Downloading emoji data...",
            subText = "First time setup, please wait",
            image = hs.image.imageFromName("NSNetwork"),
        }})

        downloadEmojiData(function(success)
            if success then
                data = loadEmojiData()
                if data then
                    -- Retry the search now that we have data
                    handleEmoji(query, searchId, callback)
                else
                    callback(searchId, {{
                        text = "Error loading emoji data",
                        subText = "Failed to parse downloaded data",
                        image = hs.image.imageFromName("NSCaution"),
                    }})
                end
            else
                callback(searchId, {{
                    text = "Error downloading emoji data",
                    subText = "Check internet connection",
                    image = hs.image.imageFromName("NSCaution"),
                }})
            end
        end)
        return function() end
    end

    -- Build emoji list from CLDR data
    local emojis = {}
    for emoji, annotations in pairs(data) do
        if annotations.default then
            table.insert(emojis, {
                emoji = emoji,
                keywords = annotations.default,
            })
        end
    end

    -- Results list
    local results = {}

    -- Filter emojis by query
    for _, item in ipairs(emojis) do
        if query == "" then
            -- Show all emojis (limited)
            table.insert(results, {
                text = item.emoji,
                subText = table.concat(item.keywords, ", "),
                emoji = item.emoji,
                image = hs.image.imageFromName("NSFontPanel"),
            })
        else
            -- Search in keywords and emoji itself
            local queryLower = query:lower()
            local found = false

            -- Check if query matches emoji character itself
            if item.emoji:lower():find(queryLower, 1, true) then
                found = true
            end

            -- Check keywords
            if not found then
                for _, keyword in ipairs(item.keywords) do
                    if keyword:lower():find(queryLower, 1, true) then
                        found = true
                        break
                    end
                end
            end

            if found then
                table.insert(results, {
                    text = item.emoji,
                    subText = table.concat(item.keywords, ", "),
                    emoji = item.emoji,
                    image = hs.image.imageFromName("NSFontPanel"),
                })
            end
        end
    end

    -- Limit results
    if #results > MAX_RESULTS then
        local limited = {}
        for i = 1, MAX_RESULTS do
            limited[i] = results[i]
        end
        results = limited
    end

    callback(searchId, results)
    return function() end  -- No-op cancel
end

-- Python code execution mode - run Python code with live evaluation
local function handlePythonCode(code, searchId, callback)
    if code == "" then
        callback(searchId, {})
        return
    end

    -- Execute Python code and get result
    local output, status = hs.execute(string.format('/Users/wesdemos/repos/github/g0t4/dotfiles/.venv/bin/python -c "%s"', code:gsub('"', '\\"')))

    if status then
        -- Success - show output
        local result = output and output:gsub("%s+$", "") or ""  -- Trim trailing whitespace
        if result == "" then
            callback(searchId, {{
                text = "No output",
                subText = code,
                pythonCode = code,
                pythonResult = "",
                image = hs.image.imageFromName("NSActionTemplate"),
            }})
        else
            callback(searchId, {{
                text = result,
                subText = code,
                pythonCode = code,
                pythonResult = result,
                image = hs.image.imageFromName("NSActionTemplate"),
            }})
        end
    else
        -- Error - show error message
        local errorMsg = output and output:gsub("%s+$", "") or "Unknown error"
        callback(searchId, {{
            text = "Error: " .. errorMsg,
            subText = code,
            pythonCode = code,
            pythonResult = nil,
            image = hs.image.imageFromName("NSCaution"),
        }})
    end
    return function() end  -- No-op cancel
end

-- Simple fuzzy match function
-- Checks if query characters appear in order in the target string (case-insensitive)
local function fuzzyMatch(str, query)
    if query == "" then return true end

    local strLower = str:lower()
    local queryLower = query:lower()
    local strPos = 1

    -- Each character in query must appear in order in str
    for i = 1, #queryLower do
        local char = queryLower:sub(i, i)
        local foundPos = strLower:find(char, strPos, true)
        if not foundPos then
            return false
        end
        strPos = foundPos + 1
    end

    return true
end

-- Live filter mode - two-stage: mdfind broad filter, Lua fuzzy refine
-- Returns a cancel function
local function handleLiveFilter(query, searchId, callback)
    -- Parse query: "stage1 stage2"
    local stage1, stage2 = query:match("^(%S+)%s+(.+)$")

    if not stage1 or not stage2 then
        -- Need both args
        callback(searchId, {{
            text = "v <broad> <refine>",
            subText = "Two-stage: v repos ask → mdfind 'repos', fuzzy filter 'ask'",
            image = hs.image.imageFromName("NSInfo"),
        }})
        return function() end
    end

    -- Build mdfind query for stage1 (broad filter with wildcards)
    local escaped_stage1 = stage1:gsub("'", "'\\''")
    local mdfind_query = string.format("kMDItemFSName == '*%s*'c && kMDItemContentType == 'public.folder'", escaped_stage1)

    -- Use stdbuf for unbuffered output
    local cmd = "/opt/homebrew/bin/stdbuf"
    local args = {"-o0", "/usr/bin/mdfind", mdfind_query}

    print("=== Live Filter ===")
    print("Stage1 (mdfind):", stage1)
    print("Stage2 (fuzzy):", stage2)

    local results = {}
    local buffer = ""
    local task = nil

    task = hs.task.new(cmd,
        function(exitCode, _, stdErr)
            if searchId ~= currentSearchId then
                print("Ignoring old live filter completion", searchId)
                return
            end

            if exitCode ~= 0 and exitCode ~= 15 then
                print("Live filter error:", stdErr)
            end

            -- Final callback
            callback(searchId, results)
        end,
        function(_, stdOut, _)
            if searchId ~= currentSearchId then
                return false  -- Stop streaming for old searches
            end

            buffer = buffer .. stdOut

            while true do
                local line, rest = buffer:match("([^\r\n]+)[\r\n](.*)")
                if not line then break end
                buffer = rest

                -- Skip hidden files/directories
                if not line:match("/%.[^/]") then
                    -- Fuzzy match against stage2 (refinement query)
                    if fuzzyMatch(line, stage2) then
                        table.insert(results, {
                            text = getFilename(line),
                            subText = line,
                            path = line,
                            image = hs.image.iconForFile(line),
                        })

                        -- Update UI with top N results
                        local display = {}
                        for i = 1, math.min(#results, MAX_RESULTS) do
                            display[i] = results[i]
                        end
                        callback(searchId, display)

                        -- Stop if we have enough
                        if #results >= MAX_RESULTS then
                            if task then
                                task:terminate()
                                task = nil
                            end
                            return false
                        end
                    end
                end
            end

            return true  -- Continue streaming
        end,
        args
    )

    task:start()

    return function()
        if task then
            print("Canceling live filter", searchId)
            task:terminate()
            task = nil
        end
    end
end

-- System settings mode - open System Settings panes
local function handleSystemSettings(query, searchId, callback)
    -- Common system settings panes with their identifiers
    local settings = {
        {name = "Privacy & Security", id = "com.apple.preference.security", keywords = {"privacy", "security", "permissions"}},
        {name = "Network", id = "com.apple.Network-Settings.extension", keywords = {"network", "wifi", "ethernet"}},
        {name = "Bluetooth", id = "com.apple.BluetoothSettings", keywords = {"bluetooth"}},
        {name = "Sound", id = "com.apple.preference.sound", keywords = {"sound", "audio", "volume"}},
        {name = "Displays", id = "com.apple.Displays-Settings.extension", keywords = {"display", "monitor", "screen"}},
        {name = "Keyboard", id = "com.apple.Keyboard-Settings.extension", keywords = {"keyboard"}},
        {name = "Mouse", id = "com.apple.Mouse-Settings.extension", keywords = {"mouse"}},
        {name = "Trackpad", id = "com.apple.Trackpad-Settings.extension", keywords = {"trackpad"}},
        {name = "Printers & Scanners", id = "com.apple.preference.printfax", keywords = {"printer", "scanner", "print"}},
        {name = "Battery", id = "com.apple.preference.battery", keywords = {"battery", "power"}},
        {name = "Users & Groups", id = "com.apple.preferences.users", keywords = {"users", "accounts", "login"}},
        {name = "Touch ID & Password", id = "com.apple.preferences.password", keywords = {"touchid", "password", "biometric"}},
        {name = "Internet Accounts", id = "com.apple.Internet-Accounts-Settings.extension", keywords = {"accounts", "email", "icloud"}},
        {name = "Wallet & Apple Pay", id = "com.apple.WalletSettingsExtension", keywords = {"wallet", "pay", "cards"}},
        {name = "Notifications", id = "com.apple.preference.notifications", keywords = {"notifications", "alerts"}},
        {name = "General", id = "com.apple.Settings.General", keywords = {"general", "about"}},
        {name = "Appearance", id = "com.apple.Appearance-Settings.extension", keywords = {"appearance", "theme", "dark"}},
        {name = "Accessibility", id = "com.apple.preference.universalaccess", keywords = {"accessibility", "voiceover"}},
        {name = "Siri & Spotlight", id = "com.apple.Siri-Settings.extension", keywords = {"siri", "spotlight", "search"}},
        {name = "Desktop & Dock", id = "com.apple.Desktop-Settings.extension", keywords = {"desktop", "dock", "menubar"}},
        {name = "Screen Saver", id = "com.apple.ScreenSaver-Settings.extension", keywords = {"screensaver", "screen saver"}},
        {name = "Lock Screen", id = "com.apple.Lock-Screen-Settings.extension", keywords = {"lock", "lockscreen"}},
        {name = "Sharing", id = "com.apple.preferences.sharing", keywords = {"sharing", "airdrop", "remote"}},
        {name = "Time Machine", id = "com.apple.Time-Machine-Settings.extension", keywords = {"timemachine", "backup"}},
        {name = "Passwords", id = "com.apple.Passwords-Settings.extension", keywords = {"passwords", "keychain"}},
    }

    local results = {}

    -- Filter settings by query
    for _, setting in ipairs(settings) do
        if query == "" then
            -- Show all settings
            table.insert(results, {
                text = setting.name,
                subText = "Open in System Settings",
                settingsId = setting.id,
                image = hs.image.imageFromName("NSPreferencesGeneral"),
            })
        else
            -- Search in name and keywords
            local queryLower = query:lower()
            local nameMatch = setting.name:lower():find(queryLower, 1, true)
            local keywordMatch = false
            for _, keyword in ipairs(setting.keywords) do
                if keyword:find(queryLower, 1, true) then
                    keywordMatch = true
                    break
                end
            end

            if nameMatch or keywordMatch then
                table.insert(results, {
                    text = setting.name,
                    subText = "Open in System Settings",
                    settingsId = setting.id,
                    image = hs.image.imageFromName("NSPreferencesGeneral"),
                })
            end
        end
    end

    callback(searchId, results)
    return function() end  -- No-op cancel
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
    return function() end  -- No-op cancel
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
    return function() end  -- No-op cancel
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
            text = "s <query>",
            subText = "System Settings (e.g., 's privacy', 's network', 's bluetooth')",
            image = hs.image.imageFromName("NSPreferencesGeneral"),
        },
        {
            text = "c <query>",
            subText = "Commands (e.g., 'c reload', 'c lock', 'c sleep')",
            image = hs.image.imageFromName("NSActionTemplate"),
        },
        {
            text = "d <query>",
            subText = "Directory search (e.g., 'd repos', 'd Downloads')",
            image = hs.image.imageFromName("NSFolder"),
        },
        {
            text = "define <word>",
            subText = "Dictionary lookup (e.g., 'define recursion', 'define algorithm')",
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
            text = "/<path> or ~<path>",
            subText = "Browse filesystem (e.g., '/Applications', '~/Desktop')",
            image = hs.image.imageFromName("NSFolder"),
        },
        {
            text = "f <command>",
            subText = "Fish shell command (e.g., 'f pkill hammerspoon', 'f ls -la')",
            image = hs.image.imageFromName("NSActionTemplate"),
        },
        {
            text = "py <code>",
            subText = "Python code (e.g., 'py print(2+2)', 'py import sys; print(sys.version)')",
            image = hs.image.imageFromName("NSActionTemplate"),
        },
        {
            text = "e <query>",
            subText = "Emoji picker (e.g., 'e smile', 'e heart', 'e fire')",
            image = hs.image.imageFromName("NSFontPanel"),
        },
        {
            text = "v <broad> <refine>",
            subText = "Two-stage fuzzy: mdfind + fuzzy (e.g., 'v repos ask', 'v github dot')",
            image = hs.image.imageFromName("NSAdvanced"),
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
    -- Cancel any existing search using the cancel function
    if currentCancelFunc then
        print("Canceling previous search...")
        currentCancelFunc()
        currentCancelFunc = nil
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

    -- Debug logging
    print("=== Query Check ===")
    print("Query:", query)
    print("Query length:", #query)
    print("Matches ^a :", query:match("^a ") ~= nil)
    print("Matches ^s :", query:match("^s ") ~= nil)

    -- Check for application mode
    if query:match("^a ") then
        local appQuery = query:sub(3)  -- Remove "a " prefix
        currentCancelFunc = searchApplications(appQuery, thisSearchId, handleResults)
        return
    end

    -- Check for system settings mode
    if query:match("^s ") then
        local settingsQuery = query:sub(3)  -- Remove "s " prefix
        print("System settings mode activated, query:", settingsQuery)
        currentCancelFunc = handleSystemSettings(settingsQuery, thisSearchId, handleResults)
        return
    end

    -- Check for commands mode
    if query:match("^c ") then
        local cmdQuery = query:sub(3)  -- Remove "c " prefix
        currentCancelFunc = handleCommands(cmdQuery, thisSearchId, handleResults)
        return
    end

    -- Check for directory search mode
    if query:match("^d ") then
        local dirQuery = query:sub(3)  -- Remove "d " prefix
        currentCancelFunc = searchDirectories(dirQuery, thisSearchId, handleResults)
        return
    end

    -- Check for dictionary mode
    if query:match("^define ") then
        local word = query:sub(8)  -- Remove "define " prefix
        currentCancelFunc = handleDictionary(word, thisSearchId, handleResults)
        return
    end

    -- Check for Google search mode
    if query:match("^g ") then
        local searchQuery = query:sub(3)  -- Remove "g " prefix
        currentCancelFunc = handleWebSearch(searchQuery, thisSearchId, handleResults)
        return
    end

    -- Check for Lua calculator mode
    if query:match("^l ") then
        local expression = query:sub(3)  -- Remove "l " prefix
        currentCancelFunc = handleCalculator(expression, thisSearchId, handleResults)
        return
    end

    -- Check for LLM mode
    if query:match("^o ") then
        local llmQuery = query:sub(3)  -- Remove "o " prefix
        currentCancelFunc = handleLLM(llmQuery, thisSearchId, handleResults)
        return
    end

    -- Check for path browsing mode (absolute paths starting with / or ~)
    if query:match("^/") or query:match("^~") then
        currentCancelFunc = handlePathBrowsing(query, thisSearchId, handleResults)
        return
    end

    -- Check for fish command mode
    if query:match("^f ") then
        local command = query:sub(3)  -- Remove "f " prefix
        currentCancelFunc = handleFishCommand(command, thisSearchId, handleResults)
        return
    end

    -- Check for Python code mode
    if query:match("^py ") then
        local code = query:sub(4)  -- Remove "py " prefix
        currentCancelFunc = handlePythonCode(code, thisSearchId, handleResults)
        return
    end

    -- Check for emoji mode
    if query:match("^e ") then
        local emojiQuery = query:sub(3)  -- Remove "e " prefix
        currentCancelFunc = handleEmoji(emojiQuery, thisSearchId, handleResults)
        return
    end

    -- Check for live filter mode (two-stage: mdfind | fzf)
    if query:match("^v ") then
        local liveQuery = query:sub(3)  -- Remove "v " prefix
        currentCancelFunc = handleLiveFilter(liveQuery, thisSearchId, handleResults)
        return
    end

    -- Default to file search
    currentCancelFunc = searchFiles(query, thisSearchId, handleResults)
end

-- Refresh hotkeys
local refreshHotkeyCmdR = nil
local refreshHotkeyCtrlR = nil

-- Delete refresh hotkeys
local function deleteRefreshHotkeys()
    print("=== Deleting refresh hotkeys ===")
    if refreshHotkeyCmdR then
        refreshHotkeyCmdR:delete()
        refreshHotkeyCmdR = nil
        print("Deleted Cmd+R hotkey")
    end
    if refreshHotkeyCtrlR then
        refreshHotkeyCtrlR:delete()
        refreshHotkeyCtrlR = nil
        print("Deleted Ctrl+R hotkey")
    end
end

-- Refresh current query
local function refreshQuery()
    if chooser then
        local currentQuery = chooser:query()
        -- Trigger onQueryChange to re-run the search
        onQueryChange(currentQuery)
    end
end

-- Handle file selection
local function onChoice(choice)
    -- Delete refresh hotkeys when chooser closes (whether by selection or escape)
    deleteRefreshHotkeys()

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
        if choice.dictionaryDefinition then
            hs.pasteboard.setContents(choice.dictionaryDefinition)
            hs.alert.show("Definition copied: " .. choice.dictionaryDefinition:sub(1, 50) .. "...")
        else
            hs.execute(string.format('open dict://%s', choice.dictionaryWord))
        end
        return
    end

    -- Handle web search
    if choice.webSearchUrl then
        hs.execute(string.format('open "%s"', choice.webSearchUrl))
        return
    end

    -- Handle system settings
    if choice.settingsId then
        hs.execute(string.format('open "x-apple.systempreferences:%s"', choice.settingsId))
        return
    end

    -- Handle command execution
    if choice.command then
        choice.command()
        return
    end

    -- Handle fish command execution
    if choice.fishCommand then
        local output, status = hs.execute(string.format('/opt/homebrew/bin/fish -c "%s"', choice.fishCommand:gsub('"', '\\"')))
        if status then
            local result = output and output:gsub("%s+$", "") or ""
            if result ~= "" then
                hs.pasteboard.setContents(result)
                hs.alert.show("Output copied: " .. result:sub(1, 100))
            else
                hs.alert.show("Command executed (no output)")
            end
        else
            hs.alert.show("Error: " .. (output or "Command failed"))
        end
        return
    end

    -- Handle Python code execution
    if choice.pythonCode then
        if choice.pythonResult and choice.pythonResult ~= "" then
            hs.pasteboard.setContents(choice.pythonResult)
            hs.alert.show("Copied: " .. choice.pythonResult:sub(1, 50))
        else
            hs.alert.show("No output to copy")
        end
        return
    end

    -- Handle emoji selection
    if choice.emoji then
        hs.pasteboard.setContents(choice.emoji)
        -- Paste the emoji immediately
        hs.eventtap.keyStroke({"cmd"}, "v")
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

    -- Enable refresh hotkeys when chooser is shown
    if not refreshHotkeyCmdR then
        refreshHotkeyCmdR = hs.hotkey.new({"cmd"}, "r", refreshQuery)
        refreshHotkeyCtrlR = hs.hotkey.new({"ctrl"}, "r", refreshQuery)
    end
    refreshHotkeyCmdR:enable()
    refreshHotkeyCtrlR:enable()

    chooser:show()
end

-- Hide the launcher
function M.hide()
    if chooser then
        chooser:hide()
    end
    -- Delete refresh hotkeys when hidden
    deleteRefreshHotkeys()
end

-- Setup keybinding
function M.init()
    hs.hotkey.bind({"alt"}, "space", function()
        M.show()
    end)

    -- Check emoji cache age daily in background
    hs.timer.doEvery(24 * 60 * 60, checkEmojiCacheAge)
    -- Also check on startup (after 5 seconds to avoid slowing down init)
    hs.timer.doAfter(5, checkEmojiCacheAge)

    print("File launcher initialized (alt+space)")
end

return M
