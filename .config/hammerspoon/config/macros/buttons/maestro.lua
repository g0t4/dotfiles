require("config.macros.buttons.helpers")

-- @classmod MaestroButton
-- @field number number
-- @field deck hs.streamdeck
local MaestroButton = {}
MaestroButton.__index = MaestroButton

function MaestroButton:new(number, deck, image)
    -- FYI... actually most buttons are static, including KM buttons
    --   when I need a dynamic button, I can revist this...
    --   for now keep both concepts together:
    --   1. behavior (keyboard maestro part) maestroButtonAction
    --   2. button image/color display

    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.number = number
    o.deck = deck
    o.image = image
    return o
end

function MaestroButton:start()
    -- technically don't need this for static images
    self.deck:setButtonImage(self.number, self.image)
end

function MaestroButton:stop()
    resetButton(self.number, self.deck)
end

function MaestroButton:pressed()
    --  /Applications/Keyboard\ Maestro.app/Contents/MacOS/keyboardmaestro
    --  or osascript
    local macro = "Titles - Add * Arrow (Parameterized)"
    local param = "wes-arrows-right"
    verbose("exec KM: " .. macro .. "(" .. param .. ")")
end

function MaestroButton:released()
end

return MaestroButton
