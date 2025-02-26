local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
local AppObserver = require("config.macros.streamdeck.profiles.appObserver")



local FallbackProfiles = AppObserver:new("iTerm2")

FallbackProfiles:addProfile("4+", function(_, deck)
    return {
        LuaButton:new(3, deck, appIconHammerspoon(), hs.openConsole),
        LuaButton:new(4, deck, drawTextIcon("Clear Console"), hs.console.clearConsole),
        LuaButton:new(8, deck, drawTextIcon("Reload Config"), hs.reload)
    }
end)

return FallbackProfiles
