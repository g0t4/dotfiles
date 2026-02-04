local M = {}

-- File launcher using mdfind (Spotlight index)
local chooser = nil
local currentCancelFunc = nil  -- Function to cancel current search
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

-- Dictionary mode - look up word definitions with inline display
-- Returns a cancel function
local function handleDictionary(word, searchId, callback)
    if word == "" then
        callback(searchId, {})
        return
    end

    -- Use Python to access DictionaryServices framework for inline definitions
    local pythonScript = string.format([[
import sys
try:
    from DictionaryServices import DCSCopyTextDefinition
    from CoreFoundation import CFRange
    word = %q
    definition = DCSCopyTextDefinition(None, word, CFRange(0, len(word)))
    if definition:
        # Clean up the definition - take first paragraph or first 200 chars
        text = str(definition).strip()
        # Remove extra whitespace and newlines
        text = ' '.join(text.split())
        print(text[:200] + '...' if len(text) > 200 else text)
    else:
        print("No definition found")
except Exception as e:
    print(f"Error: {e}")
]], word)

    local output, status = hs.execute(string.format('/Users/wesdemos/repos/github/g0t4/dotfiles/.venv/bin/python -c "%s"', pythonScript:gsub('"', '\\"'):gsub('\n', '\\n')))

    if status and output and output ~= "" then
        local definition = output:gsub("%s+$", "")
        callback(searchId, {{
            text = definition,
            subText = word,
            dictionaryWord = word,
            dictionaryDefinition = definition,
            image = hs.image.imageFromName("NSBookmarkTemplate"),
        }})
    else
        -- Fallback to just showing the word
        callback(searchId, {{
            text = "No definition found for: " .. word,
            subText = "Press Enter to open in Dictionary.app",
            dictionaryWord = word,
            image = hs.image.imageFromName("NSBookmarkTemplate"),
        }})
    end
    return function() end  -- No-op cancel for synchronous operation
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

