
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "H", function()
    PresentationHideMouse()
end)

local last_mouse_pos = nil
function PresentationHideMouse()
    -- I hate how the damn mouse shows up in powerpoint during a recording, randomly and sometimes twice b/c of that goddamn presenter mode bullshit that yuo can't get rid of without other fucking
    -- trouble so lets just hide the fucking mouse if possible (or at least get it in a position where I could easily cover it if it shows just the tip (ie in lower right corner)
    -- so this will toggle "hiding" the mouse via a streamdeck button so I can use it when recording (I'll just make a start/stop button for toggling it that also toggles recording)
    -- last_mouse_pos = hs.mouse.absolutePosition()
    if last_mouse_pos == nil then
        last_mouse_pos = hs.mouse.absolutePosition()
        local mode = hs.screen.primaryScreen():currentMode()
        -- Dump(mode)
        -- move to lower right corner
        hs.mouse.absolutePosition({ x = mode.w, y = mode.h })
    else
        hs.mouse.absolutePosition(last_mouse_pos)
        last_mouse_pos = nil
    end
end

-- *** ideas to actually hide it?
--
-- -- https://www.hammerspoon.org/docs/hs.eventtap.html
-- -- https://www.hammerspoon.org/docs/hs.eventtap.event.types.html
-- -- https://www.hammerspoon.org/docs/hs.eventtap.event.html
-- -- https://www.hammerspoon.org/docs/hs.eventtap.new.html
-- local eventtap = hs.eventtap.new({ eventtap = true }, function(event)
--     -- print("eventtap", inspect(event))
--     if event.type == "mouseEntered" then
--         -- print("mouseEntered")
--         hs.mouse.setAbsolutePosition({ x = 0, y = 0 })
--     elseif event.type == "mouseExited" then
--         -- print("mouseExited")
--         hs.mouse.setAbsolutePosition({ x = 0, y = 0 })
--     end
-- end)
--
-- eventtap:start()
