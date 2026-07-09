---@module "config.ui.canvas_spinner"
-- Canvas-based spinner overlay module for indicating processing state.
-- Ensures only one spinner canvas exists at a time.

local CanvasSpinner = {}

---@type hs.canvas?
local _spinner_canvas = nil

---@type hs.timer?
local _spinner_timer = nil

---@type string[]
local _spinner_frames = {'⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'}

---@type integer
local _spinner_frame_index_base0 = 0

---@param screen hs.screen?
---@return table
function CanvasSpinner:start(screen)
    if _spinner_canvas then
        self:stop()
    end

    local target_screen = screen or hs.screen.mainScreen()
    local bounds = target_screen:frame()

    -- Create canvas covering the display
    local canvas = hs.canvas.new({
        x = bounds.x,
        y = bounds.y,
        w = bounds.w,
        h = bounds.h
    }):show()

    -- Set canvas behaviors and level
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    canvas:level(hs.canvas.windowLevels.floating)

    local box_w = 140
    local box_h = 50
    local box_x = (bounds.w - box_w) / 2 + bounds.x
    local box_y = (bounds.h - box_h) / 2 + bounds.y

    -- Add semi-transparent background box and spinner text
    canvas:appendElements({
        {
            type = 'rectangle',
            id = 'spinner_background',
            action = 'fill',
            frame = {x = box_x, y = box_y, w = box_w, h = box_h},
            fillColor = {red = 0, green = 0, blue = 0, alpha = 0.75},
            cornerRadius = 8
        },
        {
            type = 'text',
            id = 'spinner_text',
            action = 'build',
            string = _spinner_frames[_spinner_frame_index_base0 + 1] .. ' Processing...',
            font = 'Helvetica-Bold',
            size = 18,
            textColor = {white = 1, alpha = 1},
            alignment = 'center',
            frame = {x = box_x, y = box_y, w = box_w, h = box_h}
        }
    })

    _spinner_canvas = canvas

    -- Start timer to rotate text (0.1 seconds = 100ms)
    _spinner_timer = hs.timer.doEvery(0.1, function()
        if not _spinner_canvas then
            return
        end
        _spinner_frame_index_base0 = (_spinner_frame_index_base0 + 1) % #_spinner_frames
        local frame_text = _spinner_frames[_spinner_frame_index_base0 + 1]
        -- Update text element via canvas table indexing by id
        if _spinner_canvas['spinner_text'] then
            _spinner_canvas['spinner_text'].string = frame_text .. ' Processing...'
        end
    end)

    return self
end

---@return table
function CanvasSpinner:stop()
    if _spinner_timer then
        _spinner_timer:stop()
        _spinner_timer = nil
    end
    if _spinner_canvas then
        _spinner_canvas:delete()
        _spinner_canvas = nil
    end
    _spinner_frame_index_base0 = 0
    return self
end

-- Singleton instance
local canvas_spinner_instance = setmetatable({}, {
    __index = CanvasSpinner
})

return canvas_spinner_instance
