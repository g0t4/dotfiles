local DeckController = require("config.macros.streamdeck.deckController")
local verbose = require("config.macros.streamdeck.helpers").verbose


---@class DecksController
---@field deckControllers table<string, DeckController>
---@field appsObserver AppsObserver
local DecksController = {}
DecksController.__index = DecksController

---@return DecksController
function DecksController:new()
    local o = setmetatable({}, DecksController)
    o.deckControllers = {}
    return o
end

---@param deck hs.streamdeck
function DecksController:deckConnected(deck)
    local deckController = DeckController:new(deck)
    verbose("Deck connected:", deckController)
    local name = getDeckName(deck)
    self.deckControllers[name] = deckController
    deckController:start()
    self.appsObserver:loadCurrentAppForDeck(deckController)
end

---@param deck hs.streamdeck
function DecksController:deckDisconnected(deck)
    verbose("Deck disconnected: " .. getDeckName(deck))
    local name = getDeckName(deck)
    local deckController = self.deckControllers[name]
    if deckController then
        deckController:stop()
        self.deckControllers[name] = nil
    end
end

function DecksController:onDeviceDiscovery(connected, deck)
    if connected then
        self:deckConnected(deck)
    else
        self:deckDisconnected(deck)
    end
end

function DecksController:init()
    hs.streamdeck.init(function(connected, deck)
        self:onDeviceDiscovery(connected, deck)
    end)
end

function DecksController:getDeckNames()
    local names = {}
    for name in pairs(self.deckControllers) do
        table.insert(names, name)
    end
    return names
end

return DecksController
