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
        -- print("lookup")
        -- vim.iter(self._windows.windows_by_title):each(function(k, v)
        --     print("  Window title: " .. k .. " = " .. tostring(v:axTitle()))
        -- end)
        return self._windows.windows_by_title["SOM-FloatingWindow-Type=edit2.overlayeditfloat-ZOrder=1(Undefined+1)"]
    end

    local win = lookup()
    if not win or not win:isValid() then
        self._windows:_refresh()
        win = lookup()
    end
    self._win = win
    -- print("Found2: ", win)
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

---@param description string
---@return hs.axuielement | nil
function VolumeMenu:get_button_by_description(description)
    -- PRN extract composable helper for this too
    local win = self:find_my_window()
    if not win then return end

    -- FYI I have captures with the button on window and also nested... can I verify what it actually is?
    --   maybe it's never direclty on the window?
    --    FYI my elem inspector cannot nav the children (down nor up) for this radio button... PRN research that
    --    or the AX APIs might
    --     app:window(1):button(1)
    --     window(2):tabGroup(1):radioButton(1):button(1)
    --      but then it seems like it is actually here:
    --        tabGroup(1):button(1) in my testing...
    --
    -- elem captures Narration button:
    -- AXDescription: Narration<string>
    -- AXEnabled: true<bool>
    -- unique ref: app:window('SOM-FloatingWindow-Type=edit2.overlayeditfloat-ZOrder=1(Undefined+1)'):button(1)
    --
    -- VERSUS:
    --
    -- FML sometimes it's nested in tabGroup... (but then seems to be under tabGroup and not radioButton!)
    -- app:window(2):tabGroup(1):radioButton(1):button(1)
    -- AXDescription: Narration<string>
    -- unique ref: app:window('SOM-FloatingWindow-Type=edit2.overlayeditfloat-ZOrder=1(Undefined+1)'):tabGroup()
    --   :radioButton(''):button()

    -- print("WIN " .. tostring(win:axTitle()))
    -- vim.iter(win:children()):each(function(e)
    --     print("  " .. e:axRole() .. ": " .. e:axDescription())
    -- end)

    -- takes <3ms to find the button, that's fine for now, let's not cache controls
    local button = win:button_by_description(description)
    if button and not button:isValid() then
        print("WARNING: Button '" .. description .. "' is not valid, unexpectedly... " .. hs.inspect(button))
    end

    if not button then
        local tab_group = win:tabGroup(1)
        if not tab_group then
            print('F3: no tab group') -- debug, remove later
            return
        end
        vim.iter(tabGroup:children()):each(function(e)
            -- leave this debug code until stuff is rock solid
            print("  tabGroup child: " .. e:axRole() .. ": " .. e:axDescription())
        end)
        --   so, it's tabGroup(1):button(1) in my testing...
        -- FYI! this is working to select MUTE with the rest of the waits! Aside from this hellish button crap...
        --    the rest of the code just worked the first time!
        local button = tab_group:button(1)

        -- * vet description matches
        local desc = button:axDescription()
        if desc ~= description then
            print("WARNING: tabGroup nested button description does not match! " .. desc .. " vs " .. description)
            return nil
        end
        return button
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
