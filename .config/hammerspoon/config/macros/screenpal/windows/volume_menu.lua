local VolumeSubmenu = require("config.macros.screenpal.windows.volume_submenu")

---@class VolumeMenu
---@field _windows AppWindows
---@field _win hs.axuielement | nil
local VolumeMenu = {}
VolumeMenu.__index = VolumeMenu

---@param windows AppWindows
---@return VolumeMenu
function VolumeMenu.new(windows)
    local o = setmetatable({}, VolumeMenu)
    o._windows = windows
    o._win = o:find_my_window()
    return o
end

function VolumeMenu:find_my_window()
    if self._win and self._win:isValid() then
        return self._win
    end

    function lookup()
        return self._windows.windows_by_title["SOM-FloatingWindow-Type=edit2.overlayeditfloat-ZOrder=1(Undefined+1)"]
    end

    local win = lookup()
    if not win or not win:isValid() then
        self._windows:_refresh()
        win = lookup()
    end
    self._win = win
    return win
end

-- ?? generalize to multiple tools OR leave this specific to each tool?
--   ?? i.e. rename to ToolMenu? or have VolumeMenu/FreezeMenu/RerecordMenu?
--   ?? right now I am leaning toward the latter, especially if I keep reusable parts composable

-- FYI can access "Volume" title textField, a bit tricky,
--  ** use your cmd+ctrl+alt+up shortcut to move up to parent textField (it has children text fields that elem inspectors point out)
-- AXValue:  --
-- Volume<string> -- *** by the way NEW LINE at start, hence wrapped AXValue here
-- unique ref: app:window('SOM-FloatingWindow-Type=edit2.overlayeditfloat-ZOrder=1(Undefined+1)'):textField()

-- FYI button for Narration
--   FYI I swear this had a radio button one time I opened it... heads up if that irregularity arisesj
-- AXDescription: Narration<string>
-- AXEnabled: true<bool>
-- unique ref: app:window('SOM-FloatingWindow-Type=edit2.overlayeditfloat-ZOrder=1(Undefined+1)'):button(1)

---@param description string
---@return hs.axuielement | nil
function VolumeMenu:get_button_by_description(description)
    -- PRN extract composable helper for this too
    local win = self:find_my_window()
    if not win then return end

    -- takes <3ms to find the button, that's fine for now, let's not cache controls
    local button = win:button_by_description(description)
    if button and not button:isValid() then
        print("WARNING: Button '" .. description .. "' is not valid, unexpectedly... " .. hs.inspect(button))
    end
    return button
end

function VolumeMenu:wait_for_narrate_title_button()
    return wait_for_element(function()
        return self:get_button_by_description("Narration")
    end, 20, 20, "button Narration")
end

function VolumeMenu:_wait_for_submenu_to_open()
    -- TODO how do I find out if the submenu is already working?
    local button_description = "Narration"

    if not wait_for_element_then_press_it(function()
            return self:get_button_by_description(button_description)
        end, 20, 20, button_description) then
        error("clicking " .. button_description .. "  button failed")
    end

    local submenu = VolumeSubmenu.new(self._windows)
    submenu:wait_for_reset_button()
    return submenu
end

function VolumeMenu:wait_for_volume_to_be_mute()
    -- PRN re-eval this and shuffle as you use it
    local submenu = self:_wait_for_submenu_to_open()
    -- TODO check if already mute before click?
    --  TODO can I find out its state from "Narration" button which has an icon that changes
    --    might have to OCR the element, like I think I am doing with Keyboard Maestro presently
    submenu:press_mute_button()
    wait_until(function()
        return not submenu:is_open()
    end, 20, 20, "submenu is closed")
end

return VolumeMenu
