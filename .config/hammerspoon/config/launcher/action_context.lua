-- Context providers return ordinary data; actions need not know how it was captured.
local M = {}
local log = require("config.logs").hammerspoons()

function M.capture()
    local app = hs.application.frontmostApplication()
    if not app then return nil end
    if app:bundleID() == "com.microsoft.Powerpoint" then
        return {kind = "app", source = "powerpoint", pid = app:pid(), paths = {},
            capabilities = {"restart"}}
    end
    if app:bundleID() == "com.apple.finder" then
        local ok, paths = hs.osascript.applescript([[
            tell application "Finder"
                set paths to {}
                repeat with itemRef in (selection as list)
                    set end of paths to POSIX path of (itemRef as alias)
                end repeat
                return paths
            end tell
        ]])
        if ok and type(paths) == "table" then
            for i, path in ipairs(paths) do
                paths[i] = path == "/" and path or path:gsub("/$", "")
            end
            return {kind = "files", source = "finder", paths = paths}
        end
        return nil
    end

    local window = app:focusedWindow()
    local title = window and window:title() or ""
    if title:sub(-#" — Pip Rot") ~= " — Pip Rot" then return nil end
    local filename = os.getenv("HOME") .. "/.local/state/pip-rot/context-" .. app:pid() .. ".json"
    local context = hs.json.read(filename)
    if type(context) ~= "table" or context.version ~= 1 or context.kind ~= "files"
        or context.source ~= "pip-rot" or context.pid ~= app:pid()
        or context.window_title ~= title or type(context.paths) ~= "table" then
        log:warn("Pip Rot context unavailable or mismatched:", filename, title)
        return nil
    end
    for _, path in ipairs(context.paths) do
        if type(path) ~= "string" or path:sub(1, 1) ~= "/" then return nil end
    end
    log:info("File action context:", context)
    return context
end

return M
