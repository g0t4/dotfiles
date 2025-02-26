local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local ClockButton = require("config.macros.streamdeck.clockButton")
local Encoder = require("config.macros.streamdeck.encoder")


local FallbackProfiles = AppObserver:new("fallback")

FallbackProfiles:addProfile("1XL", function(_, deck)
    return {
        ClockButton:new(1, deck)
    }
end)

FallbackProfiles:addProfile("4+", function(_, deck)
        return {
            LuaButton:new(3, deck, appIconHammerspoon(), hs.openConsole),
            LuaButton:new(4, deck, drawTextIcon("Clear Console"), hs.console.clearConsole),
            LuaButton:new(8, deck, drawTextIcon("Reload Config"), hs.reload)
        }
    end,
    function(_, deck)
        return {
            Encoder:new(1, deck, hsIcon("test-svgs/hanging-96.png")),
            Encoder:new(2, deck, hsIcon("test-svgs/saggy-64.png")),
            Encoder:new(3, deck, hsIcon("test-svgs/stick.svg")),
            Encoder:new(4, deck, hsIcon("test-svgs/purple-pink-128.png"))
        }
    end)

return FallbackProfiles
