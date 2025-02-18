local M = {}
M.last = {
    element = nil,
    tooltip = nil,
    callout = nil,
}
local canvas = require("hs.canvas")
local function showTooltipForElement(element, frame)
    if not element then return end

    -- TODO copy to clipboard -- maybe do it by default when in scan mode?
    -- TODO add pause mode that doesn't hide callout/tooltip... but freezes it (maybe that is when to copy it!)
    --    register opt key or smth like that and unregister it when hide callout/tooltip

    -- PRN could add coloring of text if I can show an html element in canvas
    local clauses = BuildAppleScriptTo(element, false)
    local script = combineClausesWithLineContinuations(clauses)
    local text = script

    local tmpcanvas = canvas.new({ x = 0, y = 0, w = 1000, h = 1000 })
    local estimatedSizeForDefaultFont = tmpcanvas:minimumTextSize(text)
    local useFontSize = 14
    local defaultTextStyle = canvas.defaultTextStyle()
    -- *** SUPER HACK to get font sizing to work... this works though!
    --    BTW font height estimate is off, could find factor for it but for 14 point it will work with default at 27pt so I won't adjust it for now...
    -- print("defaultTextStyle", hs.inspect(defaultTextStyle))
    local ratio = useFontSize / defaultTextStyle.font.size
    local tooltipWidth = estimatedSizeForDefaultFont.w * ratio * 1.2
    local tooltipHeight = estimatedSizeForDefaultFont.h * ratio * 1.2

    -- add padding (don't subtract it from needed width/height)
    local padding = 10
    tooltipWidth = tooltipWidth + 2 * padding
    tooltipHeight = tooltipHeight + 2 * padding

    local screenFrame = hs.screen.mainScreen():frame() -- Gets the current screen dimensions

    -- Initial positioning (slightly below the element)
    local x = frame.x
    local y = frame.y + frame.h + 5 -- Below the element

    -- Ensure tooltip does not go off the right edge
    if x + tooltipWidth > screenFrame.x + screenFrame.w then
        x = screenFrame.x + screenFrame.w - tooltipWidth - 10 -- Shift left
        -- IIUC the box is positioned to right of element left side so I don't think I need to worry about x being shifted left of screen
    end

    -- Ensure tooltip does not go off the bottom edge
    if y + tooltipHeight > screenFrame.y + screenFrame.h then
        -- if it's off the bottom, then move it above the element
        y = frame.y - tooltipHeight - 5 -- Move above element
        if y < screenFrame.y then
            -- if above is also off screen, then shift it down, INSIDE the frame
            --   means it stays on top btw... could put it inside on bottom too
            y = screenFrame.y + 10 -- Shift up
        end
    end

    M.last.tooltip = hs.canvas.new({ x = x, y = y, w = tooltipWidth, h = tooltipHeight })
        :appendElements({
            -- Background box
            {
                type = "rectangle",
                action = "fill",
                frame = { x = 0, y = 0, w = tooltipWidth, h = tooltipHeight },
                fillColor = { white = 0, alpha = 0.8 }, -- Dark semi-transparent background
                roundedRectRadii = { xRadius = 8, yRadius = 8 }
            },
            -- Text
            {
                type = "text",
                text = text,
                textSize = useFontSize,
                textColor = { white = 1 },
                frame = { x = padding, y = padding, w = tooltipWidth - 2 * padding, h = tooltipHeight - 2 * padding },
                textAlignment = "left"
            }
        })
        :show()
end

local function removeHighlight()
    if not M.last.element then
        return
    end
    if M.last.tooltip then
        M.last.tooltip:delete()
    end
    if M.last.callout then
        M.last.callout:delete()
    end
    M.last.element = nil
    M.last.tooltip = nil
    M.last.callout = nil
end

local function highlightCurrentElement()
    assert(M.last ~= nil)
    removeHighlight()

    local pos = hs.mouse.absolutePosition()
    local element = hs.axuielement.systemElementAtPosition(pos)
    if element == M.last.element then
        -- skip if same element
        return
    end

    M.last.element = element
    local frame = element:attributeValue("AXFrame")
    -- sometimes the frame is off screen... like a scrolled window (i.e. hammerspoon console)...
    --   would I cap its border with the boundaries of a parent element?

    local canvas = require("hs.canvas")
    M.last.callout = canvas.new(frame)
        :appendElements({
            action = "stroke",
            padding = 0,
            type = "rectangle",
            fillColor = { red = 1, blue = 0, green = 0 },
            strokeColor = { red = 1, blue = 0, green = 0, alpha = 0.5 },
            strokeWidth = 4,
        }):show()

    showTooltipForElement(element, frame)
end

M.moves = nil
M.stop_event_source = nil
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
    if not M.moves then
        M.moves, M.stop_event_source = require("config.rx.mouse").mouseMovesThrottledObservable(50)
        M.subscription = M.moves:subscribe(
            function()
                -- stream is just move alert not position
                highlightCurrentElement()
            end
        -- function(error)
        --     -- right now my sources don't levearge error (nor complete) events... so just ignore
        --     print("[ERROR] what to do here?", error)
        -- end,
        -- function()
        --     print("[COMPLETE] what to do here?")
        -- end
        )
    else
        M.moves = nil
        M.subscription:unsubscribe() -- subscription cleanup is all... really can skip this here
        removeHighlight() -- clear the callout/tooltips
        if M.stop_event_source then
            -- separately need to stop the upstream event source (do not comingle unsub w/ stop source, usually you might have multiple subs and would want to separately control the subs vs source)
            M.stop_event_source()
            M.stop_event_source = nil
        end
    end
end)

return M
