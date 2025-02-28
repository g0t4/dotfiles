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

---@param hsdeck hs.streamdeck
function DecksController:deckConnected(hsdeck)
    local deckController = DeckController:new(hsdeck)
    verbose("Deck connected:", deckController)
    self.deckControllers[deckController.name] = deckController
    deckController:start()
    self.appsObserver:loadCurrentAppForDeck(deckController)

    hsdeck:setBrightness(80)
    -- deck:setBrightness(100) -- 0 to 100 (FYI persists across restarts of hammerspoon... IIAC only need to set this once when I wanna change it)
end

---@param hsdeck hs.streamdeck
function DecksController:deckDisconnected(hsdeck)
    local name = DeckController.getDeckName(hsdeck)
    verbose("Deck disconnected: " .. name)
    local deckController = self.deckControllers[name]
    if deckController then
        deckController:stop()
        self.deckControllers[name] = nil
    end
end

---@param connected boolean
---@param hsdeck hs.streamdeck
function DecksController:onDeviceDiscovery(connected, hsdeck)
    if connected then
        self:deckConnected(hsdeck)
    else
        self:deckDisconnected(hsdeck)
    end
end

function DecksController:init()
    hs.streamdeck.init(function(connected, hsdeck)
        self:onDeviceDiscovery(connected, hsdeck)
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
