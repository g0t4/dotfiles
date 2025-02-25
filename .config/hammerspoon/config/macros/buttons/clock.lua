require("config.macros.buttons.textToImage")

local function getTimeImage()
    local now = os.date("%H:%M")
    local date = os.date("%a\n%b %d")
    -- https://www.lua.org/pil/22.1.html
    return drawTextIcon(now .. "\n" .. date)
end



-- @classmod ClockButton
local ClockButton = {}
ClockButton.__index = ClockButton

-- @param buttonNumber number
-- @param deck hs.streamdeck
-- @return ClockButton
function ClockButton:new(buttonNumber, deck)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.buttonNumber = buttonNumber
    o.deck = deck
    o.lastTime = nil
    o.timer = hs.timer.doEvery(10, function()
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
