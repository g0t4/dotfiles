local ButtonsController = require("config.macros.streamdeck.buttonsController")
local EncodersController = require("config.macros.streamdeck.encodersController")
require("config.macros.streamdeck.helpers")
local Profiles = require("config.macros.streamdeck.profiles.profiles")

---@class DeckController
---@field deck hs.streamdeck
---@field name string
---@field buttons ButtonsController
---@field encoders EncodersController
local DeckController = {}
DeckController.__index = DeckController

---@param deck hs.streamdeck
---@return DeckController
function DeckController:new(deck)
    local o = setmetatable({}, self)
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

function DeckController:applyProfiles()
    -- load profile(s) for buttons/encoders (default, per app, per apps(later), within app, mods - ie app switcher?)
    for _, profile in ipairs(Profiles) do
        -- TODO get current app and use that
        if profile.appBundleId == "com.apple.FinalCut" and profile.deckIdentifier == self.name then
            profile:applyTo(self)
        end
    end
end

function DeckController:start()
    self:applyProfiles()
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
