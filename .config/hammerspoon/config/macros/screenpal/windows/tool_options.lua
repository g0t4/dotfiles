local log = require("config.logs").hammerspoons()
---@class ToolOptionWindows
---@field app_windows AppWindows
local ToolOptionWindows = {}
ToolOptionWindows.__index = ToolOptionWindows

---@param app_windows AppWindows
function ToolOptionWindows.new(app_windows)
    local o = setmetatable({}, ToolOptionWindows)
    o.app_windows = app_windows
    return o
end

function ToolOptionWindows:find_shape_picker_window()
    return self.app_windows:get_window_by_title("SOM-FloatingWindow-Type=edit2.overlayeditfloat-ZOrder=1(Undefined+1)")
end

function ToolOptionWindows:wait_for_shape_picker_window()
    return wait_for_element(function() return self:find_shape_picker_window() end, 20, 20, "Shape picker window")
end

---@alias ShapeType "Rectangle"|"RoundedRectangle"|"Triangle"|"Oval"  |  "Star"|"Heart"|"Line" | ""

---@param shape_type ShapeType
function ToolOptionWindows:wait_for_shape_type_checkbox_then_press_it(shape_type)
    local picker = self:wait_for_shape_picker_window()
    if not picker then
        error("Shape picker window not found")
    end
    press_if_exists(function()
        return picker:checkbox_by_description(shape_type)
    end)
end

function ToolOptionWindows:find_shape_picker_submenu_window()
    return self.app_windows:get_window_by_title("SOM-FloatingWindow-Type=edit2.side.menu.window-ZOrder=1(Undefined+1)")
end

function ToolOptionWindows:wait_for_shape_picker_submenu_window()
    return wait_for_element(function() return self:find_shape_picker_submenu_window() end, 20, 20, "Shape picker submenu window")
end

function ToolOptionWindows:get_freeze_tool_window()
    return self.app_windows:get_window_by_title("SOM-FloatingWindow-Type=edit2.tool.freeze.controls-ZOrder=1(Undefined+1)")
end

function ToolOptionWindows:wait_for_freeze_tool_window()
    return wait_for_element(function() return self:get_freeze_tool_window() end, 20, 20, "Freeze tool window")
end

function ToolOptionWindows:wait_and_press_freeze_frame_option(description)
    local win = self:wait_for_freeze_tool_window()
    if not win then
        error("Freeze tool window not found")
    end
    win:button_by_description("End"):axPress()

    press_if_exists(function() return win:button_by_description(description) end)
end


--- * RANGE SELECTION TOOLBAR WINDOW
--- has buttons to select to start/end of video file

-- app:window(2):button(2)
-- AXDescription: Select everything from this point to the start of the video<string>
-- frame: x=1099.0,y=326.0,w=40.0,h=42.0
-- unique ref: app:window('SOM-FloatingWindow-Type=edit2.addedit.toolbar.menu.window-ZOrder=1(Undefined+1)')
--   :button(desc='Select everything from this point to the start of the video')

function ToolOptionWindows:find_range_selection_toolbar_window()
    return self.app_windows:get_window_by_title("SOM-FloatingWindow-Type=edit2.addedit.toolbar.menu.window-ZOrder=1(Undefined+1)")
end

function ToolOptionWindows:wait_for_range_selection_toolbar_window()
    return wait_for_element(function() return self:find_range_selection_toolbar_window() end, 20, 20, "Range selection toolbar window")
end

return ToolOptionWindows
