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
    -- FYI not currently used, this is just an idea
    --   for now I went with F function key b/c the user doesn't see anything change
    --     F13/F16/17 (etc)
    NeovimExecCommand("lua require(\"ask-openai.api\").toggle_rag()")
end
