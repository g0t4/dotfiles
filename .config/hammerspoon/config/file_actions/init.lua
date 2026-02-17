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

-- Build the actions list for selected files
local function buildActions(paths)
    if #paths == 0 then
        return {{
            text = "No files selected",
            subText = "Select files in Finder first",
            image = hs.image.imageFromName("NSCaution"),
        }}
    end

    -- Summary of what's selected
    local summary
    if #paths == 1 then
        summary = getFilename(paths[1])
    else
        summary = #paths .. " items selected"
    end

    local actions = {}

    -- Copy path(s)
    table.insert(actions, {
        text = "Copy Path",
        subText = summary,
        action = "copy_path",
        paths = paths,
        image = hs.image.imageFromName("NSPathTemplate"),
    })

    -- Copy filename(s)
    table.insert(actions, {
        text = "Copy Filename",
        subText = summary,
        action = "copy_filename",
        paths = paths,
        image = hs.image.imageFromName("NSPathTemplate"),
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

    if choice.action == "copy_path" then
        local pathStr = table.concat(paths, "\n")
        hs.pasteboard.setContents(pathStr)
        if #paths == 1 then
            hs.alert.show("Copied: " .. paths[1])
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

    elseif choice.action == "reveal" then
        for _, path in ipairs(paths) do
            hs.execute(string.format('open -R "%s"', path))
        end

    elseif choice.action == "open_with" then
        -- Show app chooser for "Open With"
        M.showOpenWith(paths)

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
