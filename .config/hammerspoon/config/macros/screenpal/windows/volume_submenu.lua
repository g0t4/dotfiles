local log = require("config.logs").hammerspoons()

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
local VolumeSubmenu = {}
VolumeSubmenu.__index = VolumeSubmenu

---@param windows AppWindows
---@return VolumeSubmenu
function VolumeSubmenu.new(windows)
    local o = setmetatable({}, VolumeSubmenu)
    o._windows = windows
    return o
end

function VolumeSubmenu:find_volume_submenu_window()
    return self._windows:get_window_by_title("SOM-FloatingWindow-Type=edit2.side.menu.window-ZOrder=2(Undefined+2)")
end

function VolumeSubmenu:_wait_for_button_by_description(description)
    local function try_get_button_by_desc()
        -- TODO wait for volume submenu! don't just check the first time!
        local win = self:find_volume_submenu_window()
        if not win then
            log:info("Volume submenu window not found")
            return
        end
        local button = win:button_by_description(description)
        if button and not button:isValid() then
            log:error("WARNING: Button '" .. description .. "' is not valid, unexpectedly... ", button)
            -- TODO error here if it means it will always fail after this
        end
        return button
    end

    -- PRN sync with what VolumeMenu does for waiting to get its buttons by description...
    -- TODO rewrite this stuff to use syncify so I can see it all in one damn spot what actually happens (waits vs not) and write/split functions for readability
    if not wait_for_element_then_press_it(function()
            return try_get_button_by_desc()
        end, 20, 20) then
        error("clicking " .. description .. "  button failed")
    end
end

function VolumeSubmenu:wait_for_reset_button()
    return self:_wait_for_button_by_description("Reset volume levels")
end

function VolumeSubmenu:press_reset_button()
    local button = self:wait_for_reset_button()
    if not button then error("Could not find _RESET_ button") end
    button:axPress()
end

function VolumeSubmenu:press_mute_button()
    local button = self:_wait_for_button_by_description("Silence volume levels")
    if not button then error("Could not find _MUTE_ button") end
    button:axPress()
end

function VolumeSubmenu:is_open()
    local win = self:find_volume_submenu_window()
    return win and win:isValid()
end

return VolumeSubmenu
