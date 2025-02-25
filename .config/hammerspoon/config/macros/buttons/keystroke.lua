-- button press emulates a hot key:
--   hs.eventtap.keyStroke({"cmd", "alt"}, "T")
--   mostly as a reminder of an obscure hot key

local KeyStrokeButton = {}
KeyStrokeButton.__index = KeyStrokeButton


function KeyStrokeButton:new(buttonNumber, deck, modifiers, character)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.buttonNumber = buttonNumber
    o.deck = deck
    o.modifiers = modifiers
    o.character = character
    -- TODO maybes:
    -- o.delay = delay
    -- o.application = application
    return o
end

function KeyStrokeButton:start()
end

function KeyStrokeButton:stop()
    self.timer:stop()
end

function KeyStrokeButton:pressed()
    hs.eventtap.keyStroke(self.modifiers, self.character)
end

function KeyStrokeButton:released()
end

return KeyStrokeButton
