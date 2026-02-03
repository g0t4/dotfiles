local M = {}

-- File launcher using mdfind (Spotlight index)
local chooser = nil
local searchTimer = nil
local currentTask = nil
local DEBOUNCE_DELAY = 0.2 -- seconds to wait after typing stops before searching
local MAX_RESULTS = 50

-- Helper to get just filename from path for display
local function getFilename(path)
    return path:match("^.+/(.+)$") or path
end

-- Helper to get parent directory for subtext
local function getDirectory(path)
    return path:match("^(.+)/[^/]+$") or ""
end

-- Perform mdfind search
local function searchFiles(query, callback)
    -- Cancel any existing search task
    if currentTask then
        currentTask:terminate()
        currentTask = nil
    end

    if query == "" or query == nil then
        callback({})
        return
    end

    -- Build mdfind command
    -- Use -name for filename matching (faster and what users typically want in a launcher)
    local cmd = "/usr/bin/mdfind"
    local args = {"-name", query}

    local output = ""
    currentTask = hs.task.new(cmd, function(exitCode, _, stdErr)
        currentTask = nil

        if exitCode ~= 0 then
            print("mdfind error:", stdErr)
            callback({})
            return
        end

        -- Parse results (one file path per line)
        local results = {}
        local count = 0
        for line in output:gmatch("[^\r\n]+") do
            if count >= MAX_RESULTS then
                break
            end

            -- Skip hidden files/directories (those with /. in path)
            if not line:match("/%.[^/]") then
                count = count + 1
                table.insert(results, {
                    text = getFilename(line),
                    subText = getDirectory(line),
                    path = line,
                })
            end
        end

        callback(results)
    end, function(_, stdOut, _)
        -- Stream callback - accumulate output
        output = output .. stdOut
        return true
    end, args)

    currentTask:start()
end

-- Debounced search handler
local function onQueryChange(query)
    -- Cancel existing timer
    if searchTimer then
        searchTimer:stop()
        searchTimer = nil
    end

    -- Set new timer
    searchTimer = hs.timer.doAfter(DEBOUNCE_DELAY, function()
        searchFiles(query, function(results)
            if chooser then
                chooser:choices(results)
            end
        end)
    end)
end

-- Handle file selection
local function onChoice(choice)
    if not choice then
        return
    end

    -- Check if cmd key is held
    local modifiers = hs.eventtap.checkKeyboardModifiers()

    if modifiers.cmd then
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
