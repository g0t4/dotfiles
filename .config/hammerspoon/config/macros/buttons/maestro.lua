require("config.macros.buttons.helpers")

-- @classmod MaestroButton
-- @field buttonNumber number
-- @field deck hs.streamdeck
local MaestroButton = {}
MaestroButton.__index = MaestroButton

function MaestroButton:new(buttonNumber, deck, image)
    -- FYI... actually most buttons are static, including KM buttons
    --   when I need a dynamic button, I can revist this...
    --   for now keep both concepts together:
    --   1. behavior (keyboard maestro part) maestroButtonAction
    --   2. button image/color display

    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.buttonNumber = buttonNumber
    o.deck = deck
    o.image = image
    return o
end

function MaestroButton:start()
    -- technically don't need this for static images
    self.deck:setButtonImage(self.buttonNumber, self.image)
end

function MaestroButton:stop()
    resetButton(self.buttonNumber, self.deck)
end

return MaestroButton
