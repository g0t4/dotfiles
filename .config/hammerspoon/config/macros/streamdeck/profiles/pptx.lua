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
        LuaButton:new(1, deck, hsIcon("pptx/shapes/align-left.png"), menu({ "Arrange", "Align or Distribute", "Align Left" })),
        LuaButton:new(2, deck, hsIcon("pptx/shapes/align-center.png"), menu({ "Arrange", "Align or Distribute", "Align Center" })),
        LuaButton:new(3, deck, hsIcon("pptx/shapes/align-right.png"), menu({ "Arrange", "Align or Distribute", "Align Right" })),

        LuaButton:new(8, deck, hsIcon("pptx/shapes/align-top.png"), menu({ "Arrange", "Align or Distribute", "Align Top" })),
        LuaButton:new(16, deck, hsIcon("pptx/shapes/align-middle.png"), menu({ "Arrange", "Align or Distribute", "Align Middle" })),
        LuaButton:new(24, deck, hsIcon("pptx/shapes/align-bottom.png"), menu({ "Arrange", "Align or Distribute", "Align Bottom" })),
    }
end)

PptxObserver:addProfile("4+", function(_, deck)
    return {
        -- *** row 1


        -- *** row 2
    }
end)



return PptxObserver
