local ButtonsController = require("config.macros.streamdeck.buttonsController")
local EncodersController = require("config.macros.streamdeck.encodersController")
require("config.macros.streamdeck.helpers")


-- * DECK SINGULAR

---@class DeckController
---@field deck hs.streamdeck
---@field name string
---@field private buttons ButtonsController
---@field private encoders EncodersController
local DeckController = {}
DeckController.__index = DeckController

---@param deck hs.streamdeck
---@return DeckController
function DeckController:new(deck)
    o = setmetatable({}, self)
    o.deck = deck
    o.name = getDeckName(deck)
    o.buttons = o.name:find("XL$") and ButtonsController:newXL(deck) or ButtonsController:newPlus(deck)
    -- TODO add empty encoder controller instead of nil? with 0 encoders?
    o.encoders = o.name:find("Plus$") and EncodersController:newPlus(deck) or nil
    return o
end

function DeckController:__tostring()
    return "DeckController<" .. self.name .. ">"
end

---@param deck hs.streamdeck
---@param interaction string
---@param xFirst number
---@param yFirst number
---@param xLast number
---@param yLast number
function DeckController:onScreenTouched(deck, interaction, xFirst, yFirst, xLast, yLast)
    if self.encoders == nil then
        error("onScreenPressed: no encoders on " .. self.name)
        return
    end
    self.encoders:onScreenTouched(interaction, xFirst, yFirst, xLast, yLast)
end

function DeckController:onEncoderPressed(deck, encoderNumber, pressedOrReleased, turnedLeft, turnedRight)
    if self.encoders == nil then
        error("onEncoderPressed: no encoders on " .. self.name)
        return
    end
    self.encoders:onEncoderPressed(encoderNumber, pressedOrReleased, turnedLeft, turnedRight)
end

function DeckController:onButtonPressed(deck, buttonNumber, pressedOrReleased)
    if self.buttons == nil then
        error("onButtonPressed: no buttons on " .. self.name)
        return
    end
    self.buttons:onButtonPressed(buttonNumber, pressedOrReleased)
end

function DeckController:start()
    self.deck:screenCallback(function(deck, interaction, xFirst, yFirst, xLast, yLast)
        self:onScreenTouched(deck, interaction, xFirst, yFirst, xLast, yLast)
    end)
    self.deck:encoderCallback(function(deck, encoderNumber, pressedOrReleased, turnedLeft, turnedRight)
        self:onEncoderPressed(deck, encoderNumber, pressedOrReleased, turnedLeft, turnedRight)
    end)
    self.deck:buttonCallback(function(deck, buttonNumber, pressedOrReleased)
        self:onButtonPressed(deck, buttonNumber, pressedOrReleased)
    end)
end

function DeckController:stop()
    -- clear callbacks == STOP
    self.deck:screenCallback(nil)
    self.deck:encoderCallback(nil)
    self.deck:buttonCallback(nil)
end

-- * END DECK SINGULAR



---@class DecksController
---@field private _deckControllers table<string, DeckController>
local DecksController = {}


---@return DecksController
function DecksController:new()
    o = setmetatable({}, self) -- metatable, for __tostring only (so far)
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
