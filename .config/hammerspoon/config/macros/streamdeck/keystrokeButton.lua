PushButton = require("config.macros.buttons.pushButton")

-- button press emulates a hot key:
--   hs.eventtap.keyStroke({"cmd", "alt"}, "T")
--   mostly as a reminder of an obscure hot key

---@class KeyStrokeButton : PushButton
---@field buttonNumber number
---@field deck hs.streamdeck
---@field modifiers table
---@field character string
local KeyStrokeButton = setmetatable({}, { __index = PushButton })

---@param buttonNumber number
---@param deck hs.streamdeck
---@param image hs.image
---@param modifiers table
---@param character string
---@return KeyStrokeButton
function KeyStrokeButton:new(buttonNumber, deck, image, modifiers, character)
    ---@class KeyStrokeButton
    local o = PushButton.new(KeyStrokeButton, buttonNumber, deck, image)
    o.modifiers = modifiers
    o.character = character
    -- TODO maybes:
    -- o.delay = delay
    -- o.application = application
    return o
end

function KeyStrokeButton:pressed()
    hs.eventtap.keyStroke(self.modifiers, self.character)
end

function KeyStrokeButton:__tostring()
    return "KeyStrokeButton " .. (self.buttonNumber or "nil") .. " modifiers: " .. hs.inspect(self.modifiers) .. " character: " .. self.character
end

return KeyStrokeButton
