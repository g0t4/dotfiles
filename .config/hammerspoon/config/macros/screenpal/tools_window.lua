---@class ToolsWindow
---@field _windows AppWindows
---@field _win hs.axuielement | nil
local ToolsWindow = {}
ToolsWindow.__index = ToolsWindow

---@param windows AppWindows
---@return ToolsWindow
function ToolsWindow.new(windows)
    local o = setmetatable({}, ToolsWindow)
    o._windows = windows
    o._win = o:find_my_window()
    return o
end

function ToolsWindow:find_my_window()
    if self._win and self._win:isValid() then
        return self._win
    end
    function lookup()
        return self._windows.windows_by_title["SOM-FloatingWindow-Type=edit2.addedit.toolbar.menu.window-ZOrder=1(Undefined+1)"]
    end

    -- PRN this try/retry could maybe reside in the AppWindows class?
    local win = lookup()
    if not win or not win:isValid() then
        self._windows:_refresh()
        win = lookup()
    end
    self._win = win
    return win
end

---@return hs.axuielement | nil
function ToolsWindow:get_ok_button()
    local win = self:find_my_window()
    if not win then return end
    -- takes <3ms to find the button, that's fine for now, let's not cache controls
    return win:button_by_description("OK")
end

---@return boolean
function ToolsWindow:is_ok_visible()
    return self:get_ok_button() ~= nil
end

return ToolsWindow
