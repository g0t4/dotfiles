require("config.macros.streamdeck.helpers")

---@class DeckController
---@field deck hs.streamdeck
---@field name string
local DeckController = {}
function DeckController:new(o, deck)
    o = setmetatable({}, self)
    o.deck = deck
    o.name = getDeckName(deck)
    return o
end

---@class DecksController
local DecksController = {}

function DecksController:new(o)
    o = setmetatable({}, self)
    self.__index = self
    return o
end

---@param deck hs.streamdeck
function DecksController:deckConnected(deck)
    -- local deckController = DeckController:new(deck)
    print("Deck connected: " .. getDeckName(deck))
end

---@param deck hs.streamdeck
function DecksController:deckDisconnected(deck)
    -- todo find controller and remove it
    print("Deck disconnected: " .. getDeckName(deck))
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

return DecksController
