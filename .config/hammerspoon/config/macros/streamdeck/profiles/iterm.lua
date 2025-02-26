local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
local AppObserver = require("config.macros.streamdeck.profiles.appObserver")



local ItermProfile = AppObserver:new("iTerm2")

ItermProfile:addProfile("3XL", function(_, deck)
    return {
        -- row 4:
        LuaButton:new(29, deck, drawTextIcon("Clear Console"), hs.console.clearConsole),
        LuaButton:new(30, deck, drawTextIcon("Reload Config"), hs.reload),
        KeyStrokeButton:new(32, deck, hsIcon("iterm/copilot-disable.png"), {}, hs.keycodes.map.f13)
    }
end)


return ItermProfile
