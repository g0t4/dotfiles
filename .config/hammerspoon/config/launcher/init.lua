local M = {}

-- File launcher using mdfind (Spotlight index)
local chooser = nil
local currentCancelFunc = nil  -- Function to cancel current search
local currentSearchId = 0  -- Track current search across all searchers
local MAX_RESULTS = 30

-- LLM WebView state (for rendering AI responses as markdown)
local llmWebView = nil
local llmWebViewReady = false
local llmCurrentQuery = ""
local llmCurrentResponse = ""
local llmIsThinking = false

-- LLM server configuration
local LLM_SERVER = "http://ask.lan:8013"

-- Emoji data configuration
local EMOJI_CACHE_DIR = os.getenv("HOME") .. "/.local/share/hammerspoon"
local EMOJI_CACHE_FILE = EMOJI_CACHE_DIR .. "/emoji-data.json"
local EMOJI_DATA_URL = "https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/en/annotations.json"
local EMOJI_CACHE_MAX_AGE = 30 * 24 * 60 * 60  -- 30 days in seconds
local emojiData = nil  -- Cached parsed emoji data

-- History configuration
local HISTORY_FILE = os.getenv("HOME") .. "/.local/share/hammerspoon/launcher-history.txt"
local MAX_HISTORY_ITEMS = 1000
local history = {}  -- In-memory history (newest first)
local historyIndex = 0  -- Current position in history (0 = not browsing)

-- Helper to get just filename from path for display
local function getFilename(path)
    return path:match("^.+/(.+)$") or path
end

-- Helper to get parent directory for subtext
local function getDirectory(path)
    return path:match("^(.+)/[^/]+$") or ""
end

