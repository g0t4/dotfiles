---@class ToolsWindow
---@field win hs.axuielement
local ToolsWindow = {}
ToolsWindow.__index = ToolsWindow

---@param win hs.axuielement
---@return ToolsWindow
function ToolsWindow.new(win)
    local o = setmetatable({}, ToolsWindow)
    o.win = win
    return o
end

---@return hs.axuielement | nil
function get_ok_button(self)
    -- takes <3ms to find the button, that's fine for now, let's not cache controls
    return self.win:button_by_description("OK")
end

function ToolsWindow:is_ok_visible()
    return get_ok_button(self) ~= nil
end

return ToolsWindow
