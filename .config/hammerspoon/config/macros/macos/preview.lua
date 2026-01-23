local inspect = require "hs.inspect"

local function get_preview_app()
    return GetAppElement("com.apple.Preview")
end

function _PreviewApp_LineWeight(button_text_to_click)
    -- !!! DO NOT PASS STRINGS from streamdeck buttons for now
    --  you broke it horribly for any quoting when you moved to your own streamdeck KM macro button

    local app = get_preview_app()
    if not app then return end

    local win = app:axFocusedWindow()
    if not win then return end

    local toolbar = win:toolbar(1)
    if not toolbar then return end

    -- * ensure shape style popover open
    local popover = toolbar:popover(1) -- app:window(1):toolbar(1):popover(1)
    if not popover then
        -- * shape style button
        -- app:window(1):toolbar(1):button(12)
        -- AXDescription: Shape Style<string>
        -- AXHelp: Shape Style<string>
        local line_weight_picker = toolbar:button_by_description("Shape Style")
        if not line_weight_picker then return end

        line_weight_picker:axPress()
        popover = toolbar:popover(1)
    end
    if not popover then return end

    if button_text_to_click then
        -- AXDescriptions:
        --
        -- Line thickness: hairline
        -- Line thickness: 2
        -- Line thickness: 3
        -- Line thickness: 4
        -- Line thickness: 5
        -- Line thickness: 10
        -- Line thickness: 15
        --
        -- Draw line dashed
        -- Draw line with brush style
        --
        -- Draw with shadow

        local button_on_popover = popover:button_by_description_matching(button_text_to_click)
        if button_on_popover then
            print("found button")
            button_on_popover:axPress()
        end
    end
end

function PreviewApp_LineWeight_Dashed()
    _PreviewApp_LineWeight("Draw line dashed")
end

function PreviewApp_LineWeight_BrushStyle()
    _PreviewApp_LineWeight("Draw line with brush style")
end

function PreviewApp_LineWeight_Hairline()
    _PreviewApp_LineWeight("hairline")
end

function PreviewApp_LineWeight_2()
    _PreviewApp_LineWeight("Line thickness: 2")
end

function PreviewApp_LineWeight_3()
    _PreviewApp_LineWeight("Line thickness: 3")
end

function PreviewApp_LineWeight_4()
    _PreviewApp_LineWeight("Line thickness: 4")
end

function PreviewApp_LineWeight_5()
    _PreviewApp_LineWeight("Line thickness: 5")
end

function PreviewApp_LineWeight_10()
    _PreviewApp_LineWeight("Line thickness: 10")
end

function PreviewApp_LineWeight_15()
    _PreviewApp_LineWeight("Line thickness: 15")
end

function PreviewApp_DrawWithShadow()
    _PreviewApp_LineWeight("Draw with shadow")
end
