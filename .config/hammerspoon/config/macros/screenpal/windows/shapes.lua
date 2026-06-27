local log = require("config.logs").hammerspoons()
---@class ShapesWindows
---@field app_windows AppWindows
local ShapesWindows = {}
ShapesWindows.__index = ShapesWindows

---@param app_windows AppWindows
function ShapesWindows.new(app_windows)
    local o = setmetatable({}, ShapesWindows)
    o.app_windows = app_windows
    return o
end

function ShapesWindows:find_shape_picker_window()
    -- app:window('SOM-FloatingWindow-Type=edit2.overlayeditfloat-ZOrder=1(Undefined+1)'):checkBox(desc='Line')
    return self.app_windows:get_window_by_title("SOM-FloatingWindow-Type=edit2.overlayeditfloat-ZOrder=1(Undefined+1)")
end

function ShapesWindows:wait_for_shape_picker_window()
    return wait_for_element(function() return self:find_shape_picker_window() end, 20, 20, "Shape picker window")
end

---@alias ShapeType "Line"|"Rectangle"

---@param shape_type ShapeType
function ShapesWindows:wait_for_shape_type_checkbox_then_press_it(shape_type)
    local picker = self:wait_for_shape_picker_window()
    if not picker then
        error("Shape picker window not found")
    end
    -- TODO use clickIfExists helper? add pressIfExists?
    local checkbox = vim.iter(picker:checkBoxes())
        :find(function(cb)
            return cb:axDescription() == shape_type
        end)
    if not checkbox then
        local message = "Shape type checkbox not found in the picker window"
        log:info(message) -- in my case I allow missing shape type to fall through to ... button... maybe I shouldn't?
    end
    checkbox:axPress()
end

return ShapesWindows
