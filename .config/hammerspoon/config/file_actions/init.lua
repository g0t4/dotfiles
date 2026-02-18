local M = {}

-- File actions menu for selected files (like Alfred's file actions)
local chooser = nil

-- Get selected files from the frontmost app
local function getSelectedFiles()
    local app = hs.application.frontmostApplication()
    local appName = app and app:name() or ""

    print("=== File Actions ===")
    print("Frontmost app:", appName)

    if appName == "Finder" then
        -- Get Finder selection via AppleScript
        local ok, result = hs.osascript.applescript([[
            tell application "Finder"
                set selectedItems to selection
                set pathList to ""
                repeat with anItem in selectedItems
                    set posixPath to POSIX path of (anItem as alias)
                    if pathList is "" then
                        set pathList to posixPath
                    else
                        set pathList to pathList & linefeed & posixPath
                    end if
                end repeat
                return pathList
            end tell
        ]])

        if ok and result and result ~= "" then
            local paths = {}
            for line in result:gmatch("[^\n]+") do
                -- Remove trailing slash from directories for consistency
                local path = line:gsub("/$", "")
                table.insert(paths, path)
            end
            print("Finder selection:", #paths, "items")
            return paths
        end
    end

    -- TODO: support other apps (e.g. Path Finder, Terminal, etc.)
    print("No files selected or unsupported app:", appName)
    return {}
end

-- Helper to get just filename from path
local function getFilename(path)
    return path:match("^.+/(.+)$") or path
end

-- Format file size for display
local function formatSize(bytes)
    if not bytes then return nil end
    if bytes < 1024 then
        return string.format("%d B", bytes)
    elseif bytes < 1024 * 1024 then
        return string.format("%.1f KB", bytes / 1024)
    elseif bytes < 1024 * 1024 * 1024 then
        return string.format("%.1f MB", bytes / (1024 * 1024))
    else
        return string.format("%.1f GB", bytes / (1024 * 1024 * 1024))
    end
end

-- Format relative time for display
local function formatTimeAgo(timestamp)
    if not timestamp then return nil end
    local diff = os.time() - timestamp
    if diff < 60 then
        return "just now"
    elseif diff < 3600 then
        local mins = math.floor(diff / 60)
        return mins .. (mins == 1 and " min ago" or " mins ago")
    elseif diff < 86400 then
        local hours = math.floor(diff / 3600)
        return hours .. (hours == 1 and " hour ago" or " hours ago")
    elseif diff < 604800 then
        local days = math.floor(diff / 86400)
        return days .. (days == 1 and " day ago" or " days ago")
    else
        return os.date("%b %d, %Y", timestamp)
    end
end

-- Build a rich summary string for selected files
local function buildSummary(paths)
    if #paths == 1 then
        local path = paths[1]
        local attrs = hs.fs.attributes(path)
        local parts = { getFilename(path) }
        if attrs then
            if attrs.mode == "directory" then
                table.insert(parts, "folder")
            elseif attrs.size then
                table.insert(parts, formatSize(attrs.size))
            end
            if attrs.modification then
                table.insert(parts, formatTimeAgo(attrs.modification))
            end
        end
        return table.concat(parts, " · ")
    else
        -- Multiple files: aggregate size
        local totalSize = 0
        local dirCount = 0
        local fileCount = 0
        for _, path in ipairs(paths) do
            local attrs = hs.fs.attributes(path)
            if attrs then
                if attrs.mode == "directory" then
                    dirCount = dirCount + 1
                else
                    fileCount = fileCount + 1
                    totalSize = totalSize + (attrs.size or 0)
                end
            end
        end
        local parts = {}
        if fileCount > 0 then
            table.insert(parts, fileCount .. (fileCount == 1 and " file" or " files"))
        end
        if dirCount > 0 then
            table.insert(parts, dirCount .. (dirCount == 1 and " folder" or " folders"))
        end
        if totalSize > 0 then
            table.insert(parts, formatSize(totalSize))
        end
        return table.concat(parts, " · ")
    end
end

-- Build the actions list for selected files
local function buildActions(paths)
    if #paths == 0 then
        return {{
            text = "No files selected",
            subText = "Select files in Finder first",
            image = hs.image.imageFromName("NSCaution"),
        }}
    end

    local summary = buildSummary(paths)

    local actions = {}

    -- Copy path(s)
    table.insert(actions, {
        text = "Copy Path",
        subText = summary,
        action = "copy_path",
        paths = paths,
        image = hs.image.imageFromName("NSPathTemplate"),
    })

    -- Copy file contents
    table.insert(actions, {
        text = "Copy File Contents",
        subText = summary,
        action = "copy_contents",
        paths = paths,
        image = hs.image.imageFromName("NSMultipleDocuments"),
    })

    -- Copy filename(s)
    table.insert(actions, {
        text = "Copy Filename",
        subText = summary,
        action = "copy_filename",
        paths = paths,
        image = hs.image.imageFromName("NSPathTemplate"),
    })

    -- Copy as Markdown link
    table.insert(actions, {
        text = "Copy as Markdown Link",
        subText = summary,
        action = "copy_markdown",
        paths = paths,
        image = hs.image.imageFromName("NSPathTemplate"),
    })

    -- Open Terminal Here
    table.insert(actions, {
        text = "Open Terminal Here",
        subText = summary,
        action = "open_terminal",
        paths = paths,
        image = hs.image.imageFromName("NSActionTemplate"),
    })

    -- Reveal in Finder (useful if triggered from non-Finder app later)
    table.insert(actions, {
        text = "Reveal in Finder",
        subText = summary,
        action = "reveal",
        paths = paths,
        image = hs.image.imageFromName("NSRevealFreestandingTemplate"),
    })

    -- Open with...
    table.insert(actions, {
        text = "Open With...",
        subText = "Choose application",
        action = "open_with",
        paths = paths,
        image = hs.image.imageFromName("NSShareTemplate"),
    })

    -- Diff (only for exactly 2 files)
    if #paths == 2 then
        table.insert(actions, {
            text = "Diff",
            subText = getFilename(paths[1]) .. " vs " .. getFilename(paths[2]),
            action = "diff",
            paths = paths,
            image = hs.image.imageFromName("NSColumnViewTemplate"),
        })
    end

    -- Move to Trash
    table.insert(actions, {
        text = "Move to Trash",
        subText = summary,
        action = "trash",
        paths = paths,
        image = hs.image.imageFromName("NSTrashFull"),
    })

    return actions
end

-- Execute the chosen action
local function onChoice(choice)
    if not choice or not choice.action then
        return
    end

    local paths = choice.paths

    if choice.action == "copy_contents" then
        local contents = {}
        local skipped = 0
        for _, path in ipairs(paths) do
            local attrs = hs.fs.attributes(path)
            if attrs and attrs.mode == "directory" then
                skipped = skipped + 1
            else
                local file = io.open(path, "r")
                if file then
                    local data = file:read("*all")
                    file:close()
                    if data then
                        if #paths > 1 then
                            table.insert(contents, "--- " .. getFilename(path) .. " ---\n" .. data)
                        else
                            table.insert(contents, data)
                        end
                    end
                else
                    skipped = skipped + 1
                end
            end
        end
        if #contents > 0 then
            hs.pasteboard.setContents(table.concat(contents, "\n\n"))
            local msg = #contents == 1 and "Contents copied" or #contents .. " files copied"
            if skipped > 0 then
                msg = msg .. " (" .. skipped .. " skipped)"
            end
            hs.alert.show(msg)
        else
            hs.alert.show("No readable file contents")
        end

    elseif choice.action == "copy_path" then
        local escaped = {}
        for _, path in ipairs(paths) do
            -- Backslash-escape shell metacharacters
            table.insert(escaped, (path:gsub("([%s%(%)%&%;%|%<%>%*%?%[%]%#%$%!%'%\"%\\])", "\\%1")))
        end
        local pathStr = table.concat(escaped, "\n")
        hs.pasteboard.setContents(pathStr)
        if #paths == 1 then
            hs.alert.show("Copied: " .. escaped[1])
        else
            hs.alert.show("Copied " .. #paths .. " paths")
        end

    elseif choice.action == "copy_filename" then
        local names = {}
        for _, path in ipairs(paths) do
            table.insert(names, getFilename(path))
        end
        local nameStr = table.concat(names, "\n")
        hs.pasteboard.setContents(nameStr)
        if #names == 1 then
            hs.alert.show("Copied: " .. names[1])
        else
            hs.alert.show("Copied " .. #names .. " filenames")
        end

    elseif choice.action == "copy_markdown" then
        local links = {}
        for _, path in ipairs(paths) do
            local name = getFilename(path)
            table.insert(links, string.format("[%s](file://%s)", name, path))
        end
        local linkStr = table.concat(links, "\n")
        hs.pasteboard.setContents(linkStr)
        if #links == 1 then
            hs.alert.show("Copied link: " .. links[1])
        else
            hs.alert.show("Copied " .. #links .. " markdown links")
        end

    elseif choice.action == "open_terminal" then
        for _, path in ipairs(paths) do
            -- Use the directory of the file (or the dir itself)
            local dir = path
            local attrs = hs.fs.attributes(path)
            if attrs and attrs.mode ~= "directory" then
                dir = path:match("^(.+)/[^/]+$") or path
            end
            hs.execute(string.format('open -a "Terminal" "%s"', dir))
        end

    elseif choice.action == "reveal" then
        for _, path in ipairs(paths) do
            hs.execute(string.format('open -R "%s"', path))
        end

    elseif choice.action == "open_with" then
        -- Show app chooser for "Open With"
        M.showOpenWith(paths)

    elseif choice.action == "diff" then
        local output, status = hs.execute(string.format('diff "%s" "%s"', paths[1], paths[2]))
        if status then
            hs.alert.show("Files are identical")
        else
            -- diff returns exit code 1 when files differ
            local result = output and output:gsub("%s+$", "") or ""
            if result ~= "" then
                hs.pasteboard.setContents(result)
                hs.alert.show("Files differ - diff copied to clipboard")
            else
                hs.alert.show("Files differ")
            end
        end

    elseif choice.action == "trash" then
        for _, path in ipairs(paths) do
            hs.execute(string.format('mv "%s" ~/.Trash/', path))
        end
        if #paths == 1 then
            hs.alert.show("Trashed: " .. getFilename(paths[1]))
        else
            hs.alert.show("Trashed " .. #paths .. " items")
        end
    end
end

-- Show "Open With" app chooser
function M.showOpenWith(paths)
    local appChooser = hs.chooser.new(function(choice)
        if not choice or not choice.appPath then
            return
        end
        for _, path in ipairs(paths) do
            hs.execute(string.format('open -a "%s" "%s"', choice.appPath, path))
        end
    end)

    appChooser:bgDark(true)
    appChooser:fgColor({red=1.0, green=1.0, blue=1.0})
    appChooser:subTextColor({red=0.6, green=0.6, blue=0.6})
    appChooser:width(50)

    -- Search for apps with mdfind
    appChooser:queryChangedCallback(function(query)
        if query == "" then
            appChooser:choices({})
            return
        end

        local escaped = query:gsub("'", "'\\''")
        local mdfind_query = string.format(
            "kMDItemContentType == 'com.apple.application-bundle' && kMDItemFSName == '*%s*'c",
            escaped
        )

        local output, status = hs.execute(string.format("/usr/bin/mdfind '%s'", mdfind_query))
        if not status then return end

        local results = {}
        for line in output:gmatch("[^\n]+") do
            local appName = line:match("([^/]+)%.app$")
            if appName then
                table.insert(results, {
                    text = appName,
                    subText = line,
                    appPath = line,
                    image = hs.image.iconForFile(line),
                })
            end
            if #results >= 20 then break end
        end

        appChooser:choices(results)
    end)

    appChooser:show()
end

-- Show file actions menu
function M.show()
    local paths = getSelectedFiles()
    local actions = buildActions(paths)

    chooser = hs.chooser.new(onChoice)

    -- Styling (match launcher)
    chooser:bgDark(true)
    chooser:fgColor({red=1.0, green=1.0, blue=1.0})
    chooser:subTextColor({red=0.6, green=0.6, blue=0.6})
    chooser:width(50)

    chooser:choices(actions)
    chooser:show()
end

-- Setup keybinding
function M.init()
    hs.hotkey.bind({"alt", "cmd"}, "/", function()
        M.show()
    end)
    print("File actions initialized (alt+cmd+/)")
end

return M
