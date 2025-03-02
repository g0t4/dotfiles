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
---@param label string|nil
---@return hs.image
function hsCircleIcon(hexColor, deck, label)
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
    if label then
        label = "\n" .. label
        local styledText = hs.styledtext.new(label, {
            font = {
                -- PERFECT SIZE FOR 96x96 XL buttons... figure out PLUS later (IIGC just increase size a smidge)
                size = 26,
            },
            paragraphStyle = {
                alignment = "center",
            },
            color = { hex = "#000000" },
        })
        canvas[2] = {
            type = "text",
            text = styledText,
        }
    end
    return canvas:imageFromCanvas()
end

local km_docs_menu_item = "B06C1815-51D0-4DD7-A22C-5A3C39C4D1E0"

BraveObserver:addProfilePage(DECK_3XL, PAGE_1, function(_, deck)
    return {
        MaestroButton:new(1, deck, hsCircleIcon("#FFFF00", deck),
            km_docs_menu_item, "Highlight color yellow"),

        -- #FCE5CD (highlight light orange 3) => increase saturation for button color: #FFC690
        MaestroButton:new(2, deck, hsCircleIcon("#FFC690", deck, "rec"),
            km_docs_menu_item, "highlight light orange 3"),

        -- "none" == remove highlight (background color)
        MaestroButton:new(3, deck, hsCircleIcon("#FFFFFF", deck, "none"),
            km_docs_menu_item, "highlight none"),

        -- changes text color (not highlight) => looks nice! (could be veritcal middle aligned but this is FINE for now)
        MaestroButton:new(9, deck, drawTextIcon("dark green 2", deck,
                { color = { hex = "#38761D" }, font = { size = 30 } }),
            km_docs_menu_item, "dark green 2"),

        KeyStrokeButton:new(5, deck, drawTextIcon("⇒", deck), {}, "⇒"),
    }
end)

function BraveObserver:getProfilePage(deckName, pageNumber)
    local page = AppObserver.getProfilePage(self, deckName, pageNumber)
    if page == nil then
        return nil
    end

    -- lookup website
    local app = hs.application.get(APPS.BraveBrowserBeta)
    if app == nil then return nil end
    local appElement = hs.axuielement.applicationElement(app)
    if appElement == nil then return nil end
    local window = appElement:attributeValue("AXFocusedWindow")
    if window == nil then return nil end
    local urlTextField = window:group(1):group(1):group(1):group(1):toolbar(1):group(1):textField(1)
    if urlTextField == nil then return nil end
    local url = urlTextField:attributeValue("AXValue")
    if url and url:find("^https://docs.google.com") then
        if deck.name == DECK_3XL and pageNumber == PAGE_1 then
            return {
                MaestroButton:new(31, deck, hsCircleIcon("#FFFF00", deck),
                    km_docs_menu_item, "Highlight color yellow"),
                MaestroButton:new(32, deck, hsCircleIcon("#FF0000", deck),
                    km_docs_menu_item, "Highlight color red"),
            }
        end
    end

    return {}

    -- TODO if it makes sense move to register sets of mods like addProfilePage so its only done once and dont need 'deck' passed here then either
    -- for now compute on the fly is fine for simplicity
end

return BraveObserver
