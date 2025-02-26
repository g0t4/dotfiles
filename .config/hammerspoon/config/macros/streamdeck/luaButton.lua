PushButton = require("config.macros.buttons.pushButton")


-- a button that executes a lua script
---@class LuaButton : PushButton
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

function LuaButton:__tostring()
    return "LuaButton: " .. (self.buttonNumber or "nil")
end

-- local test = LuaButton:new(1, {}, nil, function() print("test lua func") end)
-- print("__tostring on lua button:\n ", test)

return LuaButton