-- Load history from file
local function loadHistory()
    history = {}
    local file = io.open(HISTORY_FILE, "r")
    if not file then
        print("No history file found, starting fresh")
        return
    end

    for line in file:lines() do
        local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" then
            table.insert(history, trimmed)
        end
    end
    file:close()

    print("Loaded", #history, "history items")
end

-- Save history to file
local function saveHistory()
    -- Ensure directory exists
    local dir = HISTORY_FILE:match("^(.+)/[^/]+$")
    if dir then
        hs.fs.mkdir(dir)
    end

    local file = io.open(HISTORY_FILE, "w")
    if not file then
        print("Error: Could not save history to", HISTORY_FILE)
        return
    end

    -- Save in reverse order (newest first in file)
    for i = 1, math.min(#history, MAX_HISTORY_ITEMS) do
        file:write(history[i] .. "\n")
    end
    file:close()

    print("Saved", math.min(#history, MAX_HISTORY_ITEMS), "history items")
end

-- Add query to history (deduplicates and moves to front)
local function addToHistory(query)
    if not query or query == "" then
        return
    end

    -- Remove if already exists
    for i = #history, 1, -1 do
        if history[i] == query then
            table.remove(history, i)
        end
    end

    -- Add to front
    table.insert(history, 1, query)

    -- Trim to max size
    while #history > MAX_HISTORY_ITEMS do
        table.remove(history)
    end

    -- Save to disk
    saveHistory()
    print("Added to history:", query)
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

-- Application search mode using mdfind for system-wide search
-- Returns a cancel function
local function searchApplications(query, searchId, callback)
    -- Build mdfind query for all application bundles
    local mdfind_query = "kMDItemContentType == 'com.apple.application-bundle'"

    -- Add name filter if query provided
    if query ~= "" then
        local escaped_query = query:gsub("'", "'\\''")
        mdfind_query = mdfind_query .. string.format(" && kMDItemFSName == '*%s*'c", escaped_query)
    end

    local cmd = "/opt/homebrew/bin/stdbuf"
    local args = {"-o0", "/usr/bin/mdfind", mdfind_query}

    print("Starting app search, query:", query, "searchId:", searchId)
    print("mdfind query:", mdfind_query)

    local results = {}
    local buffer = ""
    local task = nil

    task = hs.task.new(cmd, function(exitCode, _, stdErr)
        if searchId ~= currentSearchId then
            print("Ignoring old app search", searchId)
            return
        end

        if exitCode ~= 0 and exitCode ~= 15 then
            print("mdfind app search error:", stdErr)
        end

        -- Final callback with results
        callback(searchId, results)
    end, function(_, stdOut, _)
        if searchId ~= currentSearchId then
            return true
        end

        buffer = buffer .. stdOut

        -- Process complete lines
        while true do
            local line, rest = buffer:match("([^\r\n]+)[\r\n](.*)")
            if not line then
                break
            end
            buffer = rest

            -- Extract app name from path (last component without .app extension)
            local appName = line:match("([^/]+)%.app$")
            if appName then
                table.insert(results, {
                    text = appName,
                    subText = line,
                    appPath = line,
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
            print("Canceling app search", searchId)
            task:terminate()
            task = nil
        end
    end
end

local function getLLMWebViewHTML()
    return [=[<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>AI Response</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body { height: 100%; }
    body {
      background: #1e1e1e;
      color: #d4d4d4;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
      font-size: 14px;
      line-height: 1.7;
      display: flex;
      flex-direction: column;
    }
    #header {
      padding: 10px 16px;
      background: #252526;
      color: #9cdcfe;
      font-size: 12px;
      font-weight: 500;
      border-bottom: 1px solid #333;
      flex-shrink: 0;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    #thinking {
      padding: 8px 16px;
      color: #888;
      font-style: italic;
      font-size: 13px;
      display: none;
      flex-shrink: 0;
    }
    #scroll { flex: 1; overflow-y: auto; padding: 16px; }
    h1, h2, h3 { color: #e0e0e0; margin: 16px 0 8px; line-height: 1.3; }
    h1 { font-size: 1.4em; }
    h2 { font-size: 1.2em; border-bottom: 1px solid #333; padding-bottom: 4px; }
    h3 { font-size: 1.05em; }
    p { margin: 8px 0; }
    a { color: #4ec9b0; text-decoration: none; }
    a:hover { text-decoration: underline; }
    code {
      font-family: "SF Mono", "Fira Code", "Menlo", monospace;
      font-size: 12.5px;
      background: #2d2d2d;
      padding: 1px 5px;
      border-radius: 3px;
      color: #ce9178;
    }
    pre {
      background: #1a1a2e;
      border: 1px solid #2d2d4e;
      border-radius: 6px;
      padding: 12px;
      overflow-x: auto;
      margin: 10px 0;
    }
    pre code { background: none; padding: 0; color: #d4d4d4; border-radius: 0; }
    blockquote { border-left: 3px solid #555; padding-left: 12px; color: #999; margin: 8px 0 8px 4px; }
    ul, ol { margin: 8px 0 8px 24px; }
    li { margin: 3px 0; }
    hr { border: none; border-top: 1px solid #333; margin: 16px 0; }
    table { border-collapse: collapse; width: 100%; margin: 8px 0; }
    th, td { border: 1px solid #444; padding: 6px 10px; text-align: left; }
    th { background: #252526; }
    .cursor {
      display: inline-block;
      width: 2px; height: 1em;
      background: #d4d4d4;
      animation: blink 1s step-end infinite;
      vertical-align: text-bottom;
      margin-left: 1px;
    }
    @keyframes blink { 50% { opacity: 0; } }
    /* VSCode dark token colors for hljs */
    .hljs { background: transparent !important; padding: 0 !important; }
    .hljs-keyword, .hljs-built_in { color: #569cd6; }
    .hljs-string { color: #ce9178; }
    .hljs-comment { color: #6a9955; font-style: italic; }
    .hljs-number { color: #b5cea8; }
    .hljs-function, .hljs-title { color: #dcdcaa; }
    .hljs-variable, .hljs-attr, .hljs-params { color: #9cdcfe; }
    .hljs-type { color: #4ec9b0; }
    .hljs-literal { color: #569cd6; }
    .hljs-meta { color: #808080; }
  </style>
</head>
<body>
  <div id="header">&#x1F4AC; AI Response</div>
  <div id="thinking">&#x280B; Thinking...</div>
  <div id="scroll">
    <div id="content"><span class="cursor"></span></div>
  </div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/marked@9/marked.min.js"></script>
  <script>
    // Fallback renderers if CDN scripts fail to load
    if (typeof marked === 'undefined') {
      window.marked = { use: function() {}, parse: function(t) {
        var e = t.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
        return '<pre style="white-space:pre-wrap;word-wrap:break-word">' + e + '</pre>';
      }};
    }
    if (typeof hljs === 'undefined') {
      window.hljs = { highlight: function(code) { return {value: code}; },
                      highlightAuto: function(code) { return {value: code}; },
                      getLanguage: function() { return null; } };
    }

    // Configure marked with syntax highlighting in fenced code blocks
    var renderer = new marked.Renderer();
    renderer.code = function(code, lang) {
      var highlighted;
      try {
        if (lang && hljs.getLanguage(lang)) {
          highlighted = hljs.highlight(code, {language: lang, ignoreIllegals: true}).value;
        } else {
          highlighted = hljs.highlightAuto(code).value;
        }
      } catch(e) {
        highlighted = code.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
      }
      return '<pre><code class="hljs language-' + (lang||'') + '">' + highlighted + '</code></pre>';
    };
    marked.use({ gfm: true, breaks: true, renderer: renderer });

    var streaming = true;
    var thinkingTimer = null;
    var thinkingFrame = 0;
    var thinkingFrames = ['⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏'];

    function setQuery(q) {
      document.getElementById('header').textContent = '💬 ' + q;
    }

    function showThinking() {
      var el = document.getElementById('thinking');
      el.style.display = 'block';
      if (!thinkingTimer) {
        thinkingTimer = setInterval(function() {
          thinkingFrame = (thinkingFrame + 1) % thinkingFrames.length;
          el.textContent = thinkingFrames[thinkingFrame] + ' Thinking...';
        }, 100);
      }
    }

    function hideThinking() {
      document.getElementById('thinking').style.display = 'none';
      if (thinkingTimer) { clearInterval(thinkingTimer); thinkingTimer = null; }
    }

    function updateContent(markdown, isThinking) {
      if (isThinking) { showThinking(); return; }
      hideThinking();
      if (!markdown) return;
      var cursorHtml = streaming ? '<span class="cursor"></span>' : '';
      document.getElementById('content').innerHTML = marked.parse(markdown) + cursorHtml;
      var scroll = document.getElementById('scroll');
      scroll.scrollTop = scroll.scrollHeight;
    }

    function setComplete() {
      streaming = false;
      hideThinking();
      document.querySelectorAll('.cursor').forEach(function(c) { c.remove(); });
    }

    // TODO: support multiple parallel generations — each generation gets its own card/section,
    // identified by a generationId, shown side-by-side or stacked with headers.
  </script>
</body>
</html>]=]
end

-- hs.json.encode only accepts tables, so escape strings manually for JS
local function jsStr(s)
    s = s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    return '"' .. s .. '"'
end

local function pushLLMContent()
    if not llmWebView or not llmWebViewReady then return end
    local js = string.format("updateContent(%s, %s)",
        jsStr(llmCurrentResponse),
        llmIsThinking and "true" or "false")
    llmWebView:evaluateJavaScript(js)
end

local function closeLLMWebView()
    if llmWebView then
        llmWebView:delete()
        llmWebView = nil
    end
    llmWebViewReady = false
    llmCurrentQuery = ""
    llmCurrentResponse = ""
    llmIsThinking = false
    -- Restore chooser results area
    if chooser then chooser:rows(10) end
end

local function createLLMWebView()
    if llmWebView then
        llmWebView:delete()
        llmWebView = nil
    end
    llmWebViewReady = false

    local screen = hs.screen.mainScreen():frame()
    local w = math.min(screen.w * 0.7, 1000)
    local h = screen.h * 0.55
    local x = screen.x + (screen.w - w) / 2
    local y = screen.y + screen.h * 0.38  -- below the chooser area at top

    local mask = hs.webview.windowMasks.titled
               + hs.webview.windowMasks.closable
               + hs.webview.windowMasks.resizable
               + hs.webview.windowMasks.nonactivating  -- don't steal focus from chooser input

    llmWebView = hs.webview.new({x=x, y=y, w=w, h=h})
    llmWebView:windowStyle(mask)
    llmWebView:level(hs.drawing.windowLevels.floating)
    llmWebView:navigationCallback(function(action, view)
        if action == "didFinishNavigation" then
            llmWebViewReady = true
            view:evaluateJavaScript(string.format("setQuery(%s)", jsStr(llmCurrentQuery)))
            pushLLMContent()
        end
    end)
    llmWebView:html(getLLMWebViewHTML())
    llmWebView:show()
    llmWebView:bringToFront(true)
end

-- LLM completion mode — streams response into a WebView rendered as markdown
-- Returns a cancel function
local function handleLLM(query, searchId, callback)
    if query == "" then
        closeLLMWebView()
        callback(searchId, {})
        return function() end
    end

    -- Open WebView and collapse chooser to input bar only
    llmCurrentQuery = query
    llmCurrentResponse = ""
    llmIsThinking = false
    if chooser then chooser:rows(0) end
    createLLMWebView()
    callback(searchId, {})

    local jsonPayload = hs.json.encode({
        messages = {
            {role = "system", content = "You are a helpful AI assistant. Use markdown formatting in your responses."},
            {role = "user", content = query},
        },
        stream = true,
        temperature = 0.7,
        max_tokens = 4096,
    })

    local cmd = "/usr/bin/curl"
    local args = {
        "-s", "-X", "POST",
        LLM_SERVER .. "/v1/chat/completions",
        "-H", "Content-Type: application/json",
        "-d", jsonPayload,
    }

    local buffer = ""
    local thinkingContent = ""
    local task = nil

    print("Starting LLM request:", query, "searchId:", searchId)

    task = hs.task.new(cmd, function(exitCode, _, stdErr)
        if searchId ~= currentSearchId then return end
        if exitCode ~= 0 then
            print("LLM error:", stdErr)
            llmCurrentResponse = "*Error connecting to LLM server*\n\n```\n" .. (stdErr or "Unknown") .. "\n```"
            llmIsThinking = false
        end
        if llmWebView and llmWebViewReady then
            llmWebView:evaluateJavaScript("setComplete()")
        end
    end, function(_, stdOut, _)
        if searchId ~= currentSearchId then return false end
        buffer = buffer .. stdOut

        while true do
            local line, rest = buffer:match("([^\r\n]+)[\r\n](.*)")
            if not line then break end
            buffer = rest

            local data = line:match("^data: (.+)$")
            if data and data ~= "[DONE]" then
                local ok, json = pcall(hs.json.decode, data)
                if ok and json.choices and json.choices[1] and json.choices[1].delta then
                    local delta = json.choices[1].delta
                    if delta.reasoning_content then
                        thinkingContent = thinkingContent .. delta.reasoning_content
                        llmIsThinking = true
                    end
                    if delta.content and delta.content ~= "" then
                        llmCurrentResponse = llmCurrentResponse .. delta.content
                        llmIsThinking = false
                    end
                    pushLLMContent()
                end
            end
        end

        return true
    end, args)

    task:start()

    return function()
        if task then task:terminate(); task = nil end
        closeLLMWebView()
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
-- Uses a single Python process to look up all words at once
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

    print("=== Dictionary Prefix Search ===")
    print("Query:", query)
    print("Matches:", table.concat(matchingWords, ", "))
    print("================================")

    -- Build a single Python script that looks up all words
    local wordsLiteral = ""
    for _, word in ipairs(matchingWords) do
        wordsLiteral = wordsLiteral .. string.format("%q, ", word)
    end

    local pythonScript = string.format([[
from CoreServices.DictionaryServices import DCSCopyTextDefinition
from CoreFoundation import CFRange
words = [%s]
for word in words:
    definition = DCSCopyTextDefinition(None, word, CFRange(0, len(word)))
    if definition:
        text = str(definition).strip()
        text = ' '.join(text.split())
        print(word + "\t" + (text[:120] + '...' if len(text) > 120 else text))
    else:
        print(word + "\t")
]], wordsLiteral)

    local tmpfile = string.format("/tmp/hammerspoon-dict-%d.py", searchId)
    local file = io.open(tmpfile, "w")
    file:write(pythonScript)
    file:close()

    local cancelled = false
    local output = ""
    local task = nil

    -- Use pyobjc venv that has CoreServices/DictionaryServices
    task = hs.task.new(os.getenv("HOME") .. "/repos/github/g0t4/dotfiles/.config/hammerspoon/config/learn/axuielem/pyobjc/.venv/bin/python",
        function(exitCode, _, _)  -- completion callback
            os.remove(tmpfile)
            if cancelled or searchId ~= currentSearchId then
                return
            end

            -- Parse output: each line is "word\tdefinition"
            local results = {}
            for line in output:gmatch("[^\r\n]+") do
                local word, definition = line:match("^([^\t]+)\t(.*)$")
                if word then
                    definition = definition and definition:gsub("%s+$", "") or ""
                    if definition ~= "" then
                        table.insert(results, {
                            text = word .. ": " .. definition,
                            subText = "Select to open in Dictionary.app",
                            dictionaryWord = word,
                            dictionaryDefinition = definition,
                            image = hs.image.imageFromName("NSBookmarkTemplate"),
                        })
                    end
                end
            end

            if #results == 0 then
                callback(searchId, {{
                    text = "No definitions found for: " .. query,
                    subText = "Try a different word",
                    image = hs.image.imageFromName("NSBookmarkTemplate"),
                }})
            else
                callback(searchId, results)
            end
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

    -- Show placeholder while waiting
    callback(searchId, {{
        text = "Looking up: " .. table.concat(matchingWords, ", "),
        subText = "Searching dictionary...",
        image = hs.image.imageFromName("NSBookmarkTemplate"),
    }})

    -- Return cancel function
    return function()
        cancelled = true
        if task then
            task:terminate()
            task = nil
        end
        os.remove(tmpfile)
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

-- Show available modes
local function showModes()
    return {
        {
            text = "b <query>",
            subText = "Bookmarks (e.g., 'b lock', 'b trash', 'b mute')",
            image = hs.image.imageFromName("NSBookmarksTemplate"),
        },
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

-- Bookmarks - fixed items that surface during rootless search
-- NOTE: actions are stored by name and dispatched in onChoice (hs.chooser can't serialize functions)
local bookmarks = {
    {
        name = "trash",
        keywords = {"trash", "bin", "rubbish", "deleted"},
        text = "Open Trash",
        subText = "Show Trash folder in Finder",
        image = hs.image.imageFromName("NSTrashFull"),
    },
    {
        name = "lock",
        keywords = {"lock", "lockscreen"},
        text = "Lock Screen",
        subText = "Lock the screen",
        image = hs.image.imageFromName("NSLockLockedTemplate"),
    },
    {
        name = "sleep",
        keywords = {"sleep"},
        text = "Sleep",
        subText = "Put computer to sleep",
        image = hs.image.imageFromName("NSStopProgressTemplate"),
    },
    {
        name = "logout",
        keywords = {"logout", "log out", "signout", "sign out"},
        text = "Log Out",
        subText = "Log out of current user session",
        image = hs.image.imageFromName("NSUser"),
    },
    {
        name = "restart",
        keywords = {"restart", "reboot"},
        text = "Restart",
        subText = "Restart the Mac",
        image = hs.image.imageFromName("NSRefreshTemplate"),
    },
    {
        name = "shutdown",
        keywords = {"shutdown", "shut down", "power off", "poweroff"},
        text = "Shut Down",
        subText = "Shut down the Mac",
        image = hs.image.imageFromName("NSStopProgressFreestandingTemplate"),
    },
    {
        name = "mute",
        keywords = {"mute", "unmute", "volume"},
        text = "Toggle Mute",
        subText = "Mute/unmute system audio",
        image = hs.image.imageFromName("NSTouchBarAudioOutputVolumeOffTemplate"),
    },
    {
        name = "reload",
        keywords = {"reload", "hammerspoon"},
        text = "Reload Hammerspoon",
        subText = "Reload Hammerspoon config",
        image = hs.image.imageFromName("NSRefreshTemplate"),
    },
    {
        name = "console",
        keywords = {"console", "hammerspoon"},
        text = "Hammerspoon Console",
        subText = "Open Hammerspoon console",
        image = hs.image.imageFromName("NSActionTemplate"),
    },
    {
        name = "dark",
        keywords = {"dark", "darkmode", "light", "theme", "appearance"},
        text = "Toggle Dark Mode",
        subText = "Switch between dark and light mode",
        image = hs.image.imageFromName("NSQuickLookTemplate"),
    },
    {
        name = "sentence_case",
        keywords = {"sentence", "case", "sentencecase"},
        text = "Sentence Case",
        subText = "Convert clipboard text to sentence case, copy and paste",
        image = hs.image.imageFromName("NSActionTemplate"),
    },
    {
        name = "title_case",
        keywords = {"title", "titlecase", "title_case"},
        text = "Title Case",
        subText = "Convert clipboard text to title case, copy and paste",
        image = hs.image.imageFromName("NSActionTemplate"),
    },
}

-- Bookmark action dispatch (keyed by name)
local bookmarkActions = {
    trash = function()
        hs.execute('open "trash://"')
    end,
    lock = function()
        hs.caffeinate.lockScreen()
    end,
    sleep = function()
        hs.caffeinate.systemSleep()
    end,
    logout = function()
        hs.osascript.applescript('tell application "System Events" to log out')
    end,
    restart = function()
        hs.osascript.applescript('tell application "System Events" to restart')
    end,
    shutdown = function()
        hs.osascript.applescript('tell application "System Events" to shut down')
    end,
    mute = function()
        local device = hs.audiodevice.defaultOutputDevice()
        if device then
            device:setMuted(not device:muted())
            local state = device:muted() and "Muted" or "Unmuted"
            hs.alert.show(state)
        end
    end,
    reload = function()
        hs.reload()
    end,
    console = function()
        hs.openConsole()
    end,
    dark = function()
        hs.osascript.applescript('tell app "System Events" to tell appearance preferences to set dark mode to not dark mode')
    end,
    sentence_case = function()
        -- Read current clipboard content
        local txt = hs.pasteboard.readString() or ""

        -- List of words that should retain their original casing.
        -- These are matched case‑insensitively after the sentence‑case conversion.
        local preserve_words = {
            "GNU", "PROMPT_COMMAND", "PIPESTATUS", "IFS", "PATH", "STDERR", "STDOUT",
            "STDIN", "TTY", "PTY", "PID", "PPID", "UID", "GID", "ANSI", "EOF", "EOL",
            "shopt", "sed", "awk", "wget", "vim", "nvim", "jq",
            "grok.com", "x.com", "PDF", "CSV", "eBay", "xAI", "DeepSearch", "DeeperSearch",
            "vLLM", "FastAPI", "StreamingResponse", "WebSocket", "WebSockets", "HTTPX",
            "ASGI", "WSGI", "GZipMiddleware", "SlowAPIMiddleware", "SlowApi",
            "HorizontalPodAutoscaler", "HPA", "CPU", "GitRepo", "K3s", "RKE2", "RKE", "RKE1",
            "GCP", "GKE", "YAML", "ChatGPT", "K8s", "GPU", "MCP", "ModelContextProtocol",
            "LLM", "LLMs", "AI", "HTTPS", "GH", "PAT",
            "StatefulSet", "DaemonSet", "CronJob", "ReplicaSet",
            "NodePort", "LoadBalancer", "ClusterIP",
            "PersistentVolume", "PersistentVolumeClaim", "StorageClass",
            "ConfigMap", "HostPath", "JDK", "DSL", "systemd", "dockerd", "containerd",
            "ctr", "runc", "k3s", "kubectl", "kubeadm", "PackageReference", "dotnet",
            "CLI", "aspnetcore", "SDK", "dockerignore", "WSL2", "WSL", "VirtualBox", "vagrant",
            "gitignore", "Dockerfile", "docker-compose", "docker-compose.yml", "compose.yml",
            "package.json", "git", "gRPC", "xDS", "VM", "VMs", "DNS",
            "/etc/resolv.conf", "dig", "HCL", "SMTP", "SIGHUP", "SIGKILL", "SIGINT", "SIGTERM",
            "MailHog", "VSCode", "SRV", "curl", "consul-template", "envconsul",
            "localhost", "tcpflow", "tcpdump", "ipconfig", "ifconfig", "NGINX",
            ".editorconfig", "EditorConfig", "Vagrantfile",
            "LF", "CRLF", "CR",
            ".gitconfig", ".gitignore", ".gitattributes", ".bash_history", ".zsh_history",
            ".hush_login", ".zshenv", ".zshrc", ".bashrc", ".bash_logout", ".profile",
            ".vscode", ".vagrant.d", ".vagrant", ".ssh", ".config",
            "bash_history",
        }

        -- Helper: convert a string to sentence case.
        local function to_sentence_case(s)
            return (s:gsub("([^.!?]+)([.!?]?)", function(sentence, punct)
                sentence = sentence:lower()
                sentence = sentence:gsub("^%s*%l", string.upper)
                return sentence .. punct
            end))
        end

        local new_txt = to_sentence_case(txt)

        -- Preserve the original casing of special words.
        for _, w in ipairs(preserve_words) do
            local lower = w:lower()
            -- Replace any occurrence of the lower‑cased word with the proper case.
            new_txt = new_txt:gsub(lower, w)
        end

        -- Write back to clipboard
        hs.pasteboard.writeObjects({new_txt})
        -- Type the text into the focused app
        hs.eventtap.keyStrokes(new_txt)
    end,
    title_case = function()
        -- wrapper function gets title cased value
        local stdout, ok, exit_type, rc = hs.execute("fish -c \"title_case_wrapper\"")
        if not ok then
            -- TODO need STDERR to show in this case? and stdout? not sure I can get STDERR with hs.exectue()?
            hs.alert.show("Title case conversion failed... rc=" .. rc)
            return
        end
        -- Trim trailing whitespace/newlines from the wrapper output.
        local title = stdout:gsub("%s+$", "")
        if title == "" then
            hs.alert.show("Title case produced empty result")
            return
        end
        print("title cased: ", title) -- remove when things are working well enough
        hs.pasteboard.writeObjects({ title })
        hs.eventtap.keyStrokes(title)
    end,
}

-- Tab completions: ordered list of {match, result} pairs
-- Priority: exact prefixes first, then keyword aliases, then bookmark keywords
local tabCompletions = {}

-- Prefix shortcuts (typing "a" + Tab → "a " enters app mode)
local prefixShortcuts = {"a", "b", "s", "d", "define", "g", "l", "o", "f", "py", "e", "v"}
for _, p in ipairs(prefixShortcuts) do
    table.insert(tabCompletions, {match = p, result = p .. " "})
end

-- Keyword aliases for prefixes (typing "app" + Tab → "a ")
local prefixAliases = {
    {"app", "a "}, {"apps", "a "}, {"applications", "a "},
    {"book", "b "}, {"bookmarks", "b "},
    {"settings", "s "}, {"system", "s "},
    {"dir", "d "}, {"directory", "d "},
    {"dict", "define "}, {"dictionary", "define "},
    {"google", "g "},
    {"lua", "l "}, {"calc", "l "},
    {"llm", "o "},
    {"fish", "f "},
    {"python", "py "},
    {"emoji", "e "},
    {"fuzzy", "v "},
}
for _, a in ipairs(prefixAliases) do
    table.insert(tabCompletions, {match = a[1], result = a[2]})
end

-- Bookmark keywords (typing "tra" + Tab → "trash")
for _, bookmark in ipairs(bookmarks) do
    for _, keyword in ipairs(bookmark.keywords) do
        table.insert(tabCompletions, {match = keyword, result = bookmark.name})
    end
end

-- Handle Tab key: find first completion where match starts with query
local function handleTabCompletion()
    if not chooser then return false end
    local query = chooser:query()
    if query == "" then return false end
    local queryLower = query:lower()

    for _, comp in ipairs(tabCompletions) do
        if comp.match:sub(1, #queryLower) == queryLower then
            chooser:query(comp.result)
            return true
        end
    end
    return false
end

-- Match bookmarks and prefix hints against a query
local function matchBookmarks(query)
    local queryLower = query:lower()
    local matches = {}

    -- Match bookmarks
    for _, bookmark in ipairs(bookmarks) do
        for _, keyword in ipairs(bookmark.keywords) do
            if keyword:find(queryLower, 1, true) then
                table.insert(matches, {
                    text = bookmark.text,
                    subText = bookmark.subText,
                    image = bookmark.image,
                    bookmark = bookmark.name,
                })
                break
            end
        end
    end

    -- Match prefix hints from showModes()
    local modes = showModes()
    for _, mode in ipairs(modes) do
        local modeText = mode.text:lower()
        local modeSub = mode.subText:lower()
        if modeText:find(queryLower, 1, true) or modeSub:find(queryLower, 1, true) then
            table.insert(matches, {
                text = mode.text,
                subText = mode.subText,
                image = mode.image,
                prefixHint = true,
            })
        end
    end

    return matches
end

-- Browse all bookmarks (b prefix)
local function handleBookmarks(query, searchId, callback)
    local results = {}
    local queryLower = query:lower()

    for _, bookmark in ipairs(bookmarks) do
        if query == "" then
            table.insert(results, {
                text = bookmark.text,
                subText = bookmark.subText,
                image = bookmark.image,
                bookmark = bookmark.name,
            })
        else
            -- Search name, text, subText, and keywords
            local found = false
            if bookmark.text:lower():find(queryLower, 1, true) or bookmark.subText:lower():find(queryLower, 1, true) then
                found = true
            end
            if not found then
                for _, keyword in ipairs(bookmark.keywords) do
                    if keyword:find(queryLower, 1, true) then
                        found = true
                        break
                    end
                end
            end
            if found then
                table.insert(results, {
                    text = bookmark.text,
                    subText = bookmark.subText,
                    image = bookmark.image,
                    bookmark = bookmark.name,
                })
            end
        end
    end

    callback(searchId, results)
    return function() end
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

-- Search handler - cancels previous search on every keystroke
local function onQueryChange(query)
    -- Reset history browsing when user starts typing
    -- (unless the query change came from history navigation)
    if chooser and chooser:query() ~= query then
        historyIndex = 0
    end

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

    -- Check for bookmarks mode
    if query:match("^b ") then
        local bookmarkQuery = query:sub(3)  -- Remove "b " prefix
        currentCancelFunc = handleBookmarks(bookmarkQuery, thisSearchId, handleResults)
        return
    end

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

    -- Default to file search, with bookmarks/prefix hints prepended
    local bookmarkMatches = matchBookmarks(query)

    -- Wrap handleResults to prepend bookmark matches to mdfind results
    local function handleResultsWithBookmarks(searchId, results)
        if searchId ~= currentSearchId then return end

        local merged = {}
        for _, item in ipairs(bookmarkMatches) do
            table.insert(merged, item)
        end
        for _, item in ipairs(results) do
            table.insert(merged, item)
        end

        if chooser then
            chooser:choices(merged)
        end
    end

    currentCancelFunc = searchFiles(query, thisSearchId, handleResultsWithBookmarks)
end

-- Active hotkeys (enabled while chooser is shown)
local refreshHotkeyCmdR = nil
local refreshHotkeyCtrlR = nil
local historyHotkeyUp = nil
local historyHotkeyDown = nil
local tabEventTap = nil

-- Delete active hotkeys
local function deleteActiveHotkeys()
    print("=== Deleting active hotkeys ===")
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
    if historyHotkeyUp then
        historyHotkeyUp:delete()
        historyHotkeyUp = nil
        print("Deleted Cmd+Up hotkey")
    end
    if historyHotkeyDown then
        historyHotkeyDown:delete()
        historyHotkeyDown = nil
        print("Deleted Cmd+Down hotkey")
    end
    if tabEventTap then
        tabEventTap:stop()
        tabEventTap = nil
        print("Stopped Tab eventtap")
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

-- Navigate to previous history item
local function historyPrevious()
    if not chooser or #history == 0 then
        return
    end

    -- If not browsing history yet, start from the beginning
    if historyIndex == 0 then
        historyIndex = 1
    else
        -- Move to next older item (if available)
        historyIndex = math.min(historyIndex + 1, #history)
    end

    -- Set query to history item
    local historyQuery = history[historyIndex]
    chooser:query(historyQuery)
    print("History up: index", historyIndex, "query:", historyQuery)
end

-- Navigate to next history item (or back to empty)
local function historyNext()
    if not chooser or historyIndex == 0 then
        return
    end

    -- Move to newer item
    historyIndex = math.max(historyIndex - 1, 0)

    if historyIndex == 0 then
        -- Back to empty query
        chooser:query("")
        print("History down: back to empty")
    else
        -- Set query to history item
        local historyQuery = history[historyIndex]
        chooser:query(historyQuery)
        print("History down: index", historyIndex, "query:", historyQuery)
    end
end

-- Handle file selection
local function onChoice(choice)
    -- Cancel any in-flight search (terminates curl, closes webview, etc.)
    if currentCancelFunc then
        currentCancelFunc()
        currentCancelFunc = nil
    end

    -- Save current query to history (whether selected or cancelled)
    local currentQuery = chooser and chooser:query() or ""
    if currentQuery ~= "" then
        addToHistory(currentQuery)
    end

    -- Reset history browsing
    historyIndex = 0

    -- Delete active hotkeys when chooser closes (whether by selection or escape)
    deleteActiveHotkeys()

    -- Log for debugging
    print("=== onChoice callback ===")
    print("choice:", hs.inspect(choice))
    local modifiers = hs.eventtap.checkKeyboardModifiers()
    print("modifiers:", hs.inspect(modifiers))
    print("========================")

    if not choice then
        return
    end

    -- Handle bookmark action
    if choice.bookmark then
        local action = bookmarkActions[choice.bookmark]
        if action then action() end
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

    -- Reset history browsing
    historyIndex = 0

    -- Create and enable active hotkeys
    if not refreshHotkeyCmdR then
        refreshHotkeyCmdR = hs.hotkey.new({"cmd"}, "r", refreshQuery)
        refreshHotkeyCtrlR = hs.hotkey.new({"ctrl"}, "r", refreshQuery)
        historyHotkeyUp = hs.hotkey.new({"cmd"}, "up", historyPrevious)
        historyHotkeyDown = hs.hotkey.new({"cmd"}, "down", historyNext)
    end
    refreshHotkeyCmdR:enable()
    refreshHotkeyCtrlR:enable()
    historyHotkeyUp:enable()
    historyHotkeyDown:enable()

    -- Tab completion eventtap
    if not tabEventTap then
        tabEventTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
            if event:getKeyCode() == 48 then -- Tab
                if handleTabCompletion() then
                    return true -- consume the event
                end
            end
            return false
        end)
    end
    tabEventTap:start()

    chooser:show()
end

-- Hide the launcher
function M.hide()
    if chooser then
        chooser:hide()
    end
    -- Delete active hotkeys when hidden
    deleteActiveHotkeys()
end

-- Setup keybinding
function M.init()
    -- Load history from disk
    loadHistory()

    hs.hotkey.bind({"alt"}, "space", function()
        M.show()
    end)

    print("File launcher initialized (alt+space)")
    print("History: Cmd+Up/Down to navigate,", #history, "items loaded")
end

return M
