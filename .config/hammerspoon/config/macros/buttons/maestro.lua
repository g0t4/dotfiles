require("config.macros.buttons.helpers")
require("config.macros.buttons.commands")
local PushButton = require("config.macros.buttons.push")

---@class MaestroButton : PushButton
---@field macro string @Name or UUID
---@field param string|nil
local MaestroButton = setmetatable({}, { __index = PushButton })

function MaestroButton:new(buttonNumber, deck, image, macro, param)
    ---@class MaestroButton
    local o = PushButton.new(MaestroButton, buttonNumber, deck, image)
    o.macro = macro
    o.param = param
    return o
end

function MaestroButton:pressed()
    -- FYI could use osascript too (pass applescript to hammerspoon?)
    verbose("exec KM: " .. self.macro .. " (" .. self.param .. ")")
    runKMMacro(self.macro, self.param)
end

function MaestroButton:__tostring()
    return "MaestroButton: " .. (self.buttonNumber or "nil")
        .. " " .. self.macro
        .. " " .. self.param
end

return MaestroButton
