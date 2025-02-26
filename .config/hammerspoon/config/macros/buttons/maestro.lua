require("config.macros.buttons.helpers")
require("config.macros.buttons.commands")

---@class MaestroButton
---@field buttonNumber number
---@field deck hs.streamdeck
---@field image hs.image
---@field macro string
---@field param string|nil
local MaestroButton = {}
MaestroButton.__index = MaestroButton

function MaestroButton:new(buttonNumber, deck, image, macro, param)
    -- FYI... actually most buttons are static, including KM buttons
    --   when I need a dynamic button, I can revist this...
    --   for now keep both concepts together:
    --   1. behavior (keyboard maestro part) maestroButtonAction
    --   2. button image/color display

    local o = {}
    setmetatable(o, self)
    o.buttonNumber = buttonNumber
    o.deck = deck
    o.image = image
    o.macro = macro
    o.param = param
    return o
end

function MaestroButton:start()
    -- technically don't need this for static images
    self.deck:setButtonImage(self.buttonNumber, self.image)
end

function MaestroButton:stop()
    resetButton(self.buttonNumber, self.deck)
end

function MaestroButton:pressed()
    -- FYI could use osascript too (pass applescript to hammerspoon?)
    verbose("exec KM: " .. self.macro .. "(" .. self.param .. ")")
    runKMMacro(self.macro, self.param)
end

function MaestroButton:released()
end

return MaestroButton
