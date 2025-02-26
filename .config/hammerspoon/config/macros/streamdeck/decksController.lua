local DeckController = require("config.macros.streamdeck.deckController")
require("config.macros.streamdeck.helpers")

---@class DecksController
---@field private _deckControllers table<string, DeckController>
local DecksController = {}

---@return DecksController
function DecksController:new()
    local o = setmetatable({}, self) -- metatable, for __tostring only (so far)
    self.__index = self
    self._deckControllers = {}
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

---@param application hs.application
function DecksController:applicationActivated(application)
    print("Application activated: " .. application.name)
end

function DecksController:applicationChanged(application)
    -- TODO what does this look like, this is just a stub method to think about it
    -- for example, using AXObserver, filtering the events for something important..
    --   do I wanna have an app specific controller? that might actually make sense
    --   then it can register watches it wants and handle extra features like dynamic
    --   sets of buttons... which might be a bit too much for one controller alone?
    --   could have base controller logic that is shared too
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

return DecksController
