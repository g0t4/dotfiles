require("config.macros.streamdeck.helpers")
require("config.macros.streamdeck.commands")
local PushButton = require("config.macros.streamdeck.pushButton")

-- *** CommandButton

---@class CommandButton : PushButton
---@field buttonNumber integer
---@field deck hs.streamdeck
---@field image string
---@field command table<integer, string>
local CommandButton = setmetatable({}, { __index = PushButton })

function CommandButton:new(buttonNumber, deck, image, command)
    ---@class CommandButton
    local o = PushButton.new(CommandButton, buttonNumber, deck, image)
    o.command = command
    return o
end

function CommandButton:pressed()
    local commandString = table.concat(self.command, " ")
    verbose("exec command: " .. commandString)
    runCommand(commandString)
end

return CommandButton
