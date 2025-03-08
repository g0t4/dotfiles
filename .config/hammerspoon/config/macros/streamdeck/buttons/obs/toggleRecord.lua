local PushButton = require("config.macros.streamdeck.pushButton")

---@class ToggleRecordButton : PushButton
local ToggleRecordButton = setmetatable({}, { __index = PushButton })


local offIcon = hsIcon("test-svgs/hanging-96.png")
local onIcon = hsIcon("test-svgs/upright2-64.png")

---@param buttonNumber integer
---@param deck DeckController
---@return ToggleRecordButton
function ToggleRecordButton:new(buttonNumber, deck)
    ---@class ToggleRecordButton
    local o = PushButton.new(ToggleRecordButton, buttonNumber, deck, offIcon)
    return o
end

function ToggleRecordButton:start()
    -- todo get current state and show that icon (do in background)
    PushButton.start(self)
    hs.timer.doAfter(0.01, function()
        local status = Record.status()
        if status.outputActive then
            self.icon = onIcon
        else
            self.icon = offIcon
        end
    end)
end

function ToggleRecordButton:stop()
end

function ToggleRecordButton:pressed()
    Record.toggle()
end

function ToggleRecordButton:__tostring()
    return "ToggleRecordButton: " .. (self.buttonNumber or "nil")
end

return ToggleRecordButton
