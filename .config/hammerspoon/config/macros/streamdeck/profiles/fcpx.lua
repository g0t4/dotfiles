local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")




local FcpxObserver = AppObserver:new("Final Cut Pro")

FcpxObserver:addProfile("3XL", function(_, deck)
    -- local macro = "'Titles - Add wes-arrows-* (Parameterized)'"
    local macro = "BEE464BB-0C6F-4B8A-9AAF-81603BBA8351"
    return {
        -- TODO can I decouple deck here?
        MaestroButton:new(26, deck, hsIcon("fcpx/titles/down-arrow.png"), macro, "wes-arrows-down"),
        MaestroButton:new(27, deck, hsIcon("fcpx/titles/right-arrow.png"), macro, "wes-arrows-right"),
        MaestroButton:new(25, deck, hsIcon("fcpx/titles/left-arrow.png"), macro, "wes-arrows-left"),
        MaestroButton:new(18, deck, hsIcon("fcpx/titles/up-arrow.png"), macro, "wes-arrows-up"),
        KeyStrokeButton:new(14, deck, hsIcon("fcpx/timeline/edges/select-right-60x60.png"), {}, "["),
        KeyStrokeButton:new(15, deck, hsIcon("fcpx/timeline/edges/select-both-edges-60x60.png"), {}, "\\"),
        KeyStrokeButton:new(16, deck, hsIcon("fcpx/timeline/edges/select-left-60x60.png"), {}, "]")
    }
end)




return FcpxObserver
