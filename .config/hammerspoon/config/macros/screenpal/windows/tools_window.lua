---@class ToolBarWindow
---@field _windows AppWindows
---@field _win hs.axuielement | nil
local ToolBarWindow = {}
ToolBarWindow.__index = ToolBarWindow

---@param windows AppWindows
---@return ToolBarWindow
function ToolBarWindow.new(windows)
    local o = setmetatable({}, ToolBarWindow)
    o._windows = windows
    o._win = o:find_my_window()
    return o
end

function ToolBarWindow:find_my_window()
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

---@param exact_match string
---@return hs.axuielement | nil
function ToolBarWindow:get_button_by_description(exact_match)
    return self:get_button_by_description_matching("^" .. exact_match .. "$")
end

---@param lua_pattern string
---@return hs.axuielement | nil
function ToolBarWindow:get_button_by_description_matching(lua_pattern)
    local win = self:find_my_window()
    if not win then return end

    -- -- takes <3ms to find the button, that's fine for now, let's not cache controls
    local button = win:button_by_description_matching(lua_pattern)
    if button and not button:isValid() then
        print("WARNING: Button matching pattern '" .. lua_pattern .. "' is not valid, unexpectedly... " .. hs.inspect(button))
        -- IIAC this would only happen if an OLD window was still valid that had an invalid button
        -- that does not seem likely, instead I would assume only the most recent window reference is valid
        -- ** DO NOT put this code into every element lookup, unless this happens with OK
    end
    return button
end

function ToolBarWindow:wait_for_cancel_or_ok_button()
    -- toolbar opens to cancel/ok one tool is started
    wait_until(function()
        return (self:get_button_by_description("Cancel") ~= nil)
            or (self:get_button_by_description("OK") ~= nil)
    end, 20, 20, "ok or cancel button - toolbar opened for tool")
end

function ToolBarWindow:wait_for_tools_button()
    return wait_for_element(function() return self:get_button_by_description("Tools") end, 20, 20, "button Tools")
end

function ToolBarWindow:wait_for_ok_button()
    return wait_for_element(function() return self:get_button_by_description("OK") end, 20, 20, "button OK")
end

function ToolBarWindow:wait_for_ok_button_then_press_it()
    if not wait_for_element_then_press_it(function() return self:get_button_by_description("OK") end, 20, 20) then
        error("clicking OK button failed") -- kill action is fine b/c I will be using this in streamdeck button handlers, just means that button press dies
    end
    -- FYI taking 300-400ms to find Tools button, so don't shirk waiting
    self:wait_for_tools_button()
    -- no further action, thus don't need return value (not found, no diff than if found)
end

---@return hs.axuielement[]
function ToolBarWindow:get_edits_buttons()
    self:wait_for_tools_button() -- good way to wait for toolbar to be "ready"
    -- first two are not for edits, they're the Tools menu and button to use the last used tool (Volume in this case)
    -- AXButton: desc:'Tools'
    -- AXButton: desc:'Volume'
    -- AXButton: desc:'Shape (2.68 sec)'
    -- AXButton: desc:'Volume (0.32 sec)'
    --   the buttons for current edits/tools have () in description
    --
    --   FYI in AppleScript I used:
    --       return a reference to (every button of my toolbar whose description ends with " sec)")
    --       use this if you have issues with just ()
    --
    return vim.iter(self._win:buttons())
        :filter(function(button)
            local description = button:attributeValue("AXDescription")
            return string.match(description, "%b()") ~= nil
        end)
        :totable()
end

---@param substring string
---@return hs.axuielement[]
function ToolBarWindow:get_edit_buttons_by_description(substring)
    return vim.iter(self:get_edits_buttons())
        :filter(function(button) return button:attributeValue("AXDescription"):find(substring) ~= nil end)
        :totable()
end

---@return hs.axuielement[]
function ToolBarWindow:get_volume_edit_buttons()
    return self:get_edit_buttons_by_description("Volume")
end

function ToolBarWindow:get_copy_overlay_button()
    -- if needed, organize this with other buttons that show when an "edit" is open
    return self:get_button_by_description_matching("^Copy overlay")
end

return ToolBarWindow
