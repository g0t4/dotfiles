-- *** Google Docs helpers

local function readFile(path)
    local file = io.open(path, "r")
    if not file then
        -- FYI this is bubbling up from `hs` CLI => KM => macos notification (on errors) so that's perfect
        error("Could not read file: " .. path)
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

local _cachedGoogleDocsJSHelpers = nil
local function getGoogleDocsJavaScriptHelpers()
    -- "~/.hammerspoon/config/macros/google-docs-helpers.js
    local file = hs.fs.currentDir() .. "/config/macros/google-docs/google-docs-helpers.js"
    if _cachedGoogleDocsJSHelpers == nil then
        _cachedGoogleDocsJSHelpers = readFile(file)
    end
    return _cachedGoogleDocsJSHelpers
end

function RunJavaScriptInBrave(script)
    script = getGoogleDocsJavaScriptHelpers() .. "\n\n" .. script

    local escaped = script:gsub('"', '\\"')

    hs.osascript.applescript([[
tell application "Brave Browser Beta"
    set code to "]] .. escaped .. [["
    set result to execute active tab of first window javascript code
end tell
]])
end

function StreamDeckGoogleDocsTextBgColorShowPalette()
    RunJavaScriptInBrave('dispatchMouseDownUpEvents("#bgColorButton");')
end

function StreamDeckGoogleDocsCropButton()
    RunJavaScriptInBrave('dispatchMouseDownUpEvents("#cropButton");')
end

function StreamDeckGoogleDocsMoreButton()
    RunJavaScriptInBrave('dispatchMouseDownUpEvents("#moreButton");')
end

function StreamDeckTestBraveJavaScript()
    local script = "console.log(\"BUTTSWATCHES\");"
    RunJavaScriptInBrave(script)

    local multi = [[
console.log("multiS");
    ]]
    RunJavaScriptInBrave(multi)
end

--
function StreamDeckConsoleClear()
    RunJavaScriptInBrave("console.clear();")
end
