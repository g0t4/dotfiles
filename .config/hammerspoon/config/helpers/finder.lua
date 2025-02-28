function getSelectedFinderDirectories()
    local paths = getSelectedFinderPaths()
    local dirs = {}
    for _, path in ipairs(paths) do
        local exists = hs.fs.attributes(path)
        local isDir = exists and exists.mode == "directory"
        if isDir then
            table.insert(dirs, path)
        end
    end
    -- print("selectedFinderDirectories", hs.inspect(dirs))
    return dirs
end

--- return all selected finder item paths (0+ paths)
--- if nothing is selected, but a window is open, return the directory of that window
function getSelectedFinderPaths()
    local script = [[
        tell application "Finder"
            try
                set selectedItems to selection
                if (count of selectedItems) > 0 then
                    set paths to {}
                    repeat with i in selectedItems
                        set end of paths to POSIX path of (i as alias)
                    end repeat
                    return paths
                else
                    -- if nothing is selected, but a window is open, return the directory of that window
                    return {POSIX path of (target of front window as alias)}
                end if
            on error
                return {}
            end try
        end tell
    ]]

    -- btw applescript func returns lua compatible types (parses from func result) AFAICT (haven't looked yet :)
    local success, paths, _ = hs.osascript.applescript(script)
    -- print("selectedFinderPaths", hs.inspect(paths))
    if success and paths then
        return paths
    else
        return {}
    end
end
