local function NOOP() end

function NeovimExecCommand(cmdline, callback)
    callback = callback or NOOP
    hs.eventtap.keyStroke({}, hs.keycodes.map["escape"])
    hs.eventtap.keyStroke({}, hs.keycodes.map["escape"])

    hs.eventtap.keyStrokes(":")

    -- PRN rewrite to use my coroutines "fwk"
    hs.timer.doAfter(0.1, function()
        -- wait a second for cmd mode else will mess up with typing
        hs.eventtap.keyStrokes(cmdline)

        hs.timer.doAfter(0.1, function()
            -- enter won't work right away, allow typing to complete
            hs.eventtap.keyStroke({}, hs.keycodes.map["return"])
            callback()
        end)
    end)
end

function NeovimAskToggleRag()
    -- FYI not currently used, this is just an idea
    --   for now I went with F function key b/c the user doesn't see anything change
    --     F13/F16/17 (etc)
    NeovimExecCommand("lua require(\"ask-openai.config\").toggle_rag()")
end

function StreamDeckITerm2ScriptingInspector()
    -- Open iTerm2's Scripting Inspector (or refresh it if already open)
    -- PRN refactor to AXUIElement, ported as-is for commit history
    local script = [[
        tell application "System Events"

            set proc to application process "iTerm2"
            set inspectorWindow to a reference to window "Scripting Inspector" of proc
            if not (exists inspectorWindow) then
                set consoleWindow to a reference to window "Scripting Console" of proc
                if not (exists consoleWindow) then
                    -- app:menuBar(1):menuBarItem(7):menu(1):menuItem(1):menu(1):menuItem(13)
                    set consoleMenuItem to a reference to menu item "Console" of menu ¬
                        "Manage" of menu item "Manage" of menu "Scripts" of menu bar 1 of proc
                    click consoleMenuItem
                end if

                -- open inspector button:
                --   app:window(1):button(3)
                --   AXDescription: Inspector<string>
                --   AXHelp: Inspector<string>
                --   unique ref: app:window('Script Console'):button(desc='Inspector')

                set Inspector to first button of window "Script Console" of ¬
                    application process "iTerm2" whose description is "Inspector"
                click Inspector
            else
                perform action "AXRaise" of inspectorWindow
                click (first button of inspectorWindow whose description is "refresh")
                -- REFRESH BUTTON
                --   app:window(1):button(1)
                --   AXDescription: refresh<string>
                --   unique ref: app:window('Scripting Inspector'):button('')
            end if

        end tell
    ]]
    hs.osascript.applescript(script)
end
