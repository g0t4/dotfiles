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

local function updateIcon(self)
    hs.timer.doAfter(0.01, function()
        local status = Record.status()
        if status.outputActive then
            self.image = onIcon
        else
            self.image = offIcon
        end
        self.deck.hsdeck:setButtonImage(self.buttonNumber, self.image)
    end)
end

function ToggleRecordButton:start()
    -- todo get current state and show that icon (do in background)
    self.deck.hsdeck:setButtonImage(self.buttonNumber, self.image)
    updateIcon(self)
end

function ToggleRecordButton:stop()
end

function ToggleRecordButton:pressed()
    Record.toggle()
    updateIcon(self)
end

function ToggleRecordButton:__tostring()
    return "ToggleRecordButton: " .. (self.buttonNumber or "nil")
end

return ToggleRecordButton
