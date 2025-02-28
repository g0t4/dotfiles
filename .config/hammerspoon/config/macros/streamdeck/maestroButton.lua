require("config.macros.streamdeck.helpers")
require("config.macros.streamdeck.commands")
local PushButton = require("config.macros.streamdeck.pushButton")

---@class MaestroButton : PushButton
---@field macro string @Name or UUID
---@field param string|nil
local MaestroButton = setmetatable({}, { __index = PushButton })

---@param buttonNumber number
---@param deck DeckController
---@param image hs.image
---@param macro string @Name or UUID
---@param param string|nil
---@return MaestroButton
function MaestroButton:new(buttonNumber, deck, image, macro, param)
    ---@class MaestroButton
    local o = PushButton.new(MaestroButton, buttonNumber, deck, image)
    o.macro = macro
    o.param = param
    return o
end

function MaestroButton:pressed()
    runKMMacro(self.macro, self.param)
end

function MaestroButton:__tostring()
    return "MaestroButton: " .. (self.buttonNumber or "nil")
        .. " " .. (self.macro or "nil")
        .. " " .. (self.param or "nil")
end

return MaestroButton
