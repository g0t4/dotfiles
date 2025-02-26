-- button press emulates a hot key:
--   hs.eventtap.keyStroke({"cmd", "alt"}, "T")
--   mostly as a reminder of an obscure hot key

---@class KeyStrokeButton : PushButton
---@field buttonNumber number
---@field deck hs.streamdeck
---@field modifiers table
---@field character string
local KeyStrokeButton = setmetatable({}, { __index = PushButton })
-- BTW... here is how you read the line above:
--    KeyStrokeButton is a new table with a metatable that has its __index set to PushButton
--    a {} doesn't have a metatable, so we're just attaching one right away
--    so, KeyStrokeButton inherits everything "static" from PushButton (i.e. functions)


---@param buttonNumber number
---@param deck hs.streamdeck
---@param image hs.image
---@param modifiers table
---@param character string
---@return KeyStrokeButton
function KeyStrokeButton:new(buttonNumber, deck, image, modifiers, character)
    ---@class KeyStrokeButton
    local o = PushButton.new(KeyStrokeButton, buttonNumber, deck)
    o.modifiers = modifiers
    o.character = character
    o.image = image
    -- TODO maybes:
    -- o.delay = delay
    -- o.application = application
    return o
end

function KeyStrokeButton:start()
    self.deck:setButtonImage(self.buttonNumber, self.image)
end

function KeyStrokeButton:stop()
    resetButton(self.buttonNumber, self.deck)
end

function KeyStrokeButton:pressed()
    hs.eventtap.keyStroke(self.modifiers, self.character)
end

function KeyStrokeButton:released()
end

return KeyStrokeButton