-- Emoji picker mode
local function handleEmoji(query, searchId, callback)
    -- Comprehensive emoji list with keywords
    local emojis = {
        -- Smileys & Emotion
        {emoji = "😀", keywords = {"grinning", "smile", "happy"}},
        {emoji = "😃", keywords = {"smile", "happy", "joy"}},
        {emoji = "😄", keywords = {"smile", "happy", "joy", "laugh"}},
        {emoji = "😁", keywords = {"grin", "smile", "happy"}},
        {emoji = "😅", keywords = {"sweat", "smile", "relief"}},
        {emoji = "😂", keywords = {"joy", "tears", "laugh", "lol", "funny"}},
        {emoji = "🤣", keywords = {"rofl", "laugh", "rolling", "floor"}},
        {emoji = "😊", keywords = {"blush", "smile", "happy"}},
        {emoji = "😇", keywords = {"angel", "innocent", "halo"}},
        {emoji = "🙂", keywords = {"smile", "happy"}},
        {emoji = "🙃", keywords = {"upside", "down", "silly"}},
        {emoji = "😉", keywords = {"wink", "flirt"}},
        {emoji = "😌", keywords = {"relieved", "calm", "peaceful"}},
        {emoji = "😍", keywords = {"love", "heart", "eyes", "crush"}},
        {emoji = "🥰", keywords = {"love", "hearts", "smile", "happy"}},
        {emoji = "😘", keywords = {"kiss", "love", "heart"}},
        {emoji = "😗", keywords = {"kiss", "whistle"}},
        {emoji = "😙", keywords = {"kiss", "smile"}},
        {emoji = "😚", keywords = {"kiss", "closed", "eyes"}},
        {emoji = "😋", keywords = {"yum", "delicious", "tasty", "food"}},
        {emoji = "😛", keywords = {"tongue", "playful"}},
        {emoji = "😝", keywords = {"tongue", "wink", "playful"}},
        {emoji = "😜", keywords = {"tongue", "wink", "playful"}},
        {emoji = "🤪", keywords = {"zany", "crazy", "wild"}},
        {emoji = "🤨", keywords = {"raised", "eyebrow", "skeptical"}},
        {emoji = "🧐", keywords = {"monocle", "thinking", "curious"}},
        {emoji = "🤓", keywords = {"nerd", "geek", "glasses"}},
        {emoji = "😎", keywords = {"cool", "sunglasses", "awesome"}},
        {emoji = "🤩", keywords = {"star", "struck", "excited", "wow"}},
        {emoji = "🥳", keywords = {"party", "celebrate", "birthday"}},
        {emoji = "😏", keywords = {"smirk", "sly"}},
        {emoji = "😒", keywords = {"unamused", "unhappy"}},
        {emoji = "😞", keywords = {"disappointed", "sad"}},
        {emoji = "😔", keywords = {"pensive", "sad", "thoughtful"}},
        {emoji = "😟", keywords = {"worried", "concerned"}},
        {emoji = "😕", keywords = {"confused", "puzzled"}},
        {emoji = "🙁", keywords = {"frown", "sad"}},
        {emoji = "☹️", keywords = {"frown", "sad"}},
        {emoji = "😣", keywords = {"persevere", "struggle"}},
        {emoji = "😖", keywords = {"confounded", "frustrated"}},
        {emoji = "😫", keywords = {"tired", "exhausted"}},
        {emoji = "😩", keywords = {"weary", "tired"}},
        {emoji = "🥺", keywords = {"pleading", "puppy", "eyes", "sad"}},
        {emoji = "😢", keywords = {"cry", "sad", "tears"}},
        {emoji = "😭", keywords = {"sob", "cry", "sad", "tears"}},
        {emoji = "😤", keywords = {"triumph", "smug", "steam"}},
        {emoji = "😠", keywords = {"angry", "mad"}},
        {emoji = "😡", keywords = {"rage", "angry", "mad"}},
        {emoji = "🤬", keywords = {"cursing", "swearing", "angry"}},
        {emoji = "🤯", keywords = {"exploding", "head", "mind", "blown"}},
        {emoji = "😳", keywords = {"flushed", "embarrassed"}},
        {emoji = "🥵", keywords = {"hot", "sweating"}},
        {emoji = "🥶", keywords = {"cold", "freezing"}},
        {emoji = "😱", keywords = {"scream", "shocked", "scared"}},
        {emoji = "😨", keywords = {"fearful", "scared"}},
        {emoji = "😰", keywords = {"anxious", "nervous", "sweat"}},
        {emoji = "😥", keywords = {"sad", "relieved"}},
        {emoji = "😓", keywords = {"sweat", "downcast"}},
        {emoji = "🤗", keywords = {"hug", "hugging"}},
        {emoji = "🤔", keywords = {"think", "thinking", "hmm"}},
        {emoji = "🤭", keywords = {"hand", "over", "mouth", "oops"}},
        {emoji = "🤫", keywords = {"shh", "quiet", "secret"}},
        {emoji = "🤥", keywords = {"lying", "pinocchio"}},
        {emoji = "😶", keywords = {"no", "mouth", "silent"}},
        {emoji = "😐", keywords = {"neutral", "meh"}},
        {emoji = "😑", keywords = {"expressionless"}},
        {emoji = "😬", keywords = {"grimace", "awkward"}},
        {emoji = "🙄", keywords = {"eye", "roll", "whatever"}},
        {emoji = "😯", keywords = {"hushed", "surprised"}},
        {emoji = "😦", keywords = {"frown", "open", "mouth"}},
        {emoji = "😧", keywords = {"anguish", "worried"}},
        {emoji = "😮", keywords = {"open", "mouth", "surprised"}},
        {emoji = "😲", keywords = {"astonished", "shocked"}},
        {emoji = "🥱", keywords = {"yawn", "tired", "bored"}},
        {emoji = "😴", keywords = {"sleep", "sleeping", "zzz"}},
        {emoji = "🤤", keywords = {"drool", "sleep"}},
        {emoji = "😪", keywords = {"sleepy", "tired"}},
        {emoji = "😵", keywords = {"dizzy", "confused"}},
        {emoji = "🤐", keywords = {"zipper", "mouth", "secret"}},
        {emoji = "🥴", keywords = {"woozy", "drunk", "dizzy"}},
        {emoji = "🤢", keywords = {"nauseated", "sick"}},
        {emoji = "🤮", keywords = {"vomit", "sick", "puke"}},
        {emoji = "🤧", keywords = {"sneeze", "sick"}},
        {emoji = "😷", keywords = {"mask", "sick", "medical"}},
        {emoji = "🤒", keywords = {"thermometer", "sick", "fever"}},
        {emoji = "🤕", keywords = {"bandage", "hurt", "injured"}},

        -- Gestures & Body Parts
        {emoji = "👍", keywords = {"thumbs", "up", "like", "good", "yes", "ok", "approve"}},
        {emoji = "👎", keywords = {"thumbs", "down", "dislike", "bad", "no"}},
        {emoji = "👊", keywords = {"fist", "bump", "punch"}},
        {emoji = "✊", keywords = {"fist", "power"}},
        {emoji = "🤛", keywords = {"left", "fist", "bump"}},
        {emoji = "🤜", keywords = {"right", "fist", "bump"}},
        {emoji = "🤞", keywords = {"fingers", "crossed", "luck", "hope"}},
        {emoji = "✌️", keywords = {"victory", "peace"}},
        {emoji = "🤟", keywords = {"love", "you"}},
        {emoji = "🤘", keywords = {"rock", "metal", "horns"}},
        {emoji = "👌", keywords = {"ok", "okay", "perfect"}},
        {emoji = "🤌", keywords = {"pinched", "fingers", "italian"}},
        {emoji = "🤏", keywords = {"pinch", "small"}},
        {emoji = "👈", keywords = {"left", "point"}},
        {emoji = "👉", keywords = {"right", "point"}},
        {emoji = "👆", keywords = {"up", "point"}},
        {emoji = "👇", keywords = {"down", "point"}},
        {emoji = "☝️", keywords = {"index", "point", "up"}},
        {emoji = "✋", keywords = {"hand", "raised", "stop"}},
        {emoji = "🤚", keywords = {"raised", "back", "hand"}},
        {emoji = "🖐️", keywords = {"hand", "five", "fingers"}},
        {emoji = "🖖", keywords = {"vulcan", "spock", "star", "trek"}},
        {emoji = "👋", keywords = {"wave", "hello", "bye", "hi"}},
        {emoji = "🤙", keywords = {"call", "me", "shaka"}},
        {emoji = "💪", keywords = {"muscle", "strong", "flex", "strength"}},
        {emoji = "🙏", keywords = {"pray", "thanks", "please", "namaste"}},
        {emoji = "🤝", keywords = {"handshake", "deal", "agreement"}},
        {emoji = "👏", keywords = {"clap", "applause", "congrats"}},
        {emoji = "🙌", keywords = {"raised", "hands", "celebrate", "praise", "yay"}},

        -- Hearts & Love
        {emoji = "❤️", keywords = {"heart", "love", "red"}},
        {emoji = "🧡", keywords = {"orange", "heart", "love"}},
        {emoji = "💛", keywords = {"yellow", "heart", "love"}},
        {emoji = "💚", keywords = {"green", "heart", "love"}},
        {emoji = "💙", keywords = {"blue", "heart", "love"}},
        {emoji = "💜", keywords = {"purple", "heart", "love"}},
        {emoji = "🖤", keywords = {"black", "heart", "love"}},
        {emoji = "🤍", keywords = {"white", "heart", "love"}},
        {emoji = "🤎", keywords = {"brown", "heart", "love"}},
        {emoji = "💔", keywords = {"broken", "heart", "sad"}},
        {emoji = "❤️‍🔥", keywords = {"heart", "fire", "love", "passion"}},
        {emoji = "❤️‍🩹", keywords = {"mending", "heart", "healing"}},
        {emoji = "💕", keywords = {"two", "hearts", "love"}},
        {emoji = "💞", keywords = {"revolving", "hearts", "love"}},
        {emoji = "💓", keywords = {"beating", "heart", "love"}},
        {emoji = "💗", keywords = {"growing", "heart", "love"}},
        {emoji = "💖", keywords = {"sparkling", "heart", "love"}},
        {emoji = "💘", keywords = {"cupid", "arrow", "heart", "love"}},
        {emoji = "💝", keywords = {"gift", "heart", "love"}},
        {emoji = "💟", keywords = {"heart", "decoration"}},

        // Common symbols
        {emoji = "✅", keywords = {"check", "mark", "yes", "done", "complete", "success"}},
        {emoji = "✔️", keywords = {"check", "yes", "done"}},
        {emoji = "❌", keywords = {"x", "cross", "no", "wrong", "error"}},
        {emoji = "⭐", keywords = {"star", "favorite"}},
        {emoji = "🌟", keywords = {"glowing", "star", "sparkle"}},
        {emoji = "⚡", keywords = {"lightning", "zap", "fast", "power"}},
        {emoji = "🔥", keywords = {"fire", "hot", "lit", "flame"}},
        {emoji = "💯", keywords = {"hundred", "100", "perfect", "full"}},
        {emoji = "💫", keywords = {"dizzy", "star"}},
        {emoji = "✨", keywords = {"sparkle", "shine", "magic"}},
        {emoji = "🎉", keywords = {"party", "celebrate", "congrats", "tada"}},
        {emoji = "🎊", keywords = {"confetti", "celebrate", "party"}},
        {emoji = "🎈", keywords = {"balloon", "party", "celebrate"}},
        {emoji = "🎁", keywords = {"gift", "present", "birthday"}},
        {emoji = "🏆", keywords = {"trophy", "win", "award", "champion"}},
        {emoji = "🥇", keywords = {"gold", "medal", "first", "winner"}},
        {emoji = "🥈", keywords = {"silver", "medal", "second"}},
        {emoji = "🥉", keywords = {"bronze", "medal", "third"}},

        // Nature
        {emoji = "🌈", keywords = {"rainbow", "colorful"}},
        {emoji = "☀️", keywords = {"sun", "sunny", "bright"}},
        {emoji = "🌙", keywords = {"moon", "night"}},
        {emoji = "⭐", keywords = {"star"}},
        {emoji = "🌺", keywords = {"flower", "hibiscus"}},
        {emoji = "🌸", keywords = {"cherry", "blossom", "flower"}},
        {emoji = "🌼", keywords = {"blossom", "flower"}},
        {emoji = "🌻", keywords = {"sunflower", "flower"}},
        {emoji = "🌹", keywords = {"rose", "flower", "love"}},
        {emoji = "🌷", keywords = {"tulip", "flower"}},
        {emoji = "🌱", keywords = {"seedling", "plant", "grow"}},
        {emoji = "🌿", keywords = {"herb", "leaf", "plant"}},
        {emoji = "🍀", keywords = {"clover", "luck", "four", "leaf"}},
        {emoji = "🌵", keywords = {"cactus", "desert"}},
        {emoji = "🌴", keywords = {"palm", "tree", "tropical"}},
        {emoji = "🌳", keywords = {"tree", "nature"}},
        {emoji = "🌲", keywords = {"evergreen", "tree", "pine"}},

        // Food & Drink
        {emoji = "☕", keywords = {"coffee", "cafe", "hot", "drink"}},
        {emoji = "🍕", keywords = {"pizza", "food"}},
        {emoji = "🍔", keywords = {"burger", "hamburger", "food"}},
        {emoji = "🍟", keywords = {"fries", "french", "food"}},
        {emoji = "🌭", keywords = {"hot", "dog", "food"}},
        {emoji = "🍿", keywords = {"popcorn", "snack"}},
        {emoji = "🍩", keywords = {"donut", "doughnut", "sweet"}},
        {emoji = "🍪", keywords = {"cookie", "sweet"}},
        {emoji = "🎂", keywords = {"cake", "birthday", "celebrate"}},
        {emoji = "🍰", keywords = {"cake", "slice", "dessert"}},
        {emoji = "🧁", keywords = {"cupcake", "sweet"}},
        {emoji = "🍦", keywords = {"ice", "cream", "soft", "serve"}},
        {emoji = "🍨", keywords = {"ice", "cream", "dessert"}},
        {emoji = "🍧", keywords = {"shaved", "ice", "dessert"}},
        {emoji = "🍭", keywords = {"lollipop", "candy", "sweet"}},
        {emoji = "🍬", keywords = {"candy", "sweet"}},
        {emoji = "🍫", keywords = {"chocolate", "bar", "sweet"}},
        {emoji = "🍎", keywords = {"apple", "red", "fruit"}},
        {emoji = "🍏", keywords = {"apple", "green", "fruit"}},
        {emoji = "🍊", keywords = {"orange", "fruit"}},
        {emoji = "🍋", keywords = {"lemon", "fruit"}},
        {emoji = "🍌", keywords = {"banana", "fruit"}},
        {emoji = "🍉", keywords = {"watermelon", "fruit"}},
        {emoji = "🍇", keywords = {"grapes", "fruit"}},
        {emoji = "🍓", keywords = {"strawberry", "fruit"}},
        {emoji = "🍑", keywords = {"peach", "fruit"}},
        {emoji = "🍒", keywords = {"cherry", "fruit"}},
        {emoji = "🥝", keywords = {"kiwi", "fruit"}},
        {emoji = "🍅", keywords = {"tomato", "vegetable"}},
        {emoji = "🥑", keywords = {"avocado", "food"}},
        {emoji = "🍆", keywords = {"eggplant", "vegetable"}},
        {emoji = "🥦", keywords = {"broccoli", "vegetable"}},
        {emoji = "🥕", keywords = {"carrot", "vegetable"}},
        {emoji = "🌽", keywords = {"corn", "vegetable"}},
        {emoji = "🥐", keywords = {"croissant", "bread"}},
        {emoji = "🥖", keywords = {"baguette", "bread", "french"}},
        {emoji = "🍞", keywords = {"bread", "loaf"}},
        {emoji = "🥯", keywords = {"bagel", "bread"}},
        {emoji = "🍕", keywords = {"pizza"}},
        {emoji = "🍝", keywords = {"spaghetti", "pasta"}},
        {emoji = "🍜", keywords = {"noodles", "ramen", "bowl"}},
        {emoji = "🍲", keywords = {"stew", "pot", "soup"}},
        {emoji = "🍛", keywords = {"curry", "rice"}},
        {emoji = "🍣", keywords = {"sushi", "japanese"}},
        {emoji = "🍱", keywords = {"bento", "box", "japanese"}},
        {emoji = "🍙", keywords = {"rice", "ball", "onigiri"}},
        {emoji = "🥟", keywords = {"dumpling", "food"}},
        {emoji = "🥠", keywords = {"fortune", "cookie"}},
        {emoji = "🥡", keywords = {"takeout", "box", "chinese"}},
        {emoji = "🍺", keywords = {"beer", "drink", "alcohol"}},
        {emoji = "🍻", keywords = {"beers", "cheers", "toast", "drink"}},
        {emoji = "🍷", keywords = {"wine", "glass", "drink"}},
        {emoji = "🥂", keywords = {"champagne", "toast", "celebrate"}},
        {emoji = "🍾", keywords = {"champagne", "bottle", "celebrate"}},
        {emoji = "🍹", keywords = {"tropical", "drink", "cocktail"}},
        {emoji = "🍸", keywords = {"cocktail", "martini", "drink"}},
        {emoji = "🥃", keywords = {"whiskey", "glass", "drink"}},

        // Animals
        {emoji = "🐶", keywords = {"dog", "puppy", "pet"}},
        {emoji = "🐱", keywords = {"cat", "kitten", "pet"}},
        {emoji = "🐭", keywords = {"mouse", "rat"}},
        {emoji = "🐹", keywords = {"hamster", "pet"}},
        {emoji = "🐰", keywords = {"rabbit", "bunny"}},
        {emoji = "🦊", keywords = {"fox"}},
        {emoji = "🐻", keywords = {"bear"}},
        {emoji = "🐼", keywords = {"panda", "bear"}},
        {emoji = "🐨", keywords = {"koala", "bear"}},
        {emoji = "🐯", keywords = {"tiger"}},
        {emoji = "🦁", keywords = {"lion"}},
        {emoji = "🐮", keywords = {"cow"}},
        {emoji = "🐷", keywords = {"pig"}},
        {emoji = "🐸", keywords = {"frog"}},
        {emoji = "🐵", keywords = {"monkey"}},
        {emoji = "🙈", keywords = {"see", "no", "evil", "monkey"}},
        {emoji = "🙉", keywords = {"hear", "no", "evil", "monkey"}},
        {emoji = "🙊", keywords = {"speak", "no", "evil", "monkey"}},
        {emoji = "🐒", keywords = {"monkey"}},
        {emoji = "🦍", keywords = {"gorilla", "monkey"}},
        {emoji = "🐔", keywords = {"chicken", "hen"}},
        {emoji = "🐧", keywords = {"penguin", "bird"}},
        {emoji = "🐦", keywords = {"bird"}},
        {emoji = "🐤", keywords = {"baby", "chick", "bird"}},
        {emoji = "🐣", keywords = {"hatching", "chick", "bird"}},
        {emoji = "🐥", keywords = {"chick", "bird"}},
        {emoji = "🦆", keywords = {"duck", "bird"}},
        {emoji = "🦅", keywords = {"eagle", "bird"}},
        {emoji = "🦉", keywords = {"owl", "bird"}},
        {emoji = "🦇", keywords = {"bat"}},
        {emoji = "🐺", keywords = {"wolf"}},
        {emoji = "🐗", keywords = {"boar", "pig"}},
        {emoji = "🐴", keywords = {"horse"}},
        {emoji = "🦄", keywords = {"unicorn", "magical"}},
        {emoji = "🐝", keywords = {"bee", "honey"}},
        {emoji = "🐛", keywords = {"bug", "caterpillar"}},
        {emoji = "🦋", keywords = {"butterfly"}},
        {emoji = "🐌", keywords = {"snail", "slow"}},
        {emoji = "🐞", keywords = {"ladybug", "bug"}},
        {emoji = "🐜", keywords = {"ant", "bug"}},
        {emoji = "🦗", keywords = {"cricket", "bug"}},
        {emoji = "🕷️", keywords = {"spider", "bug"}},
        {emoji = "🦂", keywords = {"scorpion"}},
        {emoji = "🦟", keywords = {"mosquito", "bug"}},
        {emoji = "🐢", keywords = {"turtle", "slow"}},
        {emoji = "🐍", keywords = {"snake"}},
        {emoji = "🦎", keywords = {"lizard", "gecko"}},
        {emoji = "🐙", keywords = {"octopus"}},
        {emoji = "🦑", keywords = {"squid"}},
        {emoji = "🦀", keywords = {"crab"}},
        {emoji = "🦞", keywords = {"lobster"}},
        {emoji = "🦐", keywords = {"shrimp"}},
        {emoji = "🐠", keywords = {"fish", "tropical"}},
        {emoji = "🐟", keywords = {"fish"}},
        {emoji = "🐡", keywords = {"blowfish", "puffer"}},
        {emoji = "🐬", keywords = {"dolphin"}},
        {emoji = "🦈", keywords = {"shark"}},
        {emoji = "🐳", keywords = {"whale", "spouting"}},
        {emoji = "🐋", keywords = {"whale"}},

        // Activities & Sports
        {emoji = "⚽", keywords = {"soccer", "ball", "football"}},
        {emoji = "🏀", keywords = {"basketball", "ball"}},
        {emoji = "🏈", keywords = {"football", "american"}},
        {emoji = "⚾", keywords = {"baseball", "ball"}},
        {emoji = "🥎", keywords = {"softball", "ball"}},
        {emoji = "🎾", keywords = {"tennis", "ball"}},
        {emoji = "🏐", keywords = {"volleyball", "ball"}},
        {emoji = "🏉", keywords = {"rugby", "ball"}},
        {emoji = "🥏", keywords = {"frisbee", "disc"}},
        {emoji = "🎱", keywords = {"pool", "8ball", "billiards"}},
        {emoji = "🏓", keywords = {"ping", "pong", "table", "tennis"}},
        {emoji = "🏸", keywords = {"badminton"}},
        {emoji = "🥊", keywords = {"boxing", "glove"}},
        {emoji = "🥋", keywords = {"martial", "arts", "karate"}},
        {emoji = "🥅", keywords = {"goal", "net"}},
        {emoji = "⛳", keywords = {"golf", "flag"}},
        {emoji = "🏹", keywords = {"bow", "arrow", "archery"}},
        {emoji = "🎣", keywords = {"fishing", "pole"}},
        {emoji = "🎮", keywords = {"game", "controller", "video", "games"}},
        {emoji = "🕹️", keywords = {"joystick", "game"}},
        {emoji = "🎯", keywords = {"dart", "target", "bullseye"}},
        {emoji = "🎲", keywords = {"dice", "game"}},
        {emoji = "🎰", keywords = {"slot", "machine", "gambling"}},
        {emoji = "🎳", keywords = {"bowling"}},

        // Travel & Places
        {emoji = "🚗", keywords = {"car", "automobile"}},
        {emoji = "🚕", keywords = {"taxi", "cab"}},
        {emoji = "🚙", keywords = {"suv", "car"}},
        {emoji = "🚌", keywords = {"bus"}},
        {emoji = "🚎", keywords = {"trolley", "bus"}},
        {emoji = "🏎️", keywords = {"race", "car", "fast"}},
        {emoji = "🚓", keywords = {"police", "car", "cop"}},
        {emoji = "🚑", keywords = {"ambulance", "emergency"}},
        {emoji = "🚒", keywords = {"fire", "truck", "engine"}},
        {emoji = "🚐", keywords = {"minibus", "van"}},
        {emoji = "🚚", keywords = {"truck", "delivery"}},
        {emoji = "🚛", keywords = {"truck", "semi", "lorry"}},
        {emoji = "🚜", keywords = {"tractor", "farm"}},
        {emoji = "🏍️", keywords = {"motorcycle", "bike"}},
        {emoji = "🛵", keywords = {"scooter", "moped"}},
        {emoji = "🚲", keywords = {"bicycle", "bike"}},
        {emoji = "🛴", keywords = {"scooter", "kick"}},
        {emoji = "✈️", keywords = {"airplane", "plane", "flight"}},
        {emoji = "🚁", keywords = {"helicopter"}},
        {emoji = "🚀", keywords = {"rocket", "space", "fast", "launch"}},
        {emoji = "🛸", keywords = {"ufo", "alien", "flying", "saucer"}},
        {emoji = "🚢", keywords = {"ship", "boat"}},
        {emoji = "⛵", keywords = {"sailboat", "boat"}},
        {emoji = "🚤", keywords = {"speedboat", "boat"}},
        {emoji = "⛴️", keywords = {"ferry", "boat"}},
        {emoji = "🛥️", keywords = {"motor", "boat"}},
        {emoji = "🚂", keywords = {"train", "locomotive"}},
        {emoji = "🚆", keywords = {"train"}},
        {emoji = "🚇", keywords = {"metro", "subway"}},
        {emoji = "🚊", keywords = {"tram"}},
        {emoji = "🚝", keywords = {"monorail"}},
        {emoji = "🚋", keywords = {"tram", "car"}},
        {emoji = "🚃", keywords = {"railway", "car"}},
        {emoji = "⛽", keywords = {"gas", "fuel", "pump"}},
        {emoji = "🏠", keywords = {"house", "home"}},
        {emoji = "🏡", keywords = {"house", "garden", "home"}},
        {emoji = "🏢", keywords = {"office", "building"}},
        {emoji = "🏣", keywords = {"post", "office"}},
        {emoji = "🏤", keywords = {"european", "post", "office"}},
        {emoji = "🏥", keywords = {"hospital", "medical"}},
        {emoji = "🏦", keywords = {"bank"}},
        {emoji = "🏨", keywords = {"hotel"}},
        {emoji = "🏩", keywords = {"love", "hotel"}},
        {emoji = "🏪", keywords = {"convenience", "store"}},
        {emoji = "🏫", keywords = {"school"}},
        {emoji = "🏬", keywords = {"department", "store"}},
        {emoji = "🏭", keywords = {"factory", "industrial"}},
        {emoji = "🏯", keywords = {"castle", "japanese"}},
        {emoji = "🏰", keywords = {"castle", "european"}},
        {emoji = "🗼", keywords = {"tokyo", "tower"}},
        {emoji = "🗽", keywords = {"statue", "liberty"}},
        {emoji = "⛪", keywords = {"church", "religion"}},
        {emoji = "🕌", keywords = {"mosque", "religion"}},
        {emoji = "🛕", keywords = {"temple", "hindu"}},
        {emoji = "🕍", keywords = {"synagogue", "religion"}},
        {emoji = "⛩️", keywords = {"shrine", "japanese"}},
        {emoji = "🌍", keywords = {"globe", "earth", "world", "europe"}},
        {emoji = "🌎", keywords = {"globe", "earth", "world", "americas"}},
        {emoji = "🌏", keywords = {"globe", "earth", "world", "asia"}},
        {emoji = "🗺️", keywords = {"map", "world"}},
        {emoji = "🗾", keywords = {"japan", "map"}},
        {emoji = "🧭", keywords = {"compass"}},
        {emoji = "⛰️", keywords = {"mountain"}},
        {emoji = "🏔️", keywords = {"snow", "mountain"}},
        {emoji = "🗻", keywords = {"mount", "fuji", "mountain"}},
        {emoji = "🏕️", keywords = {"camping"}},
        {emoji = "🏖️", keywords = {"beach", "umbrella"}},
        {emoji = "🏝️", keywords = {"island", "desert"}},
        {emoji = "🏜️", keywords = {"desert"}},
        {emoji = "🏞️", keywords = {"national", "park"}},
        {emoji = "🏟️", keywords = {"stadium"}},

        // Objects & Tech
        {emoji = "💻", keywords = {"laptop", "computer", "pc", "macbook"}},
        {emoji = "🖥️", keywords = {"desktop", "computer", "pc"}},
        {emoji = "⌨️", keywords = {"keyboard"}},
        {emoji = "🖱️", keywords = {"mouse", "computer"}},
        {emoji = "🖨️", keywords = {"printer"}},
        {emoji = "📱", keywords = {"phone", "mobile", "iphone", "smartphone"}},
        {emoji = "☎️", keywords = {"phone", "telephone"}},
        {emoji = "📞", keywords = {"phone", "receiver"}},
        {emoji = "📟", keywords = {"pager", "beeper"}},
        {emoji = "📠", keywords = {"fax"}},
        {emoji = "📡", keywords = {"satellite", "antenna"}},
        {emoji = "📺", keywords = {"tv", "television"}},
        {emoji = "📻", keywords = {"radio"}},
        {emoji = "🎙️", keywords = {"microphone", "studio"}},
        {emoji = "🎚️", keywords = {"level", "slider"}},
        {emoji = "🎛️", keywords = {"control", "knobs"}},
        {emoji = "🧭", keywords = {"compass"}},
        {emoji = "⏰", keywords = {"alarm", "clock"}},
        {emoji = "⏱️", keywords = {"stopwatch", "timer"}},
        {emoji = "⏲️", keywords = {"timer", "clock"}},
        {emoji = "⌚", keywords = {"watch", "apple", "time"}},
        {emoji = "📷", keywords = {"camera", "photo"}},
        {emoji = "📸", keywords = {"camera", "flash", "photo"}},
        {emoji = "📹", keywords = {"video", "camera"}},
        {emoji = "🎥", keywords = {"movie", "camera", "film"}},
        {emoji = "📽️", keywords = {"film", "projector"}},
        {emoji = "🎬", keywords = {"clapper", "board", "movie"}},
        {emoji = "📞", keywords = {"telephone", "receiver"}},
        {emoji = "☎️", keywords = {"telephone"}},
        {emoji = "📟", keywords = {"pager"}},
        {emoji = "📠", keywords = {"fax"}},
        {emoji = "📺", keywords = {"tv", "television"}},
        {emoji = "📻", keywords = {"radio"}},
        {emoji = "🎙️", keywords = {"microphone"}},
        {emoji = "🎚️", keywords = {"level", "slider"}},
        {emoji = "🎛️", keywords = {"control", "knobs"}},
        {emoji = "🔋", keywords = {"battery", "power"}},
        {emoji = "🔌", keywords = {"plug", "electric"}},
        {emoji = "💡", keywords = {"bulb", "light", "idea"}},
        {emoji = "🔦", keywords = {"flashlight", "torch"}},
        {emoji = "🕯️", keywords = {"candle", "light"}},
        {emoji = "🗑️", keywords = {"trash", "garbage", "delete"}},
        {emoji = "🛒", keywords = {"shopping", "cart", "trolley"}},
        {emoji = "💰", keywords = {"money", "bag", "cash"}},
        {emoji = "💵", keywords = {"dollar", "bill", "money"}},
        {emoji = "💴", keywords = {"yen", "money"}},
        {emoji = "💶", keywords = {"euro", "money"}},
        {emoji = "💷", keywords = {"pound", "money"}},
        {emoji = "💳", keywords = {"credit", "card"}},
        {emoji = "💎", keywords = {"gem", "diamond", "jewel"}},
        {emoji = "⚖️", keywords = {"scale", "balance", "justice"}},
        {emoji = "🔨", keywords = {"hammer", "tool"}},
        {emoji = "🪛", keywords = {"screwdriver", "tool"}},
        {emoji = "🔧", keywords = {"wrench", "tool"}},
        {emoji = "🔩", keywords = {"nut", "bolt"}},
        {emoji = "⚙️", keywords = {"gear", "settings"}},
        {emoji = "🔗", keywords = {"link", "chain"}},
        {emoji = "⛓️", keywords = {"chains"}},
        {emoji = "📎", keywords = {"paperclip"}},
        {emoji = "📌", keywords = {"pin", "pushpin"}},
        {emoji = "📍", keywords = {"pin", "location"}},
        {emoji = "✂️", keywords = {"scissors", "cut"}},
        {emoji = "📏", keywords = {"ruler", "measure"}},
        {emoji = "📐", keywords = {"triangular", "ruler"}},
        {emoji = "🗂️", keywords = {"card", "index", "dividers"}},
        {emoji = "📁", keywords = {"folder", "file"}},
        {emoji = "📂", keywords = {"open", "folder", "file"}},
        {emoji = "📋", keywords = {"clipboard"}},
        {emoji = "📄", keywords = {"page", "document"}},
        {emoji = "📃", keywords = {"page", "curl", "document"}},
        {emoji = "📰", keywords = {"newspaper", "news"}},
        {emoji = "📑", keywords = {"bookmark", "tabs"}},
        {emoji = "🔖", keywords = {"bookmark"}},
        {emoji = "📚", keywords = {"books", "library"}},
        {emoji = "📖", keywords = {"book", "open", "reading"}},
        {emoji = "📕", keywords = {"closed", "book"}},
        {emoji = "📗", keywords = {"green", "book"}},
        {emoji = "📘", keywords = {"blue", "book"}},
        {emoji = "📙", keywords = {"orange", "book"}},
        {emoji = "📓", keywords = {"notebook"}},
        {emoji = "📔", keywords = {"notebook", "decorative"}},
        {emoji = "📒", keywords = {"ledger"}},
        {emoji = "📝", keywords = {"memo", "note", "write", "pencil"}},
        {emoji = "✏️", keywords = {"pencil", "write"}},
        {emoji = "✒️", keywords = {"pen", "write"}},
        {emoji = "🖊️", keywords = {"pen", "write"}},
        {emoji = "🖋️", keywords = {"fountain", "pen", "write"}},
        {emoji = "🖍️", keywords = {"crayon", "draw"}},
        {emoji = "🖌️", keywords = {"paintbrush", "paint"}},
        {emoji = "🔍", keywords = {"magnifying", "glass", "search", "left"}},
        {emoji = "🔎", keywords = {"magnifying", "glass", "search", "right"}},
        {emoji = "🔐", keywords = {"locked", "key", "secure"}},
        {emoji = "🔒", keywords = {"locked", "secure", "private"}},
        {emoji = "🔓", keywords = {"unlocked", "open"}},
        {emoji = "🔑", keywords = {"key", "password"}},
        {emoji = "🗝️", keywords = {"old", "key"}},
    }

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
            -- Search in keywords
            local queryLower = query:lower()
            local found = false
            for _, keyword in ipairs(item.keywords) do
                if keyword:find(queryLower, 1, true) then
                    found = true
                    break
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

    -- Check for dictionary mode
    if query:match("^d ") then
        local word = query:sub(3)  -- Remove "d " prefix
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

    print("File launcher initialized (alt+space)")
end

return M
