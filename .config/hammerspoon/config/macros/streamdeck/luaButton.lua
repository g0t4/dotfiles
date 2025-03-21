PushButton = require("config.macros.streamdeck.pushButton")

-- a button that executes a lua script
---@class LuaButton : PushButton
---@field func function
local LuaButton = setmetatable({}, { __index = PushButton })

---@param buttonNumber number
---@param deck DeckController
---@param image hs.image
---@param func function
---@return LuaButton
function LuaButton:new(buttonNumber, deck, image, func)
    ---@class LuaButton
    local o = PushButton.new(LuaButton, buttonNumber, deck, image)
    o.func = func
    return o
end

function LuaButton:pressed()
    self.func()
end

function LuaButton:__tostring()
    return "LuaButton: " .. (self.buttonNumber or "nil")
end

return LuaButton
