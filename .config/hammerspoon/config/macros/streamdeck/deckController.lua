local ButtonsController = require("config.macros.streamdeck.buttonsController")
local EncodersController = require("config.macros.streamdeck.encodersController")
require("config.macros.streamdeck.helpers")

---@class DeckController
---@field hsdeck hs.streamdeck
---@field name string
---@field serial string
---@field rows number
---@field cols number
---@field buttonSize { w: number, h: number }
---@field buttons ButtonsController
---@field encoders EncodersController|nil
local DeckController = {}
DeckController.__index = DeckController

---@param hsdeck hs.streamdeck
---@return DeckController
function DeckController:new(hsdeck)
    local o = setmetatable({}, self)
    o.hsdeck = hsdeck

    ---@diagnostic disable-next-line: assign-type-mismatch
    o.name, o.serial = DeckController.getDeckName(hsdeck)
    -- ignore nil warning, easier to add one line than a few to assert a fix
    ---@diagnostic disable-next-line: assign-type-mismatch
    o.cols, o.rows = hsdeck:buttonLayout()
    ---@diagnostic disable-next-line: assign-type-mismatch
    o.buttonSize = hsdeck:imageSize()

    o.buttons = o.name:find("XL$") and ButtonsController:newXL(o) or ButtonsController:newPlus(o)
    -- TODO add empty encoder controller instead of nil? with 0 encoders?
    o.encoders = o.name:find("+$") and EncodersController:newPlus(o) or nil
    return o
end

---@param hsdeck hs.streamdeck
function DeckController.getDeckName(hsdeck)
    -- CL start
    --  + 9 end => deck 1XL
    --  + 1 end => deck 2XL
    --  + 8 end => deck 3XL
    -- A start (also ends with 4) => deck 4+

    local serial = hsdeck:serialNumber() or ""
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

---@param hsdeck hs.streamdeck
---@param interaction string
---@param xFirst number
---@param yFirst number
---@param xLast number
---@param yLast number
function DeckController:onScreenTouched(hsdeck, interaction, xFirst, yFirst, xLast, yLast)
    if self.encoders == nil then
        error("onScreenPressed: no encoders on " .. self.name)
        return
    end
    self.encoders:onScreenTouched(interaction, xFirst, yFirst, xLast, yLast)
end

---@param hsdeck hs.streamdeck
---@param encoderNumber integer
---@param pressedOrReleased boolean
---@param turnedLeft boolean
---@param turnedRight boolean
function DeckController:onEncoderPressed(hsdeck, encoderNumber, pressedOrReleased, turnedLeft, turnedRight)
    if self.encoders == nil then
        error("onEncoderPressed: no encoders on " .. self.name)
        return
    end
    self.encoders:onEncoderPressed(encoderNumber, pressedOrReleased, turnedLeft, turnedRight)
end

---@param hsdeck hs.streamdeck
---@param buttonNumber integer
---@param pressedOrReleased boolean
function DeckController:onButtonPressed(hsdeck, buttonNumber, pressedOrReleased)
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

    self.hsdeck:screenCallback(function(hsdeck, interaction, xFirst, yFirst, xLast, yLast)
        self:onScreenTouched(hsdeck, interaction, xFirst, yFirst, xLast, yLast)
    end)
    self.hsdeck:encoderCallback(function(hsdeck, encoderNumber, pressedOrReleased, turnedLeft, turnedRight)
        self:onEncoderPressed(hsdeck, encoderNumber, pressedOrReleased, turnedLeft, turnedRight)
    end)
    self.hsdeck:buttonCallback(function(hsdeck, buttonNumber, pressedOrReleased)
        self:onButtonPressed(hsdeck, buttonNumber, pressedOrReleased)
    end)
end

function DeckController:stop()
    -- clear callbacks == STOP
    self.hsdeck:screenCallback(nil)
    self.hsdeck:encoderCallback(nil)
    self.hsdeck:buttonCallback(nil)
end

return DeckController
