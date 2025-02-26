PushButton = require("config.macros.buttons.push")


-- a button that executes a lua script
---@class LuaButton : PushButton
---@field buttonNumber number
---@field deck hs.streamdeck
---@field func function
local LuaButton = setmetatable({}, { __index = PushButton })

---@param buttonNumber number
---@param deck hs.streamdeck
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

return LuaButton
