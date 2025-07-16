function NeovimExecCommand(cmdline)
    hs.eventtap.keyStroke({}, hs.keycodes.map["escape"])
    hs.eventtap.keyStroke({}, hs.keycodes.map["escape"])

    hs.eventtap.keyStrokes(":")

    hs.timer.doAfter(0.1, function()
        -- wait a second for cmd mode else will mess up with typing
        hs.eventtap.keyStrokes(cmdline)

        hs.timer.doAfter(0.1, function()
            -- enter won't work right away, allow typing to complete
            hs.eventtap.keyStroke({}, hs.keycodes.map["return"])
        end)
    end)
end

function NeovimAskToggleRag()
    NeovimExecCommand("lua require(\"ask-openai.api\").toggle_rag()")
end
