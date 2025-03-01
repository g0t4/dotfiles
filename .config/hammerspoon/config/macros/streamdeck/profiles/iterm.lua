local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
local AppObserver = require("config.macros.streamdeck.profiles.appObserver")

local ItermProfile = AppObserver:new("iTerm2")

ItermProfile:addProfilePage("3XL", 1, function(_, deck)
    return {
        -- row 4:
        KeyStrokeButton:new(32, deck, hsIcon("iterm/copilot-disable.png"), {}, hs.keycodes.map.f13)
    }
end)


return ItermProfile
