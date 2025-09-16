--
-- ?? specialize by sub-menu type, so I have one of these for volume's submenu?
--  ?? wait until I am using other submenus, for now treat as a monolith
--
-- unique ref: app:window('SOM-FloatingWindow-Type=edit2.side.menu.window-ZOrder=2(Undefined+2)')
--   :button(desc='Reset volume levels')


-- FYI button 1 - reset
-- reset volume button (when the volume was reset so it was grayed out:)
-- app:window(1):button(1)
-- AXDescription: Reset volume levels<string>
-- AXEnabled: false<bool> **** NOT ENABLED  = CURRENT VALUE!

-- AXDescription: Decrease volume levels<string>
-- AXEnabled: true<bool>

-- AXDescription: Increase volume levels<string>
-- AXEnabled: true<bool>

-- FYI button 4 - mute
-- AXDescription: Silence volume levels<string>
-- AXEnabled: true<bool> *** NOTICE it is enabled b/c its not the current value!


-- TODO I hope this can be hidden behind one facade somewhere as consumers shouldn't care about the windows


---@class VolumeSubmenu
---@field _windows AppWindows
---@field _win hs.axuielement | nil
local VolumeSubmenu = {}
VolumeSubmenu.__index = VolumeSubmenu

---@param windows AppWindows
---@return VolumeSubmenu
function VolumeSubmenu.new(windows)
    local o = setmetatable({}, VolumeSubmenu)
    o._windows = windows
    o._win = o:find_my_window()
    return o
end

function VolumeSubmenu:find_my_window()
    if self._win and self._win:isValid() then
        return self._win
    end
    function lookup()
        return self._windows.windows_by_title["SOM-FloatingWindow-Type=edit2.side.menu.window-ZOrder=2(Undefined+2)"]
    end

    local win = lookup()
    if not win or not win:isValid() then
        self._windows:_refresh()
        win = lookup()
    end
    self._win = win
    return win
end

function VolumeSubmenu:wait_for_button_by_description(description)
    local win = self:find_my_window()
    if not win then return end
    local button = win:button_by_description(description)
    if button and not button:isValid() then
        print("WARNING: Button '" .. description .. "' is not valid, unexpectedly... " .. hs.inspect(button))
    end
    return button
end

function VolumeSubmenu:wait_for_reset_button()
    return self:wait_for_button_by_description("Reset volume levels")
end

function VolumeSubmenu:press_reset_button()
    local button = self:wait_for_reset_button()
    if not button then error("Could not find button") end
    button:axPress()
end

function VolumeSubmenu:press_mute_button()
    local button = self:wait_for_button_by_description("Silence volume levels")
    if not button then error("Could not find button") end
    button:axPress()
end

function VolumeSubmenu:is_open()
    local win = self:find_my_window()
    return win and win:isValid()
end

return VolumeSubmenu
