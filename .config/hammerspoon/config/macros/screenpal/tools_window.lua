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

---@param description string
---@return hs.axuielement | nil
function ToolsWindow:get_button_by_description(description)
    local win = self:find_my_window()
    if not win then return end

    -- takes <3ms to find the button, that's fine for now, let's not cache controls
    local button = win:button_by_description(description)
    if button and not button:isValid() then
        print("WARNING: Button '" .. description .. "' is not valid, unexpectedly... " .. hs.inspect(button))
        -- IIAC this would only happen if an OLD window was still valid that had an invalid button
        -- that does not seem likely, instead I would assume only the most recent window reference is valid
        -- ** DO NOT put this code into every element lookup, unless this happens with OK
    end
    return button
end

function ToolsWindow:wait_for_tools_button()
    return wait_for_element(function() return self:get_button_by_description("Tools") end, 20, 20, "button Tools")
end

function ToolsWindow:wait_for_ok_button()
    return wait_for_element(function() return self:get_button_by_description("OK") end, 20, 20, "button OK")
end

function ToolsWindow:wait_for_ok_button_then_press_it()
    if not wait_for_element_then_press_it(function() return self:get_button_by_description("OK") end, 20, 20) then
        error("clicking OK button failed") -- kill action is fine b/c I will be using this in streamdeck button handlers, just means that button press dies
    end
    self:wait_for_tools_button()
    -- no further action, thus don't need return value (not found, no diff than if found)
end

return ToolsWindow
