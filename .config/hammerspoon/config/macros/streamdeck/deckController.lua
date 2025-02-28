local ButtonsController = require("config.macros.streamdeck.buttonsController")
local EncodersController = require("config.macros.streamdeck.encodersController")
require("config.macros.streamdeck.helpers")

---@class DeckController
---@field deck hs.streamdeck
---@field name string
---@field serial string
---@field rows number
---@field cols number
---@field buttonSize { w: number, h: number }
---@field buttons ButtonsController
---@field encoders EncodersController|nil
local DeckController = {}
DeckController.__index = DeckController

---@param deck hs.streamdeck
---@return DeckController
function DeckController:new(deck)
    local o = setmetatable({}, self)
    o.deck = deck

    ---@diagnostic disable-next-line: assign-type-mismatch
    o.name, o.serial = DeckController.getDeckName(deck)
    -- ignore nil warning, easier to add one line than a few to assert a fix
    ---@diagnostic disable-next-line: assign-type-mismatch
    o.cols, o.rows = deck:buttonLayout()
    ---@diagnostic disable-next-line: assign-type-mismatch
    o.buttonSize = deck:imageSize()

    o.buttons = o.name:find("XL$") and ButtonsController:newXL(deck) or ButtonsController:newPlus(deck)
    -- TODO add empty encoder controller instead of nil? with 0 encoders?
    o.encoders = o.name:find("+$") and EncodersController:newPlus(deck) or nil
    return o
end

function DeckController.getDeckName(deck)
    -- CL start
    --  + 9 end => deck 1XL
    --  + 1 end => deck 2XL
    --  + 8 end => deck 3XL
    -- A start (also ends with 4) => deck 4+

    local serial = deck:serialNumber()
    if serial:find("9$") then
        return "1XL"
    elseif serial:find("1$") then
        return "2XL"
    elseif serial:find("8$") then
        return "3XL"
    elseif serial:find("^A") then
        return "4+"
    end
    return "unknown", serial
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
    self.buttons:start()
    if self.encoders ~= nil then
        self.encoders:start()
    end

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

return DeckController
