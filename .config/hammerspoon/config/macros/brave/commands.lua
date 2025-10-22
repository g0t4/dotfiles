-- FYI this uses my chrome extension bridge... just an idea for how I can define new actions like toggle-bookmark instead of just browser's native add bookmark (w/o a keymap to remove bookmark)
function BRAVE_TriggerAction(action)
    local js = string.format([[
        window.postMessage({ type: 'FROM_HS', payload: { action: '%s' } }, '*');
    ]], action)

    local script = string.format([[
        tell application "Brave Browser Beta"
            if not (exists window 1) then
                return
            end
            tell active tab of window 1
                execute javascript "%s"
            end tell
        end tell
    ]], js:gsub('"', '\\"'))

    hs.osascript.applescript(script)
end

-- hs.hotkey.bind({"cmd", "ctrl"}, "D", function()
--     sendToBrave("toggle-bookmark")
-- end)
