local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local verbose = require("config.macros.streamdeck.helpers").verbose
local MenuButton = require("config.macros.streamdeck.menuButton")
local LuaButton = require("config.macros.streamdeck.luaButton")


--- TODO app observer for shapes and other types... activate different buttons (or behaviors) based on the current seleted shape

function menu(menu)
    return function()
        selectMenuItemWithFailureTroubleshooting(menu)
    end
end

---@param deckName string
---@param appModuleName string
---@param page number
function changePage(deckName, appModuleName, page)
    local pageSettings = require("config.macros.streamdeck.settings.page")
    return function()
        pageSettings.setSavedPageNumber(deckName, appModuleName, page)
    end
end

local PptxObserver = AppObserver:new("Microsoft PowerPoint")

PptxObserver:addProfilePage(DECK_2XL, PAGE_1, function(_, deck)
    return {

    }
end)

PptxObserver:addProfilePage(DECK_3XL, PAGE_1, function(_, deck)
    return {
        -- * row 1
        LuaButton:new(1, deck, hsIcon("pptx/shapes/align-left.png"), menu({ "Arrange", "Align or Distribute", "Align Left" })),
        LuaButton:new(2, deck, hsIcon("pptx/shapes/align-center.png"), menu({ "Arrange", "Align or Distribute", "Align Center" })),
        LuaButton:new(3, deck, hsIcon("pptx/shapes/align-right.png"), menu({ "Arrange", "Align or Distribute", "Align Right" })),

        LuaButton:new(4, deck, hsIcon("pptx/shapes/distribute-horizontal.png"), menu({ "Arrange", "Align or Distribute", "Distribute Horizontally" })),
        LuaButton:new(5, deck, hsIcon("pptx/shapes/distribute-vertical.png"), menu({ "Arrange", "Align or Distribute", "Distribute Vertically" })),

        LuaButton:new(8, deck, hsIcon("pptx/shapes/align-top.png"), menu({ "Arrange", "Align or Distribute", "Align Top" })),
        LuaButton:new(16, deck, hsIcon("pptx/shapes/align-middle.png"), menu({ "Arrange", "Align or Distribute", "Align Middle" })),
        LuaButton:new(24, deck, hsIcon("pptx/shapes/align-bottom.png"), menu({ "Arrange", "Align or Distribute", "Align Bottom" })),

        LuaButton:new(16, deck, drawTextIcon(">", deck), changePage("3XL", "pptx", 2)),


        LuaButton:new(17, deck, hsIcon("pptx/shapes/flip-vertical.png"), menu({ "Arrange", "Rotate or Flip", "Flip Vertical" })),
        LuaButton:new(18, deck, hsIcon("pptx/shapes/flip-horizontal.png"), menu({ "Arrange", "Rotate or Flip", "Flip Horizontal" })),
        LuaButton:new(19, deck, hsIcon("pptx/shapes/rotate-left-90.png"), menu({ "Arrange", "Rotate or Flip", "Rotate Left 90°" })),
        LuaButton:new(20, deck, hsIcon("pptx/shapes/rotate-right-90.png"), menu({ "Arrange", "Rotate or Flip", "Rotate Right 90°" })),

    }
end)

PptxObserver:addProfilePage(DECK_3XL, PAGE_2, function(_, deck)
    return {
        -- * row 1

        -- * row 4
        LuaButton:new(25, deck, drawTextIcon("<", deck), changePage("3XL", "pptx", 1)),
    }
end)

PptxObserver:addProfilePage(DECK_4PLUS, PAGE_1, function(_, deck)
    return {
        -- *** row 1


        -- *** row 2
    }
end)



return PptxObserver
