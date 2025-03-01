local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local verbose = require("config.macros.streamdeck.helpers").verbose
local MenuButton = require("config.macros.streamdeck.menuButton")
local LuaButton = require("config.macros.streamdeck.luaButton")



function menu(menu)
    return function()
        selectMenuItemWithFailureTroubleshooting(menu)
    end
end

local PptxObserver = AppObserver:new("Microsoft PowerPoint")

PptxObserver:addProfile("2XL", function(_, deck)
    return {

    }
end)

PptxObserver:addProfile("3XL", function(_, deck)
    return {
    }
end)

PptxObserver:addProfile("4+", function(_, deck)
    return {
        -- *** row 1


        -- *** row 2
    }
end)



return PptxObserver
