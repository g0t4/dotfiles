require("config.macros.buttons.textToImage")
PushButton = require("config.macros.buttons.push")

local function getTimeImage()
    local now = os.date("%H:%M")
    local date = os.date("%a\n%b %d")
    -- https://www.lua.org/pil/22.1.html
    return drawTextIcon(now .. "\n" .. date)
end

---@class ClockButton : PushButton
---@field lastTime string|nil
---@field timer hs.timer
local ClockButton = setmetatable({}, { __index = PushButton })
ClockButton.__index = ClockButton

---@param buttonNumber number
---@param deck hs.streamdeck
---@return ClockButton
function ClockButton:new(buttonNumber, deck)
    -- w/o specifying child class on new object, lua-ls complains:
    --   Fields cannot be injected into the reference of `PushButton` for `lastTime`.
    --   To do so, use `---@class` for `o`. (Lua Diagnostics. inject-field))
    ---@class ClockButton
    local o = PushButton.new(self, buttonNumber, deck)
    setmetatable(o, self)
    o.lastTime = nil
    o.timer = hs.timer.doEvery(10, function()
        -- FYI this is a good case where button needs to know its deck/number to update the image!
        local now = os.date("%H:%M")
        if o.lastTime ~= nil and o.lastTime == now then
            return
        end
        deck:setButtonImage(buttonNumber, getTimeImage())
    end)
    return o
end

function ClockButton:start()
    self.timer:start()
    self.timer:fire()
end

function ClockButton:stop()
    -- todo mechanism to stop/cleanup timer if button removed
    -- FYI let something else handle reset on the button image, behavior, etc
    self.timer:stop()
end

return ClockButton
