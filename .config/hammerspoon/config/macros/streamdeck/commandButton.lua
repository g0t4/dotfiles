local PushButton = require("config.macros.streamdeck.pushButton")
require("config.macros.streamdeck.commands")
require("config.macros.streamdeck.helpers")


---@class CommandButton : PushButton
---@field command table<integer, string>
local CommandButton = setmetatable({}, { __index = PushButton })
CommandButton.__index = CommandButton

---@param buttonNumber integer
---@param deck DeckController
---@param image hs.image
---@param command table<integer, string>
---@return CommandButton
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

function CommandButton:__tostring()
    return "CommandButton " .. table.concat(self.command, " ")
end

return CommandButton
