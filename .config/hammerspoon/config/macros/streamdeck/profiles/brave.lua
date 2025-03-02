local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local CommandButton = require("config.macros.streamdeck.commandButton")
local verbose = require("config.macros.streamdeck.helpers").verbose
local MenuButton = require("config.macros.streamdeck.menuButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
require("config.macros.streamdeck.iconHelpers")


-- TODO add in web site observer that changes buttons based on site
--   google docs I can activate my buttons for menu items like highlight colors
--   that way I don't have to dedicate a button to one purpose and waste it when on other sites

local BraveObserver = AppObserver:new(APPS.BraveBrowserBeta)


---@param deck DeckController
---@return hs.canvas
function newButtonCanvas(deck)
    local canvas = hs.canvas.new({ x = 0, y = 0, w = deck.buttonSize.w, h = deck.buttonSize.h })
    assert(canvas ~= nil, "canvas is not nil")
    return canvas
end

---@param hexColor string
---@param deck DeckController
---@return hs.image
function hsCircleIcon(hexColor, deck)
    local diameter = math.min(deck.buttonSize.w, deck.buttonSize.h)
    local canvas = newButtonCanvas(deck)

    canvas[1] = {
        type = "circle",
        action = "fill", -- action = "strokeAndFill", -- don't need outline (yet?)
        fillColor = { hex = hexColor },
        -- strokeColor = hexColor,

        -- center = { x = "50%", y = "50%" }, -- this is the default and is perfect
        -- TODO radius = 90% -- default is 50%
        radius = "40%",
    }

    return canvas:imageFromCanvas()
end

BraveObserver:addProfilePage(DECK_3XL, PAGE_1, function(_, deck)
    local km_docs_menu_item = "B06C1815-51D0-4DD7-A22C-5A3C39C4D1E0"

    return {
        MaestroButton:new(1, deck, hsCircleIcon("#FFFF00", deck),
            km_docs_menu_item, "Highlight color yellow"),

        -- TODO "rec"
        -- #FCE5CD (highlight light orange 3) => increase saturation for button color: #FFC690
        MaestroButton:new(2, deck, hsCircleIcon("#FFC690", deck),
            km_docs_menu_item, "highlight light orange 3"),

        -- TODO this is color of text not background
        MaestroButton:new(3, deck, hsCircleIcon("#00FFFF", deck),
            km_docs_menu_item, "highlight none"),

        -- TODO "none"
        MaestroButton:new(4, deck, hsCircleIcon("#FF00FF", deck),
            km_docs_menu_item, "dark green 2"),

        KeyStrokeButton:new(5, deck, drawTextIcon("⇒", deck), {}, "⇒"),
    }
end)


return BraveObserver
