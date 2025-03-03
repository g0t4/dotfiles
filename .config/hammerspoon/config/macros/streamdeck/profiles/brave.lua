local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local CommandButton = require("config.macros.streamdeck.commandButton")
local verbose = require("config.macros.streamdeck.helpers").verbose
local MenuButton = require("config.macros.streamdeck.menuButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
require("config.macros.streamdeck.iconHelpers")
local f = require("config.helpers.underscore")


local BraveObserver = AppObserver:new(APPS.BraveBrowserBeta)

local km_docs_menu_item = "B06C1815-51D0-4DD7-A22C-5A3C39C4D1E0"

---@param deck DeckController
---@return PushButton[] # empty if none, never nil
function getMyDeck3Page1Mods(deck, pageNumber)
    local url = getCurrentURL()
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
end

BraveObserver:addProfilePage(DECK_3XL, PAGE_1, function(_, deck)
    -- ! TODO run some timing to find out how much would be saved if these were cached and not re-created on every profile change
    local base = {
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
    local myMods = getMyDeck3Page1Mods(deck, PAGE_1)
    if myMods == nil then
        return base
    else
        -- FYI works for now but clicking them will be broken (IIAC first button per # would get press event)
        f.each(myMods, function(_index, button)
            -- !!! TODO override, not just ADD
            base[#base + 1] = button
        end)
        return base
    end
end)

-- Override setupWatchers to handle URL changes and other Brave-specific events
function BraveObserver:setupWatchers()
    -- TODO plugin my AXObserver
    -- TODO make actual watcher + handler smth like this:
    function tmpWatcherHandlerStartPoint()
        local url = getCurrentURL()
        if url then
            -- Store the current URL (and check it for changes?)
            self.currentURL = url

            -- Refresh the decks with the current URL context
            self:refreshDecks()
        end
    end

    -- self.watcher:start()
end

function getCurrentURL()
    local app = hs.application.get(APPS.BraveBrowserBeta)
    if not app then return end

    ---@type hs.axuielement|nil
    local appElement = hs.axuielement.applicationElement(app)
    if not appElement then return end

    ---@type hs.axuielement|nil
    local window = appElement:attributeValue("AXFocusedWindow")
    if not window then return end

    local urlTextField = window:group(1):group(1):group(1):group(1):toolbar(1):group(1):textField(1)
    if not urlTextField then return end

    return urlTextField:attributeValue("AXValue")
end

return BraveObserver
