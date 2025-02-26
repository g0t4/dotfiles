local DeckController = require("config.macros.streamdeck.deckController")
require("config.macros.streamdeck.helpers")

---@class DecksController
---@field private _deckControllers table<string, DeckController>
local DecksController = {}
DecksController.__index = DecksController

---@return DecksController
function DecksController:new()
    local o = setmetatable({}, DecksController)
    o._deckControllers = {}
    return o
end

---@param deck hs.streamdeck
function DecksController:deckConnected(deck)
    local deckController = DeckController:new(deck)
    print("Deck connected:", deckController)
    local name = getDeckName(deck)
    self._deckControllers[name] = deckController
    -- print("Starting deck controller:", hs.inspect(getmetatable(deckController)))
    deckController:start()
end

---@param deck hs.streamdeck
function DecksController:deckDisconnected(deck)
    print("Deck disconnected: " .. getDeckName(deck))
    local name = getDeckName(deck)
    local deckController = self._deckControllers[name]
    if deckController then
        print("Stopping deck controller:", deckController)
        deckController:stop()
        self._deckControllers[name] = nil
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
    for name in pairs(self._deckControllers) do
        table.insert(names, name)
    end
    return names
end

return DecksController
