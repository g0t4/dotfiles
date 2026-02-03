local M = {}

-- File launcher using mdfind (Spotlight index)
local chooser = nil
local currentTask = nil
local currentTaskId = 0  -- Track which task is current
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
        print("Terminating previous mdfind task...")
        currentTask:terminate()
        currentTask = nil
    end

    if query == "" or query == nil then
        callback({})
        return
    end

    -- Increment task ID so we can ignore old tasks
    currentTaskId = currentTaskId + 1
    local thisTaskId = currentTaskId

    -- Build mdfind command
    -- Full Spotlight search (faster than -name in practice)
    local cmd = "/usr/bin/mdfind"
    local args = {query}
    print("Starting new mdfind for query:", query, "taskId:", thisTaskId)

    local output = ""
    currentTask = hs.task.new(cmd, function(exitCode, _, stdErr)
        -- Ignore if this isn't the current task anymore
        if thisTaskId ~= currentTaskId then
            print("Ignoring old task", thisTaskId)
            return
        end

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
                    image = hs.image.iconForFile(line),
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

-- Search handler - cancels previous search on every keystroke
local function onQueryChange(query)
    -- searchFiles already cancels any running task, so just call it directly
    searchFiles(query, function(results)
        if chooser then
            chooser:choices(results)
        end
    end)
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

    print("File launcher initialized (alt+space, shift/cmd+enter to reveal, option+enter to copy path)")
end

return M
